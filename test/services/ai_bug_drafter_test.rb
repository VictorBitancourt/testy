require "test_helper"

class AiBugDrafterTest < ActiveSupport::TestCase
  setup do
    @provider = AiProviders::Anthropic.new(api_key: "sk-test", model: "claude-sonnet-5-5")
  end

  test "returns the form fields from the reply" do
    reply = { title: "Pagamento trava com cartão vencido", description: "D", steps_to_reproduce: "1. A\n2. B",
              obtained_result: "Carrega para sempre", expected_result: "Mensagem de cartão vencido",
              feature_tag: "Pagamentos", cause_tag: "validação" }.to_json
    drafter = AiBugDrafter.new(project: projects(:main), provider: @provider)
    drafter.stubs(:call_api).returns("```json\n#{reply}\n```")

    result = drafter.call("ao pagar com cartão vencido a tela trava")

    assert result.success?, result.error
    assert_equal "Pagamento trava com cartão vencido", result.data["title"]
    assert_equal "1. A\n2. B", result.data["steps_to_reproduce"]
    assert_equal "pagamentos", result.data["feature_tag"]
    assert_equal AiBugDrafter::FIELDS, result.data.keys
  end

  test "prompt lists the known tags so the AI reuses them" do
    drafter = AiBugDrafter.new(project: projects(:main), provider: @provider)
    prompt = drafter.send(:build_prompt, "notas")

    assert_includes prompt, "checkout"
    assert_includes prompt, "validation"
    assert_includes prompt, "notas"
  end

  test "blank text" do
    assert AiBugDrafter.new(project: projects(:main), provider: @provider).call(" ").failure?
  end

  test "reply that is not an object" do
    drafter = AiBugDrafter.new(project: projects(:main), provider: @provider)
    drafter.stubs(:call_api).returns("[1, 2]")

    assert_match(/parse/, drafter.call("x").error)
  end
end
