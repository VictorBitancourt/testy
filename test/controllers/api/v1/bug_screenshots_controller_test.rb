require "test_helper"

class Api::V1::BugScreenshotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bug = bugs(:open_bug)
    @valid_params = {
      screenshot: {
        filename: "checkout-error.png",
        content_type: "image/png",
        data: Base64.strict_encode64("fake png data")
      }
    }
  end

  test "create attaches the screenshot to the bug" do
    assert_difference -> { @bug.evidence_files.count }, 1 do
      api_post "/api/v1/bugs/#{@bug.id}/screenshots", params: @valid_params
    end

    assert_response :created
    assert_equal "checkout-error.png", json_response.dig("screenshot", "filename")
  end

  test "create keeps the evidence already attached" do
    api_post "/api/v1/bugs/#{@bug.id}/screenshots", params: @valid_params
    api_post "/api/v1/bugs/#{@bug.id}/screenshots", params: @valid_params

    assert_equal 2, @bug.evidence_files.count
  end

  test "create accepts a multipart file" do
    file = Rack::Test::UploadedFile.new(StringIO.new("fake png data"), "image/png", original_filename: "step-3.png")

    post "/api/v1/bugs/#{@bug.id}/screenshots",
      params: { screenshot: { file: file } },
      headers: { "Authorization" => "Bearer #{ADMIN_TOKEN}" }

    assert_response :created
    assert_equal "step-3.png", json_response.dig("screenshot", "filename")
  end

  test "create with invalid content_type returns 422" do
    api_post "/api/v1/bugs/#{@bug.id}/screenshots",
      params: { screenshot: { filename: "notes.txt", content_type: "text/plain", data: Base64.strict_encode64("text") } }

    assert_response :unprocessable_entity
  end

  test "create without auth returns 401" do
    api_post "/api/v1/bugs/#{@bug.id}/screenshots", params: @valid_params, token: "invalid_token"

    assert_response :unauthorized
  end

  test "create as non-owner returns 403" do
    api_post "/api/v1/bugs/#{@bug.id}/screenshots", params: @valid_params, token: USER_TOKEN

    assert_response :forbidden
  end

  test "create on a missing bug returns 404" do
    api_post "/api/v1/bugs/999999/screenshots", params: @valid_params

    assert_response :not_found
  end

  test "show lists the bug evidence" do
    api_post "/api/v1/bugs/#{@bug.id}/screenshots", params: @valid_params

    api_get "/api/v1/bugs/#{@bug.id}"

    assert_equal [ "checkout-error.png" ], json_response.dig("bug", "evidence_files").map { |f| f["filename"] }
  end
end
