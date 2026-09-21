class Album < ApplicationRecord
  belongs_to :artist
  has_many :tracks, dependent: :destroy
  validates :title, presence: true
end
