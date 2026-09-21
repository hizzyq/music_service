class CreateTracks < ActiveRecord::Migration[8.1]
  def change
    create_table :tracks do |t|
      t.string :title, null: false
      t.integer :duration
      t.integer :track_number
      t.string :file_key, null: false
      t.references :album, null: false, foreign_key: true

      t.timestamps
    end
  end
end
