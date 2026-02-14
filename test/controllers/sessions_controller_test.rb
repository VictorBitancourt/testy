require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create" do
    assert_difference -> { Session.count }, +1 do
      post session_path, params: { username: users(:admin).username, password: "password123" }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with wrong password" do
    assert_no_difference -> { Session.count } do
      post session_path, params: { username: users(:admin).username, password: "wrong" }
    end

    assert_redirected_to new_session_path
  end

  test "create with nonexistent username" do
    post session_path, params: { username: "nobody", password: "password123" }
    assert_redirected_to new_session_path
  end

  test "create redirects to return url after authentication" do
    get test_plans_path
    assert_redirected_to new_session_path

    post session_path, params: { username: users(:admin).username, password: "password123" }
    assert_redirected_to test_plans_url
  end

  test "destroy" do
    sign_in_as users(:admin)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "destroy removes the session record" do
    sign_in_as users(:admin)

    assert_difference -> { Session.count }, -1 do
      delete session_path
    end
  end
end
