require "application_system_test_case"

class BugEvidenceTest < ApplicationSystemTestCase
  test "editing a bug keeps its evidence" do
    login_as(users(:admin))
    bug = bugs(:open_bug)
    bug.evidence_files.attach(io: file_fixture("test_evidence.png").open, filename: "test_evidence.png", content_type: "image/png")

    visit edit_bug_path(bug)
    assert_selector "[data-attached-evidence] .evidence-item img", count: 1

    fill_in "Title", with: "Checkout button does nothing"
    click_button "Update Bug"

    assert_text "Checkout button does nothing"
    assert_selector ".evidence-item img", count: 1
    assert_equal 1, bug.reload.evidence_files.count
  end
end
