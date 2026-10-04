class Playlist < ApplicationRecord
  belongs_to :user
  has_many :playlist_tracks, -> { order(position: :asc) }, dependent: :destroy
  has_many :tracks, through: :playlist_tracks

  validates :name, presence: true
end
