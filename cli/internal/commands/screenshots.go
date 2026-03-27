package commands

import (
	"encoding/json"
	"fmt"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/output"
)

// NewScreenshotsCmd creates the screenshots command group.
func NewScreenshotsCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "screenshots",
		Short: "Manage screenshot evidence",
	}
	cmd.AddCommand(newScreenshotsAttachCmd())
	return cmd
}

func newScreenshotsAttachCmd() *cobra.Command {
	var (
		planID     string
		scenarioID string
		filePath   string
		filename   string
	)

	cmd := &cobra.Command{
		Use:   "attach",
		Short: "Attach a screenshot as evidence to a scenario",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			path := fmt.Sprintf("/api/v1/test_plans/%s/test_scenarios/%s/screenshots", planID, scenarioID)

			extraFields := map[string]string{}
			if filename != "" {
				extraFields["filename"] = filename
			}

			data, err := app.Client.PostMultipart(path, "screenshot[file]", filePath, extraFields)
			if err != nil {
				return app.Err(err)
			}

			var resp any
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			return app.OK(resp, output.WithSummary("Screenshot attached"))
		},
	}
	cmd.Flags().StringVar(&planID, "plan", "", "Test plan ID")
	cmd.Flags().StringVar(&scenarioID, "scenario", "", "Test scenario ID")
	cmd.Flags().StringVar(&filePath, "file", "", "Path to screenshot file")
	cmd.Flags().StringVar(&filename, "filename", "", "Override filename")
	_ = cmd.MarkFlagRequired("plan")
	_ = cmd.MarkFlagRequired("scenario")
	_ = cmd.MarkFlagRequired("file")
	return cmd
}
