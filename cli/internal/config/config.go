package config

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
)

// Config holds CLI configuration.
type Config struct {
	BaseURL string `json:"base_url"`
	Token   string `json:"-"`
}

// configDir returns the testy config directory (~/.config/testy).
func configDir() string {
	if xdg := os.Getenv("XDG_CONFIG_HOME"); xdg != "" {
		return filepath.Join(xdg, "testy")
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".config", "testy")
}

// TokenPath returns the path to the token file.
func TokenPath() string {
	return filepath.Join(configDir(), "token")
}

// configPath returns the path to the config file.
func configPath() string {
	return filepath.Join(configDir(), "config.json")
}

// Load resolves configuration from flags > env > config file > defaults.
func Load(baseURL string) *Config {
	cfg := &Config{
		BaseURL: "http://localhost:3000",
	}

	// Layer 1: config file
	if data, err := os.ReadFile(configPath()); err == nil {
		_ = json.Unmarshal(data, cfg)
	}

	// Layer 2: environment variables
	if v := os.Getenv("TESTY_BASE_URL"); v != "" {
		cfg.BaseURL = v
	}
	if v := os.Getenv("TESTY_API_TOKEN"); v != "" {
		cfg.Token = v
	}

	// Layer 3: flag override
	if baseURL != "" {
		cfg.BaseURL = baseURL
	}

	// Load token from file if not set via env
	if cfg.Token == "" {
		if data, err := os.ReadFile(TokenPath()); err == nil {
			cfg.Token = strings.TrimSpace(string(data))
		}
	}

	return cfg
}

// SaveToken writes the token to disk.
func SaveToken(token string) error {
	dir := configDir()
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	return os.WriteFile(TokenPath(), []byte(token), 0o600)
}

// RemoveToken deletes the stored token.
func RemoveToken() error {
	return os.Remove(TokenPath())
}
