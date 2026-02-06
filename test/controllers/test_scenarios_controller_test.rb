require "test_helper"

class TestScenariosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plan = test_plans(:login_plan)
    @scenario = test_scenarios(:login_success)
  end

  test "POST create with valid params" do
    assert_difference "TestScenario.count", 1 do
      post test_plan_test_scenarios_url(@plan), params: {
        test_scenario: { title: "Logout do sistema", given: "Usuario logado", when_step: "Clica em sair", then_step: "Redireciona para login" }
      }
    end
    assert_redirected_to test_plan_url(@plan)
  end

  test "POST create with invalid params" do
    assert_no_difference "TestScenario.count" do
      post test_plan_test_scenarios_url(@plan), params: {
        test_scenario: { title: "" }
      }
    end
    assert_redirected_to test_plan_url(@plan)
    assert_equal "Erro ao adicionar cenário.", flash[:alert]
  end

  test "PATCH update with valid params" do
    patch test_plan_test_scenario_url(@plan, @scenario), params: {
      test_scenario: { title: "Titulo atualizado" }
    }
    assert_redirected_to test_plan_url(@plan)
    @scenario.reload
    assert_equal "Titulo atualizado", @scenario.title
  end

  test "DELETE destroy" do
    assert_difference "TestScenario.count", -1 do
      delete test_plan_test_scenario_url(@plan, @scenario)
    end
    assert_redirected_to test_plan_url(@plan)
  end

  test "PATCH update_status with valid status" do
    patch update_status_test_plan_test_scenario_url(@plan, @scenario), params: { status: "approved" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body["success"]
  end

  test "PATCH update_status with invalid status" do
    patch update_status_test_plan_test_scenario_url(@plan, @scenario), params: { status: "invalid" }, as: :json
    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_not body["success"]
  end
end
