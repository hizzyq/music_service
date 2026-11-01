require "test_helper"

class ArtistTest < ActiveSupport::TestCase
  test "validates presence of name" do
    artist = Artist.new
    assert_not artist.valid?
    assert artist.errors[:name].any?
  end

  test "creates valid artist and associates albums" do
    artist = Artist.create!(name: "Justice", bio: "French electronic duo")
    assert artist.valid?

    album = artist.albums.create!(title: "Cross")
    assert_includes artist.albums, album
  end
end
