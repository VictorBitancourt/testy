package commands

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/output"
	"github.com/victorbitancourt/testy-cli/internal/version"
)

// NewDoctorCmd creates the doctor command.
func NewDoctorCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "doctor",
		Short: "Check CLI health and diagnose issues",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())

			checks := []map[string]any{}

			// 1. CLI version
			checks = append(checks, map[string]any{
				"check":  "cli_version",
				"status": "ok",
				"detail": version.Version,
			})

			// 2. Auth
			authCheck := map[string]any{"check": "authentication"}
			if app.IsAuthenticated() {
				authCheck["status"] = "ok"
				authCheck["detail"] = "Token found"
			} else {
				authCheck["status"] = "fail"
				authCheck["detail"] = "Not logged in. Run: testy login <user> <pass>"
			}
			checks = append(checks, authCheck)

			// 3. API connectivity
			apiCheck := map[string]any{"check": "api_connectivity"}
			_, err := app.Client.Get("/api/v1/tags", map[string]string{"limit": "1"})
			if err != nil {
				apiCheck["status"] = "fail"
				apiCheck["detail"] = fmt.Sprintf("Cannot reach %s: %v", app.Config.BaseURL, err)
			} else {
				apiCheck["status"] = "ok"
				apiCheck["detail"] = app.Config.BaseURL
			}
			checks = append(checks, apiCheck)

			// 4. Playwright MCP
			playwrightCheck := map[string]any{"check": "playwright_mcp"}
			if _, err := exec.LookPath("npx"); err != nil {
				playwrightCheck["status"] = "warn"
				playwrightCheck["detail"] = "npx not found — Playwright MCP unavailable"
			} else {
				playwrightCheck["status"] = "ok"
				playwrightCheck["detail"] = "npx available"
			}
			checks = append(checks, playwrightCheck)

			// 5. Skill installed
			skillCheck := map[string]any{"check": "skill_installed"}
			home, _ := os.UserHomeDir()
			skillPath := filepath.Join(home, ".claude", "skills", "testy", "SKILL.md")
			if _, err := os.Stat(skillPath); err == nil {
				versionPath := filepath.Join(home, ".claude", "skills", "testy", ".installed-version")
				installedVersion, _ := os.ReadFile(versionPath)
				if string(installedVersion) == version.Version {
					skillCheck["status"] = "ok"
					skillCheck["detail"] = fmt.Sprintf("Installed (v%s)", version.Version)
				} else {
					skillCheck["status"] = "warn"
					skillCheck["detail"] = fmt.Sprintf("Outdated (installed: %s, current: %s). Run: testy skill install", string(installedVersion), version.Version)
				}
			} else {
				skillCheck["status"] = "warn"
				skillCheck["detail"] = "Not installed. Run: testy skill install"
			}
			checks = append(checks, skillCheck)

			// Machine output
			if app.IsMachineOutput() {
				allOK := true
				for _, c := range checks {
					if c["status"] == "fail" {
						allOK = false
					}
				}
				result := map[string]any{
					"healthy": allOK,
					"version": version.Version,
					"checks":  checks,
				}
				return app.OK(result)
			}

			// Human output
			fmt.Fprintf(cmd.OutOrStdout(), "Testy CLI v%s\n\n", version.Version)
			allOK := true
			for _, c := range checks {
				status := c["status"].(string)
				icon := "+"
				if status == "fail" {
					icon = "x"
					allOK = false
				} else if status == "warn" {
					icon = "!"
				}
				// Convert check detail to string safely
				detail := ""
				if d, ok := c["detail"]; ok {
					b, _ := json.Marshal(d)
					detail = string(b)
					// Remove surrounding quotes if it's a simple string
					if len(detail) > 1 && detail[0] == '"' && detail[len(detail)-1] == '"' {
						detail = detail[1 : len(detail)-1]
					}
				}
				fmt.Fprintf(cmd.OutOrStdout(), "  [%s] %-20s %s\n", icon, c["check"], detail)
			}

			fmt.Fprintln(cmd.OutOrStdout())
			if allOK {
				fmt.Fprintln(cmd.OutOrStdout(), "All checks passed.")
			} else {
				fmt.Fprintln(cmd.OutOrStdout(), "Some checks failed. See details above.")
				return app.Err(output.ErrAPI(1, "Health check failed"))
			}
			return nil
		},
	}
}
