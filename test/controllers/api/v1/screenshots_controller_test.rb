require "test_helper"

class Api::V1::ScreenshotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plan = test_plans(:login_plan)
    @scenario = test_scenarios(:login_success)
    @valid_params = {
      screenshot: {
        filename: "login-page.png",
        content_type: "image/png",
        data: Base64.strict_encode64("fake png data")
      }
    }
  end

  test "create with valid params returns 201 and attaches file" do
    assert_difference -> { @scenario.evidence_files.count }, 1 do
      api_post "/api/v1/test_plans/#{@plan.id}/test_scenarios/#{@scenario.id}/screenshots",
        params: @valid_params
    end

    assert_response :created
    assert_equal "login-page.png", json_response.dig("screenshot", "filename")
    assert_equal "image/png", json_response.dig("screenshot", "content_type")
  end

  test "create defaults content_type to image/png" do
    api_post "/api/v1/test_plans/#{@plan.id}/test_scenarios/#{@scenario.id}/screenshots",
      params: { screenshot: { filename: "shot.png", data: Base64.strict_encode64("data") } }

    assert_response :created
    assert_equal "image/png", json_response.dig("screenshot", "content_type")
  end

  test "create with invalid content_type returns 422" do
    api_post "/api/v1/test_plans/#{@plan.id}/test_scenarios/#{@scenario.id}/screenshots",
      params: { screenshot: { filename: "test.txt", content_type: "text/plain", data: Base64.strict_encode64("text") } }

    assert_response :unprocessable_entity
    assert json_response["error"].include?("text/plain")
  end

  test "create without auth returns 401" do
    api_post "/api/v1/test_plans/#{@plan.id}/test_scenarios/#{@scenario.id}/screenshots",
      params: @valid_params, token: "invalid_token"

    assert_response :unauthorized
  end

  test "create as non-owner returns 403" do
    api_post "/api/v1/test_plans/#{@plan.id}/test_scenarios/#{@scenario.id}/screenshots",
      params: @valid_params, token: USER_TOKEN

    assert_response :forbidden
  end

  test "create with non-existent scenario returns 404" do
    api_post "/api/v1/test_plans/#{@plan.id}/test_scenarios/999999/screenshots",
      params: @valid_params

    assert_response :not_found
  end

  test "create with non-existent plan returns 404" do
    api_post "/api/v1/test_plans/999999/test_scenarios/#{@scenario.id}/screenshots",
      params: @valid_params

    assert_response :not_found
  end
end
