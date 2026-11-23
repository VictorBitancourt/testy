module Api
  module V1
    class ScreenshotsController < BaseController
      include Api::ScreenshotUpload

      before_action :set_test_plan
      before_action :set_test_scenario
      before_action -> { authorize_plan_owner_or_admin!(@test_plan) }

      def create
        attach_screenshot(@test_scenario)
      end

      private

      def set_test_plan
        @test_plan = TestPlan.find(params[:test_plan_id])
      end

      def set_test_scenario
        @test_scenario = @test_plan.test_scenarios.find(params[:test_scenario_id])
      end
    end
  end
end
