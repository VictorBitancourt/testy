require "test_helper"

class AiScenarioGeneratorTest < ActiveSupport::TestCase
  setup do
    @plan = test_plans(:login_plan)
    @generator = AiScenarioGenerator.new(@plan)
    ENV["GEMINI_API_KEY"] ||= "test-api-key"
  end

  teardown do
    ENV.delete("GEMINI_API_KEY")
  end

  test "returns error for blank prompt" do
    result = @generator.call("")

    assert result.failure?
    assert_match(/description/i, result.error)
  end

  test "returns error when API key is missing" do
    stub_env("GEMINI_API_KEY", nil) do
      result = @generator.call("Login feature")

      assert result.failure?
      assert_match(/GEMINI_API_KEY/i, result.error)
    end
  end

  test "returns error for blank API key" do
    stub_env("GEMINI_API_KEY", "") do
      result = @generator.call("Login feature")

      assert result.failure?
      assert_match(/GEMINI_API_KEY/i, result.error)
    end
  end

  test "creates scenarios from valid API response" do
    stub_ai_api_with_json(valid_scenarios_json) do
      initial_count = @plan.test_scenarios.count

      result = @generator.call("Login feature")

      assert result.success?
      assert_equal 2, result.data.count
      assert_equal initial_count + 2, @plan.reload.test_scenarios.count
    end
  end

  test "creates scenarios in the correct language" do
    json = gemini_response_json([
      { "title" => "Sucesso no login", "given" => "Usuário na página de login", "when_step" => "Insere credenciais válidas", "then_step" => "Redirecionado para dashboard" }
    ])

    stub_ai_api_with_json(json) do
      result = @generator.call("Funcionalidade de login")

      assert result.success?
      scenario = result.data.first
      assert_equal "Sucesso no login", scenario.title
    end
  end

  test "rolls back on validation failure" do
    stub_ai_api_with_json(invalid_json_response) do
      initial_count = @plan.test_scenarios.count

      result = @generator.call("Login feature")

      assert result.failure?
      assert_equal initial_count, @plan.reload.test_scenarios.count
    end
  end

  test "handles timeout errors" do
    stub_request(:post, /generativelanguage.googleapis.com/)
      .to_timeout

    result = @generator.call("Login feature")

    assert result.failure?
    assert_match(/timed out/i, result.error)
  end

  test "handles API errors" do
    stub_ai_api_error(status: 429, body: "Rate limit exceeded") do
      result = @generator.call("Login feature")

      assert result.failure?
      assert_match(/429/, result.error)
    end
  end

  test "handles JSON parse errors" do
    stub_request(:post, /generativelanguage.googleapis.com/)
      .to_return(status: 200, body: "not valid json at all")

    result = @generator.call("Login feature")

    assert result.failure?
    assert_match(/parse/i, result.error)
  end

  test "handles missing candidates in response" do
    stub_ai_api_with_json({ "candidates" => [] }.to_json) do
      result = @generator.call("Login feature")

      assert result.failure?
    end
  end

  test "strips whitespace from scenario fields" do
    json = gemini_response_json([
      { "title" => "  Login  ", "given" => "  Given  ", "when_step" => "  When  ", "then_step" => "  Then  " }
    ])

    stub_ai_api_with_json(json) do
      result = @generator.call("Login feature")

      assert result.success?
      scenario = result.data.first
      assert_equal "Login", scenario.title
      assert_equal "Given", scenario.given
      assert_equal "When", scenario.when_step
      assert_equal "Then", scenario.then_step
    end
  end

  test "build_prompt includes feature description" do
    prompt = "User authentication"
    generated = @generator.send(:build_prompt, prompt)

    assert_includes generated, prompt
    assert_includes generated, "Happy path"
    assert_includes generated, "JSON"
  end

  private

  def stub_env(key, value)
    original = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = original
  end
end
