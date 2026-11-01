ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers (disable parallelization for simplicity with database locks)
    # parallelize(workers: :number_of_processors)

    # Do not auto-load fixtures so tests control their own records cleanly
    # fixtures :all

    # Helper: Generate Bearer token header for controller tests
    def authenticated_header(user)
      token = JsonWebToken.encode(user_id: user.id, role: user.role)
      { "Authorization" => "Bearer #{token}" }
    end

    # Helper: Create a standard test user
    def create_user(role: :listener, email: nil)
      unique_email = email || "user_#{SecureRandom.hex(4)}@test.com"
      User.create!(
        email: unique_email,
        password: "password123",
        password_confirmation: "password123",
        role: role
      )
    end

    # Helper: Create an artist, album, and track
    def create_track(artist_name: "Test Artist", album_title: "Test Album", title: "Test Track", file_key: "tracks/sample.mp3")
      artist = Artist.find_or_create_by!(name: artist_name)
      album = artist.albums.find_or_create_by!(title: album_title) do |a|
        a.release_year = 2024
        a.cover_key = "covers/test_cover.jpg"
      end
      album.tracks.create!(
        title: title,
        duration: 200,
        track_number: 1,
        file_key: file_key,
        waveform: Array.new(100, 0.5)
      )
    end
  end
end
