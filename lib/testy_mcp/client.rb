# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module TestyMcp
  class Client
    Result = Struct.new(:status, :body) do
      def success? = status.between?(200, 299)
    end

    attr_accessor :token

    def initialize(base_url:, token: nil)
      @base_url = base_url.chomp("/")
      @token = token
    end

    def authenticated?
      !@token.nil? && !@token.empty?
    end

    def get(path, params = {})
      uri = build_uri(path, params)
      request = Net::HTTP::Get.new(uri)
      execute(uri, request)
    end

    def post(path, body = {})
      uri = build_uri(path)
      request = Net::HTTP::Post.new(uri)
      request.body = JSON.generate(body)
      execute(uri, request)
    end

    def patch(path, body = {})
      uri = build_uri(path)
      request = Net::HTTP::Patch.new(uri)
      request.body = JSON.generate(body)
      execute(uri, request)
    end

    def delete(path)
      uri = build_uri(path)
      request = Net::HTTP::Delete.new(uri)
      execute(uri, request)
    end

    private

    def build_uri(path, params = {})
      uri = URI("#{@base_url}#{path}")
      uri.query = URI.encode_www_form(params.compact) unless params.empty?
      uri
    end

    def execute(uri, request)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request["Authorization"] = "Bearer #{@token}" if authenticated?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30

      response = http.request(request)
      body = response.body.nil? || response.body.empty? ? nil : JSON.parse(response.body)

      Result.new(response.code.to_i, body)
    rescue Errno::ECONNREFUSED
      Result.new(0, { "error" => "Connection refused — is the Testy server running at #{@base_url}?" })
    rescue Net::OpenTimeout
      Result.new(0, { "error" => "Connection timed out to #{@base_url}" })
    rescue JSON::ParserError
      Result.new(response.code.to_i, { "error" => "Invalid JSON response" })
    end
  end
end
