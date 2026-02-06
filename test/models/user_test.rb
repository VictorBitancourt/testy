require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "create" do
    user = User.new(username: "testuser", password: "password123", password_confirmation: "password123")
    assert user.valid?
  end

  test "normalizes username with strip and downcase" do
    assert_equal "admin", User.new(username: "  ADMIN  ").username
  end

  test "validates username presence" do
    user = User.new(password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "validates username uniqueness" do
    User.create!(username: "taken", password: "password123")
    user = User.new(username: "TAKEN", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end

  test "validates username length" do
    assert_not User.new(username: "ab", password: "password123").valid?
    assert_not User.new(username: "a" * 51, password: "password123").valid?
  end

  test "validates username format" do
    %w[admin@site admin.name admin! admin+1].each do |bad|
      assert_not User.new(username: bad, password: "password123").valid?, "expected #{bad.inspect} to be invalid"
    end

    %w[admin_user admin-user test_user-1].each do |good|
      assert User.new(username: good, password: "password123", password_confirmation: "password123").valid?, "expected #{good.inspect} to be valid"
    end
  end

  test "validates password length" do
    user = User.new(username: "testuser", password: "short")
    assert_not user.valid?
  end

  test "validates role inclusion" do
    user = User.new(username: "testuser", password: "password123", role: "superadmin")
    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end

  test "default role is user" do
    assert_equal "user", User.new.role
  end

  test "admin?" do
    assert users(:admin).admin?
    assert_not users(:regular_user).admin?
  end

  test "destroying user destroys sessions" do
    user = users(:admin)
    user.sessions.create!

    assert_difference -> { Session.count }, -user.sessions.count do
      user.destroy
    end
  end

  test "has many test_plans" do
    assert users(:admin).test_plans.count > 0
  end
end
