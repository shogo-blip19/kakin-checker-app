class CreatePays < ActiveRecord::Migration[8.1]
  def change
    create_table :pays do |t|
      t.references :user, null: false, foreign_key: true
      t.references :preset_title, null: false, foreign_key: true
      t.integer :amount, null: false
      t.date :paid_at, null: false

      t.timestamps
    end
  end
end
