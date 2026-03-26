require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    Api::V1::AuthController::RATE_LIMIT_STORE.clear
  end

  test "login with valid credentials returns token" do
    api_post "/api/v1/auth/login", params: { username: "admin", password: "password123" }, token: nil

    assert_response :created
    assert json_response["token"].present?
    assert_equal "admin", json_response.dig("user", "username")
    assert_equal "admin", json_response.dig("user", "role")
  end

  test "login with invalid credentials returns 401" do
    api_post "/api/v1/auth/login", params: { username: "admin", password: "wrong" }, token: nil

    assert_response :unauthorized
    assert_equal "Invalid username or password", json_response["error"]
  end

  test "login with non-existent user returns 401" do
    api_post "/api/v1/auth/login", params: { username: "nobody", password: "password123" }, token: nil

    assert_response :unauthorized
  end

  test "login creates an api token record" do
    assert_difference "ApiToken.count", 1 do
      api_post "/api/v1/auth/login", params: { username: "admin", password: "password123" }, token: nil
    end
  end

  test "login with token_name stores the name" do
    api_post "/api/v1/auth/login", params: { username: "admin", password: "password123", token_name: "CI pipeline" }, token: nil

    assert_response :created
    token = ApiToken.last
    assert_equal "CI pipeline", token.name
  end

  test "logout destroys the token" do
    assert_difference "ApiToken.count", -1 do
      api_delete "/api/v1/auth/logout", token: ADMIN_TOKEN
    end

    assert_response :ok
    assert_equal "Logged out successfully", json_response["message"]
  end

  test "logout with invalid token returns 401" do
    api_delete "/api/v1/auth/logout", token: "invalid_token"

    assert_response :unauthorized
  end

  test "rate limiting on login endpoint" do
    5.times do
      api_post "/api/v1/auth/login", params: { username: "admin", password: "wrong" }, token: nil
      assert_response :unauthorized
    end

    api_post "/api/v1/auth/login", params: { username: "admin", password: "wrong" }, token: nil
    assert_response :too_many_requests
  end
end
