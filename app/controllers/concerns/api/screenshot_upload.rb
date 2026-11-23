# Attaches a screenshot sent to the API (multipart file or base64 data) to a
# record's evidence files and renders it.
module Api::ScreenshotUpload
  extend ActiveSupport::Concern

  private
    def attach_screenshot(record)
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

      record.evidence_files.attach(
        io: io,
        filename: filename,
        content_type: content_type
      )

      attachment = record.evidence_files.blobs.last

      render json: {
        screenshot: {
          id: attachment.id,
          filename: attachment.filename.to_s,
          content_type: attachment.content_type,
          byte_size: attachment.byte_size
        }
      }, status: :created
    end
end
