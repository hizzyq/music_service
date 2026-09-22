class Track < ApplicationRecord
  belongs_to :album
  has_one :artist, through: :album

  validates :title, :file_key, presence: true

  def stream_url(expires_in: 15.minutes.to_i)
    # Формируем читаемое имя файла для плеера/скачивания (например, "Skrillex - Bangarang.mp3")
    display_name = "#{artist&.name || 'Artist'} - #{title}.mp3".gsub(/["\\]/, "")

    S3_PRESIGNER.presigned_url(
      :get_object,
      bucket: S3_BUCKET_NAME,
      key: file_key,
      expires_in: expires_in,
      response_content_type: "audio/mpeg",
      response_content_disposition: "inline; filename=\"#{display_name}\""
    )
  end
end
