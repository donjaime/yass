package yass

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

// The personal memory (design §1, §2): one markdown file per clone, in the user's own folder, that
// says who you are, your team and your yass folders. Every worktree of a clone shares its git common
// dir, so they all find the same file; another clone gets its own. Nothing about it is in the repo.

// Me is what the personal memory's frontmatter says.
type Me struct {
	File    string
	Name    string
	Team    string
	Folders []string // yass folders by path from the repo top, as yass status prints them
	Unknown []string // keys the binary doesn't read
	Exists  bool
}

var meKeys = map[string]bool{"name": true, "team": true, "folders": true}

// userConfigDir is where YASS keeps a person's files: $YASS_CONFIG_DIR, else %APPDATA%\yass on Windows,
// else ${XDG_CONFIG_HOME:-~/.config}/yass.
func userConfigDir() (string, error) {
	if d := os.Getenv("YASS_CONFIG_DIR"); d != "" {
		return d, nil
	}
	if runtime.GOOS == "windows" {
		if d := os.Getenv("APPDATA"); d != "" {
			return filepath.Join(d, "yass"), nil
		}
	}
	if d := os.Getenv("XDG_CONFIG_HOME"); d != "" {
		return filepath.Join(d, "yass"), nil
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(home, ".config", "yass"), nil
}

// memoryFile is the personal memory's path for the clone dir is in: clones/<repo>-<id>.md, where <id>
// is the first 8 hex characters of a SHA-256 of the clone's git common dir.
func memoryFile(top string) (string, error) {
	common := gitCommonDir(top)
	if common == "" {
		return "", fmt.Errorf("the personal memory is per clone, so it needs a git repo")
	}
	dir, err := userConfigDir()
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256([]byte(filepath.Clean(common)))
	name := filepath.Base(filepath.Dir(common)) // the main checkout, for worktrees too
	if filepath.Base(common) != ".git" {
		name = strings.TrimSuffix(filepath.Base(common), ".git") // a bare repo
	}
	return filepath.Join(dir, "clones", fmt.Sprintf("%s-%s.md", name, hex.EncodeToString(sum[:])[:8])), nil
}

// loadMe reads the personal memory for this repo's clone. No file is a Me with Exists false.
func loadMe(top string) (*Me, error) {
	f, err := memoryFile(top)
	if err != nil {
		return nil, err
	}
	m := &Me{File: f}
	b, err := os.ReadFile(f)
	if err != nil {
		return m, nil
	}
	m.Exists = true
	meta, _ := frontmatter(string(b))
	m.Name, m.Team = meta["name"], meta["team"]
	for _, p := range strings.Split(meta["folders"], ",") {
		if p = strings.Trim(strings.TrimSpace(p), `"'`); p != "" {
			m.Folders = append(m.Folders, filepath.ToSlash(filepath.Clean(p)))
		}
	}
	for _, k := range sortedKeys(keySet(meta)) {
		if !meKeys[k] {
			m.Unknown = append(m.Unknown, k)
		}
	}
	return m, nil
}

func keySet(m map[string]string) map[string]bool {
	out := map[string]bool{}
	for k := range m {
		out[k] = true
	}
	return out
}

// meTemplate is a new personal memory: who you are from git, no folders yet (yass-init fills them in).
func meTemplate(name string) string {
	return `---
name: ` + name + `
team:
folders: []
---
# Notes for agents
<!-- Yours alone, for this clone: who you are and which yass folders are your team's (folders:, by
     path from the repo top, as yass status prints them; the first is where yass new puts a change from
     the repo root). Anything you'd tell an agent every session goes here. What your team shares goes
     in its yass folder's team.md instead. -->
`
}

func cmdMe(a *args) error {
	r := findRepo()
	m, err := loadMe(r.Top)
	if err != nil {
		return err
	}
	if !m.Exists {
		name, _ := git(r.Top, "config", "user.name")
		if err := os.MkdirAll(filepath.Dir(m.File), 0o755); err != nil {
			return err
		}
		if err := os.WriteFile(m.File, []byte(meTemplate(strings.TrimSpace(name))), 0o644); err != nil {
			return err
		}
		fmt.Printf("created %s\n", m.File)
	} else {
		fmt.Println(m.File)
	}
	b, err := os.ReadFile(m.File)
	if err != nil {
		return err
	}
	fmt.Print("\n" + string(b))
	return nil
}

// myRoots are the yass folders the personal memory names, in its order. A folder can be named by
// the yass folder's path or, for a team folder, the folder it serves (services/search for
// services/search/yass/).
func (r *Repo) myRoots(m *Me) (mine []*Root, unknown []string) {
	for _, f := range m.Folders {
		var hit *Root
		for _, root := range r.Roots {
			dir, owner := filepath.ToSlash(r.disp(root.Dir)), filepath.ToSlash(r.disp(root.Owner))
			if f == dir || (root.Owner != r.Top && f == owner) {
				hit = root
				break
			}
		}
		if hit == nil {
			unknown = append(unknown, f)
		} else {
			mine = append(mine, hit)
		}
	}
	return mine, unknown
}

// checkMe notes keys the memory has that the binary doesn't read (it's your own file) and warns
// about folders it names that aren't yass folders here.
func (r *Repo) checkMe() *Me {
	m, err := loadMe(r.Top)
	if err != nil || !m.Exists {
		return m
	}
	for _, k := range m.Unknown {
		r.note("%s: '%s' isn't something yass reads (it reads name:, team: and folders:)", m.File, k)
	}
	if _, unknown := r.myRoots(m); len(unknown) > 0 {
		r.warn("%s: folders: %s isn't a yass folder here", m.File, strings.Join(unknown, ", "))
	}
	return m
}
