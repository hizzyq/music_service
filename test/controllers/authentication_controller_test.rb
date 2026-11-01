require "test_helper"

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  test "POST /auth/register creates user and returns token" do
    assert_difference "User.count", 1 do
      post "/auth/register", params: {
        email: "newuser@test.com",
        password: "password123",
        password_confirmation: "password123"
      }, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert json["token"].present?
    assert_equal "newuser@test.com", json["user"]["email"]
    assert_equal "listener", json["user"]["role"]
  end

  test "POST /auth/register fails with duplicate email" do
    create_user(email: "existing@test.com")

    post "/auth/register", params: {
      email: "existing@test.com",
      password: "password123"
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].present?
  end

  test "POST /auth/login returns token for valid credentials" do
    user = create_user(email: "login@test.com")

    post "/auth/login", params: {
      email: "login@test.com",
      password: "password123"
    }, as: :json

    assert_response :ok
    json = JSON.parse(response.body)
    assert json["token"].present?
    assert_equal user.id, json["user"]["id"]
  end

  test "POST /auth/login returns 401 for wrong password" do
    create_user(email: "login@test.com")

    post "/auth/login", params: {
      email: "login@test.com",
      password: "wrongpassword"
    }, as: :json

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Неверный email или пароль", json["error"]
  end
end
