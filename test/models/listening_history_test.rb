require "test_helper"

class ListeningHistoryTest < ActiveSupport::TestCase
  test "validates presence of listened_at and associations" do
    user = create_user
    track = create_track

    history = ListeningHistory.new(user: user, track: track, listened_at: Time.current)
    assert history.valid?

    history.listened_at = nil
    assert_not history.valid?
    assert history.errors[:listened_at].any?
  end
end
