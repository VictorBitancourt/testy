# frozen_string_literal: true

module TestyMcp
  module Tools
    class ListBugs < MCP::Tool
      tool_name "list_bugs"
      description "List bugs with optional filters for status, tags, date range, and search."
      annotations(read_only_hint: true, destructive_hint: false)

      input_schema(
        properties: {
          status: { type: "string", enum: %w[open resolved], description: "Filter by status" },
          feature_tag: { type: "string", description: "Filter by feature tag" },
          cause_tag: { type: "string", description: "Filter by cause tag" },
          date_from: { type: "string", description: "Filter from date (YYYY-MM-DD)" },
          date_until: { type: "string", description: "Filter until date (YYYY-MM-DD)" },
          search: { type: "string", description: "Search by title" },
          page: { type: "integer", description: "Page number for pagination" }
        },
      )

      class << self
        include Base

        def call(status: nil, feature_tag: nil, cause_tag: nil, date_from: nil, date_until: nil, search: nil, page: nil, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          params = {
            status: status, feature_tag: feature_tag, cause_tag: cause_tag,
            date_from: date_from, date_until: date_until, search: search, page: page
          }.compact
          result = client.get("/api/v1/bugs", params)

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end

    class GetBug < MCP::Tool
      tool_name "get_bug"
      description "Get a bug by ID with full details."
      annotations(read_only_hint: true, destructive_hint: false)

      input_schema(
        properties: {
          id: { type: "integer", description: "Bug ID" }
        },
        required: ["id"]
      )

      class << self
        include Base

        def call(id:, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          result = client.get("/api/v1/bugs/#{id}")

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end

    class CreateBug < MCP::Tool
      tool_name "create_bug"
      description "Create a new bug report."
      annotations(read_only_hint: false, destructive_hint: false)

      input_schema(
        properties: {
          title: { type: "string", description: "Bug title" },
          description: { type: "string", description: "Bug description" },
          steps_to_reproduce: { type: "string", description: "Steps to reproduce the bug" },
          obtained_result: { type: "string", description: "What actually happened" },
          expected_result: { type: "string", description: "What was expected" },
          feature_tag: { type: "string", description: "Feature tag" },
          cause_tag: { type: "string", description: "Root cause tag" },
          status: { type: "string", enum: %w[open resolved], description: "Bug status (default: open)" }
        },
        required: ["title", "description"]
      )

      class << self
        include Base

        def call(title:, description:, steps_to_reproduce: nil, obtained_result: nil, expected_result: nil, feature_tag: nil, cause_tag: nil, status: nil, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          body = {
            bug: {
              title: title, description: description, steps_to_reproduce: steps_to_reproduce,
              obtained_result: obtained_result, expected_result: expected_result,
              feature_tag: feature_tag, cause_tag: cause_tag, status: status
            }.compact
          }
          result = client.post("/api/v1/bugs", body)

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end

    class UpdateBug < MCP::Tool
      tool_name "update_bug"
      description "Update an existing bug."
      annotations(read_only_hint: false, destructive_hint: false)

      input_schema(
        properties: {
          id: { type: "integer", description: "Bug ID" },
          title: { type: "string", description: "New title" },
          description: { type: "string", description: "New description" },
          steps_to_reproduce: { type: "string", description: "New steps to reproduce" },
          obtained_result: { type: "string", description: "New obtained result" },
          expected_result: { type: "string", description: "New expected result" },
          feature_tag: { type: "string", description: "New feature tag" },
          cause_tag: { type: "string", description: "New cause tag" },
          status: { type: "string", enum: %w[open resolved], description: "New status" }
        },
        required: ["id"]
      )

      class << self
        include Base

        def call(id:, title: nil, description: nil, steps_to_reproduce: nil, obtained_result: nil, expected_result: nil, feature_tag: nil, cause_tag: nil, status: nil, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          body = {
            bug: {
              title: title, description: description, steps_to_reproduce: steps_to_reproduce,
              obtained_result: obtained_result, expected_result: expected_result,
              feature_tag: feature_tag, cause_tag: cause_tag, status: status
            }.compact
          }
          result = client.patch("/api/v1/bugs/#{id}", body)

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end

    class DeleteBug < MCP::Tool
      tool_name "delete_bug"
      description "Delete a bug."
      annotations(read_only_hint: false, destructive_hint: true)

      input_schema(
        properties: {
          id: { type: "integer", description: "Bug ID" }
        },
        required: ["id"]
      )

      class << self
        include Base

        def call(id:, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          result = client.delete("/api/v1/bugs/#{id}")

          return error_response(result) unless result.success?

          text_response("Bug #{id} deleted.")
        end
      end
    end
  end
end
