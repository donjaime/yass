package yass

import (
	"fmt"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"regexp"
	"strings"
)

// The optional pre-commit check: progress travels with code; intent changes get their own commit.
//
// It warns when one commit changes code and also edits existing intent in a yass folder: prd.md,
// design.md, plan.md beyond marking boxes, a yass folder's queue.md, or a change's title, Goal or
// Acceptance. Writing new intent files is fine. Marking boxes and appending to Log and Decisions
// alongside code is expected and never flagged. Editing the archive is always flagged: it's append-only.

var (
	hookBoxRE = regexp.MustCompile(`^(\s*[-*+]\s+)\[[ xX/]\]`) // starting, ticking or unticking is progress; dropping ([-]) is not
	h1RE      = regexp.MustCompile(`(?m)^# .*$`)
)

type entry struct{ status, path, oldPath string }

type place struct {
	kind   string // "changes", "archive", "queue", "meta", or "" for code
	fname  string
	folder string // for the archive: the archived change's folder
}

type hook struct {
	prefixes []string // yass folders inside the repo that yass.yaml files point to, repo-relative
	ignored  []string // folders a yass.yaml ignores, repo-relative: their files are ordinary files
}

func newHook() *hook {
	h := &hook{}
	// Only the yass folders, seen from the top (git's paths are relative to it); no changes are read.
	r := &Repo{}
	r.Top = repoTop(getwd())
	r.Cwd = r.Top
	r.findRoots()
	for _, d := range r.Ignored {
		rel, _ := filepath.Rel(r.Top, d)
		h.ignored = append(h.ignored, filepath.ToSlash(rel))
	}
	for _, root := range r.Roots {
		if root.Config != "" && within(root.Dir, r.Top) && root.Dir != r.Top {
			rel, _ := filepath.Rel(r.Top, root.Dir)
			h.prefixes = append(h.prefixes, filepath.ToSlash(rel))
		}
	}
	return h
}

func (h *hook) where(p string) place {
	for _, d := range h.ignored {
		if strings.HasPrefix(p, d+"/") {
			return place{}
		}
	}
	parts := strings.Split(p, "/")
	if path.Base(p) == ConfigName {
		return place{kind: "meta"}
	}
	for _, pre := range h.prefixes {
		if !strings.HasPrefix(p, pre+"/") {
			continue
		}
		rest := strings.Split(strings.TrimPrefix(p, pre+"/"), "/")
		if len(rest) == 1 && rest[0] == QueueName {
			return place{kind: "queue", fname: QueueName}
		}
		if len(rest) >= 2 && (rest[0] == "changes" || rest[0] == "archive") {
			return place{rest[0], parts[len(parts)-1], pre + "/" + changeFolder(rest)}
		}
		return place{kind: "meta"}
	}
	for i := 0; i < len(parts)-1; i++ {
		if parts[i] == "yass" && (parts[i+1] == "changes" || parts[i+1] == "archive") {
			return place{parts[i+1], parts[len(parts)-1], strings.Join(parts[:i+1], "/") + "/" + changeFolder(parts[i+1:])}
		}
	}
	if len(parts) >= 2 && parts[len(parts)-2] == "yass" && parts[len(parts)-1] == QueueName {
		return place{kind: "queue", fname: QueueName}
	}
	if len(parts) >= 2 && parts[len(parts)-2] == "yass" && parts[len(parts)-1] == "README.md" {
		return place{kind: "meta"}
	}
	return place{}
}

// changeFolder is the change's folder in a path that starts at changes/ or archive/: the folder
// right under it, or, in the archive, the one under <YYYY>/<MM>/.
func changeFolder(rest []string) string {
	n := 2
	if rest[0] == "archive" && len(rest) >= 4 && yearRE.MatchString(rest[1]) && monthRE.MatchString(rest[2]) {
		n = 4
	}
	if n > len(rest) {
		n = len(rest)
	}
	return strings.Join(rest[:n], "/")
}

func norm(text string) []string {
	var out []string
	for _, l := range lines(commentRE.ReplaceAllString(text, "")) {
		l = strings.TrimRight(hookBoxRE.ReplaceAllString(l, "${1}[ ]"), " \t")
		if strings.TrimSpace(l) != "" {
			out = append(out, l)
		}
	}
	return out
}

func intentOfChangeMD(text string) string {
	parts := []string{}
	if m := h1RE.FindString(text); m != "" {
		parts = append(parts, m)
	}
	parts = append(parts, norm(section(text, "Goal"))...)
	parts = append(parts, "--")
	parts = append(parts, norm(section(text, "Acceptance"))...)
	return strings.Join(parts, "\n")
}

// show is a file at a commit; ref "" is the index (what's staged).
func show(ref, p string) string {
	out, _ := git("", "show", ref+":"+p)
	return normalize(out)
}

