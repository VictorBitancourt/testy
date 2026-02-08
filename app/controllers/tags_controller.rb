class TagsController < ApplicationController
  def autocomplete
    tags = Tag.search(params[:q]).order(:name).limit(10)
    render json: tags.pluck(:name)
  end
end
