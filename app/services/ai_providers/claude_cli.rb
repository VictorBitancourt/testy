require "open3"
require "tmpdir"

module AiProviders
  # Claude through the local Claude Code CLI (`claude -p`), with whatever login
  # the CLI already has (e.g. a company account). No API key: testy must run on
  # the machine where `claude` is installed and signed in.
  class ClaudeCli < Base
    @key = "claude_cli"
    @label = "Claude (CLI local)"
    @env_prefix = "CLAUDE_CLI"
    @default_model = "sonnet"
    @console_url = "https://docs.claude.com/en/docs/claude-code/setup"
    @needs_api_key = false

    def self.executable
      ENV.fetch("CLAUDE_CLI_PATH", "claude")
    end

    def self.executable_path
      return executable if executable.include?("/") && File.executable?(executable)
      ENV["PATH"].to_s.split(File::PATH_SEPARATOR).map { |dir| File.join(dir, executable) }.find { |path| File.executable?(path) }
    end

    def self.available? = executable_path.present?

    def configuration_error
      "The `#{executable}` command was not found. Install Claude Code and sign in, or set CLAUDE_CLI_PATH." unless executable_path
    end

    def complete(prompt)
      output = run_cli(prompt)
      reply = JSON.parse(output)
      if reply["is_error"]
        Rails.logger.error("[AI #{label}] CLI error: #{reply["result"]}")
        raise ApiError, "CLI: #{reply["result"].to_s.truncate(200)}"
      end
      reply_text!(reply["result"])
    end

    private
      def executable = self.class.executable
      def executable_path = self.class.executable_path

      # No tools, no MCP servers, no saved session; run outside any project so
      # no project settings or CLAUDE.md are picked up. User settings still
      # apply, which is where a company login usually lives.
      def command
        [ executable_path || executable, "-p", "--output-format", "json", "--model", model,
          "--tools", "", "--no-session-persistence", "--strict-mcp-config" ]
      end

      def run_cli(prompt)
        Dir.mktmpdir("testy-claude") do |dir|
          Open3.popen3(*command, chdir: dir) do |stdin, stdout, stderr, wait|
            stdin.write(prompt)
            stdin.close
            out = Thread.new { stdout.read }
            err = Thread.new { stderr.read }
            unless wait.join(READ_TIMEOUT)
              Process.kill("TERM", wait.pid)
              [ out, err ].each(&:join)
              raise Net::ReadTimeout, "claude -p took longer than #{READ_TIMEOUT}s"
            end
            output, errors = out.value, err.value
            # On errors such as a missing login the CLI still prints its JSON reply.
            unless wait.value.success? || output.lstrip.start_with?("{")
              Rails.logger.error("[AI #{label}] CLI exited #{wait.value.exitstatus}: #{errors}")
              raise ApiError, "CLI exit #{wait.value.exitstatus}: #{errors.lines.last.to_s.strip.truncate(200)}"
            end
            output
          end
        end
      rescue Errno::ENOENT
        raise ApiError, "CLI: `#{executable}` not found"
      end
  end
end
