class Album < ApplicationRecord
  belongs_to :artist
  has_many :tracks, dependent: :destroy
  validates :title, presence: true

  def cover_url(expires_in: 1.hour.to_i)
    return nil if cover_key.blank?

    S3_PRESIGNER.presigned_url(
      :get_object,
      bucket: S3_BUCKET_NAME,
      key: cover_key,
      expires_in: expires_in
    )
  end
end
