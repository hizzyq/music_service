require "test_helper"

class AlbumTest < ActiveSupport::TestCase
  setup do
    @artist = Artist.create!(name: "Daft Punk")
  end

  test "validates presence of title" do
    album = Album.new(artist: @artist)
    assert_not album.valid?
    assert album.errors[:title].any?
  end

  test "cover_url returns nil if cover_key is blank" do
    album = @artist.albums.create!(title: "Discovery", cover_key: nil)
    assert_nil album.cover_url
  end

  test "cover_url returns presigned S3 url when cover_key is set" do
    album = @artist.albums.create!(title: "Discovery", cover_key: "covers/discovery.jpg")
    url = album.cover_url
    assert url.present?
    assert_includes url, "covers/discovery.jpg"
  end

  test "destroys associated tracks when album is destroyed" do
    album = @artist.albums.create!(title: "Discovery")
    album.tracks.create!(title: "One More Time", file_key: "tracks/one.mp3")

    assert_difference "Track.count", -1 do
      album.destroy
    end
  end
end
