module ApiTestHelper
  ADMIN_TOKEN = "test_admin_token_123"
  USER_TOKEN = "test_user_token_456"

  private

  def api_get(path, params: {}, token: ADMIN_TOKEN)
    get path, params: params, headers: api_headers(token), as: :json
  end

  def api_post(path, params: {}, token: ADMIN_TOKEN)
    post path, params: params, headers: api_headers(token), as: :json
  end

  def api_patch(path, params: {}, token: ADMIN_TOKEN)
    patch path, params: params, headers: api_headers(token), as: :json
  end

  def api_delete(path, token: ADMIN_TOKEN)
    delete path, headers: api_headers(token), as: :json
  end

  def api_headers(token)
    { "Authorization" => "Bearer #{token}" }
  end

  def json_response
    JSON.parse(response.body)
  end
end
