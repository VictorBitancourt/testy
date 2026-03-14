class Bugs::ReportsController < ApplicationController
  before_action :set_bug

  def show
    respond_to do |format|
      format.html { render template: "bugs/report", layout: false }
      format.pdf do
        render ferrum_pdf: {
          paper_width: 8.27,
          paper_height: 11.69,
          margin_top: 0,
          margin_bottom: 0,
          margin_left: 0,
          margin_right: 0
        },
        template: "bugs/report_pdf",
        formats: [ :html ],
        layout: false,
        disposition: :inline,
        filename: "bug_#{@bug.id}.pdf"
      end
    end
  end

  private
    def set_bug
      @bug = Bug.find(params[:bug_id])
    end
end
