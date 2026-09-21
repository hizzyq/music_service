class CreateAlbums < ActiveRecord::Migration[8.1]
  def change
    create_table :albums do |t|
      t.string :title, null: false
      t.integer :release_year
      t.string :cover_key
      t.references :artist, null: false, foreign_key: true

      t.timestamps
    end
  end
end
