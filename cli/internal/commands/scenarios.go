package commands

import (
	"encoding/json"
	"fmt"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/output"
)

// NewScenariosCmd creates the scenarios command group.
func NewScenariosCmd() *cobra.Command {
	var planID string

	cmd := &cobra.Command{
		Use:     "scenarios",
		Aliases: []string{"scenario"},
		Short:   "Manage test scenarios",
	}

	cmd.PersistentFlags().StringVar(&planID, "plan", "", "Test plan ID (required)")
	_ = cmd.MarkPersistentFlagRequired("plan")

	cmd.AddCommand(newScenariosCreateCmd(&planID))
	cmd.AddCommand(newScenariosUpdateCmd(&planID))
	cmd.AddCommand(newScenariosDeleteCmd(&planID))
	return cmd
}

func newScenariosCreateCmd(planID *string) *cobra.Command {
	var (
		given  string
		when   string
		then   string
		status string
		bugID  string
	)

	cmd := &cobra.Command{
		Use:   "create <title>",
		Short: "Create a test scenario",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			scenario := map[string]any{
				"title":     args[0],
				"given":     given,
				"when_step": when,
				"then_step": then,
			}
			if status != "" {
				scenario["status"] = status
			}
			if bugID != "" {
				scenario["bug_id"] = bugID
			}

			body := map[string]any{"test_scenario": scenario}
			path := fmt.Sprintf("/api/v1/test_plans/%s/test_scenarios", *planID)
			data, err := app.Client.Post(path, body)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				TestScenario any `json:"test_scenario"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			return app.OK(resp.TestScenario, output.WithSummary("Scenario created"))
		},
	}
	cmd.Flags().StringVar(&given, "given", "", "Given precondition")
	cmd.Flags().StringVar(&when, "when", "", "When action")
	cmd.Flags().StringVar(&then, "then", "", "Then expected result")
	cmd.Flags().StringVar(&status, "status", "", "Scenario status")
	cmd.Flags().StringVar(&bugID, "bug-id", "", "Associated bug ID")
	return cmd
}

func newScenariosUpdateCmd(planID *string) *cobra.Command {
	var (
		title  string
		given  string
		when   string
		then   string
		status string
		bugID  string
	)

	cmd := &cobra.Command{
		Use:   "update <scenario_id>",
		Short: "Update a test scenario",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			scenario := map[string]any{}
			if cmd.Flags().Changed("title") {
				scenario["title"] = title
			}
			if cmd.Flags().Changed("given") {
				scenario["given"] = given
			}
			if cmd.Flags().Changed("when") {
				scenario["when_step"] = when
			}
			if cmd.Flags().Changed("then") {
				scenario["then_step"] = then
			}
			if cmd.Flags().Changed("status") {
				scenario["status"] = status
			}
			if cmd.Flags().Changed("bug-id") {
				scenario["bug_id"] = bugID
			}

			if len(scenario) == 0 {
				return app.Err(output.ErrUsage("No update fields specified"))
			}

			body := map[string]any{"test_scenario": scenario}
			path := fmt.Sprintf("/api/v1/test_plans/%s/test_scenarios/%s", *planID, args[0])
			data, err := app.Client.Patch(path, body)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				TestScenario any `json:"test_scenario"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			return app.OK(resp.TestScenario, output.WithSummary("Scenario updated"))
		},
	}
	cmd.Flags().StringVar(&title, "title", "", "Scenario title")
	cmd.Flags().StringVar(&given, "given", "", "Given precondition")
	cmd.Flags().StringVar(&when, "when", "", "When action")
	cmd.Flags().StringVar(&then, "then", "", "Then expected result")
	cmd.Flags().StringVar(&status, "status", "", "Scenario status")
	cmd.Flags().StringVar(&bugID, "bug-id", "", "Associated bug ID")
	return cmd
}

func newScenariosDeleteCmd(planID *string) *cobra.Command {
	return &cobra.Command{
		Use:   "delete <scenario_id>",
		Short: "Delete a test scenario",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			path := fmt.Sprintf("/api/v1/test_plans/%s/test_scenarios/%s", *planID, args[0])
			if err := app.Client.Delete(path); err != nil {
				return app.Err(err)
			}

			return app.OK(map[string]string{
				"deleted": args[0],
			}, output.WithSummary(fmt.Sprintf("Scenario #%s deleted", args[0])))
		},
	}
}
