require "test_helper"

class AiTranslationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:regular_user)
  end

  test "returns the translated fields as json" do
    AiTranslator.any_instance.expects(:call).with({ "bug[title]" => "Pagamento trava" }).returns(Result.success({ "bug[title]" => "Payment hangs" }))

    post ai_translation_path, params: { fields: { "bug[title]" => "Pagamento trava" } }, as: :json

    assert_response :success
    assert_equal "Payment hangs", response.parsed_body["fields"]["bug[title]"]
  end

  test "error" do
    post ai_translation_path, params: { fields: {} }, as: :json

    assert_response :unprocessable_entity
    assert_equal "Nothing to translate.", response.parsed_body["error"]
  end

  test "bug form and new scenario form have the translate button" do
    get new_bug_path
    assert_select "[data-controller=ai-translate] button"
    assert_select "[data-translatable]", 5

    sign_in_as users(:admin)
    get test_plan_path(test_plans(:login_plan))
    assert_select "[data-controller=ai-translate] button"
  end
end
