require "test_helper"

class AdminTracksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_user(role: :admin, email: "admin_tester@test.com")
    @listener = create_user(role: :listener, email: "listener_tester@test.com")
    @track = create_track(title: "Track for deletion", file_key: "tracks/del.mp3")
  end

  test "POST /admin/tracks/presign_upload returns 403 Forbidden for listener" do
    post "/admin/tracks/presign_upload", params: { filename: "sample.flac" },
                                         headers: authenticated_header(@listener), as: :json
    assert_response :forbidden
  end

  test "POST /admin/tracks/presign_upload returns presigned PUT URL for admin" do
    post "/admin/tracks/presign_upload", params: { filename: "sample.flac" },
                                         headers: authenticated_header(@admin), as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json["upload_url"].present?
    assert json["file_key"].present?
    assert_equal "audio/flac", json["content_type"]
  end

  test "DELETE /admin/tracks/:id returns 403 Forbidden for listener" do
    delete "/admin/tracks/#{@track.id}", headers: authenticated_header(@listener)
    assert_response :forbidden
  end

  test "DELETE /admin/tracks/:id deletes track for admin" do
    assert_difference "Track.count", -1 do
      delete "/admin/tracks/#{@track.id}", headers: authenticated_header(@admin)
    end
    assert_response :success
  end
end
