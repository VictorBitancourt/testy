require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:admin))
  end

  test "autocomplete returns matching tags as JSON" do
    get tags_autocomplete_path, params: { q: "log" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_includes json, "login"
    assert_not_includes json, "sprint-23"
  end

  test "autocomplete returns empty array for no match" do
    get tags_autocomplete_path, params: { q: "nonexistent" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_empty json
  end

  test "autocomplete requires authentication" do
    sign_out

    get tags_autocomplete_path, params: { q: "log" }
    assert_redirected_to new_session_path
  end
end
