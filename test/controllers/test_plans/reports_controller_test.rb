require "test_helper"

class TestPlans::ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
    @plan = test_plans(:login_plan)
  end

  test "tex lists every scenario with its status and evidence caption" do
    test_scenarios(:login_success).evidence_files.attach(
      io: file_fixture("test_evidence.png").open, filename: "tela_login.png", content_type: "image/png"
    )
    test_scenarios(:login_success).evidence_files.last.update!(caption: "Tela de login com 100% dos campos")

    get test_plan_report_path(@plan, format: :tex)

    assert_response :success
    assert_includes response.body, "\\newcommand{\\NumeroCenarios}{3}"
    assert_includes response.body, "\\newcommand{\\Historia}{System Login}"
    assert_includes response.body, "\\newcommand{\\StatusEvidencia}{\\Pendente}"
    assert_includes response.body, "\\cenario[\\Aprovado]\n {Login with valid credentials}"
    assert_includes response.body, "\\cenario[\\Pendente]\n {Login with incorrect password}"
    assert_match(/\\evidencia\{evidencia-\d+\.png\}\{Tela de login com 100\\% dos campos\}/, response.body)
    assert_includes response.body, "\\newcommand{\\Logo}{}"
  end

  test "tex falls back to the file name as caption" do
    test_scenarios(:login_success).evidence_files.attach(
      io: file_fixture("test_evidence.png").open, filename: "tela_login.png", content_type: "image/png"
    )

    get test_plan_report_path(@plan, format: :tex)

    assert_match(/\\evidencia\{evidencia-\d+\.png\}\{tela\\_login\.png\}/, response.body)
  end

  test "plan status is approved only when every scenario is" do
    get test_plan_report_path(test_plans(:approved_plan), format: :tex)
    assert_includes response.body, "\\newcommand{\\StatusEvidencia}{\\Aprovado}"

    get test_plan_report_path(test_plans(:failed_plan), format: :tex)
    assert_includes response.body, "\\newcommand{\\StatusEvidencia}{\\Reprovado}"
    assert_includes response.body, "\\cenario[\\Reprovado]\n {Payment with invalid card}"
  end

  test "tex uses the global logo" do
    Setting.current.report_logo.attach(io: file_fixture("test_evidence.png").open, filename: "logo.png", content_type: "image/png")

    get test_plan_report_path(@plan, format: :tex)

    assert_includes response.body, "\\newcommand{\\Logo}{\\includegraphics[width=6cm,height=2.2cm,keepaspectratio]{logo.png}}"
  end

  test "pdf compiles with pdflatex" do
    skip "pdflatex not installed" unless system("command -v pdflatex > /dev/null 2>&1")
    Setting.current.report_logo.attach(io: file_fixture("report_evidence.png").open, filename: "logo.png", content_type: "image/png")
    test_scenarios(:login_success).evidence_files.attach(
      io: file_fixture("report_evidence.png").open, filename: "tela.png", content_type: "image/png"
    )

    get test_plan_report_path(@plan, format: :pdf)

    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  end

  test "pdf failure redirects back to the plan" do
    EvidenceReport.any_instance.stubs(:to_pdf).raises(LatexDocument::Error, "pdflatex não encontrado.")

    get test_plan_report_path(@plan, format: :pdf)

    assert_redirected_to test_plan_path(@plan)
    assert_equal "pdflatex não encontrado.", flash[:alert]
  end

  test "tex follows the app language" do
    scenario = test_scenarios(:login_success)
    scenario.update!(given: "Given the user is on the login page", then_step: "Then the dashboard opens")

    get test_plan_report_path(@plan, format: :tex, locale: "en")
    assert_includes response.body, "\\newcommand{\\TituloDocumento}{Test Execution Evidence}"
    assert_includes response.body, "\\newcommand{\\TGiven}{Given}"
    assert_includes response.body, " {the user is on the login page}"
    assert_includes response.body, " {the dashboard opens}"

    get test_plan_report_path(@plan, format: :tex, locale: "pt-BR")
    assert_includes response.body, "\\newcommand{\\TituloDocumento}{Evidência de Execução de Testes}"
    assert_includes response.body, "\\newcommand{\\TGiven}{Dado que}"
  end
end
