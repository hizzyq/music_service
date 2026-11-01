require "test_helper"

class HistoryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    @track = create_track(title: "Night Drive")
  end

  test "GET /history requires authentication" do
    get "/history"
    assert_response :unauthorized
  end

  test "POST /history records track playback" do
    assert_difference "@user.listening_histories.count", 1 do
      post "/history", params: { track_id: @track.id }, headers: authenticated_header(@user), as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Запись добавлена в историю", json["message"]
  end

  test "GET /history returns recent listening log" do
    @user.listening_histories.create!(track: @track, listened_at: Time.current)

    get "/history", headers: authenticated_header(@user)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json.size
    assert_equal @track.id, json.first["track"]["id"]
    assert_equal "Night Drive", json.first["track"]["title"]
  end
end
