require "test_helper"

class RecommendationsServiceTest < ActiveSupport::TestCase
  setup do
    @user1 = create_user(email: "alice@test.com")
    @user2 = create_user(email: "bob@test.com")

    @artist1 = Artist.create!(name: "Skrillex")
    @album1 = @artist1.albums.create!(title: "Recess")
    @track1 = @album1.tracks.create!(title: "Ragga Bomb", duration: 200, file_key: "tracks/1.mp3")
    @track2 = @album1.tracks.create!(title: "Coast Is Clear", duration: 210, file_key: "tracks/2.mp3")

    @artist2 = Artist.create!(name: "Deadmau5")
    @album2 = @artist2.albums.create!(title: "Random Album Title")
    @track3 = @album2.tracks.create!(title: "Ghosts n Stuff", duration: 250, file_key: "tracks/3.mp3")
    @track4 = @album2.tracks.create!(title: "Strobe", duration: 300, file_key: "tracks/4.mp3")
  end

  test "cold start returns catalog tracks with reasons" do
    results = RecommendationsService.call(user: @user1, limit: 10)
    assert results.any?
    assert results.first.key?(:track)
    assert results.first.key?(:score)
    assert results.first.key?(:reason)
  end

  test "recommends tracks by preferred artist when user has history" do
    # Alice listens to track1 by Skrillex
    @user1.listening_histories.create!(track: @track1, listened_at: 1.day.ago)

    results = RecommendationsService.call(user: @user1, limit: 10)
    track_ids = results.map { |r| r[:track].id }

    # Track 2 (also by Skrillex) should be recommended
    assert_includes track_ids, @track2.id
    skrillex_rec = results.find { |r| r[:track].id == @track2.id }
    assert_match(/Skrillex/, skrillex_rec[:reason])
  end

  test "collaborative filtering boosts tracks listened to by similar users" do
    # Both Alice and Bob listened to Track 1
    @user1.listening_histories.create!(track: @track1, listened_at: 2.days.ago)
    @user2.listening_histories.create!(track: @track1, listened_at: 2.days.ago)

    # Bob also listened to Track 3 by Deadmau5
    @user2.listening_histories.create!(track: @track3, listened_at: 1.day.ago)

    results = RecommendationsService.call(user: @user1, limit: 10)
    rec = results.find { |r| r[:track].id == @track3.id }

    assert rec.present?, "Track 3 should be recommended to Alice via Bob's history"
    assert rec[:score] >= 25
  end

  test "respects requested limit" do
    results = RecommendationsService.call(user: @user1, limit: 2)
    assert results.size <= 2
  end
end
