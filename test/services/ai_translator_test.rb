require "test_helper"

class AiTranslatorTest < ActiveSupport::TestCase
  setup do
    @translator = AiTranslator.new(provider: AiProviders::Anthropic.new(api_key: "sk-test", model: "claude-sonnet-5-5"))
  end

  test "returns the translated fields with the same keys" do
    @translator.stubs(:call_api).returns("```json\n#{{ "bug[title]" => "Payment hangs", "bug[description]" => "Loads forever" }.to_json}\n```")

    result = @translator.call("bug[title]" => "Pagamento trava", "bug[description]" => "Carrega para sempre", "bug[expected_result]" => " ")

    assert result.success?, result.error
    assert_equal({ "bug[title]" => "Payment hangs", "bug[description]" => "Loads forever" }, result.data)
  end

  test "keeps the original text of a field missing from the reply" do
    @translator.stubs(:call_api).returns({ "title" => "Login" }.to_json)

    result = @translator.call("title" => "Entrar", "given" => "Dado que estou logado")

    assert_equal "Dado que estou logado", result.data["given"]
  end

  test "tags come back lowercase" do
    @translator.stubs(:call_api).returns({ "bug[feature_tag]" => "Payments", "bug[cause_tag]" => "Validation" }.to_json)

    result = @translator.call("bug[feature_tag]" => "pagamentos", "bug[cause_tag]" => "validação")

    assert_equal({ "bug[feature_tag]" => "payments", "bug[cause_tag]" => "validation" }, result.data)
  end

  test "prompt carries the fields" do
    prompt = @translator.send(:build_prompt, { "given" => "Dado que estou na home" })

    assert_includes prompt, "English"
    assert_includes prompt, "no Portuguese may be left"
    assert_includes prompt, %("given": "Dado que estou na home")
  end

  test "nothing to translate" do
    assert @translator.call("title" => "  ").failure?
  end

  test "too much text" do
    assert @translator.call("title" => "a" * (AiTranslator::MAX_LENGTH + 1)).failure?
  end

  test "reply that is not an object" do
    @translator.stubs(:call_api).returns("[1]")

    assert_match(/parse/, @translator.call("title" => "x").error)
  end
end
