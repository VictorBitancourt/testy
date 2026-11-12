require "test_helper"

class AiProvidersTest < ActiveSupport::TestCase
  SCENARIOS = [ { "title" => "Login ok", "given" => "Na tela de login", "when_step" => "Entra com dados válidos", "then_step" => "Vê o painel" } ].freeze

  setup do
    @plan = test_plans(:login_plan)
    @env = ENV.to_h.slice("AI_PROVIDER", "GEMINI_API_KEY", "OPENAI_API_KEY", "ANTHROPIC_API_KEY")
    %w[AI_PROVIDER GEMINI_API_KEY OPENAI_API_KEY ANTHROPIC_API_KEY].each { |k| ENV.delete(k) }
  end

  teardown do
    %w[AI_PROVIDER GEMINI_API_KEY OPENAI_API_KEY ANTHROPIC_API_KEY].each { |k| ENV.delete(k) }
    @env.each { |k, v| ENV[k] = v }
  end

  test "defaults to Gemini when nothing is available" do
    assert_instance_of AiProviders::Gemini, AiProviders.configured
  end

  test "without a choice, uses the provider that has a key" do
    Setting.current.update!(openai_api_key: "sk-openai")

    assert_instance_of AiProviders::OpenAi, AiProviders.configured
  end

  test "without a choice or keys, uses the local Claude CLI when installed" do
    Dir.mktmpdir do |dir|
      cli = File.join(dir, "claude")
      File.write(cli, "#!/bin/sh\n")
      File.chmod(0o755, cli)
      ENV["CLAUDE_CLI_PATH"] = cli

      assert_instance_of AiProviders::ClaudeCli, AiProviders.configured
    ensure
      ENV["CLAUDE_CLI_PATH"] = "/nonexistent/claude"
    end
  end

  test "settings choose the provider, key and model" do
    Setting.current.update!(ai_provider: "anthropic", anthropic_api_key: "sk-ant-x", ai_model: "claude-opus-5-5")
    provider = AiProviders.configured

    assert_instance_of AiProviders::Anthropic, provider
    assert_equal "sk-ant-x", provider.api_key
    assert_equal "claude-opus-5-5", provider.model
  end

  test "environment is the fallback" do
    ENV["AI_PROVIDER"] = "openai"
    ENV["OPENAI_API_KEY"] = "sk-env"
    provider = AiProviders.configured

    assert_instance_of AiProviders::OpenAi, provider
    assert_equal "sk-env", provider.api_key
    assert_equal "gpt-5-mini", provider.model
  end

  test "api keys are encrypted at rest" do
    Setting.current.update!(openai_api_key: "sk-secret")

    raw = Setting.connection.select_value("SELECT openai_api_key FROM settings")
    assert_not_includes raw, "sk-secret"
    assert_equal "sk-secret", Setting.current.openai_api_key
  end

  test "switching provider resets the model to the new default" do
    setting = Setting.current
    setting.update!(ai_provider: "openai", ai_model: "gpt-5")
    setting.update!(ai_provider: "anthropic")

    assert_nil setting.reload.ai_model
  end

  test "generates scenarios with ChatGPT" do
    Setting.current.update!(ai_provider: "openai", openai_api_key: "sk-openai")
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .with(headers: { "Authorization" => "Bearer sk-openai" }, body: hash_including("model" => "gpt-5-mini", "response_format" => { "type" => "json_object" }))
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { choices: [ { message: { content: { scenarios: SCENARIOS }.to_json } } ] }.to_json)

    result = AiScenarioGenerator.new(@plan).call("Login")

    assert result.success?, result.error
    assert_equal "Login ok", result.data.first.title
  end

  test "generates scenarios with Claude" do
    Setting.current.update!(ai_provider: "anthropic", anthropic_api_key: "sk-ant")
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .with(headers: { "x-api-key" => "sk-ant", "anthropic-version" => "2023-06-01" }, body: hash_including("model" => "claude-sonnet-5-5"))
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { content: [ { type: "text", text: "```json\n#{{ scenarios: SCENARIOS }.to_json}\n```" } ] }.to_json)

    result = AiScenarioGenerator.new(@plan).call("Login")

    assert result.success?, result.error
    assert_equal "Vê o painel", result.data.first.then_step
  end

  test "names the missing key of the chosen provider" do
    Setting.current.update!(ai_provider: "anthropic")

    result = AiScenarioGenerator.new(@plan).call("Login")

    assert result.failure?
    assert_match(/ANTHROPIC_API_KEY/, result.error)
  end

  test "reports the provider on HTTP errors" do
    Setting.current.update!(ai_provider: "openai", openai_api_key: "sk-openai")
    stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return(status: 401, body: "bad key")

    result = AiScenarioGenerator.new(@plan).call("Login")

    assert_equal "ChatGPT (OpenAI) API returned HTTP 401. Please try again.", result.error
  end
end
