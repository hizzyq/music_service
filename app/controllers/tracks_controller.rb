class TracksController < ApplicationController
  before_action :authenticate_request, only: [:stream]
  before_action :set_track, only: [:show, :stream]

  def index
    @tracks = Track.includes(:album, :artist).all
    render json: @tracks.map { |track| track_payload(track) }
  end

  def show
    render json: track_payload(@track)
  end

  def stream
    render json: {
      track_id: @track.id,
      stream_url: @track.stream_url
    }
  end

  private

  def set_track
    @track = Track.find(params[:id])
  end

  def track_payload(track)
    {
      id: track.id,
      title: track.title,
      duration: track.duration,
      track_number: track.track_number,
      artist: track.artist&.name,
      album: track.album&.title,
      stream_url: track.stream_url
    }
  end
end