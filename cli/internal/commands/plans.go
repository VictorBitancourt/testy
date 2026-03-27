package commands

import (
	"encoding/json"
	"fmt"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/output"
)

// NewPlansCmd creates the plans command group.
func NewPlansCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:     "plans",
		Aliases: []string{"plan"},
		Short:   "Manage test plans",
	}
	cmd.AddCommand(newPlansListCmd())
	cmd.AddCommand(newPlansShowCmd())
	cmd.AddCommand(newPlansCreateCmd())
	cmd.AddCommand(newPlansUpdateCmd())
	cmd.AddCommand(newPlansDeleteCmd())
	return cmd
}

func newPlansListCmd() *cobra.Command {
	var (
		status    string
		search    string
		dateFrom  string
		dateUntil string
		page      string
	)

	cmd := &cobra.Command{
		Use:   "list",
		Short: "List test plans",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			params := map[string]string{}
			if status != "" {
				params["status"] = status
			}
			if search != "" {
				params["search"] = search
			}
			if dateFrom != "" {
				params["date_from"] = dateFrom
			}
			if dateUntil != "" {
				params["date_until"] = dateUntil
			}
			if page != "" {
				params["page"] = page
			}

			data, err := app.Client.Get("/api/v1/test_plans", params)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				TestPlans []any          `json:"test_plans"`
				Meta      map[string]any `json:"meta"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			count := len(resp.TestPlans)
			return app.OK(resp.TestPlans,
				output.WithSummary(fmt.Sprintf("%d test plan(s)", count)),
				output.WithMeta(resp.Meta),
			)
		},
	}
	cmd.Flags().StringVar(&status, "status", "", "Filter by status (approved, failed, in_progress, not_started)")
	cmd.Flags().StringVar(&search, "search", "", "Search by name")
	cmd.Flags().StringVar(&dateFrom, "date-from", "", "Filter by start date (YYYY-MM-DD)")
	cmd.Flags().StringVar(&dateUntil, "date-until", "", "Filter by end date (YYYY-MM-DD)")
	cmd.Flags().StringVar(&page, "page", "", "Page number")
	return cmd
}

func newPlansShowCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "show <id>",
		Short: "Show a test plan with scenarios",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			data, err := app.Client.Get("/api/v1/test_plans/"+args[0], nil)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				TestPlan any `json:"test_plan"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			return app.OK(resp.TestPlan)
		},
	}
}

func newPlansCreateCmd() *cobra.Command {
	var (
		qaName string
		tags   string
	)

	cmd := &cobra.Command{
		Use:   "create <name>",
		Short: "Create a test plan",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			name := args[0]
			body := map[string]any{
				"test_plan": map[string]any{
					"name":    name,
					"qa_name": qaName,
				},
			}
			if tags != "" {
				body["test_plan"].(map[string]any)["tag_list"] = tags
			}

			data, err := app.Client.Post("/api/v1/test_plans", body)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				TestPlan any `json:"test_plan"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			return app.OK(resp.TestPlan, output.WithSummary("Test plan created"))
		},
	}
	cmd.Flags().StringVar(&qaName, "qa", "", "QA responsible name")
	cmd.Flags().StringVar(&tags, "tags", "", "Comma-separated tags")
	return cmd
}

func newPlansUpdateCmd() *cobra.Command {
	var (
		name   string
		qaName string
		tags   string
	)

	cmd := &cobra.Command{
		Use:   "update <id>",
		Short: "Update a test plan",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			plan := map[string]any{}
			if cmd.Flags().Changed("name") {
				plan["name"] = name
			}
			if cmd.Flags().Changed("qa") {
				plan["qa_name"] = qaName
			}
			if cmd.Flags().Changed("tags") {
				plan["tag_list"] = tags
			}

			if len(plan) == 0 {
				return app.Err(output.ErrUsage("No update fields specified"))
			}

			body := map[string]any{"test_plan": plan}
			data, err := app.Client.Patch("/api/v1/test_plans/"+args[0], body)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				TestPlan any `json:"test_plan"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			return app.OK(resp.TestPlan, output.WithSummary("Test plan updated"))
		},
	}
	cmd.Flags().StringVar(&name, "name", "", "Plan name")
	cmd.Flags().StringVar(&qaName, "qa", "", "QA responsible name")
	cmd.Flags().StringVar(&tags, "tags", "", "Comma-separated tags")
	return cmd
}

func newPlansDeleteCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "delete <id>",
		Short: "Delete a test plan",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			if err := app.Client.Delete("/api/v1/test_plans/" + args[0]); err != nil {
				return app.Err(err)
			}

			return app.OK(map[string]string{
				"deleted": args[0],
			}, output.WithSummary(fmt.Sprintf("Test plan #%s deleted", args[0])))
		},
	}
}
