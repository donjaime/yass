package yass

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestResolvePath(t *testing.T) {
	base := t.TempDir()
	t.Setenv("YASS_TEST_HOME", "/srv/plans")
	t.Setenv("YASS_TEST_EMPTY", "")
	home, _ := os.UserHomeDir()
	for in, want := range map[string]string{
		"../elsewhere":               filepath.Join(filepath.Dir(base), "elsewhere"),
		"planning":                   filepath.Join(base, "planning"),
		"/abs/yass":                  "/abs/yass",
		"$YASS_TEST_HOME":            "/srv/plans",
		"${YASS_TEST_HOME}/my-repo":  "/srv/plans/my-repo",
		"~/yass/my-repo":             filepath.Join(home, "yass", "my-repo"),
		"${YASS_TEST_HOME:-..}/web":  "/srv/plans/web",
		"${YASS_TEST_UNSET:-..}/web": filepath.Join(filepath.Dir(base), "web"),
		"${YASS_TEST_EMPTY:-~/p}":    filepath.Join(home, "p"),
		"${YASS_TEST_UNSET:-}":       base,
	} {
		got, err := resolvePath(in, base)
		if err != nil || got != canon(want) {
			t.Errorf("resolvePath(%q) = %q, %v; want %q", in, got, err, canon(want))
		}
	}
	if _, err := resolvePath("${YASS_TEST_UNSET}/x", base); err == nil || err.Error() != "$YASS_TEST_UNSET isn't set" {
		t.Errorf("unset variable: %v", err)
	}
}

func TestConfigTextRoundTrips(t *testing.T) {
	f := filepath.Join(t.TempDir(), ConfigName)
	for _, p := range []string{"../private", "${YASS_HOME}/it's mine", `C:\plans`} {
		os.WriteFile(f, []byte(configText(p)), 0o644)
		c, unknown, err := loadConfig(f)
		if err != nil || c.Path != p || len(unknown) != 0 {
			t.Errorf("round trip %q: got %q %v %v", p, c.Path, unknown, err)
		}
	}
	os.WriteFile(f, []byte("path: x\ncolor: blue\n"), 0o644)
	if _, unknown, _ := loadConfig(f); len(unknown) != 1 || unknown[0] != "color" {
		t.Errorf("unknown = %v", unknown)
	}
}

func TestCanonResolvesMissingPathsThroughSymlinks(t *testing.T) {
	real := t.TempDir()
	link := filepath.Join(t.TempDir(), "link")
	if err := os.Symlink(real, link); err != nil {
		t.Skip("no symlinks here")
	}
	want := filepath.Join(canon(real), "not", "there")
	if got := canon(filepath.Join(link, "not", "there")); got != want {
		t.Errorf("canon = %q, want %q", got, want)
	}
}

func TestArchiveKeep(t *testing.T) {
	dir := t.TempDir()
	f := filepath.Join(dir, ConfigName)
	os.WriteFile(f, []byte("archive:\n  keep: 3\n  kepp: 4\n"), 0o644)
	c, unknown, err := loadConfig(f)
	if err != nil || c.Archive.Keep != 3 || len(unknown) != 1 || unknown[0] != "archive.kepp" {
		t.Fatalf("loadConfig = %+v, %v, %v", c, unknown, err)
	}
	if k := (&Root{Config: f}).keep(); k != 3 {
		t.Fatalf("keep = %d, want 3", k)
	}
	if k := (&Root{}).keep(); k != DefaultKeep {
		t.Fatalf("keep without a yass.yaml = %d, want %d", k, DefaultKeep)
	}
}

const trelloOK = `tracker:
  trello:
    board: https://trello.com/b/AbC123/payments
    lists:
      ideas: 64f0a1
      will-do: 64f0a2
      planning: 64f0a3
      implementing: 64f0a4
      done: 64f0a5
`

