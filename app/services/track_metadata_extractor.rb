require "mp3info"

class TrackMetadataExtractor
  def self.extract(file_key)
    temp_file = Tempfile.new(["track_upload", ".mp3"], binmode: true)

    begin
      # Скачиваем файл из MinIO во временный файл на диске
      S3_CLIENT.get_object(
        bucket: S3_BUCKET_NAME,
        key: file_key,
        response_target: temp_file.path
      )

      Mp3Info.open(temp_file.path) do |mp3|
        # Извлекаем данные из ID3v1 или ID3v2 с фоллбэками
        title = (mp3.tag.title || mp3.tag2["TIT2"] || File.basename(file_key, ".*")).to_s.strip
        artist_name = (mp3.tag.artist || mp3.tag2["TPE1"] || "Unknown Artist").to_s.strip
        album_title = (mp3.tag.album || mp3.tag2["TALB"] || "Single").to_s.strip

        # Номер трека может быть в формате "3" или "3/12"
        raw_track_num = mp3.tag.tracknum || mp3.tag2["TRCK"]
        track_number = raw_track_num.to_s.split("/").first.to_i
        track_number = 1 if track_number.zero?

        duration = mp3.length.round

        {
          title: title,
          artist_name: artist_name,
          album_title: album_title,
          track_number: track_number,
          duration: duration
        }
      end
    ensure
      temp_file.close
      temp_file.unlink # Удаляем временный файл с диска
    end
  end
end