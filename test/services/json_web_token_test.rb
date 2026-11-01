require "test_helper"

class JsonWebTokenTest < ActiveSupport::TestCase
  test "encodes and decodes token successfully" do
    token = JsonWebToken.encode(user_id: 123, role: "admin")
    assert token.is_a?(String)
    assert_equal 3, token.split(".").size

    decoded = JsonWebToken.decode(token)
    assert_equal 123, decoded[:user_id]
    assert_equal "admin", decoded[:role]
  end

  test "returns nil for expired token" do
    # Encode token with expiration in the past
    token = JsonWebToken.encode({ user_id: 123 }, exp: 1.minute.ago)
    decoded = JsonWebToken.decode(token)
    assert_nil decoded
  end

  test "returns nil for invalid garbage token" do
    assert_nil JsonWebToken.decode("invalid.token.here")
    assert_nil JsonWebToken.decode(nil)
  end
end
