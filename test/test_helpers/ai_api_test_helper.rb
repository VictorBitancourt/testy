module AiApiTestHelper
  def stub_ai_api_with_json(json_response)
    VCR.use_cassette("ai_api/#{caller_locations(1).first.label}", match_requests_on: [ :method, :uri, :body_without_times ]) do
      stub_request(:post, /generativelanguage.googleapis.com/)
        .to_return(
          status: 200,
          body: json_response,
          headers: { "Content-Type" => "application/json" }
        )
      yield
    end
  end

  def stub_ai_api_error(status: 500, body: "Internal Server Error")
    VCR.use_cassette("ai_api_error/#{caller_locations(1).first.label}", match_requests_on: [ :method, :uri, :body_without_times ]) do
      stub_request(:post, /generativelanguage.googleapis.com/)
        .to_return(status: status, body: body)
      yield
    end
  end

  def gemini_response_json(scenarios)
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [
              { "text" => scenarios.to_json }
            ]
          }
        }
      ]
    }.to_json
  end

  def valid_scenarios_json
    gemini_response_json([
      { "title" => "Login bem-sucedido", "given" => "O usuário está na página de login", "when_step" => "O usuário insere credenciais válidas", "then_step" => "O usuário é redirecionado para o dashboard" },
      { "title" => "Senha incorreta", "given" => "O usuário está na página de login", "when_step" => "O usuário insere senha incorreta", "then_step" => "Uma mensagem de erro é exibida" }
    ])
  end

  def invalid_json_response
    gemini_response_json([
      { "title" => "", "given" => "Given", "when_step" => "When", "then_step" => "Then" }
    ])
  end
end
