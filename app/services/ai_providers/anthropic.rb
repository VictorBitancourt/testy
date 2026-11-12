module AiProviders
  # Claude models through the Messages API.
  class Anthropic < Base
    @key = "anthropic"
    @label = "Claude (Anthropic)"
    @env_prefix = "ANTHROPIC"
    @default_model = "claude-sonnet-5-5"
    @default_base_url = "https://api.anthropic.com/v1"
    @console_url = "https://console.anthropic.com/settings/keys"

    API_VERSION = "2023-06-01"
    MAX_TOKENS = 16_000

    def complete(prompt)
      body = {
        model: model,
        max_tokens: MAX_TOKENS,
        messages: [ { role: "user", content: prompt } ]
      }
      headers = { "x-api-key" => api_key, "anthropic-version" => API_VERSION }
      data = post_json("/messages", headers, body)
      text = Array(data["content"]).select { |block| block["type"] == "text" }.map { |block| block["text"] }.join
      reply_text!(text)
    end
  end
end
