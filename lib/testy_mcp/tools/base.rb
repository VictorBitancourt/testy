# frozen_string_literal: true

module TestyMcp
  module Tools
    module Base
      def text_response(text)
        MCP::Tool::Response.new([ { type: "text", text: text } ])
      end

      def error_response(result)
        message = if result.body.is_a?(Hash)
          result.body["error"] || result.body["errors"]&.join(", ") || JSON.generate(result.body)
        else
          "HTTP #{result.status}"
        end
        MCP::Tool::Response.new([ { type: "text", text: "Error (HTTP #{result.status}): #{message}" } ], is_error: true)
      end

      def require_auth!(client)
        return nil if client.authenticated?

        MCP::Tool::Response.new(
          [ { type: "text", text: "Not authenticated. Call testy_login first or set TESTY_API_TOKEN." } ],
          is_error: true
        )
      end
    end
  end
end
