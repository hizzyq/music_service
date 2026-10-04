class AddWaveformToTracks < ActiveRecord::Migration[8.0]
  def change
    add_column :tracks, :waveform, :jsonb, default: []
  end
end
