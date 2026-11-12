class SettingsController < ApplicationController
  before_action :require_admin
  before_action :set_setting

  def edit
  end

  def update
    @setting.report_logo.purge if params[:remove_report_logo] == "1"
    AiProviders.with_api_key.each do |name|
      @setting.public_send("#{name}_api_key=", nil) if params["remove_#{name}_api_key"] == "1"
    end

    if @setting.update(setting_params)
      redirect_to edit_settings_path, notice: t("controllers.settings.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_setting
      @setting = Setting.current
    end

    API_KEY_PARAMS = AiProviders.with_api_key.map { |name| :"#{name}_api_key" }.freeze

    # A blank key field keeps the stored key (the field never shows it back).
    def setting_params
      params.fetch(:setting, {})
        .permit(:report_logo, :ai_provider, :ai_model, *API_KEY_PARAMS)
        .reject { |name, value| name.to_sym.in?(API_KEY_PARAMS) && value.blank? }
    end
end
