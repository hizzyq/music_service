require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    @track = create_track(title: "Favorite Tune")
  end

  test "GET /favorites/ids requires authentication" do
    get "/favorites/ids"
    assert_response :unauthorized
  end

  test "POST /favorites/:track_id toggles favorite status in 1 click" do
    # 1. Toggle ON
    post "/favorites/#{@track.id}", headers: authenticated_header(@user)
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal true, json["favorited"]

    # Check ids list
    get "/favorites/ids", headers: authenticated_header(@user)
    assert_response :success
    ids = JSON.parse(response.body)
    assert_includes ids, @track.id

    # 2. Toggle OFF
    post "/favorites/#{@track.id}", headers: authenticated_header(@user)
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal false, json["favorited"]

    # Check ids list again
    get "/favorites/ids", headers: authenticated_header(@user)
    ids = JSON.parse(response.body)
    assert_not_includes ids, @track.id
  end

  test "GET /favorites returns list of favorited tracks" do
    post "/favorites/#{@track.id}", headers: authenticated_header(@user)

    get "/favorites", headers: authenticated_header(@user)
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json.size
    assert_equal @track.id, json.first["id"]
    assert_equal "Favorite Tune", json.first["title"]
  end
end
