require "test_helper"

class Api::V1::TestScenariosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plan = test_plans(:login_plan)
    @scenario = test_scenarios(:login_success)
  end

  # Create
  test "create with valid params returns 201" do
    assert_difference "TestScenario.count", 1 do
      api_post "/api/v1/test_plans/#{@plan.id}/test_scenarios", params: {
        test_scenario: {
          title: "New Scenario",
          given: "Given state",
          when_step: "When action",
          then_step: "Then result"
        }
      }
    end

    assert_response :created
    assert_equal "New Scenario", json_response.dig("test_scenario", "title")
  end

  test "create with invalid params returns 422" do
    api_post "/api/v1/test_plans/#{@plan.id}/test_scenarios", params: {
      test_scenario: { title: "" }
    }

    assert_response :unprocessable_entity
    assert json_response["errors"].present?
  end

  test "create as non-owner returns 403" do
    api_post "/api/v1/test_plans/#{@plan.id}/test_scenarios", params: {
      test_scenario: {
        title: "Unauthorized",
        given: "G",
        when_step: "W",
        then_step: "T"
      }
    }, token: USER_TOKEN

    assert_response :forbidden
  end

  # Update
  test "update with valid params succeeds" do
    api_patch "/api/v1/test_plans/#{@plan.id}/test_scenarios/#{@scenario.id}", params: {
      test_scenario: { title: "Updated Title" }
    }

    assert_response :ok
    assert_equal "Updated Title", json_response.dig("test_scenario", "title")
  end

  test "update as non-owner returns 403" do
    api_patch "/api/v1/test_plans/#{@plan.id}/test_scenarios/#{@scenario.id}", params: {
      test_scenario: { title: "Hacked" }
    }, token: USER_TOKEN

    assert_response :forbidden
  end

  # Destroy
  test "destroy as owner succeeds" do
    assert_difference "TestScenario.count", -1 do
      api_delete "/api/v1/test_plans/#{@plan.id}/test_scenarios/#{@scenario.id}"
    end

    assert_response :no_content
  end

  test "destroy as non-owner returns 403" do
    api_delete "/api/v1/test_plans/#{@plan.id}/test_scenarios/#{@scenario.id}", token: USER_TOKEN

    assert_response :forbidden
  end

  test "returns 404 for non-existent plan" do
    api_post "/api/v1/test_plans/999999/test_scenarios", params: {
      test_scenario: { title: "T", given: "G", when_step: "W", then_step: "T" }
    }

    assert_response :not_found
  end
end
