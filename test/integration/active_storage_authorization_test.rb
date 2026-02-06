require "test_helper"

class ActiveStorageAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @scenario = test_scenarios(:login_success)
    @blob = attach_evidence(@scenario)
  end

  test "plan owner can view blob" do
    sign_in_as users(:admin)

    get rails_blob_path(@blob, disposition: :inline)
    assert_response :redirect
    assert_match %r{rails/active_storage}, response.location
  end

  test "other user cannot view blob" do
    sign_in_as users(:regular_user)

    get rails_blob_path(@blob, disposition: :inline)
    assert_response :forbidden
  end

  test "unauthenticated user is redirected to login" do
    get rails_blob_path(@blob, disposition: :inline)
    assert_response :redirect
    assert_match %r{/session/new}, response.location
  end

  test "admin can view any blob" do
    # Create a plan owned by regular_user
    plan = TestPlan.create!(name: "Other Plan", qa_name: "QA", user: users(:regular_user))
    scenario = plan.test_scenarios.create!(title: "Test", given: "G", when_step: "W", then_step: "T")
    blob = attach_evidence(scenario)

    sign_in_as users(:admin)

    get rails_blob_path(blob, disposition: :inline)
    assert_response :redirect
    assert_match %r{rails/active_storage}, response.location
  end

  private

  def attach_evidence(scenario)
    scenario.evidence_files.attach(
      io: file_fixture("test_evidence.png").open,
      filename: "evidence.png",
      content_type: "image/png"
    )
    scenario.evidence_files.last.blob
  end
end
