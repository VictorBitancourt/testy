package commands

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/config"
)

// NewQACmd creates the qa parent command with generate/execute/full subcommands.
func NewQACmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "qa",
		Short: "AI-powered QA automation with Claude + Playwright",
		Long:  "Launch Claude Code with specialized QA prompts to generate test plans, execute tests, or run a full cycle.",
	}

	cmd.AddCommand(newQAGenerateCmd())
	cmd.AddCommand(newQAExecuteCmd())
	cmd.AddCommand(newQAFullCmd())

	return cmd
}

func newQAGenerateCmd() *cobra.Command {
	var url, name, user, pass, context, depth, tags, qa, model string

	cmd := &cobra.Command{
		Use:   "generate",
		Short: "Explore an app and generate a test plan",
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return err
			}
			if err := requireClaude(); err != nil {
				return err
			}

			if depth != "quick" && depth != "normal" && depth != "deep" {
				return fmt.Errorf("invalid --depth %q: must be quick, normal, or deep", depth)
			}

			mcpPath, err := findMCPConfig()
			if err != nil {
				return err
			}

			ensureTokenEnv()

			system := buildQASystemPrompt()
			task := buildGeneratePrompt(url, name, user, pass, context, depth, tags, qa)

			return runClaude(task, system, mcpPath, model)
		},
	}

	cmd.Flags().StringVar(&url, "url", "", "URL of the application to test (required)")
	cmd.Flags().StringVar(&name, "name", "", "Name for the test plan (required)")
	cmd.Flags().StringVar(&user, "user", "", "Username for login on the target app")
	cmd.Flags().StringVar(&pass, "pass", "", "Password for login on the target app")
	cmd.Flags().StringVar(&context, "context", "", "Free text: business rules, constraints, notes")
	cmd.Flags().StringVar(&depth, "depth", "normal", "Test depth: quick (5-8), normal (8-15), deep (15-25 scenarios)")
	cmd.Flags().StringVar(&tags, "tags", "", "Comma-separated tags for the test plan")
	cmd.Flags().StringVar(&qa, "qa", "", "Name of the QA responsible")
	cmd.Flags().StringVar(&model, "model", "sonnet", "Claude model to use")

	_ = cmd.MarkFlagRequired("url")
	_ = cmd.MarkFlagRequired("name")

	return cmd
}

func newQAExecuteCmd() *cobra.Command {
	var plan, url, user, pass, context, model string

	cmd := &cobra.Command{
		Use:   "execute",
		Short: "Execute an existing test plan",
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return err
			}
			if err := requireClaude(); err != nil {
				return err
			}

			mcpPath, err := findMCPConfig()
			if err != nil {
				return err
			}

			ensureTokenEnv()

			system := buildQASystemPrompt()
			task := buildExecutePrompt(plan, url, user, pass, context)

			return runClaude(task, system, mcpPath, model)
		},
	}

	cmd.Flags().StringVar(&plan, "plan", "", "ID of the test plan to execute (required)")
	cmd.Flags().StringVar(&url, "url", "", "URL of the application to test (required)")
	cmd.Flags().StringVar(&user, "user", "", "Username for login on the target app")
	cmd.Flags().StringVar(&pass, "pass", "", "Password for login on the target app")
	cmd.Flags().StringVar(&context, "context", "", "Free text: business rules, constraints, notes")
	cmd.Flags().StringVar(&model, "model", "sonnet", "Claude model to use")

	_ = cmd.MarkFlagRequired("plan")
	_ = cmd.MarkFlagRequired("url")

	return cmd
}

func newQAFullCmd() *cobra.Command {
	var url, name, user, pass, context, depth, tags, qa, model string

	cmd := &cobra.Command{
		Use:   "full",
		Short: "Full cycle: generate a test plan and execute it",
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return err
			}
			if err := requireClaude(); err != nil {
				return err
			}

			if depth != "quick" && depth != "normal" && depth != "deep" {
				return fmt.Errorf("invalid --depth %q: must be quick, normal, or deep", depth)
			}

			mcpPath, err := findMCPConfig()
			if err != nil {
				return err
			}

			ensureTokenEnv()

			system := buildQASystemPrompt()
			task := buildFullPrompt(url, name, user, pass, context, depth, tags, qa)

			return runClaude(task, system, mcpPath, model)
		},
	}

	cmd.Flags().StringVar(&url, "url", "", "URL of the application to test (required)")
	cmd.Flags().StringVar(&name, "name", "", "Name for the test plan (required)")
	cmd.Flags().StringVar(&user, "user", "", "Username for login on the target app")
	cmd.Flags().StringVar(&pass, "pass", "", "Password for login on the target app")
	cmd.Flags().StringVar(&context, "context", "", "Free text: business rules, constraints, notes")
	cmd.Flags().StringVar(&depth, "depth", "normal", "Test depth: quick (5-8), normal (8-15), deep (15-25 scenarios)")
	cmd.Flags().StringVar(&tags, "tags", "", "Comma-separated tags for the test plan")
	cmd.Flags().StringVar(&qa, "qa", "", "Name of the QA responsible")
	cmd.Flags().StringVar(&model, "model", "sonnet", "Claude model to use")

	_ = cmd.MarkFlagRequired("url")
	_ = cmd.MarkFlagRequired("name")

	return cmd
}

