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
