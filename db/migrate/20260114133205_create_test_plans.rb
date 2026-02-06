class CreateTestPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :test_plans do |t|
      t.string :name
      t.string :qa_name

      t.timestamps
    end
  end
end
1