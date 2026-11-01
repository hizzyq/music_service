require "test_helper"

class TrackTest < ActiveSupport::TestCase
  setup do
    @artist = Artist.create!(name: "Test Artist")
    @album = @artist.albums.create!(title: "Test Album", cover_key: "covers/album.jpg")
    @track = @album.tracks.create!(
      title: "Electronic Beat",
      duration: 180,
      track_number: 1,
      file_key: "tracks/beat.flac",
      waveform: Array.new(100, 0.5)
    )
  end

  test "valid track belongs to album and artist" do
    assert @track.valid?
    assert_equal @album, @track.album
    assert_equal @artist, @track.artist
  end

  test "requires title and file_key" do
    t1 = Track.new(album: @album)
    assert_not t1.valid?
    assert t1.errors[:title].any?
    assert t1.errors[:file_key].any?
  end

  test "detects content_type based on file extension" do
    cases = {
      "track.flac" => "audio/flac",
      "track.m4a"  => "audio/mp4",
      "track.aac"  => "audio/aac",
      "track.wav"  => "audio/wav",
      "track.ogg"  => "audio/ogg",
      "track.mp3"  => "audio/mpeg",
      "unknown"    => "audio/mpeg"
    }

    cases.each do |key, expected_type|
      @track.file_key = key
      assert_equal expected_type, @track.content_type, "Failed for #{key}"
    end
  end

  test "generates stream_url calling S3 presigner" do
    url = @track.stream_url(expires_in: 900)
    assert url.present?
    assert_includes url, "response-content-type=audio%2Fflac"
    assert_includes url, "Electronic%20Beat"
  end

  test "delegates cover_url to album" do
    assert @track.cover_url.present?
    assert_equal @album.cover_url.split("?").first, @track.cover_url.split("?").first
  end
end
