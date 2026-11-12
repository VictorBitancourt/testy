class AddAiSettingsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :ai_provider, :string
    add_column :settings, :ai_model, :string
    add_column :settings, :gemini_api_key, :text
    add_column :settings, :openai_api_key, :text
    add_column :settings, :anthropic_api_key, :text
  end
end
