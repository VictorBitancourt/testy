# frozen_string_literal: true

module TestyMcp
  module Tools
    class CreateTestScenario < MCP::Tool
      tool_name "create_test_scenario"
      description "Create a new test scenario within a test plan."
      annotations(read_only_hint: false, destructive_hint: false)

      input_schema(
        properties: {
          test_plan_id: { type: "integer", description: "Parent test plan ID" },
          title: { type: "string", description: "Scenario title" },
          given: { type: "string", description: "Given (precondition)" },
          when_step: { type: "string", description: "When (action)" },
          then_step: { type: "string", description: "Then (expected result)" },
          status: { type: "string", description: "Scenario status" },
          bug_id: { type: "integer", description: "Associated bug ID" }
        },
        required: ["test_plan_id", "title", "given", "when_step", "then_step"]
      )

      class << self
        include Base

        def call(test_plan_id:, title:, given:, when_step:, then_step:, status: nil, bug_id: nil, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          body = {
            test_scenario: {
              title: title, given: given, when_step: when_step, then_step: then_step,
              status: status, bug_id: bug_id
            }.compact
          }
          result = client.post("/api/v1/test_plans/#{test_plan_id}/test_scenarios", body)

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end

    class UpdateTestScenario < MCP::Tool
      tool_name "update_test_scenario"
      description "Update an existing test scenario."
      annotations(read_only_hint: false, destructive_hint: false)

      input_schema(
        properties: {
          test_plan_id: { type: "integer", description: "Parent test plan ID" },
          id: { type: "integer", description: "Test scenario ID" },
          title: { type: "string", description: "New title" },
          given: { type: "string", description: "New given (precondition)" },
          when_step: { type: "string", description: "New when (action)" },
          then_step: { type: "string", description: "New then (expected result)" },
          status: { type: "string", description: "New status" },
          bug_id: { type: "integer", description: "Associated bug ID" }
        },
        required: ["test_plan_id", "id"]
      )

      class << self
        include Base

        def call(test_plan_id:, id:, title: nil, given: nil, when_step: nil, then_step: nil, status: nil, bug_id: nil, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          body = {
            test_scenario: {
              title: title, given: given, when_step: when_step, then_step: then_step,
              status: status, bug_id: bug_id
            }.compact
          }
          result = client.patch("/api/v1/test_plans/#{test_plan_id}/test_scenarios/#{id}", body)

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end

    class DeleteTestScenario < MCP::Tool
      tool_name "delete_test_scenario"
      description "Delete a test scenario from a test plan."
      annotations(read_only_hint: false, destructive_hint: true)

      input_schema(
        properties: {
          test_plan_id: { type: "integer", description: "Parent test plan ID" },
          id: { type: "integer", description: "Test scenario ID" }
        },
        required: ["test_plan_id", "id"]
      )

      class << self
        include Base

        def call(test_plan_id:, id:, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          result = client.delete("/api/v1/test_plans/#{test_plan_id}/test_scenarios/#{id}")

          return error_response(result) unless result.success?

          text_response("Test scenario #{id} deleted from plan #{test_plan_id}.")
        end
      end
    end
  end
end
