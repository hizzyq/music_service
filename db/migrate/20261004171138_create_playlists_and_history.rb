class CreatePlaylistsAndHistory < ActiveRecord::Migration[8.0]
  def change
    create_table :playlists do |t|
      t.string :name, null: false
      t.text :description
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    create_table :playlist_tracks do |t|
      t.references :playlist, null: false, foreign_key: true
      t.references :track, null: false, foreign_key: true
      t.integer :position, default: 0, null: false
      t.timestamps
    end
    add_index :playlist_tracks, [:playlist_id, :track_id], unique: true

    create_table :listening_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :track, null: false, foreign_key: true
      t.datetime :listened_at, null: false
      t.timestamps
    end
    add_index :listening_histories, [:user_id, :listened_at]
  end
end
