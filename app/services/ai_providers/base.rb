require "net/http"

module AiProviders
  # One chat API. Subclasses build the request and pull the reply text out of
  # the response; #complete returns that text.
  class Base
    OPEN_TIMEOUT = 15
    READ_TIMEOUT = 120

    attr_reader :api_key, :model

    @needs_api_key = true

    class << self
      attr_reader :key, :label, :env_prefix, :default_model, :default_base_url, :console_url

      def needs_api_key? = @needs_api_key != false
    end

    def initialize(api_key:, model:)
      @api_key = api_key
      @model = model
    end

    def label = self.class.label
    def env_key = "#{self.class.env_prefix}_API_KEY"

    # Why this provider can't be used yet, or nil when it can.
    def configuration_error
      "#{env_key} is not configured. Add the #{label} API key in Settings." if api_key.blank?
    end

    def complete(prompt)
      raise NotImplementedError
    end

    private
      def base_url
        ENV.fetch("#{self.class.env_prefix}_BASE_URL", self.class.default_base_url)
      end

      def post_json(path, headers, body)
        uri = URI("#{base_url}#{path}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        headers.each { |name, value| request[name] = value }
        request.body = body.to_json

        response = http.request(request)
        unless response.is_a?(Net::HTTPSuccess)
          Rails.logger.error("[AI #{label}] API returned #{response.code}: #{response.body}")
          raise ApiError, response.code
        end

        JSON.parse(response.body)
      end

      def reply_text!(text)
        raise JSON::ParserError, "#{label} reply has no text" if text.blank?
        text
      end
  end
end
