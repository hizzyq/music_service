require "test_helper"

class TracksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @track = create_track(title: "Starlight", file_key: "tracks/starlight.flac")
    @user = create_user
  end

  test "GET /tracks returns catalog without exposing raw stream_url" do
    get "/tracks"
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert json.any? { |t| t["id"] == @track.id }

    sample = json.find { |t| t["id"] == @track.id }
    assert_equal "Starlight", sample["title"]
    assert_equal "FLAC", sample["format"]
    assert sample.key?("waveform")
    # Security: stream_url MUST NOT be exposed in index
    assert_nil sample["stream_url"]
  end

  test "GET /tracks/:id returns single track payload" do
    get "/tracks/#{@track.id}"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @track.id, json["id"]
    assert_equal "Starlight", json["title"]
  end

  test "GET /tracks/:id/stream requires authentication (returns 401)" do
    get "/tracks/#{@track.id}/stream"
    assert_response :unauthorized
  end

  test "GET /tracks/:id/stream with valid JWT token returns presigned URL" do
    get "/tracks/#{@track.id}/stream", headers: authenticated_header(@user)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @track.id, json["track_id"]
    assert json["stream_url"].present?
    assert_includes json["stream_url"], "/music/tracks/starlight.flac"
  end
end
