class EnforceNotNullConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :test_plans, :name, false
    change_column_null :test_plans, :qa_name, false

    change_column_null :test_scenarios, :title, false
    change_column_default :test_scenarios, :status, from: nil, to: "pending"
    change_column_null :test_scenarios, :status, false, "pending"
  end
end
