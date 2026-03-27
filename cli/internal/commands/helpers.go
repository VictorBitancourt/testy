package commands

import (
	"github.com/victorbitancourt/testy-cli/internal/appctx"
	"github.com/victorbitancourt/testy-cli/internal/output"
)

// requireAuth checks authentication and returns an error if not authenticated.
func requireAuth(app *appctx.App) error {
	if !app.IsAuthenticated() {
		return output.ErrAuth("Not logged in")
	}
	return nil
}
