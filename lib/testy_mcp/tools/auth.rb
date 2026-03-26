# frozen_string_literal: true

module TestyMcp
  module Tools
    class Login < MCP::Tool
      tool_name "testy_login"
      description "Authenticate with the Testy API. Returns a session token stored in memory for subsequent requests."

      input_schema(
        properties: {
          username: { type: "string", description: "Testy username" },
          password: { type: "string", description: "Testy password" },
          token_name: { type: "string", description: "Name for the API token (default: mcp-session)" }
        },
        required: [ "username", "password" ]
      )

      class << self
        include Base

        def call(username:, password:, token_name: "mcp-session", server_context:)
          client = server_context[:client]

          result = client.post("/api/v1/auth/login", {
            username: username,
            password: password,
            token_name: token_name
          })

          return error_response(result) unless result.success?

          client.token = result.body["token"]
          user = result.body["user"]
          text_response("Logged in as #{user["username"]} (#{user["role"]})")
        end
      end
    end
  end
end
