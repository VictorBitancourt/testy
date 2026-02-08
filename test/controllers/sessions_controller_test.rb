require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
  end

  test "new" do
    get new_session_path
    assert_response :success
    assert_match "Entrar", response.body
  end

  test "create with valid credentials" do
    post session_path, params: { username: @user.username, password: "password123" }
    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with valid credentials starts a new session" do
    assert_difference -> { @user.sessions.count }, +1 do
      post session_path, params: { username: @user.username, password: "password123" }
    end
  end

  test "create with wrong password" do
    post session_path, params: { username: @user.username, password: "wrong" }
    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "create with nonexistent username" do
    post session_path, params: { username: "nobody", password: "password123" }
    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "create with invalid credentials does not create session" do
    assert_no_difference -> { Session.count } do
      post session_path, params: { username: @user.username, password: "wrong" }
    end
  end

  test "create redirects to return url after authentication" do
    get test_plans_path
    assert_redirected_to new_session_path

    post session_path, params: { username: @user.username, password: "password123" }
    assert_redirected_to test_plans_url
  end

  test "destroy" do
    sign_in_as(@user)

    delete session_path
    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "destroy removes the session record" do
    sign_in_as(@user)
    session_count = @user.sessions.count

    assert_difference -> { @user.sessions.count }, -1 do
      delete session_path
    end
  end
end
