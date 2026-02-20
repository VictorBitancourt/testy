class TestPlans::AiGenerationsController < ApplicationController
  before_action :set_test_plan
  before_action :authorize_owner_or_admin

  def create
    prompt = params[:prompt].to_s.strip

    if prompt.blank?
      render json: { success: false, error: t("controllers.ai_generations.prompt_blank") }, status: :unprocessable_entity
      return
    end

    result = @test_plan.generate_scenarios_with_ai(prompt)

    if result[:success]
      render json: { success: true, count: result[:scenarios].size }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  private
    def set_test_plan
      @test_plan = TestPlan.find(params[:test_plan_id])
    end

    def authorize_owner_or_admin
      authorize_plan_owner_or_admin(@test_plan)
    end
end