// --- Helper functions ---

// findMCPConfig locates .claude/mcp.json by walking up from the executable's directory.
func findMCPConfig() (string, error) {
	exePath, err := os.Executable()
	if err != nil {
		return "", fmt.Errorf("cannot determine executable path: %w", err)
	}
	exePath, err = filepath.EvalSymlinks(exePath)
	if err != nil {
		return "", fmt.Errorf("cannot resolve symlinks: %w", err)
	}

	dir := filepath.Dir(exePath)
	for i := 0; i < 5; i++ {
		candidate := filepath.Join(dir, ".claude", "mcp.json")
		if _, err := os.Stat(candidate); err == nil {
			return candidate, nil
		}
		dir = filepath.Dir(dir)
	}

	return "", fmt.Errorf("cannot find .claude/mcp.json (searched up from %s)", filepath.Dir(exePath))
}

// requireClaude checks that the claude CLI is available in PATH.
func requireClaude() error {
	if _, err := exec.LookPath("claude"); err != nil {
		return fmt.Errorf("'claude' CLI not found in PATH. Install it with: npm install -g @anthropic-ai/claude-code")
	}
	return nil
}

// ensureTokenEnv exports the TESTY_API_TOKEN env var so child processes (claude → testy) are authenticated.
func ensureTokenEnv() {
	if os.Getenv("TESTY_API_TOKEN") != "" {
		return
	}
	data, err := os.ReadFile(config.TokenPath())
	if err != nil {
		return
	}
	os.Setenv("TESTY_API_TOKEN", strings.TrimSpace(string(data)))
}

