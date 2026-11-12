# Caption of one evidence attachment (test scenario or bug), printed under the
# image in the LaTeX reports.
class EvidenceCaptionsController < ApplicationController
  before_action :set_attachment
  before_action :authorize_owner_or_admin

  def update
    @attachment.update!(caption: params[:caption].to_s.strip.presence)

    respond_to do |format|
      format.json { render json: { caption: @attachment.caption } }
      format.html { redirect_back_or_to owner_path, notice: t("controllers.evidence_captions.updated") }
    end
  end

  private
    def set_attachment
      @attachment = ActiveStorage::Attachment.where(name: "evidence_files", record_type: %w[TestScenario Bug]).find(params[:id])
    end

    def authorize_owner_or_admin
      case @attachment.record
      when TestScenario then authorize_plan_owner_or_admin(@attachment.record.test_plan)
      when Bug then authorize_record_owner_or_admin(@attachment.record)
      end
    end

    def owner_path
      record = @attachment.record
      record.is_a?(Bug) ? bug_path(record) : test_plan_path(record.test_plan)
    end
end
