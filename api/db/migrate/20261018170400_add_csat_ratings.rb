class AddCsatRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :csat_ratings do |t|
      t.references :ticket, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.references :customer, null: false, foreign_key: true
      t.integer :score, null: false
      t.text :comment
      t.timestamps
    end
    add_check_constraint :csat_ratings, "score BETWEEN 1 AND 5", name: "csat_ratings_score_check"
  end
end
