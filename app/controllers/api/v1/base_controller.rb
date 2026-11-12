module Api
  module V1
    class BaseController < ActionController::API
      include ApiAuthentication
      include Pagy::Method

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Not found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      rescue_from ActionController::ParameterMissing do |e|
        render json: { error: e.message }, status: :bad_request
      end

      private

      # The project named by project_id; without it, the only project there is.
      def api_project
        return Project.find(params[:project_id]) if params[:project_id].present?
        return Project.first if Project.count == 1

        raise ActionController::ParameterMissing, :project_id
      end

      def render_errors(record)
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end

      def pagination_meta(pagy)
        {
          current_page: pagy.page,
          total_pages: pagy.pages,
          total_count: pagy.count
        }
      end
    end
  end
end
