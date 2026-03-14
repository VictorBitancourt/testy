class TestScenarios::StatusesController < ApplicationController
  ALLOWED_STATUSES = %w[pending approved failed].freeze

  before_action :set_test_plan
  before_action :set_test_scenario
  before_action :authorize_owner_or_admin

  def update
    return head(:bad_request) unless params[:status].in?(ALLOWED_STATUSES)

    if @test_scenario.update(status: params[:status])
      render json: { success: true, all_approved: @test_plan.all_scenarios_approved? }
    else
      render json: { success: false, errors: @test_scenario.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
    def set_test_plan
      @test_plan = TestPlan.find(params[:test_plan_id])
    end

    def set_test_scenario
      @test_scenario = @test_plan.test_scenarios.find(params[:test_scenario_id])
    end

    def authorize_owner_or_admin
      authorize_plan_owner_or_admin(@test_plan)
    end
end
