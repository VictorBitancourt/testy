require "test_helper"

class Bugs::AiControllersTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:regular_user)
  end

  test "draft returns the fields as json" do
    AiBugDrafter.any_instance.stubs(:call).returns(Result.success({ "title" => "T" }))

    post bug_ai_draft_path, params: { text: "notas" }, as: :json

    assert_response :success
    assert_equal "T", response.parsed_body["bug"]["title"]
  end

  test "draft error" do
    AiBugDrafter.any_instance.stubs(:call).returns(Result.failure("ANTHROPIC_API_KEY is not configured."))

    post bug_ai_draft_path, params: { text: "notas" }, as: :json

    assert_response :unprocessable_entity
    assert_equal "ANTHROPIC_API_KEY is not configured.", response.parsed_body["error"]
  end

  test "new bug page shows the AI panel" do
    get new_bug_path

    assert_select "[data-controller=bug-ai]"
  end

  test "analysis is saved and rendered into the page" do
    analysis = BugAnalysis.new(project: projects(:main), summary: "Resumo X", recommendations: [ "Ação Y" ], bug_count: 3, total_bugs: 3,
      cause_counts: { "ui" => 2 }, feature_counts: {}, ai_provider: "Claude (CLI local)", ai_model: "sonnet",
      patterns: [ { "title" => "Padrão Z", "description" => "D", "recommendation" => "R", "cause_tag" => "ui", "feature_tag" => nil, "bug_ids" => [ bugs(:open_bug).id ] } ])
    AiBugAnalysis.any_instance.stubs(:call).returns(Result.success(analysis))

    assert_difference -> { BugAnalysis.count }, +1 do
      post bug_ai_analysis_path, as: :turbo_stream
    end

    assert_response :success
    assert_equal users(:regular_user), BugAnalysis.last.user
    assert_includes response.body, %(target="ai-analysis")
    assert_includes response.body, "Padrão Z"
    assert_includes response.body, "Ação Y"
    assert_includes response.body, bug_path(bugs(:open_bug))
    assert_includes response.body, bug_ai_analysis_report_path(BugAnalysis.last, format: :pdf)
  end

  test "analysis error is shown in place" do
    AiBugAnalysis.any_instance.stubs(:call).returns(Result.failure("AI service timed out. Please try again."))

    post bug_ai_analysis_path, as: :turbo_stream

    assert_includes response.body, "AI service timed out"
  end

  test "root causes page has the analyze button" do
    get bug_root_causes_path

    assert_select "form[action=?]", bug_ai_analysis_path
  end

  test "root causes page shows the latest analysis" do
    saved_analysis(summary: "Antiga")
    saved_analysis(summary: "A mais recente")

    get bug_root_causes_path

    assert_includes response.body, "A mais recente"
    assert_not_includes response.body, "Antiga"
  end

  test "analysis tex" do
    analysis = saved_analysis(summary: "Resumo 100% real")

    get bug_ai_analysis_report_path(analysis, format: :tex, locale: "pt-BR")

    assert_response :success
    assert_includes response.body, "\\secao{Resumo}\n {Resumo 100\\% real}"
    assert_includes response.body, "\\barra{ui}{2}{8.0cm}"
    assert_includes response.body, "\\padrao{1}\n {Padrão Z}"
    assert_includes response.body, "\\##{bugs(:open_bug).id} Button not working on checkout page"
    assert_includes response.body, "\\newcommand{\\TituloDocumento}{Análise de Bugs Recorrentes}"
    assert_includes response.body, "{Causa: ui}"
  end

  test "analysis tex in English" do
    get bug_ai_analysis_report_path(saved_analysis, format: :tex, locale: "en")

    assert_includes response.body, "\\newcommand{\\TituloDocumento}{Recurring Bug Analysis}"
    assert_includes response.body, "\\secao{Most frequent causes}"
    assert_includes response.body, "{Cause: ui}"
  end

  test "analysis pdf compiles with pdflatex" do
    skip "pdflatex not installed" unless system("command -v pdflatex > /dev/null 2>&1")

    get bug_ai_analysis_report_path(saved_analysis, format: :pdf)

    assert_response :success
    assert response.body.start_with?("%PDF")
  end

  private
    def saved_analysis(summary: "Resumo")
      BugAnalysis.create!(project: projects(:main), summary: summary, recommendations: [ "Ação" ], bug_count: 3, total_bugs: 3,
        cause_counts: { "ui" => 2, "validation" => 1 }, feature_counts: { "checkout" => 1 }, user: users(:admin),
        ai_provider: "Claude (CLI local)", ai_model: "sonnet",
        patterns: [ { "title" => "Padrão Z", "description" => "D", "recommendation" => "R", "cause_tag" => "ui", "feature_tag" => nil, "bug_ids" => [ bugs(:open_bug).id ] } ])
    end
end
