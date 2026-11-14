package yass

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"gopkg.in/yaml.v3"
)

// ConfigName is the settings file that can stand in for a yass/ folder and point to one elsewhere.
const ConfigName = "yass.yaml"

// Config is what a yass.yaml holds.
type Config struct {
	// Path is where the yass folder lives: absolute, relative to the yass.yaml, ~/…, or with
	// environment variables ($VAR, ${VAR}, or ${VAR:-default} for when it's unset), e.g.
	// ${YASS_HOME:-..}/my-project. Empty means yass/ next to it.
	Path string `yaml:"path"`
	// Branch is the code branch that counts as merged when boxes cite code commits.
	// Empty means origin/HEAD, else main, else master.
	Branch string `yaml:"branch"`
	// Ignore lists folders, relative to the yass.yaml, whose yass folders and yass.yaml files belong
	// to something else (examples, fixtures, vendored projects). From inside one, it's a project of its own.
	Ignore []string `yaml:"ignore"`
	// Archive holds the archive's settings.
	Archive struct {
		// Keep is how many archived changes (pieces count with their change) the yass folder's working
		// tree should keep: a soft limit. Past it, yass status says to run yass evict. 0 means the default.
		Keep int `yaml:"keep"`
	} `yaml:"archive"`
	// Tracker names the external tracker that governs the yass folder, one key per tool. trello has a
	// shape YASS checks (design §1); any other key is the team's own, stored as-is and never checked.
	// YASS never calls a tracker: the agent does, and reads these to know where.
	Tracker map[string]any `yaml:"-"` // read from the raw YAML, so a malformed one is a warning, not a broken yass.yaml

	problems []string // what's wrong with settings this version knows, worded for a warning
}

// DefaultKeep is how many archived changes a yass folder keeps when its yass.yaml doesn't say.
const DefaultKeep = 2000

var knownSettings = map[string]bool{"path": true, "branch": true, "ignore": true, "archive": true, "tracker": true}

// TrelloLists are the roles of a Trello board's lists, in board order.
var TrelloLists = []string{"ideas", "will-do", "planning", "implementing", "done"}

var (
	trelloBoardRE = regexp.MustCompile(`^https://trello\.com/b/[A-Za-z0-9]+(/\S*)?$`)
	trelloCardRE  = regexp.MustCompile(`^https://trello\.com/c/[A-Za-z0-9]+(/\S*)?$`)
)

var knownArchiveSettings = map[string]bool{"keep": true}

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
	for k, v := range raw {
		if !knownSettings[k] {
			unknown = append(unknown, k)
		}
		if sub, ok := v.(map[string]any); ok && k == "archive" {
			for sk := range sub {
				if !knownArchiveSettings[sk] {
					unknown = append(unknown, k+"."+sk)
				}
			}
		}
	}
	sort.Strings(unknown)
	c.problems = trackerProblems(raw["tracker"])
	if t, ok := raw["tracker"].(map[string]any); ok {
		c.Tracker = t
	}
	return c, unknown, nil
}

// trackerProblems checks a tracker: section. Only trello is YASS's; other keys are the team's own.
func trackerProblems(v any) []string {
	if v == nil {
		return nil
	}
	t, ok := v.(map[string]any)
	if !ok {
		return []string{"tracker: should be a section with one key per tracker (trello:, or your own)"}
	}
	tv, has := t["trello"]
	if !has {
		return nil
	}
	tr, ok := tv.(map[string]any)
	if !ok {
		return []string{"tracker.trello: should be a section with board: and lists:"}
	}
	var out []string
	for _, k := range sortedAnyKeys(tr) {
		if k != "board" && k != "lists" {
			out = append(out, fmt.Sprintf("tracker.trello: unknown setting '%s' (trello takes board: and lists:)", k))
		}
	}
	switch b, _ := tr["board"].(string); {
	case strings.TrimSpace(b) == "":
		out = append(out, "tracker.trello.board: missing; set it to the board's link (https://trello.com/b/…)")
	case !trelloBoardRE.MatchString(strings.TrimSpace(b)):
		out = append(out, fmt.Sprintf("tracker.trello.board: '%s' isn't a Trello board link (https://trello.com/b/…)", b))
	}
	lists, ok := tr["lists"].(map[string]any)
	if !ok {
		return append(out, "tracker.trello.lists: missing; it maps each list ("+strings.Join(TrelloLists, ", ")+") to its Trello ID")
	}
	known := map[string]bool{}
	for _, k := range TrelloLists {
		known[k] = true
		if id := fmt.Sprint(lists[k]); lists[k] == nil || strings.TrimSpace(id) == "" {
			out = append(out, fmt.Sprintf("tracker.trello.lists.%s: missing; set it to the list's Trello ID", k))
		}
	}
	for _, k := range sortedAnyKeys(lists) {
		if !known[k] {
			out = append(out, fmt.Sprintf("tracker.trello.lists: unknown list '%s' (the lists are %s)", k, strings.Join(TrelloLists, ", ")))
		}
	}
	return out
}

