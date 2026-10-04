class PlaylistTrack < ApplicationRecord
  belongs_to :playlist
  belongs_to :track

  validates :track_id, uniqueness: { scope: :playlist_id }
end
