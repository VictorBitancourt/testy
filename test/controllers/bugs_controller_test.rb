require "test_helper"

class BugsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "unauthenticated access redirects to login" do
    sign_out

    get bugs_path
    assert_redirected_to new_session_path
  end

  test "index" do
    get bugs_path
    assert_response :success
  end

  test "index filtered by status" do
    get bugs_path, params: { status: "open" }
    assert_response :success
  end

  test "index filtered by feature_tag" do
    get bugs_path, params: { feature_tag: "checkout" }
    assert_response :success
  end

  test "index filtered by cause_tag" do
    get bugs_path, params: { cause_tag: "ui" }
    assert_response :success
  end

  test "index filtered by date range" do
    get bugs_path, params: { date_from: Time.zone.today.to_s, date_until: Time.zone.today.to_s }
    assert_response :success
  end

  test "index with search" do
    get bugs_path, params: { search: "Button" }
    assert_response :success
  end

  test "index json format" do
    get bugs_path(format: :json)
    assert_response :success

    data = JSON.parse(response.body)
    assert_kind_of Array, data
    assert data.first.key?("id")
    assert data.first.key?("display_name")
  end

  test "show" do
    get bug_path(bugs(:open_bug))
    assert_response :success
  end

  test "new" do
    get new_bug_path
    assert_response :success
  end

  test "create" do
    assert_difference -> { Bug.count }, +1 do
      post bugs_path, params: { bug: { title: "New Bug", description: "A new bug", feature_tag: "auth", cause_tag: "backend" } }
    end

    bug = Bug.last
    assert_redirected_to bug_path(bug)
    assert_equal "New Bug", bug.title
    assert_equal users(:admin), bug.user
  end

  test "create with invalid params" do
    assert_no_difference -> { Bug.count } do
      post bugs_path, params: { bug: { title: "", description: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "edit" do
    get edit_bug_path(bugs(:open_bug))
    assert_response :success
  end

  test "update" do
    bug = bugs(:open_bug)
    patch bug_path(bug), params: { bug: { title: "Updated Title" } }

    assert_redirected_to bug_path(bug)
    assert_equal "Updated Title", bug.reload.title
  end

  test "update status to resolved" do
    bug = bugs(:open_bug)
    patch bug_path(bug), params: { bug: { status: "resolved" } }

    assert_redirected_to bug_path(bug)
    assert bug.reload.resolved?
  end

  test "update with invalid params" do
    bug = bugs(:open_bug)

    assert_no_changes -> { bug.reload.title } do
      patch bug_path(bug), params: { bug: { title: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "destroy" do
    assert_difference -> { Bug.count }, -1 do
      delete bug_path(bugs(:open_bug))
    end

    assert_redirected_to bugs_path
  end

  test "tag_suggestions for feature_tag" do
    get bug_tag_suggestions_path, params: { field: "feature_tag", q: "check" }
    assert_response :success

    data = JSON.parse(response.body)
    assert_includes data, "checkout"
  end

  test "tag_suggestions for cause_tag" do
    get bug_tag_suggestions_path, params: { field: "cause_tag", q: "u" }
    assert_response :success

    data = JSON.parse(response.body)
    assert_includes data, "ui"
  end

  test "tag_suggestions rejects invalid field" do
    get bug_tag_suggestions_path, params: { field: "title", q: "test" }
    assert_response :bad_request
  end

  test "report" do
    get bug_report_path(bugs(:open_bug))
    assert_response :success
  end

  test "report pdf" do
    get bug_report_path(bugs(:open_bug), format: :pdf)
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  # Authorization tests

  test "regular user can view bugs" do
    logout_and_sign_in_as users(:regular_user)

    get bugs_path
    assert_response :success
  end

  test "regular user can create bug" do
    logout_and_sign_in_as users(:regular_user)

    assert_difference -> { Bug.count }, +1 do
      post bugs_path, params: { bug: { title: "User Bug", description: "Found it" } }
    end

    assert_equal users(:regular_user), Bug.last.user
  end

  test "regular user cannot edit another user's bug" do
    logout_and_sign_in_as users(:regular_user)

    get edit_bug_path(bugs(:open_bug))
    assert_redirected_to root_path
  end

  test "regular user cannot update another user's bug" do
    logout_and_sign_in_as users(:regular_user)

    bug = bugs(:open_bug)
    patch bug_path(bug), params: { bug: { title: "Hacked" } }

    assert_redirected_to root_path
    assert_not_equal "Hacked", bug.reload.title
  end

  test "regular user cannot destroy another user's bug" do
    logout_and_sign_in_as users(:regular_user)

    assert_no_difference -> { Bug.count } do
      delete bug_path(bugs(:open_bug))
    end

    assert_redirected_to root_path
  end

  test "regular user can edit own bug" do
    logout_and_sign_in_as users(:regular_user)

    get edit_bug_path(bugs(:user_bug))
    assert_response :success
  end

  test "regular user can destroy own bug" do
    logout_and_sign_in_as users(:regular_user)

    assert_difference -> { Bug.count }, -1 do
      delete bug_path(bugs(:user_bug))
    end
  end

  test "admin can edit any bug" do
    get edit_bug_path(bugs(:user_bug))
    assert_response :success
  end

  test "admin can destroy any bug" do
    assert_difference -> { Bug.count }, -1 do
      delete bug_path(bugs(:user_bug))
    end
  end
end
