require "test_helper"

class TestPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:admin))
    @plan = test_plans(:login_plan)
  end

  # authentication

  test "unauthenticated access redirects to login" do
    sign_out

    get test_plans_path
    assert_redirected_to new_session_path
  end

  # index

  test "index" do
    get test_plans_path
    assert_response :success
  end

  test "index shows all plans" do
    get test_plans_path

    assert_match test_plans(:login_plan).name, response.body
    assert_match test_plans(:empty_plan).name, response.body
    assert_match test_plans(:approved_plan).name, response.body
    assert_match test_plans(:failed_plan).name, response.body
  end

  test "index filtered by status aprovado" do
    get test_plans_path, params: { status: "aprovado" }
    assert_response :success

    assert_match test_plans(:approved_plan).name, response.body
    assert_no_match test_plans(:login_plan).name, response.body
    assert_no_match test_plans(:failed_plan).name, response.body
    assert_no_match test_plans(:empty_plan).name, response.body
  end

  test "index filtered by status reprovado" do
    get test_plans_path, params: { status: "reprovado" }
    assert_response :success

    assert_match test_plans(:failed_plan).name, response.body
    assert_no_match test_plans(:approved_plan).name, response.body
    assert_no_match test_plans(:login_plan).name, response.body
    assert_no_match test_plans(:empty_plan).name, response.body
  end

  test "index filtered by status em_andamento" do
    get test_plans_path, params: { status: "em_andamento" }
    assert_response :success

    assert_match test_plans(:login_plan).name, response.body
    assert_no_match test_plans(:approved_plan).name, response.body
    assert_no_match test_plans(:failed_plan).name, response.body
    assert_no_match test_plans(:empty_plan).name, response.body
  end

  test "index filtered by status nao_iniciado" do
    get test_plans_path, params: { status: "nao_iniciado" }
    assert_response :success

    assert_match test_plans(:empty_plan).name, response.body
    assert_no_match test_plans(:login_plan).name, response.body
    assert_no_match test_plans(:approved_plan).name, response.body
    assert_no_match test_plans(:failed_plan).name, response.body
  end

  test "index filtered by date_from" do
    get test_plans_path, params: { date_from: Time.zone.today.to_s }
    assert_response :success
    assert_match test_plans(:login_plan).name, response.body
  end

  test "index filtered by date_until" do
    get test_plans_path, params: { date_until: Time.zone.today.to_s }
    assert_response :success
    assert_match test_plans(:login_plan).name, response.body
  end

  test "index filtered by combined status and date" do
    get test_plans_path, params: { status: "aprovado", date_from: Time.zone.today.to_s }
    assert_response :success

    assert_match test_plans(:approved_plan).name, response.body
    assert_no_match test_plans(:failed_plan).name, response.body
  end

  test "index shows empty state when filters match nothing" do
    get test_plans_path, params: { status: "aprovado", date_from: Time.zone.tomorrow.to_s }
    assert_response :success
    assert_match "Nenhum plano encontrado com os filtros aplicados", response.body
  end

  test "index with search filter" do
    get test_plans_path, params: { search: "Login" }
    assert_response :success
    assert_match test_plans(:login_plan).name, response.body
    assert_no_match test_plans(:approved_plan).name, response.body
  end

  test "index with search and status combined" do
    get test_plans_path, params: { search: "Login", status: "em_andamento" }
    assert_response :success
    assert_match test_plans(:login_plan).name, response.body
  end

  test "index search by tag name" do
    get test_plans_path, params: { search: "login" }
    assert_response :success

    assert_match test_plans(:login_plan).name, response.body
    assert_no_match test_plans(:empty_plan).name, response.body
  end

  test "index search by tag name and status combined" do
    get test_plans_path, params: { search: "login", status: "em_andamento" }
    assert_response :success

    assert_match test_plans(:login_plan).name, response.body
  end

  test "index paginates results" do
    20.times do |i|
      TestPlan.create!(name: "Paginated Plan #{i}", qa_name: "QA #{i}", user: users(:admin))
    end

    get test_plans_path
    assert_response :success

    # With 4 fixtures + 20 new = 24 plans, at 15/page, page 1 should have 15
    assert_select "table tbody tr", 15
  end

  # show

  test "show" do
    get test_plan_path(@plan)
    assert_response :success
    assert_match @plan.name, response.body
  end

  # new

  test "new" do
    get new_test_plan_path
    assert_response :success
  end

  # create

  test "create" do
    assert_difference -> { TestPlan.count }, +1 do
      post test_plans_path, params: { test_plan: { name: "Novo Plano", qa_name: "Carlos Lima" } }
    end

    plan = TestPlan.last
    assert_redirected_to test_plan_path(plan)
    assert_equal "Novo Plano", plan.name
    assert_equal "Carlos Lima", plan.qa_name
  end

  test "create assigns current user" do
    post test_plans_path, params: { test_plan: { name: "Meu Plano", qa_name: "QA" } }
    plan = TestPlan.last
    assert_equal users(:admin), plan.user
  end

  test "create with tags" do
    assert_difference -> { TestPlan.count }, +1 do
      post test_plans_path, params: { test_plan: { name: "Tagged Plan", qa_name: "QA", tag_list: "api, frontend" } }
    end

    plan = TestPlan.last
    assert_equal 2, plan.tags.count
    assert_includes plan.tags.pluck(:name), "api"
    assert_includes plan.tags.pluck(:name), "frontend"
  end

  test "update tags" do
    patch test_plan_path(@plan), params: { test_plan: { tag_list: "new-tag, another" } }
    assert_redirected_to test_plan_path(@plan)

    @plan.reload
    assert_equal 2, @plan.tags.count
    assert_includes @plan.tags.pluck(:name), "new-tag"
    assert_includes @plan.tags.pluck(:name), "another"
  end

  test "create with invalid params" do
    assert_no_difference -> { TestPlan.count } do
      post test_plans_path, params: { test_plan: { name: "", qa_name: "" } }
    end

    assert_response :unprocessable_entity
  end

  # edit

  test "edit" do
    get edit_test_plan_path(@plan)
    assert_response :success
  end

  # update

  test "update" do
    patch test_plan_path(@plan), params: { test_plan: { name: "Nome Atualizado" } }
    assert_redirected_to test_plan_path(@plan)
    assert_equal "Nome Atualizado", @plan.reload.name
  end

  test "update with invalid params" do
    assert_no_changes -> { @plan.reload.name } do
      patch test_plan_path(@plan), params: { test_plan: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  # destroy

  test "destroy" do
    assert_difference -> { TestPlan.count }, -1 do
      delete test_plan_path(@plan)
    end

    assert_redirected_to test_plans_path
  end

  test "destroy also removes associated scenarios" do
    scenario_count = @plan.test_scenarios.count
    assert scenario_count > 0

    assert_difference -> { TestScenario.count }, -scenario_count do
      delete test_plan_path(@plan)
    end
  end

  # report

  test "report" do
    get report_test_plan_path(@plan)
    assert_response :success
    assert_match @plan.name, response.body
  end

  test "report pdf" do
    get report_test_plan_path(@plan, format: :pdf)
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF"), "Response body should be a valid PDF (starts with %PDF header)"
  end

  # authorization

  test "regular user can view plans" do
    sign_out
    sign_in_as(users(:regular_user))

    get test_plans_path
    assert_response :success
  end

  test "regular user can create plan" do
    sign_out
    sign_in_as(users(:regular_user))

    assert_difference -> { TestPlan.count }, +1 do
      post test_plans_path, params: { test_plan: { name: "User Plan", qa_name: "QA" } }
    end

    assert_equal users(:regular_user), TestPlan.last.user
  end

  test "regular user cannot edit another users plan" do
    sign_out
    sign_in_as(users(:regular_user))

    get edit_test_plan_path(@plan)
    assert_redirected_to root_path
  end

  test "regular user cannot update another users plan" do
    sign_out
    sign_in_as(users(:regular_user))

    patch test_plan_path(@plan), params: { test_plan: { name: "Hacked" } }
    assert_redirected_to root_path
    assert_not_equal "Hacked", @plan.reload.name
  end

  test "regular user cannot destroy another users plan" do
    sign_out
    sign_in_as(users(:regular_user))

    assert_no_difference -> { TestPlan.count } do
      delete test_plan_path(@plan)
    end

    assert_redirected_to root_path
  end

  test "regular user can edit own plan" do
    sign_out
    user = users(:regular_user)
    sign_in_as(user)

    own_plan = TestPlan.create!(name: "My Plan", qa_name: "QA", user: user)

    get edit_test_plan_path(own_plan)
    assert_response :success
  end

  test "regular user can destroy own plan" do
    sign_out
    user = users(:regular_user)
    sign_in_as(user)

    own_plan = TestPlan.create!(name: "My Plan", qa_name: "QA", user: user)

    assert_difference -> { TestPlan.count }, -1 do
      delete test_plan_path(own_plan)
    end
  end

  test "admin can edit any plan" do
    get edit_test_plan_path(@plan)
    assert_response :success
  end

  test "admin can destroy any plan" do
    assert_difference -> { TestPlan.count }, -1 do
      delete test_plan_path(@plan)
    end
  end
end
