class CreatePresetTitles < ActiveRecord::Migration[8.1]
  def change
    create_table :preset_titles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :game_title, null: false

      t.timestamps
    end
  end
end
