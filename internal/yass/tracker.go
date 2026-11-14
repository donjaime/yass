package yass

import (
	"path/filepath"
	"strings"
)

// YASS fits inside a team's tracker workflow without calling the tracker: the agent moves cards and
// comments, following the playbooks. The binary checks the settings, says which column a change's card
// belongs in, and keeps the private parts of that setup from leaking into a public code repo.

// checkSettings checks each yass folder's settings.yaml (design §2), and notes a yass.yaml that points
// to plans outside the repo and that git would commit with settings beyond the pointer: those may leak
// private setup, so a human should check. It's a note, not a warning.
func (r *Repo) checkSettings() {
	for _, root := range r.Roots {
		if f := filepath.Join(root.Dir, SettingsName); isFile(f) {
			own, unknown, err := loadConfig(f)
			if err != nil {
				r.warn("%s: %v", r.disp(f), err)
			}
			for _, k := range unknown {
				r.warn("%s: unknown setting '%s' (a newer yass may know it)", r.disp(f), k)
			}
			for _, p := range own.problems {
				r.warn("%s: %s", r.disp(f), p)
			}
			if strings.TrimSpace(own.Path) != "" || len(own.Ignore) > 0 {
				r.warn("%s: path: and ignore: belong in yass.yaml, which says where the yass folder is; here they're ignored", r.disp(f))
			}
			if root.Config != "" {
				if pc, _, err := loadConfig(root.Config); err == nil {
					if _, differ := overlay(pc, own); len(differ) > 0 {
						r.warn("%s and %s give %s different values; %s's are used", r.disp(root.Config), r.disp(f), strings.Join(differ, ", "), SettingsName)
					}
				}
			}
		}
		if root.Config != "" && within(root.Config, r.Top) && !within(root.Config, root.Dir) && r.separate(root) {
			if _, ignored := git(r.Top, "check-ignore", "-q", root.Config); !ignored {
				if c, _, err := loadConfig(root.Config); err == nil {
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
						r.note("%s points to plans outside the repo, and git would commit it with %s, which may be private; check that's intentional, or move them to %s",
							r.disp(root.Config), strings.Join(extra, ", "), filepath.Join(root.Dir, SettingsName))
					}
				}
			}
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
