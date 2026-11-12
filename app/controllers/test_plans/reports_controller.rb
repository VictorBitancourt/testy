class TestPlans::ReportsController < ApplicationController
  before_action :set_test_plan

  def show
    respond_to do |format|
      format.html { render template: "test_plans/report", layout: false }
      format.pdf do
        send_data evidence_report.to_pdf, type: :pdf, disposition: :inline, filename: "#{report_filename}.pdf"
      rescue LatexDocument::Error => e
        Rails.logger.error(e.message)
        redirect_to @test_plan, alert: e.message.lines.first.strip
      end
      format.tex do
        send_data evidence_report.to_tex, type: :tex, disposition: :attachment, filename: "#{report_filename}.tex"
      end
    end
  end

  private
    def set_test_plan
      @test_plan = TestPlan.includes(test_scenarios: [ :bug, { evidence_files_attachments: :blob } ]).find(params[:test_plan_id])
    end

    def evidence_report
      EvidenceReport.new(@test_plan, logo: Setting.current.report_logo.presence)
    end

    def report_filename
      "evidencia-#{@test_plan.name.parameterize.presence || @test_plan.id}"
    end
end
