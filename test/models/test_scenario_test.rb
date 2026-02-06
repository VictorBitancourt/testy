require "test_helper"

class TestScenarioTest < ActiveSupport::TestCase
  test "invalid without title" do
    scenario = TestScenario.new(test_plan: test_plans(:login_plan), status: "pending")
    assert_not scenario.valid?
    assert_includes scenario.errors[:title], "can't be blank"
  end

  test "invalid with bad status" do
    scenario = TestScenario.new(
      test_plan: test_plans(:login_plan),
      title: "Cenario qualquer",
      status: "unknown"
    )
    assert_not scenario.valid?
    assert_includes scenario.errors[:status], "is not included in the list"
  end

  test "valid with pending status" do
    scenario = TestScenario.new(
      test_plan: test_plans(:login_plan),
      title: "Cenario valido",
      status: "pending"
    )
    assert scenario.valid?
  end

  test "valid with approved status" do
    scenario = TestScenario.new(
      test_plan: test_plans(:login_plan),
      title: "Cenario valido",
      status: "approved"
    )
    assert scenario.valid?
  end

  test "valid with failed status" do
    scenario = TestScenario.new(
      test_plan: test_plans(:login_plan),
      title: "Cenario valido",
      status: "failed"
    )
    assert scenario.valid?
  end

  test "default status is pending for new record" do
    scenario = TestScenario.new(test_plan: test_plans(:login_plan), title: "Novo cenario")
    assert_equal "pending", scenario.status
  end

  test "belongs to test plan" do
    scenario = test_scenarios(:login_success)
    assert_equal test_plans(:login_plan), scenario.test_plan
  end
end
