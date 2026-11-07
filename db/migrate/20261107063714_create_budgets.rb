class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :amount, null: false

      t.timestamps
    end
  end
end