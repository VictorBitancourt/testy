require "test_helper"

class TestScenarioTest < ActiveSupport::TestCase
  test "validates title presence" do
    scenario = TestScenario.new(test_plan: test_plans(:login_plan), status: "pending")
    assert_not scenario.valid?
    assert_includes scenario.errors[:title], "can't be blank"
  end

  test "validates status inclusion" do
    scenario = TestScenario.new(test_plan: test_plans(:login_plan), title: "Scenario", status: "unknown")
    assert_not scenario.valid?
    assert_includes scenario.errors[:status], "is not included in the list"
  end

  test "default status is pending" do
    scenario = TestScenario.new(test_plan: test_plans(:login_plan), title: "New scenario")
    assert_equal "pending", scenario.status
  end

  test "belongs to test plan" do
    assert_equal test_plans(:login_plan), test_scenarios(:login_success).test_plan
  end

  test "sets default position on create" do
    scenario = test_plans(:login_plan).test_scenarios.create!(title: "New scenario")
    assert_equal 3, scenario.position
  end
end
