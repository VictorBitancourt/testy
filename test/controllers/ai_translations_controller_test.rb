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

  test "ignores fields that are not translatable" do
    AiTranslator.any_instance.expects(:call).with({ "given" => "Dado" }).returns(Result.success({ "given" => "Given" }))

    post ai_translation_path, params: { fields: { "given" => "Dado", "bug[status]" => "aberto" } }, as: :json

    assert_response :success
  end

  test "accepts evidence captions" do
    AiTranslator.any_instance.expects(:call).with({ "title" => "Entrar", "evidence_caption_12" => "Tela de login" }).returns(Result.success({}))

    post ai_translation_path, params: { fields: { "title" => "Entrar", "evidence_caption_12" => "Tela de login", "evidence_caption_x" => "y" } }, as: :json

    assert_response :success
  end

  test "error" do
    post ai_translation_path, params: { fields: {} }, as: :json

    assert_response :unprocessable_entity
    assert_equal "Nothing to translate.", response.parsed_body["error"]
  end

  test "bug form and new scenario form have the translate button" do
    get new_bug_path
    assert_select "[data-controller=ai-translate] button"
    assert_select "[data-translatable]", 7

    sign_in_as users(:admin)
    get test_plan_path(test_plans(:login_plan))
    assert_select "[data-controller=ai-translate] button"
  end
end
