class PlaylistsController < ApplicationController
  before_action :authenticate_request
  before_action :set_playlist, only: [:show, :destroy, :add_track, :remove_track]

  # GET /playlists
  def index
    playlists = current_user.playlists.includes(:tracks).order(created_at: :desc)
    render json: playlists.map { |pl| playlist_summary(pl) }
  end

  # GET /playlists/:id
  def show
    render json: {
      id: @playlist.id,
      name: @playlist.name,
      description: @playlist.description,
      tracks: @playlist.tracks.includes(:album, :artist).map do |t|
        {
          id: t.id,
          title: t.title,
          duration: t.duration,
          artist: t.artist&.name,
          album: t.album&.title,
          cover_url: t.cover_url,
          waveform: t.waveform,
          format: File.extname(t.file_key).delete('.').upcase.presence || 'MP3'
        }
      end
    }
  end

  # POST /playlists
  def create
    playlist = current_user.playlists.new(playlist_params)
    if playlist.save
      render json: playlist_summary(playlist), status: :created
    else
      render json: { errors: playlist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /playlists/:id/tracks
  def add_track
    track = Track.find(params[:track_id])
    pos = @playlist.playlist_tracks.maximum(:position).to_i + 1
    pt = @playlist.playlist_tracks.find_or_initialize_by(track: track)
    pt.position = pos if pt.new_record?

    if pt.save
      render json: { message: "Трек добавлен в плейлист", playlist_id: @playlist.id, track_id: track.id }
    else
      render json: { errors: pt.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /playlists/:id/tracks/:track_id
  def remove_track
    pt = @playlist.playlist_tracks.find_by(track_id: params[:track_id])
    if pt&.destroy
      render json: { message: "Трек удален из плейлиста" }
    else
      render json: { error: "Трек не найден в плейлисте" }, status: :not_found
    end
  end

  # DELETE /playlists/:id
  def destroy
    @playlist.destroy
    render json: { message: "Плейлист удален" }
  end

  private

  def set_playlist
    @playlist = current_user.playlists.find(params[:id])
  end

  def playlist_params
    params.permit(:name, :description)
  end

  def playlist_summary(pl)
    {
      id: pl.id,
      name: pl.name,
      description: pl.description,
      tracks_count: pl.tracks.size,
      created_at: pl.created_at
    }
  end
end
