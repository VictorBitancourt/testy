module Api
  module V1
    class TestScenariosController < BaseController
      before_action :set_test_plan
      before_action :set_test_scenario, only: [ :update, :destroy ]
      before_action -> { authorize_plan_owner_or_admin!(@test_plan) }

      def create
        scenario = @test_plan.test_scenarios.build(test_scenario_params)

        if scenario.save
          render json: { test_scenario: serialize_scenario(scenario) }, status: :created
        else
          render_errors(scenario)
        end
      end

      def update
        if @test_scenario.update(test_scenario_params)
          render json: { test_scenario: serialize_scenario(@test_scenario) }
        else
          render_errors(@test_scenario)
        end
      end

      def destroy
        @test_scenario.destroy!
        head :no_content
      end

      private

      def set_test_plan
        @test_plan = TestPlan.find(params[:test_plan_id])
      end

      def set_test_scenario
        @test_scenario = @test_plan.test_scenarios.find(params[:id])
      end

      def test_scenario_params
        params.require(:test_scenario).permit(:title, :given, :when_step, :then_step, :status, :bug_id)
      end

      def serialize_scenario(scenario)
        {
          id: scenario.id,
          title: scenario.title,
          given: scenario.given,
          when_step: scenario.when_step,
          then_step: scenario.then_step,
          status: scenario.status,
          bug_id: scenario.bug_id,
          position: scenario.position,
          evidence_count: scenario.evidence_files.count,
          created_at: scenario.created_at,
          updated_at: scenario.updated_at
        }
      end
    end
  end
end
