require "application_system_test_case"

class ClipboardPasteTest < ApplicationSystemTestCase
  setup do
    login_as(users(:admin))
  end

  test "pasting an image adds it as scenario evidence" do
    visit test_plan_path(test_plans(:login_plan))

    fill_in "Scenario Title", with: "Pasted evidence scenario"
    fill_in "Given", with: "a screenshot was copied"
    fill_in "When", with: "the user pastes it"
    fill_in "Then", with: "it is attached as evidence"

    paste_image_into(find_field("Given"))
    assert_text "1 file selected"

    paste_image_into(find("body"))
    assert_text "2 files selected"

    click_button "+ Add Scenario"

    assert_text "Pasted evidence scenario"
    scenario = TestScenario.find_by!(title: "Pasted evidence scenario")
    assert_equal 2, scenario.evidence_files.count
    assert scenario.evidence_files.all? { |file| file.filename.to_s.match?(/\Aprint-\d{8}-\d{6}-\d\.png\z/) }
  end

  private

  def login_as(user)
    visit new_session_path
    fill_in "Username", with: user.username
    fill_in "Password", with: "password123"
    click_button "Sign In"
    assert_text "+ New Project"
  end

  # Dispatches a paste event carrying a 1x1 PNG, like a copied screenshot
  def paste_image_into(element)
    execute_script(<<~JS, element)
      const png = Uint8Array.from(atob("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="), c => c.charCodeAt(0))
      const data = new DataTransfer()
      data.items.add(new File([png], "image.png", { type: "image/png" }))
      arguments[0].dispatchEvent(new ClipboardEvent("paste", { clipboardData: data, bubbles: true, cancelable: true }))
    JS
  end
end
