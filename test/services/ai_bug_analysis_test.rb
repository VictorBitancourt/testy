require "test_helper"

class AiBugAnalysisTest < ActiveSupport::TestCase
  setup do
    @provider = AiProviders::Anthropic.new(api_key: "sk-test", model: "claude-sonnet-5-5")
  end

  test "builds an unsaved analysis with the cited bugs" do
    bug = bugs(:open_bug)
    reply = {
      summary: "Muitos bugs de checkout.",
      patterns: [ { title: "Botões sem resposta", description: "D", recommendation: "Testar cliques", cause_tag: "ui", feature_tag: "checkout", bug_ids: [ bug.id, "##{bug.id}", 999_999 ] } ],
      recommendations: [ "1. Revisar UI", "" ]
    }.to_json
    analysis = AiBugAnalysis.new(project: projects(:main), locale: :"pt-BR", provider: @provider)
    analysis.stubs(:call_api).returns(reply)

    result = analysis.call

    assert result.success?, result.error
    record = result.data
    assert record.new_record?
    assert_equal "Muitos bugs de checkout.", record.summary
    assert_equal [ bug.id ], record.patterns.first["bug_ids"]
    assert_equal [ bug ], record.pattern_list.first.bugs
    assert_equal [ "Revisar UI" ], record.recommendations
    assert_equal "Claude (Anthropic)", record.ai_provider
    assert_includes record.cause_counts.keys, "ui"
    assert record.save
  end

  test "prompt carries the counts, the bug texts and the language" do
    analysis = AiBugAnalysis.new(project: projects(:main), locale: :"pt-BR", provider: @provider)
    bugs = analysis.send(:sample)
    prompt = analysis.send(:build_prompt, bugs)

    assert_includes prompt, "##{bugs(:open_bug).id} [open] cause=ui feature=checkout Button not working on checkout page"
    assert_includes prompt, "Brazilian Portuguese"
    assert_match(/Most frequent root causes: .*\(\d+\)/, prompt)
  end

  test "no bugs" do
    TestScenario.update_all(bug_id: nil)
    Bug.delete_all

    assert_match(/no bugs/, AiBugAnalysis.new(project: projects(:main), provider: @provider).call.error)
  end
end
