class CreateBugs < ActiveRecord::Migration[8.1]
  def change
    create_table :bugs do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.text :steps_to_reproduce
      t.text :obtained_result
      t.text :expected_result
      t.string :feature_tag
      t.string :cause_tag
      t.string :status, default: "open", null: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_reference :test_scenarios, :bug, foreign_key: true, null: true
  end
end
