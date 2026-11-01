require "test_helper"

class RecommendationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    @track = create_track(title: "Ambient Space")
  end

  test "GET /recommendations requires authentication" do
    get "/recommendations"
    assert_response :unauthorized
  end

  test "GET /recommendations returns list with scores and reasons" do
    get "/recommendations", headers: authenticated_header(@user)
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert json.any? { |t| t["id"] == @track.id }

    rec = json.find { |t| t["id"] == @track.id }
    assert rec.key?("recommendation")
    assert rec["recommendation"].key?("score")
    assert rec["recommendation"].key?("reason")
  end
end
