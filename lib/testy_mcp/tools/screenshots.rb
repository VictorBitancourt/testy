# frozen_string_literal: true

require "ferrum"
require "base64"

module TestyMcp
  module Tools
    class AttachScreenshot < MCP::Tool
      tool_name "attach_screenshot"
      description "Attach a screenshot (base64-encoded) as evidence to a test scenario."
      annotations(read_only_hint: false, destructive_hint: false)

      input_schema(
        properties: {
          test_plan_id: { type: "integer", description: "Parent test plan ID" },
          scenario_id: { type: "integer", description: "Test scenario ID" },
          filename: { type: "string", description: "Filename for the screenshot (e.g. 'login-page.png')" },
          data: { type: "string", description: "Base64-encoded image data" },
          content_type: { type: "string", description: "MIME type (default: image/png)", enum: %w[image/png image/jpeg image/gif image/webp application/pdf] }
        },
        required: %w[test_plan_id scenario_id filename data]
      )

      class << self
        include Base

        def call(test_plan_id:, scenario_id:, filename:, data:, content_type: "image/png", server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          body = {
            screenshot: {
              filename: filename,
              data: data,
              content_type: content_type
            }
          }
          result = client.post("/api/v1/test_plans/#{test_plan_id}/test_scenarios/#{scenario_id}/screenshots", body)

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end
      end
    end

    class CaptureScreenshot < MCP::Tool
      tool_name "capture_screenshot"
      description "Navigate to a URL, take a screenshot with a headless browser, and attach it as evidence to a test scenario. Use this instead of browser_screenshot + attach_screenshot."
      annotations(read_only_hint: false, destructive_hint: false)

      input_schema(
        properties: {
          test_plan_id: { type: "integer", description: "Parent test plan ID" },
          scenario_id: { type: "integer", description: "Test scenario ID" },
          url: { type: "string", description: "URL to navigate to and capture" },
          filename: { type: "string", description: "Filename for the screenshot (default: screenshot.png)" }
        },
        required: %w[test_plan_id scenario_id url]
      )

      class << self
        include Base

        def call(test_plan_id:, scenario_id:, url:, filename: nil, server_context:)
          client = server_context[:client]
          auth_error = require_auth!(client)
          return auth_error if auth_error

          filename ||= "screenshot-#{Time.now.strftime('%Y%m%d%H%M%S')}.png"

          browser_path = ENV["CHROME_PATH"] || detect_browser_path
          unless browser_path
            return MCP::Tool::Response.new(
              [{ type: "text", text: "Error: Could not find Chrome or Chromium. Set CHROME_PATH environment variable." }],
              is_error: true
            )
          end

          begin
            browser = Ferrum::Browser.new(
              headless: true,
              browser_path: browser_path,
              window_size: [1280, 720],
              timeout: 15
            )
            browser.goto(url)
            data = browser.screenshot(encoding: :base64)
          rescue => e
            return MCP::Tool::Response.new(
              [{ type: "text", text: "Error capturing screenshot: #{e.message}" }],
              is_error: true
            )
          ensure
            browser&.quit
          end

          body = {
            screenshot: {
              filename: filename,
              data: data,
              content_type: "image/png"
            }
          }
          result = client.post("/api/v1/test_plans/#{test_plan_id}/test_scenarios/#{scenario_id}/screenshots", body)

          return error_response(result) unless result.success?

          text_response(JSON.pretty_generate(result.body))
        end

        private

        def detect_browser_path
          %w[/usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome /usr/bin/google-chrome-stable].find { |p| File.exist?(p) }
        end
      end
    end
  end
end
