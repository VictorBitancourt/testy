class AddIndexToTestScenariosPosition < ActiveRecord::Migration[8.1]
  def change
    add_index :test_scenarios, :position
  end
end
