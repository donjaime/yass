package yass

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"gopkg.in/yaml.v3"
)

// ConfigName is the settings file that can stand in for a yass/ folder and point to one elsewhere.
const ConfigName = "yass.yaml"

// Config is what a yass.yaml holds.
type Config struct {
	// Path is where the yass folder lives: absolute, relative to the yass.yaml, ~/…, or with
	// environment variables ($VAR or ${VAR}), e.g. ${YASS_HOME}/my-project. Empty means yass/ next to it.
	Path string `yaml:"path"`
	// Branch is the code branch that counts as merged when boxes cite code commits.
	// Empty means origin/HEAD, else main, else master.
	Branch string `yaml:"branch"`
}

var knownSettings = map[string]bool{"path": true, "branch": true}

// loadConfig reads a yass.yaml. It also returns any settings this version doesn't know.
func loadConfig(file string) (Config, []string, error) {
	var c Config
	data, err := os.ReadFile(file)
	if err != nil {
		return c, nil, err
	}
	var raw map[string]any
	if err := yaml.Unmarshal(data, &raw); err != nil {
		return c, nil, fmt.Errorf("not valid YAML: %v", err)
	}
	if err := yaml.Unmarshal(data, &c); err != nil {
		return c, nil, fmt.Errorf("not valid YAML: %v", err)
	}
	var unknown []string
	for k := range raw {
		if !knownSettings[k] {
			unknown = append(unknown, k)
		}
	}
	sort.Strings(unknown)
	return c, unknown, nil
}

// resolvePath expands environment variables and ~ in p, and makes it absolute relative to base.
func resolvePath(p, base string) (string, error) {
	var missing []string
	s := os.Expand(p, func(k string) string {
		v := os.Getenv(k)
		if v == "" {
			missing = append(missing, k)
		}
		return v
	})
	if len(missing) > 0 {
		return "", fmt.Errorf("$%s isn't set", missing[0])
	}
	if s == "~" || strings.HasPrefix(s, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		s = home + s[1:]
	}
	if !filepath.IsAbs(s) {
		s = filepath.Join(base, s)
	}
	return canon(s), nil
}

// configDir is the yass folder a yass.yaml points to.
func configDir(file string) (string, Config, []string, error) {
	owner := filepath.Dir(file)
	c, unknown, err := loadConfig(file)
	if err != nil {
		return "", c, nil, err
	}
	if strings.TrimSpace(c.Path) == "" {
		return filepath.Join(owner, "yass"), c, unknown, nil
	}
	dir, err := resolvePath(strings.TrimSpace(c.Path), owner)
	return dir, c, unknown, err
}

func configText(path string) string {
	return `# YASS settings for this folder.
# path: where its yass folder lives. Absolute, relative to this file, ~/…, or with environment
# variables, e.g. ${YASS_HOME}/my-project. Without it, yass/ next to this file.
path: '` + strings.ReplaceAll(path, "'", "''") + "'\n"
}
