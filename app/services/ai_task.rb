# One request to the configured AI provider (Settings or env) whose reply is
# JSON. Subclasses build the prompt and turn the parsed reply into their result:
#
#   run(prompt) { |data| ... }  # => Result.success(block value) or Result.failure(message)
class AiTask
  ApiError = AiProviders::ApiError

  # Without an explicit provider, the one in Settings (or env) at call time is used.
  def initialize(provider: nil)
    @fixed_provider = provider
  end

  private

  def run(prompt)
    @provider = @fixed_provider || AiProviders.configured
    if (error = @provider.configuration_error)
      return failure(error)
    end

    data = parse_json(call_api(prompt))
    success(yield(data))
  rescue JSON::ParserError => e
    Rails.logger.error("[AI #{@provider.label}] Parse error: #{e.message}")
    failure("Failed to parse AI response. Please try again.")
  rescue Net::OpenTimeout, Net::ReadTimeout
    failure("AI service timed out. Please try again.")
  rescue ApiError => e
    failure(e.message.start_with?("CLI") ? "#{@provider.label} #{e.message}" : "#{@provider.label} API returned HTTP #{e.message}. Please try again.")
  rescue StandardError => e
    Rails.logger.error("[AI #{@provider.label}] #{e.class}: #{e.message}")
    failure("AI generation failed. Please try again.")
  end

  def success(data)
    Result.success(data)
  end

  def failure(error)
    Result.failure(error)
  end

  # The reply text from the configured provider.
  def call_api(prompt)
    @provider.complete(prompt)
  end

  # The reply may come wrapped in a ```json fence.
  def parse_json(text)
    JSON.parse(text.to_s.gsub(/\A\s*```(?:json)?\s*/, "").gsub(/\s*```\s*\z/, "").strip)
  end
end
