class TestScenariosController < ApplicationController
  before_action :set_test_plan
  before_action :set_test_scenario, only: [:update, :destroy]
  before_action :authorize_owner_or_admin

  def create
    @test_scenario = @test_plan.test_scenarios.build(test_scenario_params)

    if @test_scenario.save
      redirect_to @test_plan, notice: "Scenario added!"
    else
      redirect_to @test_plan, alert: "Error adding scenario."
    end
  end

  def update
    respond_to do |format|
      format.html do
        if @test_scenario.update(test_scenario_params)
          redirect_to @test_plan, notice: "Scenario updated!"
        else
          redirect_to @test_plan, alert: "Error updating scenario."
        end
      end
      format.json do
        if @test_scenario.update(test_scenario_params.merge(status: "pending"))
          render json: { success: true, scenario: { given: @test_scenario.given, when_step: @test_scenario.when_step, then_step: @test_scenario.then_step, status: @test_scenario.status } }
        else
          render json: { success: false, errors: @test_scenario.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @test_scenario.destroy
    redirect_to @test_plan, notice: "Scenario removed!"
  end

  private
    def set_test_plan
      @test_plan = TestPlan.find(params[:test_plan_id])
    end

    def set_test_scenario
      @test_scenario = @test_plan.test_scenarios.find(params[:id])
    end

    def authorize_owner_or_admin
      authorize_plan_owner_or_admin(@test_plan)
    end

    def test_scenario_params
      params.require(:test_scenario).permit(:title, :given, :when_step, :then_step, :status, evidence_files: [])
    end
end
