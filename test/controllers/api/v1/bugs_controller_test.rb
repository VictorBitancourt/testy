require "test_helper"

class Api::V1::BugsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bug = bugs(:open_bug)
    @user_bug = bugs(:user_bug)
  end

  # Authentication
  test "index without token returns 401" do
    api_get "/api/v1/bugs", token: nil

    assert_response :unauthorized
  end

  # Index
  test "index returns paginated bugs" do
    api_get "/api/v1/bugs"

    assert_response :ok
    assert json_response["bugs"].is_a?(Array)
    assert json_response["meta"]["current_page"].present?
    assert json_response["meta"]["total_count"].present?
  end

  test "index filters by status" do
    api_get "/api/v1/bugs", params: { status: "open" }

    assert_response :ok
    json_response["bugs"].each do |bug|
      assert_equal "open", bug["status"]
    end
  end

  test "index filters by feature_tag" do
    api_get "/api/v1/bugs", params: { feature_tag: "checkout" }

    assert_response :ok
    json_response["bugs"].each do |bug|
      assert_equal "checkout", bug["feature_tag"]
    end
  end

  test "index filters by cause_tag" do
    api_get "/api/v1/bugs", params: { cause_tag: "ui" }

    assert_response :ok
    json_response["bugs"].each do |bug|
      assert_equal "ui", bug["cause_tag"]
    end
  end

  test "index filters by search" do
    api_get "/api/v1/bugs", params: { search: "checkout" }

    assert_response :ok
    assert json_response["bugs"].any?
  end

  # Show
  test "show returns bug with full details" do
    api_get "/api/v1/bugs/#{@bug.id}"

    assert_response :ok
    assert_equal @bug.title, json_response.dig("bug", "title")
    assert json_response.dig("bug", "steps_to_reproduce").present?
    assert json_response.dig("bug", "expected_result").present?
    assert json_response.dig("bug", "obtained_result").present?
  end

  test "show returns 404 for non-existent bug" do
    api_get "/api/v1/bugs/999999"

    assert_response :not_found
  end

  # Create
  test "create with valid params returns 201" do
    assert_difference "Bug.count", 1 do
      api_post "/api/v1/bugs", params: {
        bug: { title: "New API Bug", description: "Bug from API" }
      }
    end

    assert_response :created
    assert_equal "New API Bug", json_response.dig("bug", "title")
  end

  test "create assigns current api user" do
    api_post "/api/v1/bugs", params: {
      bug: { title: "User Bug", description: "Created via API" }
    }, token: USER_TOKEN

    assert_response :created
    bug = Bug.find(json_response.dig("bug", "id"))
    assert_equal users(:regular_user), bug.user
  end

  test "create with invalid params returns 422" do
    api_post "/api/v1/bugs", params: { bug: { title: "" } }

    assert_response :unprocessable_entity
    assert json_response["errors"].present?
  end

  # Update
  test "update as owner succeeds" do
    api_patch "/api/v1/bugs/#{@bug.id}", params: { bug: { title: "Updated Bug" } }

    assert_response :ok
    assert_equal "Updated Bug", json_response.dig("bug", "title")
  end

  test "update as admin on other user's bug succeeds" do
    api_patch "/api/v1/bugs/#{@user_bug.id}", params: { bug: { title: "Admin Fixed" } }, token: ADMIN_TOKEN

    assert_response :ok
  end

  test "update as non-owner non-admin returns 403" do
    api_patch "/api/v1/bugs/#{@bug.id}", params: { bug: { title: "Hacked" } }, token: USER_TOKEN

    assert_response :forbidden
  end

  # Destroy
  test "destroy as owner succeeds" do
    assert_difference "Bug.count", -1 do
      api_delete "/api/v1/bugs/#{@bug.id}"
    end

    assert_response :no_content
  end

  test "destroy as non-owner returns 403" do
    api_delete "/api/v1/bugs/#{@bug.id}", token: USER_TOKEN

    assert_response :forbidden
  end
end
