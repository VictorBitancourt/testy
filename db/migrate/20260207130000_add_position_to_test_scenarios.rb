class AddPositionToTestScenarios < ActiveRecord::Migration[8.1]
  def change
    add_column :test_scenarios, :position, :integer

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE test_scenarios
          SET position = (
            SELECT COUNT(*)
            FROM test_scenarios AS ts
            WHERE ts.test_plan_id = test_scenarios.test_plan_id
              AND ts.id <= test_scenarios.id
          ) - 1
        SQL
      end
    end
  end
end
