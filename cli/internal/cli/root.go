package cli

import (
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/commands"
	"github.com/victorbitancourt/testy-cli/internal/config"
	"github.com/victorbitancourt/testy-cli/internal/output"
	"github.com/victorbitancourt/testy-cli/internal/version"
)

// NewRootCmd creates the root cobra command.
func NewRootCmd() *cobra.Command {
	var flags appctx.GlobalFlags
	var baseURL string

	cmd := &cobra.Command{
		Use:           "testy",
		Short:         "CLI for the Testy test management platform",
		Version:       version.Version,
		SilenceUsage:  true,
		SilenceErrors: true,
		PersistentPostRunE: func(cmd *cobra.Command, args []string) error {
			if commands.RefreshSkillIfVersionChanged() {
				fmt.Fprintf(os.Stderr, "Agent skill updated to match CLI %s\n", version.Version)
			}
			return nil
		},
		PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
			if cmd.Name() == "help" || cmd.Name() == "version" {
				cfg := config.Load(baseURL)
				app := appctx.NewApp(cfg)
				app.Flags = flags
				app.ApplyFlags()
				cmd.SetContext(appctx.WithApp(cmd.Context(), app))
				return nil
			}

			cfg := config.Load(baseURL)
			app := appctx.NewApp(cfg)
			app.Flags = flags
			app.ApplyFlags()
			cmd.SetContext(appctx.WithApp(cmd.Context(), app))
			return nil
		},
	}

	// Output format flags
	cmd.PersistentFlags().BoolVarP(&flags.JSON, "json", "j", false, "Output as JSON")
	cmd.PersistentFlags().BoolVarP(&flags.Quiet, "quiet", "q", false, "Output data only, no envelope")
	cmd.PersistentFlags().BoolVarP(&flags.MD, "md", "m", false, "Output as Markdown")
	cmd.PersistentFlags().BoolVar(&flags.Agent, "agent", false, "Agent mode (data only JSON)")

	// Config flag
	cmd.PersistentFlags().StringVar(&baseURL, "url", "", "Testy server URL")

	return cmd
}

// Execute runs the root command.
func Execute() {
	cmd := NewRootCmd()

	// Register subcommands
	cmd.AddCommand(commands.NewAuthCmd())
	cmd.AddCommand(commands.NewLoginCmd())
	cmd.AddCommand(commands.NewLogoutCmd())
	cmd.AddCommand(commands.NewWhoamiCmd())
	cmd.AddCommand(commands.NewPlansCmd())
	cmd.AddCommand(commands.NewScenariosCmd())
	cmd.AddCommand(commands.NewBugsCmd())
	cmd.AddCommand(commands.NewTagsCmd())
	cmd.AddCommand(commands.NewScreenshotsCmd())
	cmd.AddCommand(commands.NewVersionCmd())
	cmd.AddCommand(commands.NewCommandsCmd())
	cmd.AddCommand(commands.NewSkillCmd())
	cmd.AddCommand(commands.NewDoctorCmd())
	cmd.AddCommand(commands.NewQACmd())

	executedCmd, err := cmd.ExecuteC()
	if err != nil {
		// Structured CLI error — output via the writer
		apiErr, ok := err.(*output.Error)
		if ok {
			w := output.New(output.FormatJSON, os.Stdout)
			_ = w.Err(apiErr)
			os.Exit(apiErr.ExitCode())
		}

		// Cobra errors (missing args, unknown flags, etc.) — print to stderr
		msg := err.Error()
		cmdPath := strings.TrimPrefix(executedCmd.CommandPath(), "testy ")
		if strings.Contains(msg, "arg(s), received 0") || strings.Contains(msg, "requires at least") {
			fmt.Fprintf(os.Stderr, "Error: argument required\n")
			fmt.Fprintf(os.Stderr, "Run 'testy %s --help' for usage.\n", cmdPath)
		} else {
			fmt.Fprintf(os.Stderr, "Error: %s\n", msg)
		}
		os.Exit(2)
	}
}
