require "application_system_test_case"

class AiTranslateTest < ApplicationSystemTestCase
  setup do
    login_as(users(:admin))
    AiProviders.stubs(:configured).returns(AiProviders::Anthropic.new(api_key: "sk-test", model: "claude-sonnet-5-5"))
  end

  test "translating a bug fills the form for review" do
    AiTranslator.any_instance.stubs(:call_api).returns({ "bug[title]" => "Payment hangs", "bug[description]" => "The page loads forever" }.to_json)
    visit new_bug_path

    fill_in "Title", with: "Pagamento trava"
    fill_in "Description", with: "A tela carrega para sempre"
    click_button "Translate to English"

    assert_text "Translated. Review before saving."
    assert_field "Title", with: "Payment hangs"
    assert_field "Description", with: "The page loads forever"
  end

  test "translating a scenario while editing it inline" do
    scenario = test_scenarios(:login_success)
    scenario.evidence_files.attach(io: file_fixture("test_evidence.png").open, filename: "test_evidence.png", content_type: "image/png")
    evidence = scenario.evidence_files.first
    evidence.update!(caption: "Tela de login")
    AiTranslator.any_instance.stubs(:call_api).returns(
      { "title" => "Successful login", "given" => "G", "when_step" => "W", "then_step" => "T", "evidence_caption_#{evidence.id}" => "Login page" }.to_json)
    visit test_plan_path(test_plans(:login_plan))

    within ".scenario-card[data-scenario-id='#{scenario.id}']" do
      find(".scenario-btn--edit").click
      click_button "Translate to English"
      assert_text "Translated. Review before saving."
      assert_field "title", with: "Successful login"
      assert_field "caption", with: "Login page"
      click_button "Save"
      assert_selector "h3", text: "Successful login"
    end

    assert_equal [ "Successful login", "G", "W", "T" ], scenario.reload.values_at(:title, :given, :when_step, :then_step)
    assert_equal "Login page", evidence.reload.caption
    assert_equal 1, scenario.evidence_files.count
  end

  test "translating the evidence captions of a bug" do
    bug = bugs(:open_bug)
    bug.evidence_files.attach(io: file_fixture("test_evidence.png").open, filename: "test_evidence.png", content_type: "image/png")
    evidence = bug.evidence_files.first
    evidence.update!(caption: "Botão travado")
    AiTranslator.any_instance.stubs(:call_api).returns({ "evidence_caption_#{evidence.id}" => "Stuck button" }.to_json)
    visit bug_path(bug)

    click_button "Translate to English"

    assert_field "caption", with: "Stuck button"
    assert_selector ".evidence-caption--saved"
    assert_equal "Stuck button", evidence.reload.caption
  end
end