func sortedAnyKeys(m map[string]any) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

// trello is the Trello board these settings name, if they name one.
func (c Config) trello() string {
	tr, _ := c.Tracker["trello"].(map[string]any)
	b, _ := tr["board"].(string)
	return strings.TrimSpace(b)
}

// ownConfig says whether a yass.yaml is a yass folder's own settings rather than a pointer: one in a
// yass/ folder with changes/ or archive/ in it (design §2). A plans folder's own yass.yaml says
// path: . and is both.
func ownConfig(file string) bool {
	owner := filepath.Dir(file)
	return filepath.Base(owner) == "yass" && (isDir(filepath.Join(owner, "changes")) || isDir(filepath.Join(owner, "archive")))
}

// resolvePath expands environment variables and ~ in p, and makes it absolute relative to base.
// ${VAR:-default} uses default when VAR is unset or empty, so side-by-side clones need no setup.
func resolvePath(p, base string) (string, error) {
	var missing []string
	s := os.Expand(p, func(k string) string {
		k, def, hasDef := strings.Cut(k, ":-")
		v := os.Getenv(k)
		if v == "" && hasDef {
			return def
		}
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

// ignoredDirs resolves a yass.yaml's ignore list (folders, or glob patterns like examples/*) to
// folders inside the folder it sits in, and says what's wrong with any entry it can't use.
func ignoredDirs(file string, c Config) ([]string, []string) {
	owner := filepath.Dir(file)
	var dirs, bad []string
	for _, e := range c.Ignore {
		e = strings.TrimSpace(e)
		if e == "" {
			continue
		}
		if filepath.IsAbs(filepath.FromSlash(e)) || !within(filepath.Join(owner, filepath.FromSlash(e)), owner) {
			bad = append(bad, fmt.Sprintf("ignore: '%s' isn't inside the folder yass.yaml is in", e))
			continue
		}
		matches, err := filepath.Glob(filepath.Join(owner, filepath.FromSlash(e)))
		if err != nil {
			bad = append(bad, fmt.Sprintf("ignore: '%s' isn't a valid pattern", e))
			continue
		}
		n, self := 0, false
		for _, m := range matches {
			if d := canon(m); d == owner {
				self = true
			} else if isDir(d) {
				dirs = append(dirs, d)
				n++
			}
		}
		if self {
			bad = append(bad, fmt.Sprintf("ignore: '%s' is the folder yass.yaml is in", e))
		} else if n == 0 {
			bad = append(bad, fmt.Sprintf("ignore: '%s' doesn't match a folder under the one yass.yaml is in", e))
		}
	}
	return dirs, bad
}

func configText(path string) string {
	return `# YASS settings for this folder.
# path: where its yass folder lives. Absolute, relative to this file, ~/…, or with environment
# variables, e.g. ${YASS_HOME}/my-project or ${YASS_HOME:-..}/my-project (.. when it's unset).
# Without it, yass/ next to this file.
# ignore: a list of folders (or patterns like examples/*) whose yass folders belong to something else.
path: '` + strings.ReplaceAll(path, "'", "''") + "'\n"
}
