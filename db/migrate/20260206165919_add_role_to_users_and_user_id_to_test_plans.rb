class AddRoleToUsersAndUserIdToTestPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, null: false, default: "user"
    add_reference :test_plans, :user, foreign_key: true

    reversible do |dir|
      dir.up do
        User.reset_column_information
        if (admin = User.first)
          TestPlan.where(user_id: nil).update_all(user_id: admin.id)
        end
      end
    end
  end
end
