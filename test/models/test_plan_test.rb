require "test_helper"

class TestPlanTest < ActiveSupport::TestCase
  test "valid test plan" do
    plan = TestPlan.new(name: "Checkout Flow", qa_name: "Ana Costa")
    assert plan.valid?
  end

  test "invalid without name" do
    plan = TestPlan.new(qa_name: "Ana Costa")
    assert_not plan.valid?
    assert_includes plan.errors[:name], "can't be blank"
  end

  test "invalid without qa_name" do
    plan = TestPlan.new(name: "Checkout Flow")
    assert_not plan.valid?
    assert_includes plan.errors[:qa_name], "can't be blank"
  end

  test "dependent destroy removes scenarios" do
    plan = test_plans(:login_plan)
    scenario_count = plan.test_scenarios.count
    assert scenario_count > 0

    assert_difference "TestScenario.count", -scenario_count do
      plan.destroy
    end
  end

  test "all_scenarios_approved? returns true when all approved" do
    plan = test_plans(:login_plan)
    plan.test_scenarios.update_all(status: "approved")
    assert plan.all_scenarios_approved?
  end

  test "all_scenarios_approved? returns false when some pending" do
    plan = test_plans(:login_plan)
    assert_not plan.all_scenarios_approved?
  end

  test "all_scenarios_approved? returns false when no scenarios" do
    plan = test_plans(:empty_plan)
    assert_not plan.all_scenarios_approved?
  end

  test "total_scenarios returns correct count" do
    plan = test_plans(:login_plan)
    assert_equal 3, plan.total_scenarios
  end

  test "approved_scenarios returns count of approved" do
    plan = test_plans(:login_plan)
    assert_equal 2, plan.approved_scenarios
  end

  # derived_status tests

  test "derived_status returns nao_iniciado when no scenarios" do
    plan = test_plans(:empty_plan)
    assert_equal "nao_iniciado", plan.derived_status
  end

  test "derived_status returns aprovado when all scenarios approved" do
    plan = test_plans(:approved_plan)
    assert_equal "aprovado", plan.derived_status
  end

  test "derived_status returns reprovado when any scenario failed" do
    plan = test_plans(:failed_plan)
    assert_equal "reprovado", plan.derived_status
  end

  test "derived_status returns em_andamento when mixed statuses without failure" do
    plan = test_plans(:login_plan)
    assert_equal "em_andamento", plan.derived_status
  end

  # scope tests

  test "scope nao_iniciado returns plans without scenarios" do
    results = TestPlan.nao_iniciado
    assert_includes results, test_plans(:empty_plan)
    assert_not_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:approved_plan)
    assert_not_includes results, test_plans(:failed_plan)
  end

  test "scope aprovado returns plans with all scenarios approved" do
    results = TestPlan.aprovado
    assert_includes results, test_plans(:approved_plan)
    assert_not_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:failed_plan)
    assert_not_includes results, test_plans(:empty_plan)
  end

  test "scope reprovado returns plans with at least one failed scenario" do
    results = TestPlan.reprovado
    assert_includes results, test_plans(:failed_plan)
    assert_not_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:approved_plan)
    assert_not_includes results, test_plans(:empty_plan)
  end

  test "scope em_andamento returns plans in progress" do
    results = TestPlan.em_andamento
    assert_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:approved_plan)
    assert_not_includes results, test_plans(:failed_plan)
    assert_not_includes results, test_plans(:empty_plan)
  end

  test "scope created_from filters by start date" do
    results = TestPlan.created_from(Time.zone.today)
    TestPlan.all.each do |plan|
      assert_includes results, plan
    end
  end

  test "scope created_until filters by end date" do
    results = TestPlan.created_until(Time.zone.today)
    TestPlan.all.each do |plan|
      assert_includes results, plan
    end
  end

  test "scope created_from excludes older plans" do
    results = TestPlan.created_from(Time.zone.tomorrow)
    assert_empty results
  end

  test "scope created_until excludes future plans" do
    results = TestPlan.created_until(Time.zone.yesterday)
    assert_empty results
  end
end
