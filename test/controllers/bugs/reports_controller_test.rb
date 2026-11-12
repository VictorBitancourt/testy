require "test_helper"

class Bugs::ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
    @bug = bugs(:open_bug)
  end

  test "tex has the bug details, sections and evidence" do
    @bug.evidence_files.attach(io: file_fixture("test_evidence.png").open, filename: "botao.png", content_type: "image/png")
    @bug.evidence_files.last.update!(caption: "Botão sem resposta")

    get bug_report_path(@bug, format: :tex, locale: "pt-BR")

    assert_response :success
    assert_includes response.body, "\\newcommand{\\TFooter}{Relatório de Bug}"
    assert_includes response.body, "\\newcommand{\\BugId}{\\##{@bug.id}}"
    assert_includes response.body, "\\newcommand{\\BugTitulo}{Button not working on checkout page}"
    assert_includes response.body, "\\newcommand{\\StatusBug}{\\Aberto}"
    assert_includes response.body, "\\newcommand{\\Funcionalidade}{checkout}"
    assert_includes response.body, "\\secao{Passos para reproduzir}\n {Click the checkout button}"
    assert_includes response.body, "\\secao{Resultado esperado}\n {Redirects to payment}"
    assert_match(/\\evidencia\{evidencia-\d+\.png\}\{Botão sem resposta\}/, response.body)
  end

  test "tex skips empty sections and lists associated scenarios" do
    bug = bugs(:resolved_bug)
    test_scenarios(:payment_failure).update!(bug: bug)

    get bug_report_path(bug, format: :tex)

    assert_includes response.body, "\\newcommand{\\StatusBug}{\\Resolvido}"
    assert_not_includes response.body, "\\secao{Passos para reproduzir}"
    assert_includes response.body, "\\cenarioassociado{Online Payment}{Payment with invalid card}{\\Reprovado}"
  end

  test "pdf compiles with pdflatex" do
    skip "pdflatex not installed" unless system("command -v pdflatex > /dev/null 2>&1")
    @bug.evidence_files.attach(io: file_fixture("report_evidence.png").open, filename: "tela.png", content_type: "image/png")

    get bug_report_path(@bug, format: :pdf)

    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  end

  test "pdf failure redirects back to the bug" do
    BugReport.any_instance.stubs(:to_pdf).raises(LatexDocument::Error, "pdflatex não encontrado.")

    get bug_report_path(@bug, format: :pdf)

    assert_redirected_to bug_path(@bug)
    assert_equal "pdflatex não encontrado.", flash[:alert]
  end

  test "tex follows the app language" do
    get bug_report_path(@bug, format: :tex, locale: "en")

    assert_includes response.body, "\\newcommand{\\TituloDocumento}{Bug Report}"
    assert_includes response.body, "\\newcommand{\\TReportedBy}{Reported by:}"
    assert_includes response.body, "\\secao{Steps to reproduce}\n {Click the checkout button}"
    assert_not_includes response.body, "\\secao{Passos para reproduzir}"
  end
end
