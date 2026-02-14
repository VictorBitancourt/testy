require "test_helper"

class TestPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "unauthenticated access redirects to login" do
    sign_out

    get test_plans_path
    assert_redirected_to new_session_path
  end

  test "index" do
    get test_plans_path
    assert_response :success
  end

  test "index filtered by status approved" do
    get test_plans_path, params: { status: "approved" }
    assert_response :success
  end

  test "index filtered by status failed" do
    get test_plans_path, params: { status: "failed" }
    assert_response :success
  end

  test "index filtered by status in_progress" do
    get test_plans_path, params: { status: "in_progress" }
    assert_response :success
  end

  test "index filtered by status not_started" do
    get test_plans_path, params: { status: "not_started" }
    assert_response :success
  end

  test "index filtered by date range" do
    get test_plans_path, params: { date_from: Time.zone.today.to_s, date_until: Time.zone.today.to_s }
    assert_response :success
  end

  test "index with search filter" do
    get test_plans_path, params: { search: "Login" }
    assert_response :success
  end

  test "index with combined filters" do
    get test_plans_path, params: { search: "Login", status: "in_progress" }
    assert_response :success
  end

  test "index paginates results" do
    20.times { |i| TestPlan.create!(name: "Plan #{i}", qa_name: "QA #{i}", user: users(:admin)) }

    get test_plans_path
    assert_response :success
    assert_select "table tbody tr", 15
  end

  test "show" do
    get test_plan_path(test_plans(:login_plan))
    assert_response :success
  end

  test "new" do
    get new_test_plan_path
    assert_response :success
  end

  test "create" do
    assert_difference -> { TestPlan.count }, +1 do
      post test_plans_path, params: { test_plan: { name: "New Plan", qa_name: "Carlos Lima" } }
    end

    plan = TestPlan.last
    assert_redirected_to test_plan_path(plan)
    assert_equal "New Plan", plan.name
    assert_equal "Carlos Lima", plan.qa_name
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

  test "create with invalid params" do
    assert_no_difference -> { TestPlan.count } do
      post test_plans_path, params: { test_plan: { name: "", qa_name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "edit" do
    get edit_test_plan_path(test_plans(:login_plan))
    assert_response :success
  end

  test "update" do
    plan = test_plans(:login_plan)
    patch test_plan_path(plan), params: { test_plan: { name: "Updated Name" } }

    assert_redirected_to test_plan_path(plan)
    assert_equal "Updated Name", plan.reload.name
  end

  test "update tags" do
    plan = test_plans(:login_plan)
    patch test_plan_path(plan), params: { test_plan: { tag_list: "new-tag, another" } }

    assert_redirected_to test_plan_path(plan)
    assert_equal 2, plan.reload.tags.count
    assert_includes plan.tags.pluck(:name), "new-tag"
  end

  test "update with invalid params" do
    plan = test_plans(:login_plan)

    assert_no_changes -> { plan.reload.name } do
      patch test_plan_path(plan), params: { test_plan: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "destroy" do
    plan = test_plans(:login_plan)
    scenario_count = plan.test_scenarios.count

    assert_difference({ -> { TestPlan.count } => -1, -> { TestScenario.count } => -scenario_count }) do
      delete test_plan_path(plan)
    end

    assert_redirected_to test_plans_path
  end

  test "report" do
    get test_plan_report_path(test_plans(:login_plan))
    assert_response :success
  end

  test "report pdf" do
    get test_plan_report_path(test_plans(:login_plan), format: :pdf)
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "regular user can view plans" do
    logout_and_sign_in_as users(:regular_user)

    get test_plans_path
    assert_response :success
  end

  test "regular user can create plan" do
    logout_and_sign_in_as users(:regular_user)

    assert_difference -> { TestPlan.count }, +1 do
      post test_plans_path, params: { test_plan: { name: "User Plan", qa_name: "QA" } }
    end

    assert_equal users(:regular_user), TestPlan.last.user
  end

  test "regular user cannot edit another user's plan" do
    logout_and_sign_in_as users(:regular_user)

    get edit_test_plan_path(test_plans(:login_plan))
    assert_redirected_to root_path
  end

  test "regular user cannot update another user's plan" do
    logout_and_sign_in_as users(:regular_user)

    plan = test_plans(:login_plan)
    patch test_plan_path(plan), params: { test_plan: { name: "Hacked" } }

    assert_redirected_to root_path
    assert_not_equal "Hacked", plan.reload.name
  end

  test "regular user cannot destroy another user's plan" do
    logout_and_sign_in_as users(:regular_user)

    assert_no_difference -> { TestPlan.count } do
      delete test_plan_path(test_plans(:login_plan))
    end

    assert_redirected_to root_path
  end

  test "regular user can edit own plan" do
    logout_and_sign_in_as users(:regular_user)
    own_plan = TestPlan.create!(name: "My Plan", qa_name: "QA", user: users(:regular_user))

    get edit_test_plan_path(own_plan)
    assert_response :success
  end

  test "regular user can destroy own plan" do
    logout_and_sign_in_as users(:regular_user)
    own_plan = TestPlan.create!(name: "My Plan", qa_name: "QA", user: users(:regular_user))

    assert_difference -> { TestPlan.count }, -1 do
      delete test_plan_path(own_plan)
    end
  end

  test "admin can edit any plan" do
    get edit_test_plan_path(test_plans(:login_plan))
    assert_response :success
  end

  test "admin can destroy any plan" do
    assert_difference -> { TestPlan.count }, -1 do
      delete test_plan_path(test_plans(:login_plan))
    end
  end
end
