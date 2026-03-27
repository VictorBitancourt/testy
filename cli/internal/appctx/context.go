package appctx

import (
	"context"
	"os"

	"github.com/victorbitancourt/testy-cli/internal/client"
	"github.com/victorbitancourt/testy-cli/internal/config"
	"github.com/victorbitancourt/testy-cli/internal/output"
)

type contextKey string

const appKey contextKey = "app"

// GlobalFlags holds values for global CLI flags.
type GlobalFlags struct {
	JSON  bool
	MD    bool
	Quiet bool
	Agent bool
}

// App holds the shared application context for all commands.
type App struct {
	Config *config.Config
	Client *client.Client
	Output *output.Writer
	Flags  GlobalFlags
}

// NewApp creates a new App.
func NewApp(cfg *config.Config) *App {
	c := client.New(cfg.BaseURL, cfg.Token)
	w := output.New(output.FormatAuto, os.Stdout)

	return &App{
		Config: cfg,
		Client: c,
		Output: w,
	}
}

// ApplyFlags configures output based on global flags.
func (a *App) ApplyFlags() {
	var format output.Format
	switch {
	case a.Flags.Agent || a.Flags.Quiet:
		format = output.FormatQuiet
	case a.Flags.JSON:
		format = output.FormatJSON
	case a.Flags.MD:
		format = output.FormatMarkdown
	default:
		format = output.FormatAuto
	}
	a.Output = output.New(format, os.Stdout)
}

// OK outputs a success response.
func (a *App) OK(data any, opts ...output.ResponseOption) error {
	return a.Output.OK(data, opts...)
}

// Err outputs an error response.
func (a *App) Err(err error) error {
	return a.Output.Err(err)
}

// IsAuthenticated checks if a token is available.
func (a *App) IsAuthenticated() bool {
	return a.Config.Token != ""
}

// IsMachineOutput returns true for programmatic output modes.
func (a *App) IsMachineOutput() bool {
	return a.Flags.Agent || a.Flags.Quiet || a.Flags.JSON
}

// WithApp stores the app in the context.
func WithApp(ctx context.Context, app *App) context.Context {
	return context.WithValue(ctx, appKey, app)
}

// FromContext retrieves the app from the context.
func FromContext(ctx context.Context) *App {
	app, _ := ctx.Value(appKey).(*App)
	return app
}
