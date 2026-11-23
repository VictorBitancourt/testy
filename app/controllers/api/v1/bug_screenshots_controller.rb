module Api
  module V1
    class BugScreenshotsController < BaseController
      include Api::ScreenshotUpload

      before_action :set_bug
      before_action -> { authorize_owner_or_admin!(@bug) }

      def create
        attach_screenshot(@bug)
      end

      private

      def set_bug
        @bug = Bug.find(params[:bug_id])
      end
    end
  end
end
