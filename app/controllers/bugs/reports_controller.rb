class Bugs::ReportsController < ApplicationController
  before_action :set_bug

  def show
    respond_to do |format|
      format.html { render template: "bugs/report", layout: false }
      format.pdf do
        send_data bug_report.to_pdf, type: :pdf, disposition: :inline, filename: "#{report_filename}.pdf"
      rescue LatexDocument::Error => e
        Rails.logger.error(e.message)
        redirect_to @bug, alert: e.message.lines.first.strip
      end
      format.tex do
        send_data bug_report.to_tex, type: :tex, disposition: :attachment, filename: "#{report_filename}.tex"
      end
    end
  end

  private
    def set_bug
      @bug = Bug.includes(:user, evidence_files_attachments: :blob).find(params[:bug_id])
    end

    def bug_report
      BugReport.new(@bug, logo: Setting.current.report_logo.presence)
    end

    def report_filename
      "bug-#{@bug.id}"
    end
end
