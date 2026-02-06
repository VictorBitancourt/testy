class TestPlans::ScenarioOrdersController < ApplicationController
  before_action :set_test_plan
  before_action :authorize_owner_or_admin

  def update
    ActiveRecord::Base.transaction do
      params[:scenario_ids].each_with_index do |id, index|
        @test_plan.test_scenarios.where(id: id).update_all(position: index)
      end
    end
    head :ok
  end

  private
    def set_test_plan
      @test_plan = TestPlan.find(params[:test_plan_id])
    end

    def authorize_owner_or_admin
      authorize_plan_owner_or_admin(@test_plan)
    end
end
