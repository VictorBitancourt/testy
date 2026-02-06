require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "autocomplete" do
    get tags_autocomplete_path, params: { q: "log" }
    assert_response :success

    assert_includes @response.parsed_body, "login"
    assert_not_includes @response.parsed_body, "sprint-23"
  end

  test "autocomplete returns empty array for no match" do
    get tags_autocomplete_path, params: { q: "nonexistent" }
    assert_response :success

    assert_empty @response.parsed_body
  end

  test "autocomplete requires authentication" do
    sign_out

    get tags_autocomplete_path, params: { q: "log" }
    assert_redirected_to new_session_path
  end
end
