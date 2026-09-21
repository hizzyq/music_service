module Admin
  class TracksController < ApplicationController
    before_action :authenticate_request
    before_action :require_admin!

    # POST /admin/tracks/presign_upload
    def presign_upload
      filename = params[:filename].to_s.gsub(/[^a-zA-Z0-9.\-_]/, "_")
      file_key = "tracks/#{SecureRandom.uuid}_#{filename}"

      upload_url = S3_PRESIGNER.presigned_url(
        :put_object,
        bucket: S3_BUCKET_NAME,
        key: file_key,
        expires_in: 15.minutes.to_i
      )

      render json: { upload_url: upload_url, file_key: file_key }
    end

    # POST /admin/tracks/process_upload
    def process_upload
      file_key = params[:file_key]
      return render json: { error: "file_key обязателен" }, status: :bad_request if file_key.blank?

      metadata = TrackMetadataExtractor.extract(file_key)

      track = ActiveRecord::Base.transaction do
        artist = Artist.find_or_create_by!(name: metadata[:artist_name])
        album = artist.albums.find_or_create_by!(title: metadata[:album_title])

        album.tracks.create!(
          title: metadata[:title],
          duration: metadata[:duration],
          track_number: metadata[:track_number],
          file_key: file_key
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
          stream_url: track.stream_url
        }
      }, status: :created
    rescue => e
      render json: { error: "Ошибка обработки метаданных: #{e.message}" }, status: :unprocessable_entity
    end

    private

    def require_admin!
      render json: { error: "Доступ запрещен: требуются права администратора" }, status: :forbidden unless current_user&.admin?
    end
  end
end