func (h *hook) check(entries []entry, oldRef, newRef string) []string {
	places := map[string]place{}
	hasCode := false
	for _, e := range entries {
		places[e.path] = h.where(e.path)
		if places[e.path].kind == "" {
			hasCode = true
		}
	}
	var out []string
	for _, e := range entries {
		pl := places[e.path]
		if pl.kind == "" || pl.kind == "meta" || pl.fname == ".gitkeep" {
			continue
		}
		fromChanges := strings.HasPrefix(e.status, "R") && h.where(e.oldPath).kind == "changes"
		if pl.kind == "queue" {
			if hasCode && e.status[0] != 'A' {
				out = append(out, e.path+": queue.md is intent; reorder in a commit without code")
			}
			continue
		}
		if pl.kind == "archive" {
			addedToOld := false
			if e.status[0] == 'A' && oldRef != "" {
				_, addedToOld = git("", "cat-file", "-e", oldRef+":"+pl.folder)
			}
			if strings.HasPrefix(e.status, "M") || strings.HasPrefix(e.status, "D") || addedToOld ||
				(strings.HasPrefix(e.status, "R") && !fromChanges) {
				out = append(out, e.path+": the archive is append-only; follow-up work is a new change with `follows:`")
			} else if fromChanges && hasCode {
				out = append(out, e.path+": archive a change in its own commit, not alongside code")
			}
			continue
		}
		if !hasCode || e.status[0] == 'A' {
			continue // new intent isn't a moved goalpost
		}
		oldP := e.oldPath
		if oldP == "" {
			oldP = e.path
		}
		old, cur := "", ""
		if oldRef != "" {
			old = show(oldRef, oldP)
		}
		if e.status[0] != 'D' {
			cur = show(newRef, e.path)
		}
		switch pl.fname {
		case "prd.md", "design.md":
			out = append(out, fmt.Sprintf("%s: %s is intent; change it in a commit without code", e.path, pl.fname))
		case "plan.md":
			if e.status[0] == 'D' || strings.Join(norm(old), "\n") != strings.Join(norm(cur), "\n") {
				out = append(out, e.path+": with code, only mark boxes in plan.md; revise the plan in its own commit")
			}
		case "change.md":
			if e.status[0] == 'D' {
				out = append(out, e.path+": removing a change alongside code")
			} else if intentOfChangeMD(old) != intentOfChangeMD(cur) {
				out = append(out, e.path+": the title, Goal or Acceptance changed; that's intent, so give it its own commit")
			}
		}
	}
	return out
}

// nameStatus lists what a diff changed. With -z, paths come raw (no quoting of non-ASCII names) and
// NUL-separated: "M\0path\0", or "R100\0old\0new\0" for renames and copies.
func nameStatus(args ...string) []entry {
	out, _ := git("", append([]string{"diff", "--name-status", "-M", "-z"}, args...)...)
	f := strings.Split(strings.TrimSuffix(out, "\x00"), "\x00")
	var rows []entry
	for i := 0; i+1 < len(f); {
		status := f[i]
		if (status[0] == 'R' || status[0] == 'C') && i+2 < len(f) {
			rows = append(rows, entry{status, f[i+2], f[i+1]})
			i += 3
		} else {
			rows = append(rows, entry{status, f[i+1], ""})
			i += 2
		}
	}
	return rows
}

func emptyTree() string {
	cmd := exec.Command("git", "hash-object", "-t", "tree", "--stdin")
	cmd.Stdin = strings.NewReader("")
	out, _ := cmd.Output()
	return strings.TrimSpace(string(out))
}

func cmdHook(a *args) int {
	switch strings.ToLower(os.Getenv("YASS_HOOK")) {
	case "off", "0", "false":
		return 0
	}
	strict := a.b["strict"] || (os.Getenv("YASS_STRICT") != "" && os.Getenv("YASS_STRICT") != "0")
	h := newHook()
	var found []string
	if rng, ok := a.v["range"]; ok {
		shas, ok := git("", "rev-list", "--reverse", "--no-merges", rng)
		if rng == "" || !ok {
			fmt.Fprintf(os.Stderr, "yass: can't read the range '%s'. In CI, fetch history first (e.g. actions/checkout with fetch-depth: 0).\n", rng)
			return 2
		}
		for _, sha := range strings.Fields(shas) {
			parent, _ := git("", "rev-parse", "-q", "--verify", sha+"^")
			parent = strings.TrimSpace(parent)
			base := parent
			if base == "" {
				base = emptyTree()
			}
			if w := h.check(nameStatus(base, sha), parent, sha); len(w) > 0 {
				subj, _ := git("", "log", "-1", "--format=%h %s", sha)
				for _, x := range w {
					found = append(found, strings.TrimSpace(subj)+": "+x)
				}
			}
		}
	} else {
		if _, merging := git("", "rev-parse", "-q", "--verify", "MERGE_HEAD"); merging {
			return 0
		}
		head := ""
		if _, ok := git("", "rev-parse", "-q", "--verify", "HEAD"); ok {
			head = "HEAD"
		}
		base := head
		if base == "" {
			base = emptyTree()
		}
		found = h.check(nameStatus("--cached", base), head, "")
	}
	if len(found) == 0 {
		return 0
	}
	verb := "heads-up"
	if strict {
		verb = "refusing"
	}
	fmt.Fprintf(os.Stderr, "yass: %s: code and intent are mixed (progress travels with code; intent gets its own commit)\n", verb)
	for _, f := range found {
		fmt.Fprintf(os.Stderr, "  - %s\n", f)
	}
	if !strict {
		fmt.Fprintln(os.Stderr, "  (a warning only; YASS_STRICT=1 makes it an error, YASS_HOOK=off skips it)")
		return 0
	}
	return 1
}