// runClaude executes claude with the given task prompt, system prompt, and MCP config.
func runClaude(task, system, mcpPath, model string) error {
	if model == "" {
		model = "sonnet"
	}

	args := []string{
		"-p", task,
		"--mcp-config", mcpPath,
		"--append-system-prompt", system,
		"--tools", "mcp__playwright__*,Bash",
		"--model", model,
		"--permission-mode", "bypassPermissions",
		"--allow-dangerously-skip-permissions",
	}

	cmd := exec.Command("claude", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	cmd.Env = os.Environ()

	return cmd.Run()
}

// --- Prompt builders ---

func buildQASystemPrompt() string {
	return `You are a QA automation agent with access to two toolsets:

## 1. Testy CLI (via Bash tool)
You are already authenticated. The session token is set. Do NOT call testy login.
Available commands:
- testy plans list/show/create/update/delete
- testy scenarios create/update/delete --plan <id>
- testy bugs list/show/create/update/delete
- testy tags list
- testy screenshots attach --plan <id> --scenario <id> --file <path>

Always use --json flag when you need to parse output programmatically.

## 2. Playwright browser tools (MCP)
- browser_navigate / browser_snapshot / browser_click / browser_type
- browser_screenshot / browser_close / browser_go_back / browser_go_forward
- browser_wait / browser_press_key / browser_select_option / browser_hover
- browser_drag / browser_tab_new / browser_tab_select / browser_tab_close / browser_tab_list

## Rules
- Use browser_snapshot (accessibility tree) to read page content and decide actions. Use browser_screenshot only for visual evidence to attach.
- ALWAYS call browser_close when done with the browser.
- Respond in the same language as any context/instructions provided by the user. Default to English if no context is given.
- Be methodical: snapshot before acting, verify results after acting.
- SCOPE RESTRICTION: Only navigate to URLs under the base URL provided by the user. NEVER follow links to external domains or unrelated URLs. If a scenario involves an external link, verify the href value via snapshot but do NOT navigate to it.
- MANDATORY STATUS: Every single scenario MUST end with a status update — either approved or failed. No scenario may be left without a verdict. If you cannot fully verify a scenario, mark it as failed and explain why in a bug report.
- MANDATORY EVIDENCE: For every scenario, you MUST take a browser_screenshot and attach it with testy screenshots attach. No scenario is complete without attached evidence.`
}

func buildGeneratePrompt(url, name, user, pass, context, depth, tags, qa string) string {
	var scenarioRange string
	switch depth {
	case "quick":
		scenarioRange = "5 to 8"
	case "deep":
		scenarioRange = "15 to 25"
	default:
		scenarioRange = "8 to 15"
	}

	var b strings.Builder

	b.WriteString("## Task: Generate a Test Plan\n\n")

	if user != "" && pass != "" {
		b.WriteString(fmt.Sprintf("### Step 0: Login\n"))
		b.WriteString(fmt.Sprintf("Navigate to %s and log in with username=%q password=%q. "+
			"After login, verify you are authenticated (look for dashboard or user menu).\n\n", url, user, pass))
	}

	b.WriteString("### Step 1: Explore the application\n")
	b.WriteString(fmt.Sprintf("Navigate to %s. Use browser_snapshot to analyze the page structure, "+
		"interactive elements, forms, buttons, and navigation links.\n", url))
	b.WriteString(fmt.Sprintf("Follow internal navigation links (1 level deep) that stay within %s. "+
		"NEVER navigate to external domains. Take snapshots of each page you visit.\n\n", url))

	b.WriteString("### Step 2: Create the test plan\n")
	b.WriteString(fmt.Sprintf("Run: testy plans create %q", name))
	if qa != "" {
		b.WriteString(fmt.Sprintf(" --qa %q", qa))
	}
	if tags != "" {
		b.WriteString(fmt.Sprintf(" --tags %q", tags))
	}
	b.WriteString(" --json\n")
	b.WriteString("Parse the JSON output to get the plan ID.\n\n")

	b.WriteString("### Step 3: Create test scenarios\n")
	b.WriteString(fmt.Sprintf("Based on your exploration, create %s test scenarios using Given/When/Then format.\n", scenarioRange))
	b.WriteString("For each scenario, run:\n")
	b.WriteString("  testy scenarios create \"<title>\" --plan <plan_id> --given \"<given>\" --when \"<when>\" --then \"<then>\"\n\n")
	b.WriteString("Cover these areas:\n")
	b.WriteString("- Happy path flows (main user journeys)\n")
	b.WriteString("- Form validations and error handling\n")
	b.WriteString("- Navigation and page transitions\n")
	b.WriteString("- Edge cases (empty states, boundary values)\n")
	if depth == "deep" {
		b.WriteString("- Accessibility (keyboard navigation, ARIA labels, contrast)\n")
		b.WriteString("- Performance (page load times, responsiveness)\n")
		b.WriteString("- Security (XSS inputs, unauthorized access attempts)\n")
	}

	b.WriteString("\n### Step 4: Show result\n")
	b.WriteString("Run: testy plans show <plan_id>\n")
	b.WriteString("Display the created plan with all scenarios.\n")
	b.WriteString("Close the browser with browser_close.\n")

	if context != "" {
		b.WriteString(fmt.Sprintf("\n### Additional Context from the Tester\n%s\n", context))
	}

	return b.String()
}

func buildExecutePrompt(plan, url, user, pass, context string) string {
	var b strings.Builder

	b.WriteString("## Task: Execute a Test Plan\n\n")

	b.WriteString("### Step 1: Load the plan\n")
	b.WriteString(fmt.Sprintf("Run: testy plans show %s --json\n", plan))
	b.WriteString("Parse the JSON to get all scenarios with their Given/When/Then steps.\n\n")

	if user != "" && pass != "" {
		b.WriteString("### Step 2: Login\n")
		b.WriteString(fmt.Sprintf("Navigate to %s and log in with username=%q password=%q. "+
			"Verify you are authenticated.\n\n", url, user, pass))
	}

	b.WriteString("### Step 3: Execute each scenario\n")
	b.WriteString("IMPORTANT: You MUST complete ALL steps below for EVERY scenario. No exceptions.\n")
	b.WriteString("- Every scenario MUST get a final status (approved or failed).\n")
	b.WriteString("- Every scenario MUST have a screenshot attached as evidence.\n")
	b.WriteString(fmt.Sprintf("- ONLY navigate to URLs under %s. Never visit external domains.\n\n", url))
	b.WriteString("For EACH scenario in the plan:\n\n")
	b.WriteString(fmt.Sprintf("1. **Navigate** to %s (or a sub-path of it relevant to the scenario)\n", url))
	b.WriteString("2. **Setup Given** — perform the precondition steps described in the Given clause\n")
	b.WriteString("3. **Execute When** — perform the action described in the When clause\n")
	b.WriteString("4. **Snapshot** — use browser_snapshot to read the resulting page state\n")
	b.WriteString("5. **Verify Then** — check if the expected outcome (Then clause) is met\n")
	b.WriteString("6. **Screenshot** — use browser_screenshot to capture visual evidence (MANDATORY)\n")
	b.WriteString("7. **Attach evidence** — run: testy screenshots attach --plan <plan_id> --scenario <scenario_id> --file <screenshot_path> (MANDATORY)\n")
	b.WriteString("8. **Update status** (MANDATORY — pick one):\n")
	b.WriteString("   - PASSED: testy scenarios update <scenario_id> --plan <plan_id> --status approved\n")
	b.WriteString("   - FAILED: testy scenarios update <scenario_id> --plan <plan_id> --status failed\n")
	b.WriteString("     Then create a bug: testy bugs create \"<descriptive title>\" --description \"<what happened>\" --steps \"<reproduction steps>\" --obtained \"<actual result>\" --expected \"<expected result>\"\n")
	b.WriteString("     Link the bug: testy scenarios update <scenario_id> --plan <plan_id> --bug-id <bug_id>\n\n")

	b.WriteString("### Step 4: Summary\n")
	b.WriteString("Close the browser with browser_close.\n")
	b.WriteString(fmt.Sprintf("Run: testy plans show %s\n", plan))
	b.WriteString("Display the final plan status with all scenario results.\n")

	if context != "" {
		b.WriteString(fmt.Sprintf("\n### Additional Context from the Tester\n%s\n", context))
	}

	return b.String()
}

func buildFullPrompt(url, name, user, pass, context, depth, tags, qa string) string {
	var scenarioRange string
	switch depth {
	case "quick":
		scenarioRange = "5 to 8"
	case "deep":
		scenarioRange = "15 to 25"
	default:
		scenarioRange = "8 to 15"
	}

	var b strings.Builder

	b.WriteString("## Task: Full QA Cycle (Generate + Execute)\n\n")
	b.WriteString("You will perform a complete QA cycle in two phases.\n\n")

	// Phase 1: Generate
	b.WriteString("---\n## Phase 1: Generate Test Plan\n\n")

	if user != "" && pass != "" {
		b.WriteString(fmt.Sprintf("### Login\nNavigate to %s and log in with username=%q password=%q. "+
			"Verify you are authenticated.\n\n", url, user, pass))
	}

	b.WriteString("### Explore the application\n")
	b.WriteString(fmt.Sprintf("Navigate to %s. Use browser_snapshot to analyze the page structure, "+
		"interactive elements, forms, buttons, and navigation links.\n", url))
	b.WriteString(fmt.Sprintf("Follow internal navigation links (1 level deep) that stay within %s. "+
		"NEVER navigate to external domains.\n\n", url))

	b.WriteString("### Create the test plan\n")
	b.WriteString(fmt.Sprintf("Run: testy plans create %q", name))
	if qa != "" {
		b.WriteString(fmt.Sprintf(" --qa %q", qa))
	}
	if tags != "" {
		b.WriteString(fmt.Sprintf(" --tags %q", tags))
	}
	b.WriteString(" --json\n")
	b.WriteString("Parse the JSON output to get the plan ID.\n\n")

	b.WriteString("### Create test scenarios\n")
	b.WriteString(fmt.Sprintf("Create %s test scenarios in Given/When/Then format.\n", scenarioRange))
	b.WriteString("Cover: happy paths, form validations, navigation, edge cases.\n")
	if depth == "deep" {
		b.WriteString("Also cover: accessibility, performance, security.\n")
	}
	b.WriteString("For each: testy scenarios create \"<title>\" --plan <plan_id> --given \"...\" --when \"...\" --then \"...\"\n\n")

	// Phase 2: Execute
	b.WriteString("---\n## Phase 2: Execute Test Plan\n\n")

	b.WriteString("### Load the plan\n")
	b.WriteString("Run: testy plans show <plan_id> --json\n")
	b.WriteString("Parse scenarios from the JSON output.\n\n")

	b.WriteString("### Execute each scenario\n")
	b.WriteString("IMPORTANT: You MUST complete ALL steps for EVERY scenario. No exceptions.\n")
	b.WriteString(fmt.Sprintf("ONLY navigate to URLs under %s. Never visit external domains.\n\n", url))
	b.WriteString("For EACH scenario:\n\n")
	b.WriteString(fmt.Sprintf("1. **Navigate** to %s (or a sub-path of it)\n", url))
	b.WriteString("2. **Setup Given** — perform precondition steps\n")
	b.WriteString("3. **Execute When** — perform the action\n")
	b.WriteString("4. **Snapshot** — browser_snapshot to read page state\n")
	b.WriteString("5. **Verify Then** — check expected outcome\n")
	b.WriteString("6. **Screenshot** — browser_screenshot for evidence (MANDATORY)\n")
	b.WriteString("7. **Attach** — testy screenshots attach --plan <plan_id> --scenario <scenario_id> --file <path> (MANDATORY)\n")
	b.WriteString("8. **Update status** — approved or failed (MANDATORY — create bug if failed)\n\n")

	b.WriteString("### Summary\n")
	b.WriteString("Close the browser with browser_close.\n")
	b.WriteString("Run: testy plans show <plan_id>\n")
	b.WriteString("Display the final plan with all results.\n")

	if context != "" {
		b.WriteString(fmt.Sprintf("\n### Additional Context from the Tester\n%s\n", context))
	}

	return b.String()
}
