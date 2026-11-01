require "test_helper"

class PlaylistsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    @track = create_track(title: "Dance Track")
  end

  test "GET /playlists requires authentication" do
    get "/playlists"
    assert_response :unauthorized
  end

  test "POST /playlists creates new playlist" do
    assert_difference "@user.playlists.count", 1 do
      post "/playlists", params: { name: "Morning Vibes", description: "Coffee playlist" },
                         headers: authenticated_header(@user), as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Morning Vibes", json["name"]
  end

  test "POST /playlists/:id/tracks adds track to playlist" do
    pl = @user.playlists.create!(name: "Chill")

    post "/playlists/#{pl.id}/tracks", params: { track_id: @track.id },
                                       headers: authenticated_header(@user), as: :json
    assert_response :success
    assert_includes pl.tracks, @track
  end

  test "DELETE /playlists/:id/tracks/:track_id removes track from playlist" do
    pl = @user.playlists.create!(name: "Chill")
    pl.playlist_tracks.create!(track: @track, position: 1)

    delete "/playlists/#{pl.id}/tracks/#{@track.id}", headers: authenticated_header(@user)
    assert_response :success
    assert_not_includes pl.reload.tracks, @track
  end

  test "DELETE /playlists/:id deletes user playlist" do
    pl = @user.playlists.create!(name: "To Delete")

    delete "/playlists/#{pl.id}", headers: authenticated_header(@user)
    assert_response :success
    assert_not Playlist.exists?(pl.id)
  end
end
