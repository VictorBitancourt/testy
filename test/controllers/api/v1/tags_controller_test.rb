require "test_helper"

class Api::V1::TagsControllerTest < ActionDispatch::IntegrationTest
  test "index returns tags" do
    api_get "/api/v1/tags"

    assert_response :ok
    assert json_response["tags"].is_a?(Array)
    assert json_response["tags"].any?
  end

  test "index filters by q" do
    api_get "/api/v1/tags", params: { q: "login" }

    assert_response :ok
    json_response["tags"].each do |tag|
      assert_match(/login/i, tag)
    end
  end

  test "index respects limit parameter" do
    api_get "/api/v1/tags", params: { limit: 1 }

    assert_response :ok
    assert json_response["tags"].size <= 1
  end

  test "index without token returns 401" do
    api_get "/api/v1/tags", token: nil

    assert_response :unauthorized
  end
end
