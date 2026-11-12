# AI reports from The Root Of All Evil, kept so they can be reopened and exported.
class CreateBugAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :bug_analyses do |t|
      t.references :user, foreign_key: true
      t.text :summary, null: false
      t.json :patterns, null: false
      t.json :recommendations, null: false
      t.json :cause_counts, null: false
      t.json :feature_counts, null: false
      t.integer :bug_count, null: false
      t.integer :total_bugs, null: false
      t.string :ai_provider
      t.string :ai_model
      t.timestamps
    end
  end
end
