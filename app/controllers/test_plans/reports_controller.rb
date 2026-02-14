class TestPlans::ReportsController < ApplicationController
  before_action :set_test_plan

  def show
    respond_to do |format|
      format.html { render template: "test_plans/report", layout: false }
      format.pdf do
        render ferrum_pdf: {
          paper_width: 8.27,
          paper_height: 11.69,
          margin_top: 0,
          margin_bottom: 0,
          margin_left: 0,
          margin_right: 0
        },
        template: "test_plans/report_pdf",
        formats: [:html],
        layout: false,
        disposition: :inline,
        filename: "test_plan_#{@test_plan.id}.pdf"
      end
    end
  end

  private
    def set_test_plan
      @test_plan = TestPlan.find(params[:test_plan_id])
    end
end
