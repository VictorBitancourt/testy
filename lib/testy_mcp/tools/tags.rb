# frozen_string_literal: true

module TestyMcp
  module Tools
    class ListTags < MCP::Tool
      tool_name "list_tags"
      description "List available tags, optionally filtered by a search query."
      annotations(read_only_hint: true, destructive_hint: false)

      input_schema(
        properties: {
          q: { type: "string", description: "Search query to filter tags" },
          limit: { type: "integer", description: "Maximum number of tags to return (1-100, default: 50)" }
        },
      )

      class << self
        include Base

        def call(q: nil, limit: nil, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          params = { q: q, limit: limit }.compact
          result = client.get("/api/v1/tags", params)

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end
  end
end
