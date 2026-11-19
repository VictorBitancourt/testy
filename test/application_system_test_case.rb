require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  def setup
    super
    Capybara.default_max_wait_time = 10
  end

  def login_as(user)
    visit new_session_path
    fill_in "Username", with: user.username
    fill_in "Password", with: "password123"
    click_button "Sign In"
    assert_text "+ New Project"
  end
end
