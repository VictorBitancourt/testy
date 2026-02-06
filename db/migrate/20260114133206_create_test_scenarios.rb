class CreateTestScenarios < ActiveRecord::Migration[8.1]
  def change
    create_table :test_scenarios do |t|
      t.references :test_plan, null: false, foreign_key: true
      t.string :title
      t.text :given
      t.text :when_step
      t.text :then_step
      t.string :status

      t.timestamps
    end
  end
end
