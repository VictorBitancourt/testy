package commands

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/auth"
	"github.com/victorbitancourt/testy-cli/internal/client"
	"github.com/victorbitancourt/testy-cli/internal/config"
	"github.com/victorbitancourt/testy-cli/internal/output"
)

// NewAuthCmd creates the auth command group.
func NewAuthCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "auth",
		Short: "Manage authentication",
	}
	cmd.AddCommand(newAuthLoginCmd())
	cmd.AddCommand(newAuthLogoutCmd())
	cmd.AddCommand(newAuthStatusCmd())
	return cmd
}

// NewLoginCmd creates the top-level login shortcut.
func NewLoginCmd() *cobra.Command {
	return newAuthLoginCmd()
}

// NewLogoutCmd creates the top-level logout shortcut.
func NewLogoutCmd() *cobra.Command {
	cmd := newAuthLogoutCmd()
	cmd.Use = "logout"
	return cmd
}

// NewWhoamiCmd creates the top-level whoami shortcut.
func NewWhoamiCmd() *cobra.Command {
	cmd := newAuthStatusCmd()
	cmd.Use = "whoami"
	cmd.Short = "Show current authentication status"
	return cmd
}

func newAuthLoginCmd() *cobra.Command {
	var tokenName string

	cmd := &cobra.Command{
		Use:   "login <username> <password>",
		Short: "Authenticate with the Testy server",
		Args:  cobra.ExactArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			username, password := args[0], args[1]

			// Create a temporary client without token for login
			c := client.New(app.Config.BaseURL, "")
			resp, err := auth.Login(c, username, password)
			if err != nil {
				return app.Err(err)
			}

			_ = tokenName // reserved for future use

			return app.OK(map[string]any{
				"username": resp.User.Username,
				"role":     resp.User.Role,
			}, output.WithSummary(fmt.Sprintf("Logged in as %s", resp.User.Username)))
		},
	}
	cmd.Flags().StringVar(&tokenName, "token-name", "testy-cli", "Name for the API token")
	return cmd
}

func newAuthLogoutCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "logout",
		Short: "Remove stored credentials",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())

			if err := auth.Logout(app.Client); err != nil {
				// Ignore removal errors (file may not exist)
			}

			return app.OK(map[string]string{
				"status": "logged_out",
			}, output.WithSummary("Logged out. Token removed."))
		},
	}
}

func newAuthStatusCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "status",
		Short: "Check authentication status",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())

			if !auth.IsLoggedIn() {
				return app.Err(output.ErrAuth("Not logged in"))
			}

			return app.OK(map[string]any{
				"authenticated": true,
				"token_path":    config.TokenPath(),
			}, output.WithSummary(fmt.Sprintf("Authenticated (token at %s)", config.TokenPath())))
		},
	}
}
