package commands

import (
	"encoding/json"
	"fmt"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/output"
)

// NewTagsCmd creates the tags command group.
func NewTagsCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:     "tags",
		Aliases: []string{"tag"},
		Short:   "Manage tags",
	}
	cmd.AddCommand(newTagsListCmd())
	return cmd
}

func newTagsListCmd() *cobra.Command {
	var (
		search string
		limit  string
	)

	cmd := &cobra.Command{
		Use:   "list",
		Short: "List tags",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			params := map[string]string{}
			if search != "" {
				params["q"] = search
			}
			if limit != "" {
				params["limit"] = limit
			}

			data, err := app.Client.Get("/api/v1/tags", params)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				Tags []string `json:"tags"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			// Convert to []any for output
			items := make([]any, len(resp.Tags))
			for i, t := range resp.Tags {
				items[i] = t
			}

			return app.OK(items,
				output.WithSummary(fmt.Sprintf("%d tag(s)", len(resp.Tags))),
			)
		},
	}
	cmd.Flags().StringVar(&search, "search", "", "Search tags by name")
	cmd.Flags().StringVar(&limit, "limit", "", "Max results (default 50, max 100)")
	return cmd
}
