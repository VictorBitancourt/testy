# Translates form fields into English; nothing is saved here.
class AiTranslationsController < ApplicationController
  BUG_FIELDS = %w[title description steps_to_reproduce obtained_result expected_result].freeze
  SCENARIO_FIELDS = %w[title given when_step then_step].freeze
  # Field names as the forms send them: "bug[title]", "test_scenario[given]",
  # or bare ("given") from the inline scenario edit.
  FIELDS = (BUG_FIELDS.map { |f| "bug[#{f}]" } + SCENARIO_FIELDS.map { |f| "test_scenario[#{f}]" } + SCENARIO_FIELDS).freeze

  def create
    fields = params.fetch(:fields, {}).permit(*FIELDS).to_h
    result = AiTranslator.new.call(fields)

    if result.success?
      render json: { success: true, fields: result.data }
    else
      render json: { success: false, error: result.error }, status: :unprocessable_entity
    end
  end
end
