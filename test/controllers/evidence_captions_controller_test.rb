require "test_helper"

class EvidenceCaptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
    @scenario = test_scenarios(:login_success)
    @scenario.evidence_files.attach(io: file_fixture("test_evidence.png").open, filename: "tela.png", content_type: "image/png")
    @attachment = @scenario.evidence_files.last
  end

  test "update caption as json" do
    patch evidence_caption_path(@attachment), params: { caption: "  Tela inicial  " }, as: :json

    assert_response :success
    assert_equal "Tela inicial", @attachment.reload.caption
  end

  test "blank caption clears it" do
    @attachment.update!(caption: "Antiga")

    patch evidence_caption_path(@attachment), params: { caption: "" }, as: :json

    assert_nil @attachment.reload.caption
  end

  test "html update redirects to the plan" do
    patch evidence_caption_path(@attachment), params: { caption: "Tela" }

    assert_redirected_to test_plan_path(@scenario.test_plan)
  end

  test "bug evidence caption" do
    bug = bugs(:open_bug)
    bug.evidence_files.attach(io: file_fixture("test_evidence.png").open, filename: "bug.png", content_type: "image/png")

    patch evidence_caption_path(bug.evidence_files.last), params: { caption: "Erro 500" }, as: :json

    assert_equal "Erro 500", bug.evidence_files.last.reload.caption
  end

  test "user who does not own the plan cannot change captions" do
    logout_and_sign_in_as users(:regular_user)

    patch evidence_caption_path(@attachment), params: { caption: "Invasão" }

    assert_redirected_to root_path
    assert_nil @attachment.reload.caption
  end

  test "plan page shows the caption field" do
    get test_plan_path(@scenario.test_plan)

    assert_select "form[action=?] input[name=caption]", evidence_caption_path(@attachment)
  end
end
