module Admin
  class TracksController < ApplicationController
    before_action :authenticate_request
    before_action :require_admin!

    # POST /admin/tracks/presign_upload
    def presign_upload
      raw_filename = params[:filename].to_s
      ext = File.extname(raw_filename).downcase
      base = File.basename(raw_filename, ".*").gsub(/[^a-zA-Z0-9.\-_]/, "_")
      filename = "#{base}#{ext}"
      file_key = "tracks/#{SecureRandom.uuid}_#{filename}"

      content_type = case ext
                     when ".flac" then "audio/flac"
                     when ".m4a"  then "audio/mp4"
                     when ".aac"  then "audio/aac"
                     when ".wav"  then "audio/wav"
                     when ".ogg"  then "audio/ogg"
                     else "audio/mpeg"
                     end

      upload_url = S3_PRESIGNER.presigned_url(
        :put_object,
        bucket: S3_BUCKET_NAME,
        key: file_key,
        expires_in: 15.minutes.to_i,
        content_type: content_type
      )

      render json: { upload_url: upload_url, file_key: file_key, content_type: content_type }
    end

    # POST /admin/tracks/process_upload
    def process_upload
      file_key = params[:file_key]
      return render json: { error: "file_key обязателен" }, status: :bad_request if file_key.blank?

      metadata = TrackMetadataExtractor.extract(file_key)

      track = ActiveRecord::Base.transaction do
        artist = Artist.find_or_create_by!(name: metadata[:artist_name])
        album = artist.albums.find_or_create_by!(title: metadata[:album_title]) do |alb|
          alb.release_year = metadata[:release_year] if metadata[:release_year]
        end

        album.update!(cover_key: metadata[:cover_key]) if metadata[:cover_key].present? && album.cover_key.blank?

        album.tracks.create!(
          title: metadata[:title],
          duration: metadata[:duration],
          track_number: metadata[:track_number],
          file_key: file_key,
          waveform: metadata[:waveform]
        )
      end

      render json: {
        message: "Трек успешно добавлен и распознан",
        track: {
          id: track.id,
          title: track.title,
          artist: track.artist.name,
          album: track.album.title,
          duration: track.duration,
          track_number: track.track_number,
          file_key: track.file_key,
          cover_url: track.cover_url,
          waveform: track.waveform
        }
      }, status: :created
    rescue => e
      render json: { error: "Ошибка обработки метаданных: #{e.message}" }, status: :unprocessable_entity
    end

    # DELETE /admin/tracks/:id
    def destroy
      track = Track.find(params[:id])
      file_key = track.file_key
      album = track.album

      track.destroy!

      # Удаляем аудиофайл из MinIO
      begin
        S3_CLIENT.delete_object(bucket: S3_BUCKET_NAME, key: file_key) if file_key.present?
      rescue => e
        Rails.logger.warn "Failed to delete audio from S3: #{e.message}"
      end

      # Если альбом опустел, удаляем его и его обложку
      if album && album.tracks.empty?
        cover_key = album.cover_key
        album.destroy
        begin
          S3_CLIENT.delete_object(bucket: S3_BUCKET_NAME, key: cover_key) if cover_key.present?
        rescue => e
          Rails.logger.warn "Failed to delete cover from S3: #{e.message}"
        end
      end

      render json: { message: "Трек успешно удален из библиотеки" }
    end

    private

    def require_admin!
      render json: { error: "Доступ запрещен: требуются права администратора" }, status: :forbidden unless current_user&.admin?
    end
  end
end