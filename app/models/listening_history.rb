class ListeningHistory < ApplicationRecord
  belongs_to :user
  belongs_to :track

  validates :listened_at, presence: true
end