func TestTrackerSettings(t *testing.T) {
	f := filepath.Join(t.TempDir(), ConfigName)
	for name, tc := range map[string]struct {
		yaml string
		want []string
	}{
		"a whole trello board":                         {trelloOK, nil},
		"other trackers are the team's own, any shape": {"tracker:\n  jira:\n    site: https://acme.atlassian.net\n    project: PAY\n    boards: [1, 2]\n  acme-pm: anything\n", nil},
		"a list missing": {strings.Replace(trelloOK, "      done: 64f0a5\n", "", 1),
			[]string{"tracker.trello.lists.done: missing; set it to the list's Trello ID"}},
		"an empty list ID": {strings.Replace(trelloOK, "done: 64f0a5", "done: ''", 1),
			[]string{"tracker.trello.lists.done: missing; set it to the list's Trello ID"}},
		"not a board link": {strings.Replace(trelloOK, "https://trello.com/b/AbC123/payments", "https://trello.com/c/AbC123", 1),
			[]string{"tracker.trello.board: 'https://trello.com/c/AbC123' isn't a Trello board link (https://trello.com/b/…)"}},
		"no board": {strings.Replace(trelloOK, "    board: https://trello.com/b/AbC123/payments\n", "", 1),
			[]string{"tracker.trello.board: missing; set it to the board's link (https://trello.com/b/…)"}},
		"unknown keys under trello and lists": {strings.Replace(trelloOK, "    lists:\n", "    labels: x\n    lists:\n      backlog: 1\n", 1),
			[]string{"tracker.trello: unknown setting 'labels' (trello takes board: and lists:)",
				"tracker.trello.lists: unknown list 'backlog' (the lists are ideas, will-do, planning, implementing, done)"}},
		"no lists": {"tracker:\n  trello:\n    board: https://trello.com/b/AbC123\n",
			[]string{"tracker.trello.lists: missing; it maps each list (ideas, will-do, planning, implementing, done) to its Trello ID"}},
		"not a section": {"tracker: trello\n", []string{"tracker: should be a section with one key per tracker (trello:, or your own)"}},
	} {
		os.WriteFile(f, []byte(tc.yaml), 0o644)
		c, unknown, err := loadConfig(f)
		if err != nil || len(unknown) != 0 || strings.Join(c.problems, "\n") != strings.Join(tc.want, "\n") {
			t.Errorf("%s: problems %q, unknown %v, err %v; want %q", name, c.problems, unknown, err, tc.want)
		}
	}
}

func TestOwnSettingsWin(t *testing.T) {
	top := t.TempDir()
	plans := filepath.Join(top, "plans")
	os.MkdirAll(filepath.Join(plans, "changes"), 0o755)
	pointer := filepath.Join(top, ConfigName)
	os.WriteFile(pointer, []byte("path: plans\nbranch: main\narchive:\n  keep: 5\n"), 0o644)
	own := filepath.Join(plans, ConfigName)
	os.WriteFile(own, []byte("path: .\nbranch: trunk\n"+trelloOK), 0o644)
	root := &Root{Dir: plans, Config: pointer, Own: own}
	s := root.settings()
	if s.Branch != "trunk" || s.Archive.Keep != 5 || s.trello() != "https://trello.com/b/AbC123/payments" {
		t.Fatalf("settings = branch %q keep %d board %q", s.Branch, s.Archive.Keep, s.trello())
	}
	inline := filepath.Join(top, "yass")
	os.MkdirAll(filepath.Join(inline, "archive"), 0o755)
	if !ownConfig(filepath.Join(inline, ConfigName)) || ownConfig(pointer) || ownConfig(own) {
		t.Errorf("ownConfig: only a yass/ folder's own yass.yaml is one (a plans folder's says path: .)")
	}
}

func TestCardColumn(t *testing.T) {
	dir := t.TempDir()
	own := filepath.Join(dir, ConfigName)
	os.WriteFile(own, []byte(trelloOK), 0o644)
	root := &Root{Dir: dir, Config: own}
	card := "https://trello.com/c/Xy12/fix"
	n := 0
	mk := func(box string, parent *Change) *Change {
		n++
		p := filepath.Join(dir, "changes", fmt.Sprintf("2026-11-14-c%d", n))
		os.MkdirAll(p, 0o755)
		os.WriteFile(filepath.Join(p, "change.md"), []byte("---\nsource: "+card+"\n---\n# C\n\n## Steps\n"+box+"\n"), 0o644)
		return newChange(p, root, parent)
	}
	parent := mk("- [ ] a", nil)
	for _, tc := range []struct {
		c    *Change
		want string
	}{
		{mk("- [ ] a", nil), "Planning"},
		{mk("- [/] a", nil), "Implementing"},
		{mk("- [x] a", nil), "Implementing, until its archive merges: then Done"},
		{mk("- [x] a", parent), "Done"},
	} {
		if link, col := tc.c.card(); link != card || col != tc.want {
			t.Errorf("card() = %q, %q; want %q", link, col, tc.want)
		}
	}
	if link, _ := (&Change{Root: root, Meta: map[string]string{"source": "gh#41"}}).card(); link != "" {
		t.Errorf("a source that isn't a card: %q", link)
	}
	if link, _ := (&Change{Root: &Root{Dir: dir}, Meta: map[string]string{"source": card}}).card(); link != "" {
		t.Errorf("no board: %q", link)
	}
}
