class FavoritesController < ApplicationController
  before_action :authenticate_request

  # GET /favorites
  def index
    playlist = favorites_playlist
    tracks = playlist.tracks.includes(:album, :artist)
    render json: tracks.map { |t|
      {
        id: t.id,
        title: t.title,
        duration: t.duration,
        artist: t.artist&.name,
        album: t.album&.title,
        cover_url: t.cover_url,
        waveform: t.waveform
      }
    }
  end

  # POST /favorites/:track_id (Toggle favorite)
  def toggle
    playlist = favorites_playlist
    track = Track.find(params[:track_id])
    pt = playlist.playlist_tracks.find_by(track: track)

    if pt
      pt.destroy
      render json: { favorited: false, message: "Удалено из избранного" }
    else
      pos = playlist.playlist_tracks.maximum(:position).to_i + 1
      playlist.playlist_tracks.create!(track: track, position: pos)
      render json: { favorited: true, message: "Добавлено в избранное" }
    end
  end

  # GET /favorites/ids (быстрый список ID для подсветки сердечек на фронтенде)
  def ids
    playlist = favorites_playlist
    render json: playlist.tracks.pluck(:id)
  end

  private

  def favorites_playlist
    current_user.playlists.find_or_create_by!(name: "Избранное") do |pl|
      pl.description = "Ваши любимые композиции"
    end
  end
end
