package yass

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

// The personal memory (design §1, §2): one global settings.json in the user's config folder, with an
// entry per clone, read and written only by `yass me`. Agents run the CLI instead of opening the file,
// since their file permissions usually stop at the project's folders. A clone is keyed by its git
// common dir, which every worktree shares; another clone gets its own entry.

// SettingsFile is the global settings file's name, in the user's config folder.
const SettingsFile = "settings.json"

// Me is this clone's personal memory: who you are, and your team's yass folders here.
type Me struct {
	File    string   `json:"-"`
	Clone   string   `json:"clone"`
	Repo    string   `json:"repo"`
	Name    string   `json:"name"`
	Team    string   `json:"team"`
	Folders []string `json:"folders"`
	Notes   string   `json:"notes"`
	Saved   bool     `json:"saved"` // whether this clone has an entry yet
}

// userConfigDir is where YASS keeps a person's files: $YASS_CONFIG_DIR, else %APPDATA%\yass on
// Windows, else ${XDG_CONFIG_HOME:-~/.config}/yass.
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

// cloneKey names a clone: the first 8 hex characters of a SHA-256 of its git common dir.
func cloneKey(common string) string {
	sum := sha256.Sum256([]byte(filepath.Clean(common)))
	return hex.EncodeToString(sum[:])[:8]
}

// settings is the global file, kept as raw JSON so keys YASS doesn't know survive a write.
type settings struct {
	file string
	raw  map[string]json.RawMessage
}

func readSettings() (*settings, error) {
	dir, err := userConfigDir()
	if err != nil {
		return nil, err
	}
	s := &settings{file: filepath.Join(dir, SettingsFile), raw: map[string]json.RawMessage{}}
	b, err := os.ReadFile(s.file)
	if os.IsNotExist(err) {
		return s, nil
	}
	if err != nil {
		return nil, err
	}
	if err := json.Unmarshal(b, &s.raw); err != nil {
		return nil, fmt.Errorf("%s isn't valid JSON: %v", s.file, err)
	}
	return s, nil
}

// clones is the per-clone part, each entry kept raw for the same reason.
func (s *settings) clones() map[string]map[string]json.RawMessage {
	out := map[string]map[string]json.RawMessage{}
	if c, ok := s.raw["clones"]; ok {
		json.Unmarshal(c, &out)
	}
	return out
}

// write saves the file atomically: a temp file in the same folder, then a rename, so two agents
// saving at once can't leave it half written.
func (s *settings) write() error {
	if err := os.MkdirAll(filepath.Dir(s.file), 0o755); err != nil {
		return err
	}
	b, err := json.MarshalIndent(s.raw, "", "  ")
	if err != nil {
		return err
	}
	f, err := os.CreateTemp(filepath.Dir(s.file), ".settings-*.json")
	if err != nil {
		return err
	}
	if _, err := f.Write(append(b, '\n')); err != nil {
		f.Close()
		os.Remove(f.Name())
		return err
	}
	if err := f.Close(); err != nil {
		os.Remove(f.Name())
		return err
	}
	return os.Rename(f.Name(), s.file)
}

// loadMe reads this clone's memory. With no entry yet, Saved is false and the name comes from git.
func loadMe(top string) (*Me, *settings, error) {
	common := gitCommonDir(top)
	if common == "" {
		return nil, nil, fmt.Errorf("the personal memory is per clone, so it needs a git repo")
	}
	s, err := readSettings()
	if err != nil {
		return nil, nil, err
	}
	m := &Me{File: s.file, Clone: cloneKey(common), Repo: filepath.Dir(filepath.Clean(common))}
	if filepath.Base(common) != ".git" {
		m.Repo = filepath.Clean(common) // a bare repo
	}
	json.Unmarshal(s.raw["name"], &m.Name)
	if e, ok := s.clones()[m.Clone]; ok {
		m.Saved = true
		json.Unmarshal(e["team"], &m.Team)
		json.Unmarshal(e["folders"], &m.Folders)
		json.Unmarshal(e["notes"], &m.Notes)
	}
	if m.Name == "" {
		n, _ := git(top, "config", "user.name")
		m.Name = strings.TrimSpace(n)
	}
	for i, f := range m.Folders {
		m.Folders[i] = filepath.ToSlash(filepath.Clean(strings.TrimSpace(f)))
	}
	if m.Folders == nil {
		m.Folders = []string{}
	}
	return m, s, nil
}

// saveMe writes this clone's entry, and the name, keeping everything else in the file.
func saveMe(m *Me, s *settings) error {
	name, _ := json.Marshal(m.Name)
	s.raw["name"] = name
	clones := s.clones()
	e := clones[m.Clone]
	if e == nil {
		e = map[string]json.RawMessage{}
	}
	for k, v := range map[string]any{"repo": m.Repo, "team": m.Team, "folders": m.Folders, "notes": m.Notes} {
		b, _ := json.Marshal(v)
		e[k] = b
	}
	clones[m.Clone] = e
	cb, _ := json.Marshal(clones)
	s.raw["clones"] = cb
	return s.write()
}

func cmdMe(a *args) error {
	r := findRepo()
	m, s, err := loadMe(r.Top)
	if err != nil {
		return err
	}
	_, setName := a.v["name"]
	_, setTeam := a.v["team"]
	_, setFolders := a.v["folders"]
	_, setNotes := a.v["notes"]
	if setName || setTeam || setFolders || setNotes {
		if setName {
			m.Name = strings.TrimSpace(a.v["name"])
		}
		if setTeam {
			m.Team = strings.TrimSpace(a.v["team"])
		}
		if setNotes {
			m.Notes = a.v["notes"]
		}
		if setFolders {
			m.Folders = []string{}
			for _, f := range strings.Split(a.v["folders"], ",") {
				if f = strings.TrimSpace(f); f != "" {
					m.Folders = append(m.Folders, filepath.ToSlash(filepath.Clean(f)))
				}
			}
			if _, unknown := r.myRoots(m); len(unknown) > 0 {
				return fmt.Errorf("not a yass folder here: %s (yass root lists them)", strings.Join(unknown, ", "))
			}
		}
		if err := saveMe(m, s); err != nil {
			return err
		}
		m.Saved = true
	}
	if a.b["json"] {
		b, _ := json.MarshalIndent(m, "", "  ")
		fmt.Println(string(b))
		return nil
	}
	saved := ""
	if !m.Saved {
		saved = "  (not saved yet: set a field, e.g. yass me --folders <yass folder>)"
	}
	fmt.Printf("%s, this clone (%s)%s\n", m.File, m.Clone, saved)
	fmt.Printf("name:    %s\nteam:    %s\nfolders: %s\nnotes:   %s\n", m.Name, m.Team, strings.Join(m.Folders, ", "), m.Notes)
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

// checkMe warns about folders the memory names that aren't yass folders here (a hand edit, or a
// folder since removed), and about a settings file that can't be read.
func (r *Repo) checkMe() *Me {
	m, _, err := loadMe(r.Top)
	if err != nil {
		if gitCommonDir(r.Top) != "" {
			r.warn("%v", err)
		}
		return nil
	}
	if _, unknown := r.myRoots(m); len(unknown) > 0 {
		r.warn("%s: folders: %s isn't a yass folder here (yass me --folders sets them)", m.File, strings.Join(unknown, ", "))
	}
	return m
}
