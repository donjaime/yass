package yass

import (
	"path/filepath"
	"strings"
)

// YASS fits inside a team's tracker workflow without calling the tracker: the agent moves cards and
// comments, following the playbooks. The binary checks the settings, says which column a change's card
// belongs in, and keeps the private parts of that setup from leaking into a public code repo.

// LocalTracker is the file a yass folder keeps a tracker workflow in when the agent's harness has no
// memory of its own. It's per machine, so git must ignore it.
const LocalTracker = "tracker.local.md"

// checkSettings warns about settings in the wrong place: with plans kept separate, the code repo's
// yass.yaml carries only the pointer (path: and ignore:), and a local tracker file stays out of git.
func (r *Repo) checkSettings() {
	for _, root := range r.Roots {
		if root.Config != "" && !within(root.Config, root.Dir) && r.separate(root) {
			if c, _, err := loadConfig(root.Config); err == nil {
				var moved []string
				if strings.TrimSpace(c.Branch) != "" {
					moved = append(moved, "branch:")
				}
				if c.Archive.Keep > 0 {
					moved = append(moved, "archive:")
				}
				if c.Tracker != nil {
					moved = append(moved, "tracker:")
				}
				if len(moved) > 0 {
					msg := "%s: with plans kept separate, it should carry only path: and ignore:; move %s to %s (with path: .)"
					if c.Tracker != nil {
						msg += ", since this file may be public"
					}
					r.warn(msg, r.disp(root.Config), strings.Join(moved, ", "), filepath.Join(root.Dir, ConfigName))
				}
			}
		}
		f := filepath.Join(root.Dir, LocalTracker)
		if !isFile(f) || gitCommonDir(root.Dir) == "" {
			continue
		}
		if _, ignored := git(root.Dir, "check-ignore", "-q", LocalTracker); !ignored {
			r.warn("%s: keeps this machine's tracker workflow, so git should ignore it; add %s to %s",
				r.disp(f), LocalTracker, r.disp(filepath.Join(root.Dir, ".gitignore")))
		}
	}
}

// card is a change's Trello card and the column its state puts it in, when its yass folder has a board
// and its source: is a card. A top-level change moves to Done when its archive merges; a piece, when
// it's done, since pieces are archived with their change.
func (c *Change) card() (link, column string) {
	if c.Root == nil || c.Root.settings().trello() == "" {
		return "", ""
	}
	link = strings.TrimSpace(c.Meta["source"])
	if !trelloCardRE.MatchString(link) {
		return "", ""
	}
	switch c.state() {
	case "not started":
		return link, "Planning"
	case "done":
		if c.Parent != nil {
			return link, "Done"
		}
		return link, "Implementing, until its archive merges: then Done"
	}
	return link, "Implementing"
}
