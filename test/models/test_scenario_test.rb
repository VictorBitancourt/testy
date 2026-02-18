require "test_helper"

class TestScenarioTest < ActiveSupport::TestCase
  test "validates title presence" do
    scenario = TestScenario.new(test_plan: test_plans(:login_plan), status: "pending")
    assert_not scenario.valid?
    assert_includes scenario.errors[:title], "can't be blank"
  end

  test "validates given presence" do
    scenario = TestScenario.new(test_plan: test_plans(:login_plan), title: "Scenario", given: "", when_step: "When", then_step: "Then")
    assert_not scenario.valid?
    assert_includes scenario.errors[:given], "can't be blank"
  end

  test "validates when_step presence" do
    scenario = TestScenario.new(test_plan: test_plans(:login_plan), title: "Scenario", given: "Given", when_step: "", then_step: "Then")
    assert_not scenario.valid?
    assert_includes scenario.errors[:when_step], "can't be blank"
  end

  test "validates then_step presence" do
    scenario = TestScenario.new(test_plan: test_plans(:login_plan), title: "Scenario", given: "Given", when_step: "When", then_step: "")
    assert_not scenario.valid?
    assert_includes scenario.errors[:then_step], "can't be blank"
  end

  test "validates status inclusion" do
    scenario = TestScenario.new(test_plan: test_plans(:login_plan), title: "Scenario", given: "Given", when_step: "When", then_step: "Then", status: "unknown")
    assert_not scenario.valid?
    assert_includes scenario.errors[:status], "is not included in the list"
  end

  test "default status is pending" do
    scenario = TestScenario.new(test_plan: test_plans(:login_plan), title: "New scenario", given: "Given", when_step: "When", then_step: "Then")
    assert_equal "pending", scenario.status
  end

  test "belongs to test plan" do
    assert_equal test_plans(:login_plan), test_scenarios(:login_success).test_plan
  end

  test "sets default position on create" do
    scenario = test_plans(:login_plan).test_scenarios.create!(title: "New scenario", given: "Given", when_step: "When", then_step: "Then")
    assert_equal 3, scenario.position
  end

  test "has many attached evidence files" do
    scenario = test_scenarios(:login_success)
    scenario.evidence_files.attach(
      io: StringIO.new("fake image data"),
      filename: "screenshot.png",
      content_type: "image/png"
    )

    assert_equal 1, scenario.evidence_files.count
    assert_equal "screenshot.png", scenario.evidence_files.first.filename.to_s
  end

  test "can attach multiple evidence files" do
    scenario = test_scenarios(:login_success)
    2.times do |i|
      scenario.evidence_files.attach(
        io: StringIO.new("fake data #{i}"),
        filename: "file_#{i}.png",
        content_type: "image/png"
      )
    end

    assert_equal 2, scenario.evidence_files.count
  end
end
