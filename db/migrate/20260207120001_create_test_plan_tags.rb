class CreateTestPlanTags < ActiveRecord::Migration[8.1]
  def change
    create_table :test_plan_tags do |t|
      t.references :test_plan, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :test_plan_tags, [ :test_plan_id, :tag_id ], unique: true
  end
end
