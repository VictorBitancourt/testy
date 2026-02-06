require "net/http"

class AiScenarioGenerator
  ApiError = Class.new(StandardError)

  def initialize(test_plan)
    @test_plan = test_plan
  end

  def call(prompt)
    return failure("Please enter a feature description.") if prompt.blank?

    api_key = ENV["GEMINI_API_KEY"]
    return failure("GEMINI_API_KEY is not configured.") if api_key.blank?

    gemini_prompt = build_prompt(prompt)
    response_body = call_api(api_key, gemini_prompt)
    data = parse_response(response_body)
    scenarios = create_scenarios(data)

    success(scenarios)
  rescue JSON::ParserError => e
    Rails.logger.error("[Gemini AI] Parse error: #{e.message}")
    failure("Failed to parse AI response. Please try again.")
  rescue Net::OpenTimeout, Net::ReadTimeout
    failure("AI service timed out. Please try again.")
  rescue ApiError => e
    failure("Gemini API returned HTTP #{e.message}. Please try again.")
  rescue StandardError => e
    Rails.logger.error("[Gemini AI] #{e.class}: #{e.message}")
    failure("AI generation failed. Please try again.")
  end

  private

  def success(data)
    Result.success(data)
  end

  def failure(error)
    Result.failure(error)
  end

  def build_prompt(description)
    <<~PROMPT
      You are a senior QA engineer. Given the feature description below, generate test scenarios using these techniques:
      - Happy path
      - Alternative/negative paths
      - Boundary value analysis
      - Equivalence partitioning
      - Edge cases

      Rules:
      - Return ONLY a JSON array, no extra text
      - Each object must have keys: "title", "given", "when_step", "then_step"
      - Each step must be a single sentence (no AND)
      - Match the language of the input description
      - Generate between 5 and 15 scenarios

      Feature description:
      #{description}
    PROMPT
  end

  def call_api(api_key, prompt)
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent")

    body = {
      contents: [ { parts: [ { text: prompt } ] } ],
      generationConfig: {
        responseMimeType: "application/json"
      }
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
    http.open_timeout = 15
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-goog-api-key"] = api_key
    request.body = body.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("[Gemini AI] API returned #{response.code}: #{response.body}")
      raise ApiError, response.code
    end

    response.body
  end

  def parse_response(body)
    parsed = JSON.parse(body)
    text = parsed.dig("candidates", 0, "content", "parts", 0, "text").to_s

    text = text.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "").strip

    data = JSON.parse(text)
    raise JSON::ParserError, "Expected an array" unless data.is_a?(Array)

    data
  end

  def create_scenarios(data)
    ActiveRecord::Base.transaction do
      data.map do |item|
        @test_plan.test_scenarios.create!(
          title: item["title"].to_s.strip,
          given: item["given"].to_s.strip,
          when_step: item["when_step"].to_s.strip,
          then_step: item["then_step"].to_s.strip
        )
      end
    end
  end
end
