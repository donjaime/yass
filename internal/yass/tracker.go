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

// checkSettings notes a yass.yaml that points to plans outside the repo and that git would commit
// with settings beyond the pointer (design §2): those describe private plans, so a human should check
// that publishing them is intentional. It's a note, not a warning. And a local tracker file stays out of git.
func (r *Repo) checkSettings() {
	for _, root := range r.Roots {
		if root.Config != "" && within(root.Config, r.Top) && !within(root.Config, root.Dir) && r.separate(root) {
			if _, ignored := git(r.Top, "check-ignore", "-q", root.Config); !ignored {
				c := root.settings()
				var extra []string
				if strings.TrimSpace(c.Branch) != "" {
					extra = append(extra, "branch:")
				}
				if c.Archive.Keep > 0 {
					extra = append(extra, "archive:")
				}
				if c.Tracker != nil {
					extra = append(extra, "tracker:")
				}
				if len(extra) > 0 {
					r.note("%s points to plans outside the repo, and git would commit it with %s; check that's intentional, or keep the file out of git (it works from there too)",
						r.disp(root.Config), strings.Join(extra, ", "))
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
