require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "edit" do
    get edit_settings_path
    assert_response :success
  end

  test "upload report logo" do
    patch settings_path, params: { setting: { report_logo: fixture_file_upload("test_evidence.png", "image/png") } }

    assert_redirected_to edit_settings_path
    assert Setting.current.report_logo.attached?
  end

  test "reject non-image logo" do
    patch settings_path, params: { setting: { report_logo: fixture_file_upload("not_an_image.txt", "text/plain") } }

    assert_response :unprocessable_entity
    assert_not Setting.current.reload.report_logo.attached?
  end

  test "remove report logo" do
    Setting.current.report_logo.attach(io: file_fixture("test_evidence.png").open, filename: "logo.png", content_type: "image/png")

    patch settings_path, params: { remove_report_logo: "1" }

    assert_redirected_to edit_settings_path
    assert_not Setting.current.reload.report_logo.attached?
  end

  test "regular user cannot change settings" do
    logout_and_sign_in_as users(:regular_user)

    get edit_settings_path
    assert_redirected_to root_path

    patch settings_path, params: { setting: { report_logo: fixture_file_upload("test_evidence.png", "image/png") } }
    assert_redirected_to root_path
    assert_not Setting.current.report_logo.attached?
  end

  test "save AI provider, model and key" do
    patch settings_path, params: { setting: { ai_provider: "anthropic", ai_model: "claude-opus-5-5", anthropic_api_key: "sk-ant" } }

    assert_redirected_to edit_settings_path
    setting = Setting.current
    assert_equal "anthropic", setting.ai_provider
    assert_equal "claude-opus-5-5", setting.ai_model
    assert_equal "sk-ant", setting.anthropic_api_key
  end

  test "blank key field keeps the stored key" do
    Setting.current.update!(openai_api_key: "sk-keep")

    patch settings_path, params: { setting: { ai_provider: "openai", openai_api_key: "" } }

    assert_equal "sk-keep", Setting.current.openai_api_key
  end

  test "remove an API key" do
    Setting.current.update!(gemini_api_key: "g-key")

    patch settings_path, params: { remove_gemini_api_key: "1" }

    assert_nil Setting.current.gemini_api_key
  end

  test "edit never shows stored keys" do
    Setting.current.update!(anthropic_api_key: "sk-hidden")

    get edit_settings_path

    assert_not_includes response.body, "sk-hidden"
  end

  test "reject unknown provider" do
    patch settings_path, params: { setting: { ai_provider: "skynet" } }

    assert_response :unprocessable_entity
  end
end
