# Translates form fields into English; nothing is saved here.
class AiTranslationsController < ApplicationController
  def create
    fields = params[:fields].respond_to?(:permit!) ? params[:fields].permit!.to_h : {}
    result = AiTranslator.new.call(fields)

    if result.success?
      render json: { success: true, fields: result.data }
    else
      render json: { success: false, error: result.error }, status: :unprocessable_entity
    end
  end
end
