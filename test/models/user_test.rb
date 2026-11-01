require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user creation with listener default role" do
    user = User.new(email: "listener@example.com", password: "password123")
    assert user.valid?
    assert user.listener?
    assert_not user.admin?
  end

  test "admin role check" do
    user = User.new(email: "admin@example.com", password: "password123", role: :admin)
    assert user.valid?
    assert user.admin?
    assert_not user.listener?
  end

  test "downcases and strips email before validation" do
    user = User.create!(email: "  USER@Example.COM  ", password: "password123")
    assert_equal "user@example.com", user.email
  end

  test "rejects invalid email formats" do
    invalid_emails = ["notanemail", "user@", "@domain.com", "user space@test.com"]
    invalid_emails.each do |email|
      user = User.new(email: email, password: "password123")
      assert_not user.valid?, "#{email} should be invalid"
      assert_includes user.errors[:email], "некорректный формат почты"
    end
  end

  test "enforces email uniqueness case-insensitively" do
    User.create!(email: "unique@test.com", password: "password123")
    duplicate = User.new(email: "UNIQUE@test.com", password: "password456")
    assert_not duplicate.valid?
    assert duplicate.errors[:email].any?
  end

  test "enforces password minimum length of 6 characters" do
    user = User.new(email: "short@test.com", password: "123")
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "destroys associated playlists and listening histories on user delete" do
    user = create_user
    track = create_track
    user.playlists.create!(name: "My Playlist")
    user.listening_histories.create!(track: track, listened_at: Time.current)

    assert_difference ["User.count", "Playlist.count", "ListeningHistory.count"], -1 do
      user.destroy
    end
  end
end
