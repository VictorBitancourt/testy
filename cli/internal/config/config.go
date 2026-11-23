package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Config holds CLI configuration.
type Config struct {
	BaseURL string `json:"base_url"`
	Token   string `json:"-"`
	// Project is the selected project (workspace), by id or name.
	Project string `json:"project,omitempty"`
	// ProjectSource says where Project came from: flag, env or config.
	ProjectSource string `json:"-"`
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
func Load(baseURL, project string) *Config {
	cfg := &Config{
		BaseURL: "http://localhost:3000",
	}

	// Layer 1: config file
	if data, err := os.ReadFile(configPath()); err == nil {
		_ = json.Unmarshal(data, cfg)
	}
	if cfg.Project != "" {
		cfg.ProjectSource = "config"
	}

	// Layer 2: environment variables
	if v := os.Getenv("TESTY_BASE_URL"); v != "" {
		cfg.BaseURL = v
	}
	if v := os.Getenv("TESTY_API_TOKEN"); v != "" {
		cfg.Token = v
	}
	if v := os.Getenv("TESTY_PROJECT"); v != "" {
		cfg.Project, cfg.ProjectSource = v, "env"
	}

	// Layer 3: flag override
	if baseURL != "" {
		cfg.BaseURL = baseURL
	}
	if project != "" {
		cfg.Project, cfg.ProjectSource = project, "flag"
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

// SaveProject stores the selected project in the config file, keeping the
// other settings. An empty project clears the selection.
func SaveProject(project string) error {
	settings := map[string]any{}
	if data, err := os.ReadFile(configPath()); err == nil {
		if err := json.Unmarshal(data, &settings); err != nil {
			return fmt.Errorf("cannot parse %s: %w", configPath(), err)
		}
	}

	if project == "" {
		delete(settings, "project")
	} else {
		settings["project"] = project
	}

	if err := os.MkdirAll(configDir(), 0o700); err != nil {
		return err
	}
	data, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(configPath(), append(data, '\n'), 0o600)
}
