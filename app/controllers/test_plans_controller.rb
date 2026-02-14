class TestPlansController < ApplicationController
  include Pagy::Method

  before_action :set_test_plan, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner_or_admin, only: [:edit, :update, :destroy]

  def index
    @test_plans = TestPlan.includes(:test_scenarios, :user, :tags).order(created_at: :desc)

    if params[:status].present?
      @test_plans = case params[:status]
      when "approved" then @test_plans.approved_plans
      when "failed" then @test_plans.failed_plans
      when "in_progress" then @test_plans.in_progress
      when "not_started" then @test_plans.not_started
      else @test_plans
      end
    end

    @test_plans = @test_plans.created_from(params[:date_from]) if params[:date_from].present?
    @test_plans = @test_plans.created_until(params[:date_until]) if params[:date_until].present?

    @search = params[:search]
    @test_plans = @test_plans.search(@search) if @search.present?

    @filters_active = params[:status].present? || params[:date_from].present? || params[:date_until].present? || @search.present?

    @pagy, @test_plans = pagy(@test_plans)
  end

  def show
    @test_scenarios = @test_plan.test_scenarios.to_a
    @new_scenario = @test_plan.test_scenarios.build
  end

  def new
    @test_plan = TestPlan.new
  end

  def create
    @test_plan = TestPlan.new(test_plan_params)
    @test_plan.user = Current.user

    if @test_plan.save
      redirect_to @test_plan, notice: "Test plan created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @test_plan.update(test_plan_params)
      redirect_to @test_plan, notice: "Test plan updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @test_plan.destroy
    redirect_to test_plans_path, notice: "Test plan removed!"
  end

  private
    def set_test_plan
      @test_plan = TestPlan.find(params[:id])
    end

    def authorize_owner_or_admin
      authorize_plan_owner_or_admin(@test_plan)
    end

    def test_plan_params
      params.require(:test_plan).permit(:name, :qa_name, :tag_list)
    end
end
