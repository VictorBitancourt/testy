require "test_helper"

class TestScenariosControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "unauthenticated access redirects to login" do
    sign_out

    post test_plan_test_scenarios_path(test_plans(:login_plan)), params: { test_scenario: { title: "Test" } }
    assert_redirected_to new_session_path
  end

  test "create" do
    plan = test_plans(:login_plan)

    assert_difference -> { plan.test_scenarios.count }, +1 do
      post test_plan_test_scenarios_path(plan), params: {
        test_scenario: { title: "System logout", given: "User is logged in", when_step: "Clicks sign out", then_step: "Redirects to login" }
      }
    end

    assert_redirected_to test_plan_path(plan)

    scenario = plan.test_scenarios.last
    assert_equal "System logout", scenario.title
    assert_equal "pending", scenario.status
  end

  test "create with invalid params" do
    plan = test_plans(:login_plan)

    assert_no_difference -> { TestScenario.count } do
      post test_plan_test_scenarios_path(plan), params: { test_scenario: { title: "" } }
    end

    assert_redirected_to test_plan_path(plan)
  end

  test "update" do
    plan = test_plans(:login_plan)
    scenario = test_scenarios(:login_success)

    patch test_plan_test_scenario_path(plan, scenario), params: { test_scenario: { title: "Updated title" } }

    assert_redirected_to test_plan_path(plan)
    assert_equal "Updated title", scenario.reload.title
  end

  test "update preserves unsubmitted fields" do
    scenario = test_scenarios(:login_success)
    original_given = scenario.given

    patch test_plan_test_scenario_path(test_plans(:login_plan), scenario), params: { test_scenario: { title: "New title" } }

    assert_equal original_given, scenario.reload.given
  end

  test "destroy" do
    plan = test_plans(:login_plan)

    assert_difference -> { plan.test_scenarios.count }, -1 do
      delete test_plan_test_scenario_path(plan, test_scenarios(:login_success))
    end

    assert_redirected_to test_plan_path(plan)
  end

  test "update_status to approved" do
    plan = test_plans(:login_plan)
    scenario = test_scenarios(:login_failure)

    patch test_plan_test_scenario_status_path(plan, scenario), params: { status: "approved" }, as: :json
    assert_response :success

    assert @response.parsed_body["success"]
    assert_equal "approved", scenario.reload.status
  end

  test "update_status to failed" do
    plan = test_plans(:login_plan)
    scenario = test_scenarios(:login_success)

    patch test_plan_test_scenario_status_path(plan, scenario), params: { status: "failed" }, as: :json
    assert_response :success

    assert @response.parsed_body["success"]
    assert_equal "failed", scenario.reload.status
  end

  test "update_status with invalid status" do
    plan = test_plans(:login_plan)
    scenario = test_scenarios(:login_success)

    patch test_plan_test_scenario_status_path(plan, scenario), params: { status: "invalid" }, as: :json
    assert_response :unprocessable_entity

    assert_not @response.parsed_body["success"]
  end

  test "update_status returns all_approved flag" do
    plan = test_plans(:login_plan)
    plan.test_scenarios.update_all(status: "approved")

    patch test_plan_test_scenario_status_path(plan, test_scenarios(:login_success)), params: { status: "approved" }, as: :json

    assert @response.parsed_body["all_approved"]
  end

  test "update_status returns all_approved false when not all approved" do
    plan = test_plans(:login_plan)

    patch test_plan_test_scenario_status_path(plan, test_scenarios(:login_success)), params: { status: "approved" }, as: :json

    assert_not @response.parsed_body["all_approved"]
  end

  test "reorder" do
    plan = test_plans(:login_plan)
    s1 = test_scenarios(:login_success)
    s2 = test_scenarios(:login_failure)
    s3 = test_scenarios(:login_approved)

    patch test_plan_scenario_order_path(plan), params: { scenario_ids: [ s3.id, s1.id, s2.id ] }, as: :json
    assert_response :success

    assert_equal 0, s3.reload.position
    assert_equal 1, s1.reload.position
    assert_equal 2, s2.reload.position
  end

  test "reorder requires authentication" do
    sign_out

    patch test_plan_scenario_order_path(test_plans(:login_plan)),
      params: { scenario_ids: [ test_scenarios(:login_success).id ] }, as: :json

    assert_redirected_to new_session_path
  end

  test "regular user cannot create scenario on another user's plan" do
    logout_and_sign_in_as users(:regular_user)

    assert_no_difference -> { TestScenario.count } do
      post test_plan_test_scenarios_path(test_plans(:login_plan)), params: { test_scenario: { title: "Hacked" } }
    end

    assert_redirected_to root_path
  end

  test "regular user cannot destroy scenario on another user's plan" do
    logout_and_sign_in_as users(:regular_user)

    assert_no_difference -> { TestScenario.count } do
      delete test_plan_test_scenario_path(test_plans(:login_plan), test_scenarios(:login_success))
    end

    assert_redirected_to root_path
  end

  test "update via JSON resets status to pending" do
    plan = test_plans(:login_plan)
    scenario = test_scenarios(:login_success)
    assert_equal "approved", scenario.status

    patch test_plan_test_scenario_path(plan, scenario), params: {
      test_scenario: { given: "Updated given" }
    }, as: :json

    assert_response :success
    body = response.parsed_body
    assert body["success"]
    assert_equal "pending", body["scenario"]["status"]
    assert_equal "Updated given", body["scenario"]["given"]
    assert_equal "pending", scenario.reload.status
  end

  test "update via JSON returns fields" do
    plan = test_plans(:login_plan)
    scenario = test_scenarios(:login_failure)

    patch test_plan_test_scenario_path(plan, scenario), params: {
      test_scenario: { given: "New given", when_step: "New when", then_step: "New then" }
    }, as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal "New given", body["scenario"]["given"]
    assert_equal "New when", body["scenario"]["when_step"]
    assert_equal "New then", body["scenario"]["then_step"]
  end

  test "update via JSON with invalid params returns error" do
    plan = test_plans(:login_plan)
    scenario = test_scenarios(:login_success)

    patch test_plan_test_scenario_path(plan, scenario), params: {
      test_scenario: { title: "" }
    }, as: :json

    assert_response :unprocessable_entity
    assert_not response.parsed_body["success"]
  end

  test "regular user cannot reorder scenarios on another user's plan" do
    logout_and_sign_in_as users(:regular_user)

    patch test_plan_scenario_order_path(test_plans(:login_plan)),
      params: { scenario_ids: [ test_scenarios(:login_success).id ] }, as: :json

    assert_redirected_to root_path
  end

  test "regular user can create scenario on own plan" do
    logout_and_sign_in_as users(:regular_user)
    own_plan = TestPlan.create!(name: "My Plan", qa_name: "QA", user: users(:regular_user))

    assert_difference -> { own_plan.test_scenarios.count }, +1 do
      post test_plan_test_scenarios_path(own_plan), params: {
        test_scenario: { title: "My Scenario", given: "Given", when_step: "When", then_step: "Then" }
      }
    end
  end
end
