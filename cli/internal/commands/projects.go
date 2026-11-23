package commands

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

	"github.com/spf13/cobra"

	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/config"
	"github.com/victorbitancourt/testy-cli/internal/output"
)

// project is a project (workspace) as returned by the API.
type project struct {
	ID             int    `json:"id"`
	Name           string `json:"name"`
	Description    string `json:"description"`
	TestPlansCount int    `json:"test_plans_count"`
	OpenBugsCount  int    `json:"open_bugs_count"`
}

// NewProjectsCmd creates the projects command group.
func NewProjectsCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:     "projects",
		Aliases: []string{"project", "workspaces", "workspace"},
		Short:   "Manage projects (workspaces)",
		Long: "Each project is a workspace for one application under test: its test plans and bugs stay separate.\n" +
			"Select one with 'testy projects use <id|name>', the --project flag or TESTY_PROJECT.",
	}
	cmd.AddCommand(newProjectsListCmd())
	cmd.AddCommand(newProjectsShowCmd())
	cmd.AddCommand(newProjectsCreateCmd())
	cmd.AddCommand(newProjectsUseCmd())
	cmd.AddCommand(newProjectsCurrentCmd())
	return cmd
}

func newProjectsListCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List projects",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			data, err := app.Client.Get("/api/v1/projects", nil)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				Projects []any `json:"projects"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			return app.OK(resp.Projects,
				output.WithSummary(fmt.Sprintf("%d project(s)", len(resp.Projects))),
			)
		},
	}
}

func newProjectsShowCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "show <id|name>",
		Short: "Show a project",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			p, err := findProject(app, args[0])
			if err != nil {
				return app.Err(err)
			}

			return app.OK(p)
		},
	}
}

func newProjectsCreateCmd() *cobra.Command {
	var (
		description string
		use         bool
	)

	cmd := &cobra.Command{
		Use:   "create <name>",
		Short: "Create a project",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			body := map[string]any{
				"project": map[string]any{
					"name":        args[0],
					"description": description,
				},
			}
			data, err := app.Client.Post("/api/v1/projects", body)
			if err != nil {
				return app.Err(err)
			}

			var resp struct {
				Project project `json:"project"`
			}
			if err := json.Unmarshal(data, &resp); err != nil {
				return app.Err(fmt.Errorf("failed to parse response: %w", err))
			}

			summary := "Project created"
			if use {
				if err := config.SaveProject(strconv.Itoa(resp.Project.ID)); err != nil {
					return app.Err(fmt.Errorf("project created but could not be selected: %w", err))
				}
				summary = fmt.Sprintf("Project created and selected: %s (#%d)", resp.Project.Name, resp.Project.ID)
			}

			return app.OK(resp.Project, output.WithSummary(summary))
		},
	}
	cmd.Flags().StringVar(&description, "description", "", "Project description")
	cmd.Flags().BoolVar(&use, "use", false, "Select the new project for the next commands")
	return cmd
}

func newProjectsUseCmd() *cobra.Command {
	var clear bool

	cmd := &cobra.Command{
		Use:   "use <id|name>",
		Short: "Select the project used by the next commands",
		Args: func(cmd *cobra.Command, args []string) error {
			if clear {
				return cobra.NoArgs(cmd, args)
			}
			return cobra.ExactArgs(1)(cmd, args)
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())

			if clear {
				if err := config.SaveProject(""); err != nil {
					return app.Err(err)
				}
				return app.OK(map[string]any{"project": nil},
					output.WithSummary("Project selection cleared"))
			}

			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			p, err := findProject(app, args[0])
			if err != nil {
				return app.Err(err)
			}

			// Store the id: it survives renames.
			if err := config.SaveProject(strconv.Itoa(p.ID)); err != nil {
				return app.Err(err)
			}

			return app.OK(p, output.WithSummary(fmt.Sprintf("Using project %s (#%d)", p.Name, p.ID)))
		},
	}
	cmd.Flags().BoolVar(&clear, "clear", false, "Forget the selected project")
	return cmd
}

func newProjectsCurrentCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "current",
		Short: "Show the selected project",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			app := appctx.FromContext(cmd.Context())
			if err := requireAuth(app); err != nil {
				return app.Err(err)
			}

			p, source, err := currentProject(app)
			if err != nil {
				return app.Err(err)
			}
			if p == nil {
				return app.Err(output.ErrUsageHint("No project selected and the server has several",
					"Run: testy projects list, then testy projects use <id|name>"))
			}

			return app.OK(map[string]any{
				"project": p,
				"source":  source,
			}, output.WithSummary(fmt.Sprintf("Project %s (#%d), from %s", p.Name, p.ID, source)))
		},
	}
}

// listProjects fetches every project.
func listProjects(app *appctx.App) ([]project, error) {
	data, err := app.Client.Get("/api/v1/projects", nil)
	if err != nil {
		return nil, err
	}
	var resp struct {
		Projects []project `json:"projects"`
	}
	if err := json.Unmarshal(data, &resp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}
	return resp.Projects, nil
}

// findProject finds a project by id or by name (case-insensitive).
func findProject(app *appctx.App, ref string) (*project, error) {
	ref = strings.TrimSpace(ref)
	projects, err := listProjects(app)
	if err != nil {
		return nil, err
	}

	if id, convErr := strconv.Atoi(ref); convErr == nil {
		for i := range projects {
			if projects[i].ID == id {
				return &projects[i], nil
			}
		}
	}
	for i := range projects {
		if strings.EqualFold(projects[i].Name, ref) {
			return &projects[i], nil
		}
	}

	return nil, &output.Error{
		Code:    output.CodeNotFound,
		Message: fmt.Sprintf("Project %q not found", ref),
		Hint:    "Run: testy projects list",
	}
}

// currentProject resolves the selected project (--project, TESTY_PROJECT or
// 'testy projects use'). Without a selection, the only project on the server is
// used, as the API does; with several it returns nil.
func currentProject(app *appctx.App) (*project, string, error) {
	if app.Config.Project != "" {
		p, err := findProject(app, app.Config.Project)
		return p, app.Config.ProjectSource, err
	}

	projects, err := listProjects(app)
	if err != nil {
		return nil, "", err
	}
	if len(projects) == 1 {
		return &projects[0], "only project", nil
	}
	return nil, "", nil
}

// selectedProjectID returns the id of the selected project, or "" when none is
// selected (the API then uses the only project, or every project when listing).
// A numeric selection is used as is, without asking the server.
func selectedProjectID(app *appctx.App) (string, error) {
	ref := strings.TrimSpace(app.Config.Project)
	if ref == "" {
		return "", nil
	}
	if _, err := strconv.Atoi(ref); err == nil {
		return ref, nil
	}
	p, err := findProject(app, ref)
	if err != nil {
		return "", err
	}
	return strconv.Itoa(p.ID), nil
}

// withProjectHint explains how to pick a project when the API refuses a
// create because the server has several and none was given.
func withProjectHint(err error) error {
	if apiErr, ok := err.(*output.Error); ok && strings.Contains(apiErr.Message, "project_id") {
		return &output.Error{
			Code:    output.CodeUsage,
			Message: "The server has several projects and none is selected",
			Hint:    "Pass --project <id|name> or run: testy projects use <id|name>",
		}
	}
	return err
}
