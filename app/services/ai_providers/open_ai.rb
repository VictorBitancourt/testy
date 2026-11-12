module AiProviders
  # ChatGPT models through the Chat Completions API.
  class OpenAi < Base
    @key = "openai"
    @label = "ChatGPT (OpenAI)"
    @env_prefix = "OPENAI"
    @default_model = "gpt-5-mini"
    @default_base_url = "https://api.openai.com/v1"
    @console_url = "https://platform.openai.com/api-keys"

    def complete(prompt)
      body = {
        model: model,
        messages: [ { role: "user", content: prompt } ],
        response_format: { type: "json_object" }
      }
      data = post_json("/chat/completions", { "Authorization" => "Bearer #{api_key}" }, body)
      reply_text!(data.dig("choices", 0, "message", "content"))
    end
  end
end
