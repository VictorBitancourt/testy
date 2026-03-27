package commands

import (
	"encoding/json"
	"fmt"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/output"
)

// NewBugsCmd creates the bugs command group.
func NewBugsCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:     "bugs",
		Aliases: []string{"bug"},
		Short:   "Manage bugs",
	}
	cmd.AddCommand(newBugsListCmd())
	cmd.AddCommand(newBugsShowCmd())
	cmd.AddCommand(newBugsCreateCmd())
	cmd.AddCommand(newBugsUpdateCmd())
	cmd.AddCommand(newBugsDeleteCmd())
	return cmd
}

func newBugsListCmd() *cobra.Command {
	var (
		status     string
		featureTag string
		causeTag   string
		search     string
		dateFrom   string
		dateUntil  string
		page       string
	)

	cmd := &cobra.Command{
		Use:   "list",
		Short: "List bugs",
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
			if featureTag != "" {
				params["feature_tag"] = featureTag
			}
			if causeTag != "" {
				params["cause_tag"] = causeTag
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

			data, err := app.Client.Get("/api/v1/bugs", params)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				Bugs []any          `json:"bugs"`
				Meta map[string]any `json:"meta"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			return app.OK(resp.Bugs,
				output.WithSummary(fmt.Sprintf("%d bug(s)", len(resp.Bugs))),
				output.WithMeta(resp.Meta),
			)
		},
	}
	cmd.Flags().StringVar(&status, "status", "", "Filter by status")
	cmd.Flags().StringVar(&featureTag, "feature-tag", "", "Filter by feature tag")
	cmd.Flags().StringVar(&causeTag, "cause-tag", "", "Filter by cause tag")
	cmd.Flags().StringVar(&search, "search", "", "Search by title/description")
	cmd.Flags().StringVar(&dateFrom, "date-from", "", "Filter from date (YYYY-MM-DD)")
	cmd.Flags().StringVar(&dateUntil, "date-until", "", "Filter until date (YYYY-MM-DD)")
	cmd.Flags().StringVar(&page, "page", "", "Page number")
	return cmd
}

func newBugsShowCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "show <id>",
		Short: "Show a bug",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			data, err := app.Client.Get("/api/v1/bugs/"+args[0], nil)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				Bug any `json:"bug"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			return app.OK(resp.Bug)
		},
	}
}

func newBugsCreateCmd() *cobra.Command {
	var (
		description string
		steps       string
		obtained    string
		expected    string
		featureTag  string
		causeTag    string
		status      string
	)

	cmd := &cobra.Command{
		Use:   "create <title>",
		Short: "Create a bug",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			bug := map[string]any{
				"title":       args[0],
				"description": description,
			}
			if steps != "" {
				bug["steps_to_reproduce"] = steps
			}
			if obtained != "" {
				bug["obtained_result"] = obtained
			}
			if expected != "" {
				bug["expected_result"] = expected
			}
			if featureTag != "" {
				bug["feature_tag"] = featureTag
			}
			if causeTag != "" {
				bug["cause_tag"] = causeTag
			}
			if status != "" {
				bug["status"] = status
			}

			body := map[string]any{"bug": bug}
			data, err := app.Client.Post("/api/v1/bugs", body)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				Bug any `json:"bug"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			return app.OK(resp.Bug, output.WithSummary("Bug created"))
		},
	}
	cmd.Flags().StringVar(&description, "description", "", "Bug description")
	cmd.Flags().StringVar(&steps, "steps", "", "Steps to reproduce")
	cmd.Flags().StringVar(&obtained, "obtained", "", "Obtained result")
	cmd.Flags().StringVar(&expected, "expected", "", "Expected result")
	cmd.Flags().StringVar(&featureTag, "feature-tag", "", "Feature tag")
	cmd.Flags().StringVar(&causeTag, "cause-tag", "", "Root cause tag")
	cmd.Flags().StringVar(&status, "status", "", "Bug status")
	return cmd
}

func newBugsUpdateCmd() *cobra.Command {
	var (
		title       string
		description string
		steps       string
		obtained    string
		expected    string
		featureTag  string
		causeTag    string
		status      string
	)

	cmd := &cobra.Command{
		Use:   "update <id>",
		Short: "Update a bug",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			bug := map[string]any{}
			if cmd.Flags().Changed("title") {
				bug["title"] = title
			}
			if cmd.Flags().Changed("description") {
				bug["description"] = description
			}
			if cmd.Flags().Changed("steps") {
				bug["steps_to_reproduce"] = steps
			}
			if cmd.Flags().Changed("obtained") {
				bug["obtained_result"] = obtained
			}
			if cmd.Flags().Changed("expected") {
				bug["expected_result"] = expected
			}
			if cmd.Flags().Changed("feature-tag") {
				bug["feature_tag"] = featureTag
			}
			if cmd.Flags().Changed("cause-tag") {
				bug["cause_tag"] = causeTag
			}
			if cmd.Flags().Changed("status") {
				bug["status"] = status
			}

			if len(bug) == 0 {
				return app.Err(output.ErrUsage("No update fields specified"))
			}

			body := map[string]any{"bug": bug}
			data, err := app.Client.Patch("/api/v1/bugs/"+args[0], body)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				Bug any `json:"bug"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			return app.OK(resp.Bug, output.WithSummary("Bug updated"))
		},
	}
	cmd.Flags().StringVar(&title, "title", "", "Bug title")
	cmd.Flags().StringVar(&description, "description", "", "Bug description")
	cmd.Flags().StringVar(&steps, "steps", "", "Steps to reproduce")
	cmd.Flags().StringVar(&obtained, "obtained", "", "Obtained result")
	cmd.Flags().StringVar(&expected, "expected", "", "Expected result")
	cmd.Flags().StringVar(&featureTag, "feature-tag", "", "Feature tag")
	cmd.Flags().StringVar(&causeTag, "cause-tag", "", "Root cause tag")
	cmd.Flags().StringVar(&status, "status", "", "Bug status")
	return cmd
}

func newBugsDeleteCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "delete <id>",
		Short: "Delete a bug",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			if err := app.Client.Delete("/api/v1/bugs/" + args[0]); err != nil {
				return app.Err(err)
			}

			return app.OK(map[string]string{
				"deleted": args[0],
			}, output.WithSummary(fmt.Sprintf("Bug #%s deleted", args[0])))
		},
	}
}
