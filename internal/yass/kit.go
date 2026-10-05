package yass

import (
	"fmt"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/donjaime/yass/kit"
)

// binVersion is this binary's version, as Main receives it; the stamps written into a repo use it.
var binVersion = "dev"

// HookPath is where the hook script lives in a repo, and what --hooks points core.hooksPath at.
const HookPath = "tools/yass/githooks"

var metadataRE = regexp.MustCompile(`(?m)^metadata:[ \t]*$`)

// stampVersion is the version as it's written into files: without a leading "v".
func stampVersion() string { return strings.TrimPrefix(binVersion, "v") }

// stampSkill adds metadata.yass-version to a playbook's frontmatter (the Agent Skills spec's
// extension point), replacing any yass-version already there.
func stampSkill(text, version string) string {
	m := fmRE.FindStringSubmatchIndex(text)
	if m == nil {
		return text
	}
	front := text[m[2]:m[3]]
	line := fmt.Sprintf("  yass-version: %q", version)
	var out []string
	for _, l := range lines(front) {
		if !strings.HasPrefix(strings.TrimSpace(l), "yass-version:") {
			out = append(out, l)
		}
	}
	front = strings.Join(out, "\n")
	if loc := metadataRE.FindStringIndex(front); loc != nil {
		front = front[:loc[1]] + "\n" + line + front[loc[1]:]
	} else {
		front += "\nmetadata:\n" + line
	}
	return text[:m[2]] + front + text[m[3]:]
}

// stampHook adds a "# yass-version:" line after the hook script's first line.
func stampHook(text, version string) string {
	first, rest, _ := strings.Cut(text, "\n")
	return first + "\n# yass-version: " + version + "\n" + rest
}

// stampAgents adds version=V to the AGENTS.md section's begin marker.
func stampAgents(block, version string) string {
	return strings.Replace(block, "<!-- yass:begin ", "<!-- yass:begin version="+version+" ", 1)
}

// kitSkills lists the playbooks the binary carries: name and unstamped text, sorted by name.
func kitSkills() (names []string, text map[string]string) {
	text = map[string]string{}
	matches, _ := fs.Glob(kit.FS, ".agents/skills/*/SKILL.md")
	for _, m := range matches {
		b, _ := kit.FS.ReadFile(m)
		name := path.Base(path.Dir(m))
		names, text[name] = append(names, name), string(b)
	}
	sort.Strings(names)
	return names, text
}

// userSkillsDir is where --global puts the playbooks: $YASS_SKILLS_DIR, or ~/.agents/skills.
func userSkillsDir() string {
	if d := os.Getenv("YASS_SKILLS_DIR"); d != "" {
		return d
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".agents", "skills")
}

func userClaudeSkillsDir() string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".claude", "skills")
}

// writeKit writes the playbooks (in the repo, or the user folder with global), Claude Code's copies
// and the CLAUDE.md import (with claude), and the hook script, all stamped with this binary's
// version. Files that already exist are kept. It returns the files it wrote.
func writeKit(top string, claude, global bool) ([]string, error) {
	var made []string
	place := func(p, text string, mode os.FileMode) error {
		if exists(p) {
			return nil
		}
		if err := write(p, text); err != nil {
			return err
		}
		if mode != 0 {
			if err := os.Chmod(p, mode); err != nil {
				return err
			}
		}
		made = append(made, p)
		return nil
	}
	v := stampVersion()
	skills, claudeSkills := filepath.Join(top, ".agents", "skills"), filepath.Join(top, ".claude", "skills")
	if global {
		skills, claudeSkills = userSkillsDir(), userClaudeSkillsDir()
	}
	names, text := kitSkills()
	for _, n := range names {
		stamped := stampSkill(text[n], v)
		if err := place(filepath.Join(skills, n, "SKILL.md"), stamped, 0); err != nil {
			return made, err
		}
		if claude {
			if err := place(filepath.Join(claudeSkills, n, "SKILL.md"), stamped, 0); err != nil {
				return made, err
			}
		}
	}
	hook, _ := kit.FS.ReadFile(HookPath + "/pre-commit")
	if err := place(filepath.Join(top, filepath.FromSlash(HookPath), "pre-commit"), stampHook(string(hook), v), 0o755); err != nil {
		return made, err
	}
	if claude {
		cm := filepath.Join(top, "CLAUDE.md")
		if cur := read(cm); !strings.Contains(cur, "@AGENTS.md") {
			next := "@AGENTS.md\n"
			if cur != "" {
				next += "\n" + cur
			}
			if err := write(cm, next); err != nil {
				return made, err
			}
			made = append(made, cm)
		}
	}
	return made, nil
}
