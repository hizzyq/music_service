# frozen_string_literal: true

require "disco"

class RecommendationsService
  DEFAULT_FACTORS = 8

  def self.call(user:, limit: 20)
    new(user, limit).call
  end

  def initialize(user, limit = 20)
    @user = user
    @limit = limit
  end

  def call
    candidate_scores = Hash.new(0)
    candidate_reasons = {}

    listened_ids = user_listened_track_ids
    favorite_ids = user_favorite_track_ids
    user_known_tracks = (listened_ids + favorite_ids).to_set

    # 1. Collaborative Filtering via Disco ML gem (Matrix Factorization)
    disco_recs = run_disco_collaborative
    disco_recs.each do |rec|
      track_id = rec[:item_id]
      next if user_known_tracks.include?(track_id)

      # Disco returns dot-product scores for latent factors; normalize and boost to 30..95 range
      raw_score = rec[:score].to_f
      scaled_score = [(raw_score * 1000).round + 30, 95].min
      candidate_scores[track_id] = [candidate_scores[track_id], scaled_score].max
      candidate_reasons[track_id] ||= "Нравится слушателям со схожим вкусом (Disco ML)"
    end

    # 2. Content-Based Preferences (Любимые артисты пользователя)
    preferred_artist_counts = user_preferred_artists(listened_ids, favorite_ids)
    if preferred_artist_counts.any?
      artist_tracks = Track.joins(:album)
                           .where(albums: { artist_id: preferred_artist_counts.keys })
                           .where.not(id: user_known_tracks.to_a)
                           .limit(40)

      artist_tracks.each do |t|
        artist_id = t.album&.artist_id
        weight = preferred_artist_counts[artist_id] || 1
        candidate_scores[t.id] += [weight * 20, 40].min
        candidate_reasons[t.id] ||= "Потому что вы слушали #{t.artist&.name || 'этого исполнителя'}"
      end
    end

    # 3. Global Trends (Популярные треки платформы)
    trending_map = platform_trending_tracks
    trending_map.each do |track_id, count|
      next if user_known_tracks.include?(track_id)

      candidate_scores[track_id] += count * 10
      candidate_reasons[track_id] ||= "В трендах платформы"
    end

    # 4. Cold-start / Fallback (если кандидатов мало или у пользователя нет истории)
    if candidate_scores.size < @limit
      remaining = @limit - candidate_scores.size
      fallback_tracks = Track.where.not(id: (user_known_tracks.to_a + candidate_scores.keys))
                             .order(created_at: :desc)
                             .limit(remaining)

      fallback_tracks.each do |t|
        candidate_scores[t.id] += 5
        candidate_reasons[t.id] ||= "Рекомендация каталога"
      end
    end

    # 5. Если в каталоге вообще мало треков и всё прослушано, разрешаем повторные рекомендации
    if candidate_scores.empty?
      Track.order(created_at: :desc).limit(@limit).each do |t|
        candidate_scores[t.id] = 10
        candidate_reasons[t.id] = "Рекомендация каталога"
      end
    end

    # 6. Сортировка по скорингу и загрузка связанных записей
    sorted_track_ids = candidate_scores.sort_by { |_id, score| -score }.map(&:first).first(@limit)
    tracks_by_id = Track.includes(:album, :artist).where(id: sorted_track_ids).index_by(&:id)

    sorted_track_ids.filter_map do |track_id|
      track = tracks_by_id[track_id]
      next unless track

      {
        track: track,
        score: candidate_scores[track_id],
        reason: candidate_reasons[track_id] || "Рекомендация для вас"
      }
    end
  end

  private

  attr_reader :user, :limit

  def user_listened_track_ids
    user.listening_histories.order(listened_at: :desc).limit(100).pluck(:track_id)
  end

  def user_favorite_track_ids
    fav_pl = user.playlists.find_by(name: "Избранное")
    fav_pl ? fav_pl.tracks.pluck(:id) : []
  end

  def user_preferred_artists(listened_ids, favorite_ids)
    all_sample_ids = (listened_ids.first(30) + favorite_ids).uniq
    return {} if all_sample_ids.empty?

    Track.where(id: all_sample_ids)
         .joins(:album)
         .pluck("albums.artist_id")
         .tally
  end

  def run_disco_collaborative
    history_events = ListeningHistory.select(:user_id, :track_id).map do |h|
      { user_id: h.user_id, item_id: h.track_id }
    end

    favorite_events = PlaylistTrack.joins(:playlist)
                                   .select("playlists.user_id", :track_id)
                                   .map do |pt|
      { user_id: pt.user_id, item_id: pt.track_id }
    end

    dataset = (history_events + favorite_events).uniq
    return [] if dataset.size < 2

    # Choose reasonable number of factors for matrix factorization
    factors = [dataset.size / 2, DEFAULT_FACTORS].min
    factors = [factors, 1].max

    recommender = Disco::Recommender.new(factors: factors)
    recommender.fit(dataset)
    recommender.user_recs(user.id, count: limit * 2)
  rescue StandardError => e
    Rails.logger.warn("Disco collaborative recommendation error: #{e.message}")
    []
  end

  def platform_trending_tracks
    ListeningHistory.group(:track_id)
                    .order(Arel.sql("count(*) DESC"))
                    .limit(20)
                    .count
  end
end
