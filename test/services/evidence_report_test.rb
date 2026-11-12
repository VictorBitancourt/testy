require "test_helper"

class EvidenceReportTest < ActiveSupport::TestCase
  test "escapes LaTeX specials and typography" do
    assert_equal "100\\% \\& \\_x\\_ \\{y\\} \\$5 \\#1", LatexDocument.escape("100% & _x_ {y} $5 #1")
    assert_equal "``Hub'' -- ok \\ldots{}", LatexDocument.escape("\"Hub\" – ok …")
    assert_equal "a\\newline b\\par c", LatexDocument.escape("a\nb\n\nc")
    assert_equal "Víctor", LatexDocument.escape("Víctor 🚀")
  end

  test "drops the step keyword the template already prints" do
    scenario = test_scenarios(:login_success)
    scenario.update!(given: "Dado que o usuário está logado", when_step: "Quando clica", then_step: "Então vê o painel")
    tex = EvidenceReport.new(scenario.test_plan).to_tex

    assert_includes tex, " {o usuário está logado}\n {clica}\n {vê o painel}"
  end

  test "failed scenario cites its bug" do
    scenario = test_scenarios(:payment_failure)
    scenario.update!(bug: bugs(:open_bug))
    tex = EvidenceReport.new(scenario.test_plan).to_tex

    assert_includes tex, "\\defeito{\\##{bugs(:open_bug).id} - Button not working on checkout page}"
  end
end
