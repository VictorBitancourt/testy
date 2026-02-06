require "test_helper"

class TestPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plan = test_plans(:login_plan)
  end

  test "GET index" do
    get test_plans_url
    assert_response :success
  end

  test "GET show" do
    get test_plan_url(@plan)
    assert_response :success
  end

  test "GET new" do
    get new_test_plan_url
    assert_response :success
  end

  test "POST create with valid params" do
    assert_difference "TestPlan.count", 1 do
      post test_plans_url, params: { test_plan: { name: "Novo Plano", qa_name: "Carlos Lima" } }
    end
    assert_redirected_to test_plan_url(TestPlan.last)
  end

  test "POST create with invalid params" do
    assert_no_difference "TestPlan.count" do
      post test_plans_url, params: { test_plan: { name: "", qa_name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "GET edit" do
    get edit_test_plan_url(@plan)
    assert_response :success
  end

  test "PATCH update with valid params" do
    patch test_plan_url(@plan), params: { test_plan: { name: "Nome Atualizado" } }
    assert_redirected_to test_plan_url(@plan)
    @plan.reload
    assert_equal "Nome Atualizado", @plan.name
  end

  test "PATCH update with invalid params" do
    patch test_plan_url(@plan), params: { test_plan: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy" do
    assert_difference "TestPlan.count", -1 do
      delete test_plan_url(@plan)
    end
    assert_redirected_to test_plans_url
  end

  test "GET report" do
    get report_test_plan_url(@plan)
    assert_response :success
  end

  # Filter tests

  test "GET index without filters shows all plans" do
    get test_plans_url
    assert_response :success
    assert_match test_plans(:login_plan).name, response.body
    assert_match test_plans(:empty_plan).name, response.body
    assert_match test_plans(:approved_plan).name, response.body
    assert_match test_plans(:failed_plan).name, response.body
  end

  test "GET index with status aprovado" do
    get test_plans_url, params: { status: "aprovado" }
    assert_response :success
    assert_match test_plans(:approved_plan).name, response.body
    assert_no_match test_plans(:login_plan).name, response.body
    assert_no_match test_plans(:failed_plan).name, response.body
    assert_no_match test_plans(:empty_plan).name, response.body
  end

  test "GET index with status reprovado" do
    get test_plans_url, params: { status: "reprovado" }
    assert_response :success
    assert_match test_plans(:failed_plan).name, response.body
    assert_no_match test_plans(:approved_plan).name, response.body
    assert_no_match test_plans(:login_plan).name, response.body
    assert_no_match test_plans(:empty_plan).name, response.body
  end

  test "GET index with status em_andamento" do
    get test_plans_url, params: { status: "em_andamento" }
    assert_response :success
    assert_match test_plans(:login_plan).name, response.body
    assert_no_match test_plans(:approved_plan).name, response.body
    assert_no_match test_plans(:failed_plan).name, response.body
    assert_no_match test_plans(:empty_plan).name, response.body
  end

  test "GET index with status nao_iniciado" do
    get test_plans_url, params: { status: "nao_iniciado" }
    assert_response :success
    assert_match test_plans(:empty_plan).name, response.body
    assert_no_match test_plans(:login_plan).name, response.body
    assert_no_match test_plans(:approved_plan).name, response.body
    assert_no_match test_plans(:failed_plan).name, response.body
  end

  test "GET index with date_from filter" do
    get test_plans_url, params: { date_from: Time.zone.today.to_s }
    assert_response :success
    assert_match test_plans(:login_plan).name, response.body
  end

  test "GET index with date_until filter" do
    get test_plans_url, params: { date_until: Time.zone.today.to_s }
    assert_response :success
    assert_match test_plans(:login_plan).name, response.body
  end

  test "GET index with combined status and date filters" do
    get test_plans_url, params: { status: "aprovado", date_from: Time.zone.today.to_s }
    assert_response :success
    assert_match test_plans(:approved_plan).name, response.body
    assert_no_match test_plans(:failed_plan).name, response.body
  end

  test "GET index shows empty state with active filters" do
    get test_plans_url, params: { status: "aprovado", date_from: Time.zone.tomorrow.to_s }
    assert_response :success
    assert_match "Nenhum plano encontrado com os filtros aplicados", response.body
  end
end
