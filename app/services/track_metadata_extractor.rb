require "open3"
require "json"

class TrackMetadataExtractor
  def self.extract(file_key)
    ext = File.extname(file_key).presence || ".audio"
    temp_file = Tempfile.new(["track_upload", ext], binmode: true)
    cover_file = Tempfile.new(["cover_art", ".jpg"], binmode: true)

    begin
      # 1. Скачиваем аудиофайл из MinIO во временный файл
      S3_CLIENT.get_object(
        bucket: S3_BUCKET_NAME,
        key: file_key,
        response_target: temp_file.path
      )

      # 2. Извлекаем метаданные через ffprobe (JSON output)
      probe_cmd = [
        "ffprobe", "-v", "quiet",
        "-print_format", "json",
        "-show_format", "-show_streams",
        temp_file.path
      ]
      stdout, _stderr, status = Open3.capture3(*probe_cmd)
      probe_data = status.success? ? JSON.parse(stdout) : {}

      format_info = probe_data["format"] || {}
      tags = format_info["tags"] || {}
      # Нормализуем ключи тегов к нижнему регистру (FLAC использует капсом TITLE, MP3 в lowercase)
      normalized_tags = tags.transform_keys(&:downcase)

      raw_title = normalized_tags["title"].presence || File.basename(file_key, ".*").sub(/^[a-f0-9\-]+_/, "")
      title = raw_title.to_s.strip
      artist_name = (normalized_tags["artist"] || normalized_tags["album_artist"] || "Unknown Artist").to_s.strip
      album_title = (normalized_tags["album"] || "Single").to_s.strip

      raw_track_num = normalized_tags["track"] || normalized_tags["tracknumber"] || 1
      track_number = raw_track_num.to_s.split("/").first.to_i
      track_number = 1 if track_number.zero?

      raw_year = normalized_tags["date"] || normalized_tags["year"]
      release_year = raw_year.to_s[/\d{4}/]&.to_i

      duration = (format_info["duration"].to_f).round
      duration = 1 if duration.zero?

      # 3. Извлекаем обложку альбома (если есть встроенный арт)
      cover_key = nil
      has_video_stream = (probe_data["streams"] || []).any? { |s| s["codec_type"] == "video" }
      if has_video_stream
        cover_cmd = ["ffmpeg", "-y", "-i", temp_file.path, "-an", "-vcodec", "copy", cover_file.path]
        _cout, _cerr, cstatus = Open3.capture3(*cover_cmd)
        if cstatus.success? && File.size?(cover_file.path).to_i > 100
          cover_key = "covers/#{SecureRandom.uuid}.jpg"
          File.open(cover_file.path, "rb") do |f|
            S3_CLIENT.put_object(
              bucket: S3_BUCKET_NAME,
              key: cover_key,
              body: f,
              content_type: "image/jpeg"
            )
          end
        end
      end

      # 4. Генерируем 100 точек для звуковой волны (Waveform Peaks)
      waveform = generate_waveform(temp_file.path)

      {
        title: title,
        artist_name: artist_name,
        album_title: album_title,
        track_number: track_number,
        duration: duration,
        release_year: release_year,
        cover_key: cover_key,
        waveform: waveform
      }
    ensure
      temp_file.close
      temp_file.unlink
      cover_file.close
      cover_file.unlink
    end
  end

  private

  def self.generate_waveform(file_path, points = 100)
    # Даунсемплим в моно PCM 1000 Гц 16-бит
    cmd = ["ffmpeg", "-i", file_path, "-ac", "1", "-filter:a", "aresample=1000", "-f", "s16le", "-"]
    raw_pcm, _stderr, status = Open3.capture3(*cmd)
    return Array.new(points, 0.08) unless status.success? && !raw_pcm.empty?

    samples = raw_pcm.unpack("s*")
    return Array.new(points, 0.08) if samples.empty?

    chunk_size = (samples.size / points.to_f).ceil
    chunks = samples.each_slice(chunk_size).to_a

    # Вычисляем RMS (Root Mean Square) энергию для каждого бакета вместо плоского пика
    rms_values = chunks.map do |chunk|
      next 0.0 if chunk.empty?
      sum_sq = chunk.sum { |s| s * s }
      Math.sqrt(sum_sq.to_f / chunk.size)
    end

    max_rms = rms_values.max.to_f
    return Array.new(points, 0.08) if max_rms <= 0

    # Относительная нормализация к пику трека с плавной степенной кривой (1.15)
    # чтобы тихие участки (интро/куплеты) и кульминации (дропы/припевы) были четко различимы
    peaks = rms_values.map do |rms|
      ratio = rms / max_rms
      scaled = (ratio**1.15).round(3)
      [[scaled, 0.08].max, 1.0].min
    end

    # Нормализуем длину ровно до заданного количества точек
    if peaks.size < points
      peaks += Array.new(points - peaks.size, 0.08)
    else
      peaks = peaks.first(points)
    end
    peaks
  rescue => e
    Rails.logger.error "Waveform generation failed: #{e.message}"
    Array.new(points, 0.08)
  end
end