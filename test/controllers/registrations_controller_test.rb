require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new when no users exist" do
    User.destroy_all

    get new_registration_path
    assert_response :success
  end

  test "new redirects when users already exist" do
    get new_registration_path
    assert_redirected_to root_path
  end

  test "create first user" do
    User.destroy_all

    assert_difference -> { User.count }, +1 do
      post registration_path, params: { user: { username: "newadmin", password: "password123", password_confirmation: "password123" } }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]

    user = User.last
    assert_equal "newadmin", user.username
    assert_equal "admin", user.role
  end

  test "create first user starts a session" do
    User.destroy_all

    assert_difference -> { Session.count }, +1 do
      post registration_path, params: { user: { username: "newadmin", password: "password123", password_confirmation: "password123" } }
    end
  end

  test "create with invalid params" do
    User.destroy_all

    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { username: "", password: "short", password_confirmation: "short" } }
    end

    assert_response :unprocessable_entity
  end

  test "create with mismatched password confirmation" do
    User.destroy_all

    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { username: "admin", password: "password123", password_confirmation: "different" } }
    end

    assert_response :unprocessable_entity
  end

  test "create is blocked when users already exist" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { username: "hacker", password: "password123", password_confirmation: "password123" } }
    end

    assert_redirected_to root_path
  end

  test "unauthenticated users are redirected to registration when no users exist" do
    User.destroy_all

    get test_plans_path
    assert_redirected_to new_registration_path
  end
end
