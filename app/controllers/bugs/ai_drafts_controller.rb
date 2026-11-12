# Fills the new-bug form from pasted notes; nothing is saved here.
class Bugs::AiDraftsController < ApplicationController
  before_action :require_project

  def create
    result = AiBugDrafter.new(project: current_project).call(params[:text].to_s.strip)

    if result.success?
      render json: { success: true, bug: result.data }
    else
      render json: { success: false, error: result.error }, status: :unprocessable_entity
    end
  end
end
