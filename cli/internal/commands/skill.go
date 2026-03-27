package commands

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/output"
	"github.com/victorbitancourt/testy-cli/internal/version"
	"github.com/victorbitancourt/testy-cli/skills"
)

// NewSkillCmd creates the skill command.
func NewSkillCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "skill",
		Short: "Manage the embedded agent skill file",
		RunE: func(cmd *cobra.Command, args []string) error {
			// Default: print the SKILL.md contents
			data, err := skills.FS.ReadFile("testy/SKILL.md")
			if err != nil {
				return fmt.Errorf("failed to read embedded SKILL.md: %w", err)
			}
			fmt.Fprint(cmd.OutOrStdout(), string(data))
			return nil
		},
	}
	cmd.AddCommand(newSkillInstallCmd())
	return cmd
}

func newSkillInstallCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "install",
		Short: "Install the skill file for Claude Code",
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())

			data, err := skills.FS.ReadFile("testy/SKILL.md")
			if err != nil {
				return app.Err(fmt.Errorf("failed to read embedded SKILL.md: %w", err))
			}

			home, err := os.UserHomeDir()
			if err != nil {
				return app.Err(fmt.Errorf("cannot determine home directory: %w", err))
			}

			// Install to ~/.claude/skills/testy/SKILL.md
			skillDir := filepath.Join(home, ".claude", "skills", "testy")
			if err := os.MkdirAll(skillDir, 0o755); err != nil {
				return app.Err(fmt.Errorf("failed to create skill directory: %w", err))
			}

			skillPath := filepath.Join(skillDir, "SKILL.md")
			if err := os.WriteFile(skillPath, data, 0o644); err != nil {
				return app.Err(fmt.Errorf("failed to write SKILL.md: %w", err))
			}

			// Write version marker for auto-refresh
			versionPath := filepath.Join(skillDir, ".installed-version")
			_ = os.WriteFile(versionPath, []byte(version.Version), 0o644)

			return app.OK(map[string]string{
				"path":    skillPath,
				"version": version.Version,
			}, output.WithSummary(fmt.Sprintf("Skill installed at %s", skillPath)))
		},
	}
}

// RefreshSkillIfVersionChanged checks if the installed skill version matches
// the current CLI version and re-installs if different.
func RefreshSkillIfVersionChanged() bool {
	home, err := os.UserHomeDir()
	if err != nil {
		return false
	}

	versionPath := filepath.Join(home, ".claude", "skills", "testy", ".installed-version")
	data, err := os.ReadFile(versionPath)
	if err != nil {
		return false // Not installed
	}

	if string(data) == version.Version {
		return false // Already up to date
	}

	// Re-install
	skillData, err := skills.FS.ReadFile("testy/SKILL.md")
	if err != nil {
		return false
	}

	skillDir := filepath.Join(home, ".claude", "skills", "testy")
	skillPath := filepath.Join(skillDir, "SKILL.md")
	if err := os.WriteFile(skillPath, skillData, 0o644); err != nil {
		return false
	}
	_ = os.WriteFile(versionPath, []byte(version.Version), 0o644)
	return true
}
