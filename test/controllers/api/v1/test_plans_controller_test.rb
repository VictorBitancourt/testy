require "test_helper"

class Api::V1::TestPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plan = test_plans(:login_plan)
  end

  # Authentication
  test "index without token returns 401" do
    api_get "/api/v1/test_plans", token: nil

    assert_response :unauthorized
  end

  # Index
  test "index returns paginated test plans" do
    api_get "/api/v1/test_plans"

    assert_response :ok
    assert json_response["test_plans"].is_a?(Array)
    assert json_response["meta"]["current_page"].present?
    assert json_response["meta"]["total_pages"].present?
    assert json_response["meta"]["total_count"].present?
  end

  test "index filters by status" do
    api_get "/api/v1/test_plans", params: { status: "approved" }

    assert_response :ok
    json_response["test_plans"].each do |plan|
      assert_equal "approved", plan["status"]
    end
  end

  test "index filters by date_from" do
    api_get "/api/v1/test_plans", params: { date_from: Date.current.to_s }

    assert_response :ok
  end

  test "index filters by search" do
    api_get "/api/v1/test_plans", params: { search: "Login" }

    assert_response :ok
    assert json_response["test_plans"].any? { |p| p["name"].include?("Login") }
  end

  # Show
  test "show returns plan with scenarios" do
    api_get "/api/v1/test_plans/#{@plan.id}"

    assert_response :ok
    assert_equal @plan.name, json_response.dig("test_plan", "name")
    assert json_response.dig("test_plan", "test_scenarios").is_a?(Array)
  end

  test "show returns 404 for non-existent plan" do
    api_get "/api/v1/test_plans/999999"

    assert_response :not_found
  end

  # Create
  test "create with valid params returns 201" do
    assert_difference "TestPlan.count", 1 do
      api_post "/api/v1/test_plans", params: { test_plan: { name: "New API Plan", qa_name: "Tester" } }
    end

    assert_response :created
    assert_equal "New API Plan", json_response.dig("test_plan", "name")
  end

  test "create assigns current api user" do
    api_post "/api/v1/test_plans", params: { test_plan: { name: "My Plan", qa_name: "QA" } }

    assert_response :created
    plan = TestPlan.find(json_response.dig("test_plan", "id"))
    assert_equal users(:admin), plan.user
  end

  test "create with invalid params returns 422" do
    api_post "/api/v1/test_plans", params: { test_plan: { name: "" } }

    assert_response :unprocessable_entity
    assert json_response["errors"].present?
  end

  test "create with tag_list sets tags" do
    api_post "/api/v1/test_plans", params: { test_plan: { name: "Tagged Plan", qa_name: "QA", tag_list: "api, v1" } }

    assert_response :created
    assert_includes json_response.dig("test_plan", "tags"), "api"
    assert_includes json_response.dig("test_plan", "tags"), "v1"
  end

  # Update
  test "update as owner succeeds" do
    api_patch "/api/v1/test_plans/#{@plan.id}", params: { test_plan: { name: "Updated Name" } }

    assert_response :ok
    assert_equal "Updated Name", json_response.dig("test_plan", "name")
  end

  test "update as admin on other user's plan succeeds" do
    user_plan = TestPlan.create!(name: "User Plan", qa_name: "QA", user: users(:regular_user))

    api_patch "/api/v1/test_plans/#{user_plan.id}", params: { test_plan: { name: "Admin Updated" } }, token: ADMIN_TOKEN

    assert_response :ok
  end

  test "update as non-owner non-admin returns 403" do
    api_patch "/api/v1/test_plans/#{@plan.id}", params: { test_plan: { name: "Hacked" } }, token: USER_TOKEN

    assert_response :forbidden
  end

  # Destroy
  test "destroy as owner succeeds" do
    assert_difference "TestPlan.count", -1 do
      api_delete "/api/v1/test_plans/#{@plan.id}"
    end

    assert_response :no_content
  end

  test "destroy as non-owner returns 403" do
    api_delete "/api/v1/test_plans/#{@plan.id}", token: USER_TOKEN

    assert_response :forbidden
  end
end
