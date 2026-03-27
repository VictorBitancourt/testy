package commands

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
)

// CommandInfo describes a CLI command.
type CommandInfo struct {
	Name        string   `json:"name"`
	Category    string   `json:"category"`
	Description string   `json:"description"`
	Flags       string   `json:"flags,omitempty"`
	Actions     []string `json:"actions,omitempty"`
}

// CommandCategory groups commands by category.
type CommandCategory struct {
	Name     string        `json:"name"`
	Commands []CommandInfo `json:"commands"`
}

// CommandCategories returns all command categories.
func CommandCategories() []CommandCategory {
	return []CommandCategory{
		{
			Name: "Test Management",
			Commands: []CommandInfo{
				{Name: "plans list", Description: "List test plans", Flags: "--status, --search, --date-from, --date-until, --page"},
				{Name: "plans show <id>", Description: "Show plan with scenarios"},
				{Name: "plans create <name>", Description: "Create a test plan", Flags: "--qa, --tags"},
				{Name: "plans update <id>", Description: "Update a test plan", Flags: "--name, --qa, --tags"},
				{Name: "plans delete <id>", Description: "Delete a test plan"},
				{Name: "scenarios create <title>", Description: "Create a scenario", Flags: "--plan (required), --given, --when, --then, --status, --bug-id"},
				{Name: "scenarios update <id>", Description: "Update a scenario", Flags: "--plan (required), --title, --given, --when, --then, --status, --bug-id"},
				{Name: "scenarios delete <id>", Description: "Delete a scenario", Flags: "--plan (required)"},
			},
		},
		{
			Name: "Bug Tracking",
			Commands: []CommandInfo{
				{Name: "bugs list", Description: "List bugs", Flags: "--status, --feature-tag, --cause-tag, --search, --date-from, --date-until, --page"},
				{Name: "bugs show <id>", Description: "Show a bug"},
				{Name: "bugs create <title>", Description: "Create a bug", Flags: "--description, --steps, --obtained, --expected, --feature-tag, --cause-tag, --status"},
				{Name: "bugs update <id>", Description: "Update a bug", Flags: "--title, --description, --steps, --obtained, --expected, --feature-tag, --cause-tag, --status"},
				{Name: "bugs delete <id>", Description: "Delete a bug"},
				{Name: "tags list", Description: "List tags", Flags: "--search, --limit"},
			},
		},
		{
			Name: "Evidence",
			Commands: []CommandInfo{
				{Name: "screenshots attach", Description: "Attach screenshot to scenario", Flags: "--plan (required), --scenario (required), --file (required), --filename"},
			},
		},
		{
			Name: "AI QA Automation",
			Commands: []CommandInfo{
				{Name: "qa generate", Description: "Explore app and generate a test plan", Flags: "--url, --name, --user, --pass, --context, --depth, --tags, --qa"},
				{Name: "qa execute", Description: "Execute an existing test plan", Flags: "--plan, --url, --user, --pass, --context"},
				{Name: "qa full", Description: "Full cycle: generate + execute", Flags: "--url, --name, --user, --pass, --context, --depth, --tags, --qa"},
			},
		},
		{
			Name: "Auth & Config",
			Commands: []CommandInfo{
				{Name: "login <user> <pass>", Description: "Authenticate with the Testy server"},
				{Name: "logout", Description: "Remove stored credentials"},
				{Name: "whoami", Description: "Show authentication status"},
				{Name: "version", Description: "Show CLI version"},
				{Name: "commands", Description: "List all commands"},
				{Name: "doctor", Description: "Check CLI health and diagnose issues"},
				{Name: "skill", Description: "Print the embedded SKILL.md"},
				{Name: "skill install", Description: "Install skill file for Claude Code"},
			},
		},
	}
}

// NewCommandsCmd creates the commands listing command.
func NewCommandsCmd() *cobra.Command {
	return &cobra.Command{
		Use:     "commands",
		Aliases: []string{"cmds"},
		Short:   "List all available commands",
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			categories := CommandCategories()

			if app.IsMachineOutput() {
				return app.OK(categories)
			}

			w := cmd.OutOrStdout()

			// Calculate column widths
			maxCmd := 0
			maxDesc := 0
			for _, cat := range categories {
				for _, c := range cat.Commands {
					if len(c.Name) > maxCmd {
						maxCmd = len(c.Name)
					}
					if len(c.Description) > maxDesc {
						maxDesc = len(c.Description)
					}
				}
			}

			// Header
			fmt.Fprintf(w, "%-*s  %-*s  %s\n",
				maxCmd, "COMMAND", maxDesc, "DESCRIPTION", "FLAGS")
			fmt.Fprintf(w, "%s  %s  %s\n",
				strings.Repeat("-", maxCmd),
				strings.Repeat("-", maxDesc),
				strings.Repeat("-", 20))

			for _, cat := range categories {
				fmt.Fprintf(w, "\n%s\n", cat.Name)
				for _, c := range cat.Commands {
					flags := c.Flags
					if flags == "" {
						flags = ""
					}
					fmt.Fprintf(w, "%-*s  %-*s  %s\n",
						maxCmd, c.Name, maxDesc, c.Description, flags)
				}
			}

			fmt.Fprintf(w, "\nGlobal flags: --json, --md, --quiet, --agent, --url\n")
			return nil
		},
	}
}
