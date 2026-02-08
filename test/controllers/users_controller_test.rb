require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:admin))
  end

  # index

  test "index lists all users" do
    get users_path
    assert_response :success
    assert_match users(:admin).username, response.body
    assert_match users(:regular_user).username, response.body
  end

  # new

  test "new" do
    get new_user_path
    assert_response :success
  end

  # create

  test "create user" do
    assert_difference -> { User.count }, +1 do
      post users_path, params: { user: { username: "newuser", password: "password123", password_confirmation: "password123" } }
    end

    assert_redirected_to users_path
    new_user = User.find_by(username: "newuser")
    assert_equal "user", new_user.role
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

  # edit

  test "edit" do
    get edit_user_path(users(:regular_user))
    assert_response :success
  end

  # update (reset password)

  test "update resets password" do
    user = users(:regular_user)
    patch user_path(user), params: { user: { password: "newpassword123", password_confirmation: "newpassword123" } }

    assert_redirected_to users_path
    assert user.reload.authenticate("newpassword123")
  end

  test "update with invalid params" do
    user = users(:regular_user)
    patch user_path(user), params: { user: { password: "short", password_confirmation: "short" } }

    assert_response :unprocessable_entity
  end

  # destroy

  test "destroy user" do
    user = users(:regular_user)
    assert_difference -> { User.count }, -1 do
      delete user_path(user)
    end

    assert_redirected_to users_path
  end

  test "cannot destroy self" do
    assert_no_difference -> { User.count } do
      delete user_path(users(:admin))
    end

    assert_redirected_to users_path
    assert_equal "Você não pode deletar a si mesmo.", flash[:alert]
  end

  # non-admin access

  test "non-admin cannot access index" do
    sign_out
    sign_in_as(users(:regular_user))

    get users_path
    assert_redirected_to root_path
  end

  test "non-admin cannot create user" do
    sign_out
    sign_in_as(users(:regular_user))

    assert_no_difference -> { User.count } do
      post users_path, params: { user: { username: "hacked", password: "password123", password_confirmation: "password123" } }
    end

    assert_redirected_to root_path
  end

  test "non-admin cannot destroy user" do
    sign_out
    sign_in_as(users(:regular_user))

    assert_no_difference -> { User.count } do
      delete user_path(users(:admin))
    end

    assert_redirected_to root_path
  end
end
