require "application_system_test_case"

class SmokeTest < ApplicationSystemTestCase
  setup do
    @user = users(:admin)
  end

  test "user can log in and view test plans" do
    visit new_session_path
    fill_in "Username", with: @user.username
    fill_in "Password", with: "password123"
    click_button "Sign In"

    assert_text "+ New Plan"
  end

  test "user can create a new test plan" do
    login_as(@user)

    visit new_test_plan_path
    fill_in "Test Plan Name", with: "Smoke test plan"
    fill_in "Responsible QA", with: "John Doe"
    click_button "Create Plan"

    assert_text "Test plan created successfully!"
  end

  test "user can view test plan details" do
    login_as(@user)

    visit test_plan_path(test_plans(:login_plan))
    assert_text test_plans(:login_plan).name
    assert_text test_plans(:login_plan).qa_name
  end

  test "user can add scenario to test plan" do
    login_as(@user)

    visit test_plan_path(test_plans(:login_plan))

    fill_in "Scenario Title", with: "Smoke test scenario"
    fill_in "Given", with: "User is on the login page"
    fill_in "When", with: "User enters valid credentials"
    fill_in "Then", with: "User is redirected to dashboard"
    click_button "+ Add Scenario"

    assert_text "Smoke test scenario"
  end

  test "user can filter test plans by status" do
    login_as(@user)

    visit test_plans_path
    click_button "Approved"

    assert_current_path(/status=approved/)
  end

  test "user can search test plans" do
    login_as(@user)

    visit test_plans_path
    fill_in "search", with: "Login"
    click_button "Search"

    assert_text "Login"
  end

  test "user can logout" do
    login_as(@user)

    visit test_plans_path
    open_nav_dropdown
    click_button "Sign Out"

    assert_current_path new_session_path
  end

  private

  def login_as(user)
    visit new_session_path
    fill_in "Username", with: user.username
    fill_in "Password", with: "password123"
    click_button "Sign In"
    assert_text "+ New Plan"
  end

  def open_nav_dropdown
    find("[data-action='click->dropdown#toggle']").click
  end
end
