module Api
  module V1
    class ScreenshotsController < BaseController
      before_action :set_test_plan
      before_action :set_test_scenario
      before_action -> { authorize_plan_owner_or_admin!(@test_plan) }

      def create
        if params.dig(:screenshot, :file).is_a?(ActionDispatch::Http::UploadedFile)
          uploaded = params[:screenshot][:file]
          filename = params.dig(:screenshot, :filename) || uploaded.original_filename
          content_type = uploaded.content_type
          if content_type.blank? || content_type == "application/octet-stream"
            content_type = Rack::Mime.mime_type(File.extname(filename), "image/png")
          end
          io = uploaded
        else
          screenshot_params = params.require(:screenshot).permit(:filename, :content_type, :data)
          content_type = screenshot_params[:content_type] || "image/png"
          data = Base64.decode64(screenshot_params[:data])
          filename = screenshot_params[:filename] || "screenshot-#{Time.current.strftime('%Y%m%d%H%M%S')}.png"
          io = StringIO.new(data)
        end

        unless content_type.in?(Attachments::ALLOWED_CONTENT_TYPES)
          return render json: { error: "Content type '#{content_type}' not allowed. Allowed: #{Attachments::ALLOWED_CONTENT_TYPES.join(', ')}" }, status: :unprocessable_entity
        end

        @test_scenario.evidence_files.attach(
          io: io,
          filename: filename,
          content_type: content_type
        )

        attachment = @test_scenario.evidence_files.blobs.last

        render json: {
          screenshot: {
            id: attachment.id,
            filename: attachment.filename.to_s,
            content_type: attachment.content_type,
            byte_size: attachment.byte_size
          }
        }, status: :created
      end

      private

      def set_test_plan
        @test_plan = TestPlan.find(params[:test_plan_id])
      end

      def set_test_scenario
        @test_scenario = @test_plan.test_scenarios.find(params[:test_scenario_id])
      end
    end
  end
end
