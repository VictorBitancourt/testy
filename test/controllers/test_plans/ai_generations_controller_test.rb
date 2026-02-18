require "test_helper"

class TestPlans::AiGenerationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "unauthenticated access redirects to login" do
    sign_out

    post test_plan_ai_generation_path(test_plans(:login_plan)), params: { prompt: "Login feature" }, as: :json
    assert_redirected_to new_session_path
  end

  test "regular user cannot generate on another user's plan" do
    logout_and_sign_in_as users(:regular_user)

    post test_plan_ai_generation_path(test_plans(:login_plan)), params: { prompt: "Login feature" }, as: :json
    assert_redirected_to root_path
  end

  test "blank prompt returns error" do
    post test_plan_ai_generation_path(test_plans(:login_plan)), params: { prompt: "  " }, as: :json

    assert_response :unprocessable_entity
    assert_equal false, response.parsed_body["success"]
    assert_match(/description/, response.parsed_body["error"])
  end

  test "missing API key returns error" do
    original_key = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = nil

    post test_plan_ai_generation_path(test_plans(:login_plan)), params: { prompt: "Login feature" }, as: :json

    assert_response :unprocessable_entity
    assert_equal false, response.parsed_body["success"]
    assert_match(/GEMINI_API_KEY/, response.parsed_body["error"])
  ensure
    ENV["GEMINI_API_KEY"] = original_key
  end

  test "authorized user can generate scenarios" do
    plan = test_plans(:login_plan)
    scenarios_data = [
      { "title" => "Valid login", "given" => "User is on login page", "when_step" => "User enters valid credentials", "then_step" => "User is redirected to dashboard" },
      { "title" => "Invalid password", "given" => "User is on login page", "when_step" => "User enters wrong password", "then_step" => "Error message is displayed" }
    ]
    fake_result = { success: true, scenarios: scenarios_data }

    stub_generate_scenarios(fake_result) do
      post test_plan_ai_generation_path(plan), params: { prompt: "User login with email and password" }, as: :json
    end

    assert_response :success
    assert_equal true, response.parsed_body["success"]
    assert_equal 2, response.parsed_body["count"]
  end

  test "regular user can generate on own plan" do
    logout_and_sign_in_as users(:regular_user)
    own_plan = TestPlan.create!(name: "My Plan", qa_name: "QA", user: users(:regular_user))
    fake_result = { success: true, scenarios: [ { "title" => "Test" } ] }

    stub_generate_scenarios(fake_result) do
      post test_plan_ai_generation_path(own_plan), params: { prompt: "Some feature" }, as: :json
    end

    assert_response :success
    assert_equal true, response.parsed_body["success"]
  end

  test "AI generation failure returns error" do
    fake_result = { success: false, error: "AI generation failed: timeout" }

    stub_generate_scenarios(fake_result) do
      post test_plan_ai_generation_path(test_plans(:login_plan)), params: { prompt: "Login feature" }, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal false, response.parsed_body["success"]
    assert_match(/failed/, response.parsed_body["error"])
  end

  private

  def stub_generate_scenarios(result)
    original_new = AiScenarioGenerator.method(:new)
    AiScenarioGenerator.define_singleton_method(:new) do |plan|
      fake = Object.new
      fake.define_singleton_method(:call) { |_prompt| result }
      fake
    end
    yield
  ensure
    AiScenarioGenerator.define_singleton_method(:new, original_new)
  end
end
