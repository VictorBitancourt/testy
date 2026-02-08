require "test_helper"

class TestScenariosControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:admin))
    @plan = test_plans(:login_plan)
    @scenario = test_scenarios(:login_success)
  end

  # authentication

  test "unauthenticated access redirects to login" do
    sign_out

    post test_plan_test_scenarios_path(@plan), params: {
      test_scenario: { title: "Test" }
    }
    assert_redirected_to new_session_path
  end

  # create

  test "create" do
    assert_difference -> { @plan.test_scenarios.count }, +1 do
      post test_plan_test_scenarios_path(@plan), params: {
        test_scenario: { title: "Logout do sistema", given: "Usuario logado", when_step: "Clica em sair", then_step: "Redireciona para login" }
      }
    end

    assert_redirected_to test_plan_path(@plan)

    scenario = @plan.test_scenarios.last
    assert_equal "Logout do sistema", scenario.title
    assert_equal "pending", scenario.status
  end

  test "create with invalid params" do
    assert_no_difference -> { TestScenario.count } do
      post test_plan_test_scenarios_path(@plan), params: {
        test_scenario: { title: "" }
      }
    end

    assert_redirected_to test_plan_path(@plan)
    assert_equal "Erro ao adicionar cenário.", flash[:alert]
  end

  # update

  test "update" do
    patch test_plan_test_scenario_path(@plan, @scenario), params: {
      test_scenario: { title: "Titulo atualizado" }
    }

    assert_redirected_to test_plan_path(@plan)
    assert_equal "Titulo atualizado", @scenario.reload.title
  end

  test "update does not change other fields when not provided" do
    original_given = @scenario.given

    patch test_plan_test_scenario_path(@plan, @scenario), params: {
      test_scenario: { title: "Novo titulo" }
    }

    assert_equal original_given, @scenario.reload.given
  end

  # destroy

  test "destroy" do
    assert_difference -> { @plan.test_scenarios.count }, -1 do
      delete test_plan_test_scenario_path(@plan, @scenario)
    end

    assert_redirected_to test_plan_path(@plan)
  end

  # update_status

  test "update_status to approved" do
    scenario = test_scenarios(:login_failure)

    patch update_status_test_plan_test_scenario_path(@plan, scenario), params: { status: "approved" }, as: :json
    assert_response :success

    body = response.parsed_body
    assert body["success"]
    assert_equal "approved", scenario.reload.status
  end

  test "update_status to failed" do
    patch update_status_test_plan_test_scenario_path(@plan, @scenario), params: { status: "failed" }, as: :json
    assert_response :success

    body = response.parsed_body
    assert body["success"]
    assert_equal "failed", @scenario.reload.status
  end

  test "update_status with invalid status" do
    patch update_status_test_plan_test_scenario_path(@plan, @scenario), params: { status: "invalid" }, as: :json
    assert_response :unprocessable_entity

    body = response.parsed_body
    assert_not body["success"]
  end

  test "update_status returns all_approved flag" do
    @plan.test_scenarios.update_all(status: "approved")

    patch update_status_test_plan_test_scenario_path(@plan, @scenario), params: { status: "approved" }, as: :json

    body = response.parsed_body
    assert body["all_approved"]
  end

  test "update_status returns all_approved false when not all approved" do
    patch update_status_test_plan_test_scenario_path(@plan, @scenario), params: { status: "approved" }, as: :json

    body = response.parsed_body
    assert_not body["all_approved"]
  end

  # reorder

  test "reorder scenarios" do
    s1 = test_scenarios(:login_success)
    s2 = test_scenarios(:login_failure)
    s3 = test_scenarios(:login_approved)

    patch reorder_test_plan_test_scenarios_path(@plan),
      params: { scenario_ids: [ s3.id, s1.id, s2.id ] }, as: :json

    assert_response :success
    assert_equal 0, s3.reload.position
    assert_equal 1, s1.reload.position
    assert_equal 2, s2.reload.position
  end

  test "reorder requires authentication" do
    sign_out

    patch reorder_test_plan_test_scenarios_path(@plan),
      params: { scenario_ids: [ @scenario.id ] }, as: :json

    assert_redirected_to new_session_path
  end

  # authorization

  test "regular user cannot create scenario on another users plan" do
    sign_out
    sign_in_as(users(:regular_user))

    assert_no_difference -> { TestScenario.count } do
      post test_plan_test_scenarios_path(@plan), params: {
        test_scenario: { title: "Hacked scenario" }
      }
    end

    assert_redirected_to root_path
  end

  test "regular user cannot destroy scenario on another users plan" do
    sign_out
    sign_in_as(users(:regular_user))

    assert_no_difference -> { TestScenario.count } do
      delete test_plan_test_scenario_path(@plan, @scenario)
    end

    assert_redirected_to root_path
  end

  test "regular user can create scenario on own plan" do
    sign_out
    user = users(:regular_user)
    sign_in_as(user)

    own_plan = TestPlan.create!(name: "My Plan", qa_name: "QA", user: user)

    assert_difference -> { own_plan.test_scenarios.count }, +1 do
      post test_plan_test_scenarios_path(own_plan), params: {
        test_scenario: { title: "My Scenario", given: "Given", when_step: "When", then_step: "Then" }
      }
    end
  end
end
