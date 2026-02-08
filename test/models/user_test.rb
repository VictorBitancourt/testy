require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with username and password" do
    user = User.new(username: "testuser", password: "password123", password_confirmation: "password123")
    assert user.valid?
  end

  test "normalizes username with strip and downcase" do
    user = User.new(username: "  ADMIN  ")
    assert_equal "admin", user.username
  end

  test "invalid without username" do
    user = User.new(password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "invalid with duplicate username" do
    User.create!(username: "taken", password: "password123")
    user = User.new(username: "taken", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end

  test "invalid with duplicate username case insensitive" do
    User.create!(username: "taken", password: "password123")
    user = User.new(username: "TAKEN", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end

  test "invalid with username too short" do
    user = User.new(username: "ab", password: "password123")
    assert_not user.valid?
    assert user.errors[:username].any? { |e| e.include?("too short") }
  end

  test "invalid with username too long" do
    user = User.new(username: "a" * 51, password: "password123")
    assert_not user.valid?
    assert user.errors[:username].any? { |e| e.include?("too long") }
  end

  test "invalid with username containing special characters" do
    %w[admin@site admin.name admin! admin+1].each do |bad_username|
      user = User.new(username: bad_username, password: "password123")
      assert_not user.valid?, "expected #{bad_username.inspect} to be invalid"
    end
  end

  test "valid with username containing underscores and hyphens" do
    %w[admin_user admin-user test_user-1 a_b].each do |good_username|
      user = User.new(username: good_username, password: "password123", password_confirmation: "password123")
      assert user.valid?, "expected #{good_username.inspect} to be valid"
    end
  end

  test "invalid with password too short" do
    user = User.new(username: "testuser", password: "short")
    assert_not user.valid?
    assert user.errors[:password].any? { |e| e.include?("too short") }
  end

  test "has many sessions" do
    user = users(:admin)
    assert_respond_to user, :sessions
  end

  test "destroying user destroys sessions" do
    user = users(:admin)
    user.sessions.create!

    assert_difference -> { Session.count }, -user.sessions.count do
      user.destroy
    end
  end

  test "validates role inclusion" do
    user = User.new(username: "testuser", password: "password123", role: "superadmin")
    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end

  test "admin? returns true for admin role" do
    user = users(:admin)
    assert user.admin?
  end

  test "admin? returns false for user role" do
    user = users(:regular_user)
    assert_not user.admin?
  end

  test "default role is user" do
    user = User.new(username: "newuser", password: "password123")
    assert_equal "user", user.role
  end

  test "has many test_plans" do
    user = users(:admin)
    assert_respond_to user, :test_plans
    assert user.test_plans.count > 0
  end
end
