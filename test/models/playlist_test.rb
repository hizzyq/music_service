require "test_helper"

class PlaylistTest < ActiveSupport::TestCase
  setup do
    @user = create_user
    @track1 = create_track(title: "Track 1", file_key: "tracks/1.mp3")
    @track2 = create_track(title: "Track 2", file_key: "tracks/2.mp3")
  end

  test "validates presence of name" do
    pl = @user.playlists.new
    assert_not pl.valid?
    assert pl.errors[:name].any?
  end

  test "adds tracks and preserves ordering" do
    pl = @user.playlists.create!(name: "Gym Workout")
    pt1 = pl.playlist_tracks.create!(track: @track1, position: 1)
    pt2 = pl.playlist_tracks.create!(track: @track2, position: 2)

    assert_equal [@track1, @track2], pl.tracks.to_a
  end

  test "prevents adding duplicate track to same playlist" do
    pl = @user.playlists.create!(name: "Favorites")
    pl.playlist_tracks.create!(track: @track1, position: 1)

    duplicate = pl.playlist_tracks.new(track: @track1, position: 2)
    assert_not duplicate.valid?
  end
end
