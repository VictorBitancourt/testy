module AiProviders
  class Gemini < Base
    @key = "gemini"
    @label = "Gemini"
    @env_prefix = "GEMINI"
    @default_model = "gemini-2.5-flash"
    @default_base_url = "https://generativelanguage.googleapis.com/v1beta"
    @console_url = "https://aistudio.google.com/apikey"

    def complete(prompt)
      body = {
        contents: [ { parts: [ { text: prompt } ] } ],
        generationConfig: { responseMimeType: "application/json" }
      }
      data = post_json("/models/#{model}:generateContent", { "x-goog-api-key" => api_key }, body)
      reply_text!(data.dig("candidates", 0, "content", "parts", 0, "text"))
    end
  end
end
