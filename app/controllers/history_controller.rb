class HistoryController < ApplicationController
  before_action :authenticate_request

  # GET /history
  def index
    history = current_user.listening_histories
                          .includes(track: [:album, :artist])
                          .order(listened_at: :desc)
                          .limit(50)

    render json: history.map { |h|
      {
        id: h.id,
        listened_at: h.listened_at,
        track: {
          id: h.track.id,
          title: h.track.title,
          duration: h.track.duration,
          artist: h.track.artist&.name,
          album: h.track.album&.title,
          cover_url: h.track.cover_url
        }
      }
    }
  end

  # POST /history
  def create
    track = Track.find(params[:track_id])
    history_entry = current_user.listening_histories.create!(
      track: track,
      listened_at: Time.current
    )

    render json: { message: "Запись добавлена в историю", id: history_entry.id }, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Трек не найден" }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
