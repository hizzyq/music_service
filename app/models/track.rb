class Track < ApplicationRecord
  belongs_to :album
  has_one :artist, through: :album
  has_many :playlist_tracks, dependent: :destroy
  has_many :playlists, through: :playlist_tracks
  has_many :listening_histories, dependent: :destroy

  validates :title, :file_key, presence: true

  def cover_url
    album&.cover_url
  end

  def content_type
    case File.extname(file_key).downcase
    when ".flac" then "audio/flac"
    when ".m4a"  then "audio/mp4"
    when ".aac"  then "audio/aac"
    when ".wav"  then "audio/wav"
    when ".ogg"  then "audio/ogg"
    else "audio/mpeg"
    end
  end

  def stream_url(expires_in: 15.minutes.to_i)
    ext = File.extname(file_key).presence || ".mp3"
    display_name = "#{artist&.name || 'Artist'} - #{title}#{ext}".gsub(/["\\]/, "")

    S3_PRESIGNER.presigned_url(
      :get_object,
      bucket: S3_BUCKET_NAME,
      key: file_key,
      expires_in: expires_in,
      response_content_type: content_type,
      response_content_disposition: "inline; filename=\"#{display_name}\""
    )
  end
end
