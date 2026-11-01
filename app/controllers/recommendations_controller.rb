# frozen_string_literal: true

class RecommendationsController < ApplicationController
  before_action :authenticate_request

  # GET /recommendations
  def index
    limit = [params.fetch(:limit, 20).to_i, 50].min
    limit = 20 if limit <= 0

    results = RecommendationsService.call(user: current_user, limit: limit)

    render json: results.map { |item|
      track = item[:track]
      {
        id: track.id,
        title: track.title,
        duration: track.duration,
        track_number: track.track_number,
        artist: track.artist&.name,
        album: track.album&.title,
        cover_url: track.cover_url,
        waveform: track.waveform,
        format: File.extname(track.file_key).delete(".").upcase.presence || "MP3",
        recommendation: {
          score: item[:score],
          reason: item[:reason]
        }
      }
    }
  end
end
