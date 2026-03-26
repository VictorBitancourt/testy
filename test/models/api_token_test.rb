require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "generates token digest on create" do
    token = users(:admin).api_tokens.create!
    assert_not_nil token.token_digest
    assert_not_nil token.raw_token
    assert_equal ApiToken.digest(token.raw_token), token.token_digest
  end

  test "raw_token is only available after create" do
    token = users(:admin).api_tokens.create!
    raw = token.raw_token
    assert_not_nil raw

    reloaded = ApiToken.find(token.id)
    assert_nil reloaded.raw_token
  end

  test "find_by_raw_token returns correct token" do
    token = api_tokens(:admin_token)
    found = ApiToken.find_by_raw_token(ApiTestHelper::ADMIN_TOKEN)
    assert_equal token, found
  end

  test "find_by_raw_token returns nil for invalid token" do
    assert_nil ApiToken.find_by_raw_token("invalid_token")
  end

  test "find_by_raw_token returns nil for blank token" do
    assert_nil ApiToken.find_by_raw_token("")
    assert_nil ApiToken.find_by_raw_token(nil)
  end

  test "token_digest uniqueness is enforced at database level" do
    existing = api_tokens(:admin_token)
    assert_raises ActiveRecord::RecordNotUnique do
      ApiToken.connection.execute(
        "INSERT INTO api_tokens (user_id, token_digest, created_at, updated_at) VALUES (#{existing.user_id}, '#{existing.token_digest}', datetime('now'), datetime('now'))"
      )
    end
  end

  test "touch_last_used updates timestamp" do
    token = api_tokens(:admin_token)
    assert_nil token.last_used_at

    token.touch_last_used
    token.reload
    assert_not_nil token.last_used_at
  end

  test "destroying user cascades to api_tokens" do
    user = users(:admin)
    assert_difference "ApiToken.count", -user.api_tokens.count do
      user.destroy
    end
  end
end
