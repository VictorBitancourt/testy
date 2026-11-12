# Chat APIs that can write test scenarios. Which one is used, and its key and
# model, come from Settings first, then from environment variables, then from
# what is available (see .automatic):
#   AI_PROVIDER=gemini|openai|anthropic|claude_cli
#   GEMINI_API_KEY / OPENAI_API_KEY / ANTHROPIC_API_KEY (claude_cli needs none)
#   GEMINI_MODEL / OPENAI_MODEL / ANTHROPIC_MODEL / CLAUDE_CLI_MODEL (and *_BASE_URL, CLAUDE_CLI_PATH)
module AiProviders
  ApiError = Class.new(StandardError)

  ALL = {
    "gemini" => "AiProviders::Gemini",
    "openai" => "AiProviders::OpenAi",
    "anthropic" => "AiProviders::Anthropic",
    "claude_cli" => "AiProviders::ClaudeCli"
  }.freeze
  DEFAULT = "gemini"

  def self.provider_class(name)
    ALL.fetch(name).constantize
  end

  # Nothing chosen: the first provider with a key, else the local Claude CLI
  # when it is installed, else Gemini (which then asks for its key).
  def self.automatic(setting)
    with_api_key.find { |name| setting.api_key_for(name).present? || ENV["#{provider_class(name).env_prefix}_API_KEY"].present? } ||
      ("claude_cli" if ClaudeCli.available?) ||
      DEFAULT
  end

  def self.with_api_key
    ALL.keys.select { |name| provider_class(name).needs_api_key? }
  end

  def self.configured(setting = Setting.current)
    name = [ setting.ai_provider, ENV["AI_PROVIDER"] ].find { |n| n.present? && ALL.key?(n) } || automatic(setting)
    klass = provider_class(name)
    klass.new(
      api_key: klass.needs_api_key? ? setting.api_key_for(name).presence || ENV[klass.env_prefix + "_API_KEY"].presence : nil,
      model: setting.ai_model.presence || ENV[klass.env_prefix + "_MODEL"].presence || klass.default_model
    )
  end
end
