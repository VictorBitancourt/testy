module ActiveStorage
  module AuthorizeBlob
    extend ActiveSupport::Concern

    included do
      include Rails.application.routes.url_helpers
      include Authentication

      before_action :authorize_blob_access
    end

    private

    def authorize_blob_access
      attachment = ::ActiveStorage::Attachment.find_by(blob_id: @blob.id)
      return head(:not_found) unless attachment

      record = attachment.record
      return unless record.is_a?(TestScenario)

      test_plan = record.test_plan
      unless current_user_admin? || test_plan.user == ::Current.user
        head :forbidden
      end
    end
  end
end
