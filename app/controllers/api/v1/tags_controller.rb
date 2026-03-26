module Api
  module V1
    class TagsController < BaseController
      def index
        limit = (params[:limit] || 50).to_i.clamp(1, 100)
        tags = Tag.order(:name)
        tags = tags.search(params[:q]) if params[:q].present?
        tags = tags.limit(limit)

        render json: { tags: tags.pluck(:name) }
      end
    end
  end
end
