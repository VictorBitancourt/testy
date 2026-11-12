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

  test "pdflatex comes from PDFLATEX, then PATH, then the MacTeX folder" do
    with_env("PDFLATEX" => "/opt/tex/pdflatex") { assert_equal "/opt/tex/pdflatex", LatexDocument.pdflatex }

    LatexDocument.stubs(:on_path?).with("pdflatex").returns(true)
    with_env("PDFLATEX" => nil) { assert_equal "pdflatex", LatexDocument.pdflatex }

    LatexDocument.stubs(:on_path?).with("pdflatex").returns(false)
    File.stubs(:executable?).with("/Library/TeX/texbin/pdflatex").returns(true)
    with_env("PDFLATEX" => nil) { assert_equal "/Library/TeX/texbin/pdflatex", LatexDocument.pdflatex }
  end

  private
    def with_env(vars)
      saved = vars.keys.index_with { |key| ENV[key] }
      vars.each { |key, value| ENV[key] = value }
      yield
    ensure
      saved.each { |key, value| ENV[key] = value }
    end
end
