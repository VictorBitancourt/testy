require "test_helper"

class AiProvidersClaudeCliTest < ActiveSupport::TestCase
  setup do
    @plan = test_plans(:login_plan)
    @dir = Dir.mktmpdir("fake-claude")
    @env = ENV.to_h.slice("CLAUDE_CLI_PATH", "AI_PROVIDER")
    ENV.delete("AI_PROVIDER")
    Setting.current.update!(ai_provider: "claude_cli")
  end

  teardown do
    FileUtils.rm_rf(@dir)
    %w[CLAUDE_CLI_PATH AI_PROVIDER].each { |k| ENV.delete(k) }
    @env.each { |k, v| ENV[k] = v }
  end

  # A stand-in `claude` that saves its argv and stdin, then prints `reply`.
  def fake_claude(reply, exit_status: 0)
    path = File.join(@dir, "claude")
    File.write(path, <<~SH)
      #!/bin/sh
      for arg in "$@"; do printf '%s\\n' "[$arg]"; done > "#{@dir}/args"
      cat > "#{@dir}/stdin"
      cat <<'JSON'
      #{reply}
      JSON
      exit #{exit_status}
    SH
    File.chmod(0o755, path)
    ENV["CLAUDE_CLI_PATH"] = path
  end

  test "generates scenarios through claude -p without an API key" do
    scenarios = { scenarios: [ { title: "Login ok", given: "Na tela de login", when_step: "Entra", then_step: "Vê o painel" } ] }
    fake_claude({ type: "result", is_error: false, result: "```json\n#{scenarios.to_json}\n```" }.to_json)

    result = AiScenarioGenerator.new(@plan).call("Login com conta corporativa")

    assert result.success?, result.error
    assert_equal "Login ok", result.data.first.title
    args = File.read(File.join(@dir, "args"))
    assert_includes args, "[-p]\n[--output-format]\n[json]\n[--model]\n[sonnet]\n[--tools]\n[]\n"
    assert_includes File.read(File.join(@dir, "stdin")), "Login com conta corporativa"
  end

  test "uses the model from Settings" do
    Setting.current.update!(ai_model: "opus")
    fake_claude({ type: "result", is_error: false, result: '{"scenarios": []}' }.to_json)

    AiScenarioGenerator.new(@plan).call("Login")

    assert_includes File.read(File.join(@dir, "args")), "[--model]\n[opus]\n"
  end

  test "reports a CLI error such as not being signed in" do
    fake_claude({ type: "result", is_error: true, result: "Invalid API key · Please run /login" }.to_json, exit_status: 1)

    result = AiScenarioGenerator.new(@plan).call("Login")

    assert result.failure?
    assert_equal "Claude (CLI local) CLI: Invalid API key · Please run /login", result.error
  end

  test "says when the claude command is missing" do
    ENV["CLAUDE_CLI_PATH"] = File.join(@dir, "nao-existe")

    result = AiScenarioGenerator.new(@plan).call("Login")

    assert result.failure?
    assert_match(/command was not found/, result.error)
  end

  test "finds claude in the installer folder when it is not on PATH" do
    home = File.join(@dir, "home")
    FileUtils.mkdir_p(File.join(home, ".local/bin"))
    claude = File.join(home, ".local/bin/claude")
    File.write(claude, "#!/bin/sh\n")
    File.chmod(0o755, claude)
    saved = ENV.to_h.slice("HOME", "PATH")
    ENV.delete("CLAUDE_CLI_PATH")
    ENV["HOME"] = home
    ENV["PATH"] = File.join(@dir, "empty")

    assert_equal claude, AiProviders::ClaudeCli.executable_path
    assert AiProviders::ClaudeCli.available?
  ensure
    saved&.each { |key, value| ENV[key] = value }
  end

  test "settings page has no API key field for the CLI" do
    assert_not AiProviders::ClaudeCli.needs_api_key?
    assert_equal %w[gemini openai anthropic], AiProviders.with_api_key
  end
end
