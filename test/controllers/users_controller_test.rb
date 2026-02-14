require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
  end

  test "index" do
    get users_path
    assert_response :success
  end

  test "new" do
    get new_user_path
    assert_response :success
  end

  test "create" do
    assert_difference -> { User.count }, +1 do
      post users_path, params: { user: { username: "newuser", password: "password123", password_confirmation: "password123" } }
    end

    assert_redirected_to users_path
    assert_equal "user", User.find_by(username: "newuser").role
  end

  test "create admin user" do
    assert_difference -> { User.count }, +1 do
      post users_path, params: { user: { username: "newadmin", password: "password123", password_confirmation: "password123", role: "admin" } }
    end

    assert_equal "admin", User.find_by(username: "newadmin").role
  end

  test "create with invalid params" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: { username: "", password: "short" } }
    end

    assert_response :unprocessable_entity
  end

  test "edit" do
    get edit_user_path(users(:regular_user))
    assert_response :success
  end

  test "update resets password" do
    user = users(:regular_user)
    patch user_path(user), params: { user: { password: "newpassword123", password_confirmation: "newpassword123" } }

    assert_redirected_to users_path
    assert user.reload.authenticate("newpassword123")
  end

  test "update with invalid params" do
    patch user_path(users(:regular_user)), params: { user: { password: "short", password_confirmation: "short" } }
    assert_response :unprocessable_entity
  end

  test "destroy" do
    assert_difference -> { User.count }, -1 do
      delete user_path(users(:regular_user))
    end

    assert_redirected_to users_path
  end

  test "cannot destroy self" do
    assert_no_difference -> { User.count } do
      delete user_path(users(:admin))
    end

    assert_redirected_to users_path
  end

  test "non-admin cannot access index" do
    logout_and_sign_in_as users(:regular_user)

    get users_path
    assert_redirected_to root_path
  end

  test "non-admin cannot create user" do
    logout_and_sign_in_as users(:regular_user)

    assert_no_difference -> { User.count } do
      post users_path, params: { user: { username: "hacked", password: "password123", password_confirmation: "password123" } }
    end

    assert_redirected_to root_path
  end

  test "non-admin cannot destroy user" do
    logout_and_sign_in_as users(:regular_user)

    assert_no_difference -> { User.count } do
      delete user_path(users(:admin))
    end

    assert_redirected_to root_path
  end
end
