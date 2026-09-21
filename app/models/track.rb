class Track < ApplicationRecord
  belongs_to :album
  has_one :artist, through: :album
  validates :title, :file_key, presence: true

  # Генерирует временный Presigned URL для прямого стриминга из MinIO
  def stream_url(expires_in: 15.minutes.to_i)
    S3_PRESIGNER.presigned_url(
      :get_object,
      bucket: S3_BUCKET_NAME,
      key: file_key,
      expires_in: expires_in
    )
  end
end
