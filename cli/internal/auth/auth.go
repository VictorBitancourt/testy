package auth

import (
	"encoding/json"
	"os"

	"github.com/victorbitancourt/testy-cli/internal/client"
	"github.com/victorbitancourt/testy-cli/internal/config"
)

// LoginResponse is the response from POST /api/v1/auth/login.
type LoginResponse struct {
	Token string       `json:"token"`
	User  LoginUser    `json:"user"`
}

// LoginUser is the user info in the login response.
type LoginUser struct {
	ID       int    `json:"id"`
	Username string `json:"username"`
	Role     string `json:"role"`
}

// Login authenticates and saves the token.
func Login(c *client.Client, username, password string) (*LoginResponse, error) {
	body := map[string]string{
		"username": username,
		"password": password,
	}
	data, err := c.Post("/api/v1/auth/login", body)
	if err != nil {
		return nil, err
	}

	var resp LoginResponse
	if err := json.Unmarshal(data, &resp); err != nil {
		return nil, err
	}

	if err := config.SaveToken(resp.Token); err != nil {
		return nil, err
	}

	return &resp, nil
}

// Logout removes the token locally and revokes on the server.
func Logout(c *client.Client) error {
	// Try to revoke on server (ignore errors — token may already be invalid)
	_ = c.Delete("/api/v1/auth/logout")
	return config.RemoveToken()
}

// IsLoggedIn checks if a token file exists.
func IsLoggedIn() bool {
	_, err := os.Stat(config.TokenPath())
	return err == nil
}
