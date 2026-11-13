# AI report on the most frequent bugs, shown on The Root Of All Evil page and
# exported as a LaTeX PDF.
class Bugs::AiAnalysesController < ApplicationController
  before_action :require_project, only: :create

  def create
    result = AiBugAnalysis.new(project: current_project).call
    if result.success?
      @analysis = result.data
      @analysis.update!(user: Current.user, project: current_project)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("ai-analysis", partial: "bugs/root_causes/ai_analysis", locals: { analysis: @analysis, error: result.error })
      end
      format.html { redirect_to bug_root_causes_path, alert: result.error }
    end
  end

  def show
    analysis = BugAnalysis.find(params[:id])
    report = BugAnalysisReport.new(analysis, logo: Setting.current.report_logo.presence)
    filename = "analise-de-bugs-#{analysis.created_at.strftime("%Y-%m-%d")}"

    respond_to do |format|
      format.pdf do
        send_data report.to_pdf, type: :pdf, disposition: pdf_disposition, filename: "#{filename}.pdf"
      rescue LatexDocument::Error => e
        Rails.logger.error(e.message)
        redirect_to bug_root_causes_path, alert: e.message.lines.first.strip
      end
      format.tex { send_data report.to_tex, type: :tex, disposition: :attachment, filename: "#{filename}.tex" }
    end
  end
end
