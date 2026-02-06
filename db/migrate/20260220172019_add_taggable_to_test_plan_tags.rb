class AddTaggableToTestPlanTags < ActiveRecord::Migration[8.1]
  def change
    add_column :test_plan_tags, :taggable_type, :string
    add_column :test_plan_tags, :taggable_id, :integer
  end
end
