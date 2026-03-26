# frozen_string_literal: true

module TestyMcp
  module Tools
    class ListTestPlans < MCP::Tool
      tool_name "list_test_plans"
      description "List test plans with optional filters for status, date range, and search."
      annotations(read_only_hint: true, destructive_hint: false)

      input_schema(
        properties: {
          status: { type: "string", enum: %w[approved failed in_progress not_started], description: "Filter by status" },
          date_from: { type: "string", description: "Filter from date (YYYY-MM-DD)" },
          date_until: { type: "string", description: "Filter until date (YYYY-MM-DD)" },
          search: { type: "string", description: "Search by name" },
          page: { type: "integer", description: "Page number for pagination" }
        },
      )

      class << self
        include Base

        def call(status: nil, date_from: nil, date_until: nil, search: nil, page: nil, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          params = { status: status, date_from: date_from, date_until: date_until, search: search, page: page }.compact
          result = client.get("/api/v1/test_plans", params)

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end

    class GetTestPlan < MCP::Tool
      tool_name "get_test_plan"
      description "Get a test plan by ID, including its test scenarios."
      annotations(read_only_hint: true, destructive_hint: false)

      input_schema(
        properties: {
          id: { type: "integer", description: "Test plan ID" }
        },
        required: [ "id" ]
      )

      class << self
        include Base

        def call(id:, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          result = client.get("/api/v1/test_plans/#{id}")

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end

    class CreateTestPlan < MCP::Tool
      tool_name "create_test_plan"
      description "Create a new test plan."
      annotations(read_only_hint: false, destructive_hint: false)

      input_schema(
        properties: {
          name: { type: "string", description: "Test plan name" },
          qa_name: { type: "string", description: "QA responsible name" },
          tag_list: { type: "string", description: "Comma-separated tags" }
        },
        required: [ "name", "qa_name" ]
      )

      class << self
        include Base

        def call(name:, qa_name:, tag_list: nil, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          body = { test_plan: { name: name, qa_name: qa_name, tag_list: tag_list }.compact }
          result = client.post("/api/v1/test_plans", body)

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end

    class UpdateTestPlan < MCP::Tool
      tool_name "update_test_plan"
      description "Update an existing test plan."
      annotations(read_only_hint: false, destructive_hint: false)

      input_schema(
        properties: {
          id: { type: "integer", description: "Test plan ID" },
          name: { type: "string", description: "New name" },
          qa_name: { type: "string", description: "New QA responsible name" },
          tag_list: { type: "string", description: "Comma-separated tags" }
        },
        required: [ "id" ]
      )

      class << self
        include Base

        def call(id:, name: nil, qa_name: nil, tag_list: nil, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          body = { test_plan: { name: name, qa_name: qa_name, tag_list: tag_list }.compact }
          result = client.patch("/api/v1/test_plans/#{id}", body)

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end

    class DeleteTestPlan < MCP::Tool
      tool_name "delete_test_plan"
      description "Delete a test plan and all its scenarios."
      annotations(read_only_hint: false, destructive_hint: true)

      input_schema(
        properties: {
          id: { type: "integer", description: "Test plan ID" }
        },
        required: [ "id" ]
      )

      class << self
        include Base

        def call(id:, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          result = client.delete("/api/v1/test_plans/#{id}")

          return error_response(result) unless result.success?

          text_response("Test plan #{id} deleted.")
        end
      end
    end
  end
end
