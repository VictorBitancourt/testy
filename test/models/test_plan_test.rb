require "test_helper"

class TestPlanTest < ActiveSupport::TestCase
  test "create" do
    plan = TestPlan.new(name: "Checkout Flow", qa_name: "Ana Costa", user: users(:admin))
    assert plan.valid?
  end

  test "validates name presence" do
    plan = TestPlan.new(qa_name: "Ana Costa", user: users(:admin))
    assert_not plan.valid?
    assert_includes plan.errors[:name], "can't be blank"
  end

  test "validates qa_name presence" do
    plan = TestPlan.new(name: "Checkout Flow", user: users(:admin))
    assert_not plan.valid?
    assert_includes plan.errors[:qa_name], "can't be blank"
  end

  test "dependent destroy removes scenarios" do
    plan = test_plans(:login_plan)
    scenario_count = plan.test_scenarios.count

    assert_difference "TestScenario.count", -scenario_count do
      plan.destroy
    end
  end

  test "dependent destroy removes test_plan_tags" do
    plan = test_plans(:login_plan)
    tag_count = plan.test_plan_tags.count

    assert_difference "TestPlanTag.count", -tag_count do
      plan.destroy
    end
  end

  test "all_scenarios_approved?" do
    assert_not test_plans(:login_plan).all_scenarios_approved?
    assert_not test_plans(:empty_plan).all_scenarios_approved?

    test_plans(:login_plan).test_scenarios.update_all(status: "approved")
    assert test_plans(:login_plan).all_scenarios_approved?
  end

  test "total_scenarios" do
    assert_equal 3, test_plans(:login_plan).total_scenarios
    assert_equal 0, test_plans(:empty_plan).total_scenarios
  end

  test "approved_scenarios" do
    assert_equal 2, test_plans(:login_plan).approved_scenarios
  end

  test "derived_status" do
    assert_equal "not_started", test_plans(:empty_plan).derived_status
    assert_equal "approved", test_plans(:approved_plan).derived_status
    assert_equal "failed", test_plans(:failed_plan).derived_status
    assert_equal "in_progress", test_plans(:login_plan).derived_status
  end

  test "scope not_started" do
    results = TestPlan.not_started
    assert_includes results, test_plans(:empty_plan)
    assert_not_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:approved_plan)
    assert_not_includes results, test_plans(:failed_plan)
  end

  test "scope approved_plans" do
    results = TestPlan.approved_plans
    assert_includes results, test_plans(:approved_plan)
    assert_not_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:failed_plan)
    assert_not_includes results, test_plans(:empty_plan)
  end

  test "scope failed_plans" do
    results = TestPlan.failed_plans
    assert_includes results, test_plans(:failed_plan)
    assert_not_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:approved_plan)
    assert_not_includes results, test_plans(:empty_plan)
  end

  test "scope in_progress" do
    results = TestPlan.in_progress
    assert_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:approved_plan)
    assert_not_includes results, test_plans(:failed_plan)
    assert_not_includes results, test_plans(:empty_plan)
  end

  test "scope created_from" do
    assert_equal TestPlan.count, TestPlan.created_from(Time.zone.today).count
    assert_empty TestPlan.created_from(Time.zone.tomorrow)
  end

  test "scope created_until" do
    assert_equal TestPlan.count, TestPlan.created_until(Time.zone.today).count
    assert_empty TestPlan.created_until(Time.zone.yesterday)
  end

  test "search by name" do
    results = TestPlan.search("Login")
    assert_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:approved_plan)
  end

  test "search by qa_name" do
    results = TestPlan.search("Maria")
    assert_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:approved_plan)
  end

  test "search by tag name" do
    results = TestPlan.search("sprint-23")
    assert_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:empty_plan)
  end

  test "search returns all when empty query" do
    assert_equal TestPlan.count, TestPlan.search("").count
  end

  test "has many tags through test_plan_tags" do
    plan = test_plans(:login_plan)
    assert_includes plan.tags, tags(:login)
    assert_includes plan.tags, tags(:sprint_23)
  end

  test "tag_list" do
    list = test_plans(:login_plan).tag_list
    assert_includes list, "login"
    assert_includes list, "sprint-23"
  end

  test "tag_list= assigns tags from comma-separated string" do
    plan = test_plans(:empty_plan)
    plan.tag_list = "api, frontend, api"
    plan.save!

    assert_equal 2, plan.tags.count
    assert_includes plan.tags.pluck(:name), "api"
    assert_includes plan.tags.pluck(:name), "frontend"
  end

  test "tag_list= strips and downcases" do
    plan = test_plans(:empty_plan)
    plan.tag_list = "  API , Frontend  "
    plan.save!

    assert_includes plan.tags.pluck(:name), "api"
    assert_includes plan.tags.pluck(:name), "frontend"
  end

  test "tag_list= ignores blank entries" do
    plan = test_plans(:empty_plan)
    plan.tag_list = "valid, , ,another"
    plan.save!

    assert_equal 2, plan.tags.count
  end

  test "scope tagged_with" do
    results = TestPlan.tagged_with("login")
    assert_includes results, test_plans(:login_plan)
    assert_not_includes results, test_plans(:empty_plan)
  end

  test "scope tagged_with returns empty when no plans match" do
    assert_empty TestPlan.tagged_with("nonexistent")
  end

  test "generate_scenarios_with_ai returns error for blank prompt" do
    plan = test_plans(:login_plan)
    result = plan.generate_scenarios_with_ai("")

    assert_equal false, result[:success]
    assert_match(/description/, result[:error])
  end

  test "generate_scenarios_with_ai returns error when API key missing" do
    plan = test_plans(:login_plan)
    original_key = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = nil

    result = plan.generate_scenarios_with_ai("Login feature")

    assert_equal false, result[:success]
    assert_match(/GEMINI_API_KEY/, result[:error])
  ensure
    ENV["GEMINI_API_KEY"] = original_key
  end

  test "generate_scenarios_with_ai handles timeout" do
    plan = test_plans(:login_plan)
    original_key = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = "test-key"

    stub_ai_call_api(->(*) { raise Net::ReadTimeout }) do
      result = plan.generate_scenarios_with_ai("Login feature")

      assert_equal false, result[:success]
      assert_match(/timed out/, result[:error])
    end
  ensure
    ENV["GEMINI_API_KEY"] = original_key
  end

  test "generate_scenarios_with_ai handles JSON parse error" do
    plan = test_plans(:login_plan)
    original_key = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = "test-key"

    stub_ai_call_api(->(*) { "not valid json at all" }) do
      result = plan.generate_scenarios_with_ai("Login feature")

      assert_equal false, result[:success]
      assert_match(/parse/, result[:error])
    end
  ensure
    ENV["GEMINI_API_KEY"] = original_key
  end

  test "generate_scenarios_with_ai rolls back on validation failure" do
    plan = test_plans(:login_plan)
    original_key = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = "test-key"

    gemini_response = {
      "candidates" => [ {
        "content" => {
          "parts" => [ {
            "text" => '[{"title":"Test","given":"G","when_step":"W","then_step":"T"},{"title":"","given":"G","when_step":"W","then_step":"T"}]'
          } ]
        }
      } ]
    }.to_json

    stub_ai_call_api(->(*) { gemini_response }) do
      initial_count = plan.test_scenarios.count
      result = plan.generate_scenarios_with_ai("Login feature")

      assert_equal false, result[:success]
      assert_equal initial_count, plan.test_scenarios.reload.count
    end
  ensure
    ENV["GEMINI_API_KEY"] = original_key
  end

  private

  def stub_ai_call_api(fake_call_api)
    original_new = AiScenarioGenerator.method(:new)
    AiScenarioGenerator.define_singleton_method(:new) do |plan|
      generator = original_new.call(plan)
      generator.define_singleton_method(:call_api) { |*args| fake_call_api.call(*args) }
      generator
    end
    yield
  ensure
    AiScenarioGenerator.define_singleton_method(:new, original_new)
  end
end
