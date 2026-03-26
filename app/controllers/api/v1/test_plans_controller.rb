module Api
  module V1
    class TestPlansController < BaseController
      before_action :set_test_plan, only: [ :show, :update, :destroy ]
      before_action -> { authorize_plan_owner_or_admin!(@test_plan) }, only: [ :update, :destroy ]

      def index
        plans = TestPlan.includes(:test_scenarios, :user, :tags).order(created_at: :desc)

        if params[:status].present?
          plans = case params[:status]
          when "approved" then plans.approved_plans
          when "failed" then plans.failed_plans
          when "in_progress" then plans.in_progress
          when "not_started" then plans.not_started
          else plans
          end
        end

        plans = plans.created_from(params[:date_from]) if params[:date_from].present?
        plans = plans.created_until(params[:date_until]) if params[:date_until].present?
        plans = plans.search(params[:search]) if params[:search].present?

        pagy, plans = pagy(plans)

        render json: {
          test_plans: plans.map { |p| serialize_plan(p) },
          meta: pagination_meta(pagy)
        }
      end

      def show
        render json: { test_plan: serialize_plan_detail(@test_plan) }
      end

      def create
        plan = TestPlan.new(test_plan_params)
        plan.user = current_api_user

        if plan.save
          render json: { test_plan: serialize_plan(plan) }, status: :created
        else
          render_errors(plan)
        end
      end

      def update
        if @test_plan.update(test_plan_params)
          render json: { test_plan: serialize_plan(@test_plan) }
        else
          render_errors(@test_plan)
        end
      end

      def destroy
        @test_plan.destroy!
        head :no_content
      end

      private

      def set_test_plan
        @test_plan = TestPlan.find(params[:id])
      end

      def test_plan_params
        params.require(:test_plan).permit(:name, :qa_name, :tag_list)
      end

      def serialize_plan(plan)
        {
          id: plan.id,
          name: plan.name,
          qa_name: plan.qa_name,
          status: plan.derived_status,
          tags: plan.tags.map(&:name),
          total_scenarios: plan.total_scenarios,
          approved_scenarios: plan.approved_scenarios,
          user: plan.user ? { id: plan.user.id, username: plan.user.username } : nil,
          created_at: plan.created_at,
          updated_at: plan.updated_at
        }
      end

      def serialize_plan_detail(plan)
        serialize_plan(plan).merge(
          test_scenarios: plan.test_scenarios.includes(evidence_files_attachments: :blob).map { |s| serialize_scenario(s) }
        )
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
