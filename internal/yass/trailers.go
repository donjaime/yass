package yass

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

// With plans kept outside the code repo, no commit can carry progress next to the code, so every
// code commit names its change in a `yass:` trailer instead (design §2):
//
//	yass: <target> [<key>:<value> ...]
//	target := none | <change> | <change>/<piece> | <piece>
//	key    := ac (the criteria the commit works toward, comma-separated)
//
// The prepare-commit-msg hook adds it, the commit-msg hook and `yass hook --range` check it.

// trailer is one parsed `yass:` trailer.
type trailer struct {
	raw, target string
	ac          []string
	unknown     []string // keys this version doesn't know: a warning, not an error
}

// parseTrailer reads a trailer's value. It's case-insensitive; YASS writes lower case.
func parseTrailer(value string) (trailer, error) {
	t := trailer{raw: strings.TrimSpace(value)}
	f := strings.Fields(strings.ToLower(t.raw))
	if len(f) == 0 {
		return t, fmt.Errorf("it names nothing")
	}
	t.target = f[0]
	if strings.Contains(t.target, ":") {
		return t, fmt.Errorf("it starts with %q, not a change", f[0])
	}
	for _, kv := range f[1:] {
		k, v, ok := strings.Cut(kv, ":")
		if !ok || k == "" || v == "" || strings.HasPrefix(v, ",") || strings.HasSuffix(v, ",") || strings.Contains(v, ",,") {
			return t, fmt.Errorf("%q isn't key:value", kv)
		}
		if k == "ac" {
			t.ac = append(t.ac, strings.Split(v, ",")...)
		} else {
			t.unknown = append(t.unknown, k)
		}
	}
	return t, nil
}

// trailerMode is how this code repo treats trailers: "off" unless its plans are separate, else
// yass.yaml's trailers: (warn by default, require, or off).
func (r *Repo) trailerMode() string {
	if !r.plansSeparate() {
		return "off"
	}
	if c, _, err := loadConfig(filepath.Join(r.Top, ConfigName)); err == nil {
		switch strings.ToLower(strings.TrimSpace(c.Trailers)) {
		case "off":
			return "off"
		case "require":
			return "require"
		}
	}
	return "warn"
}

// plansSeparate: every yass folder this repo uses is outside it, or its yass.yaml points outside
// it to a folder that isn't here (CI without the plans checked out).
func (r *Repo) plansSeparate() bool {
	if gitCommonDir(r.Top) == "" {
		return false
	}
	if len(r.Roots) == 0 {
		c, _, err := loadConfig(filepath.Join(r.Top, ConfigName))
		if err != nil || strings.TrimSpace(c.Path) == "" {
			return false
		}
		dir, err := resolvePath(strings.TrimSpace(c.Path), r.Top)
		return err == nil && !within(dir, r.Top)
	}
	for _, root := range r.Roots {
		if !r.separate(root) {
			return false
		}
	}
	return true
}

// targets maps every name a trailer can use, lower-cased, to the change it means: change folders
// (active, archived, evicted), <change>/<piece>, and a piece's own name when it's unambiguous.
func (r *Repo) targets() (named map[string]string, ambiguous map[string]bool) {
	named, ambiguous = map[string]string{}, map[string]bool{}
	r.archivedPieces()
	all := append(r.everything(), flatten(r.Archived)...)
	for _, c := range all {
		if c.Parent == nil {
			named[strings.ToLower(c.Name)] = strings.ToLower(c.Name)
			continue
		}
		label := strings.ToLower(c.label())
		named[label] = label
		n := strings.ToLower(c.Name)
		if prev, ok := named[n]; ok && prev != label {
			ambiguous[n] = true
		}
		named[n] = label
	}
	for n := range ambiguous {
		delete(named, n)
	}
	return named, ambiguous
}

// checkTarget says what's wrong with a trailer's target, if anything; names are nil when the
// plans aren't here to check against.
func checkTarget(t trailer, named map[string]string, ambiguous map[string]bool) string {
	if t.target == "none" || named == nil {
		return ""
	}
	if _, ok := named[t.target]; ok {
		return ""
	}
	if ambiguous[t.target] {
		return fmt.Sprintf("'%s' is the name of pieces in more than one change; give it as <change>/<piece>", t.target)
	}
	msg := fmt.Sprintf("'%s' isn't a change or piece", t.target)
	if near := closest(t.target, named, 3); len(near) > 0 {
		msg += "; did you mean " + strings.Join(near, ", ") + "?"
	}
	return msg
}

// closest are up to n names nearest to s by edit distance.
func closest(s string, named map[string]string, n int) []string {
	type cand struct {
		name string
		d    int
	}
	var cs []cand
	for k := range named {
		if d := editDistance(s, k); d <= max(3, len(s)/2) {
			cs = append(cs, cand{k, d})
		}
	}
	sort.Slice(cs, func(i, j int) bool { return cs[i].d < cs[j].d || cs[i].d == cs[j].d && cs[i].name < cs[j].name })
	var out []string
	for i := 0; i < len(cs) && i < n; i++ {
		out = append(out, cs[i].name)
	}
	return out
}

func editDistance(a, b string) int {
	prev := make([]int, len(b)+1)
	for j := range prev {
		prev[j] = j
	}
	for i := 1; i <= len(a); i++ {
		cur := make([]int, len(b)+1)
		cur[0] = i
		for j := 1; j <= len(b); j++ {
			cost := 1
			if a[i-1] == b[j-1] {
				cost = 0
			}
			cur[j] = min(prev[j]+1, cur[j-1]+1, prev[j-1]+cost)
		}
		prev = cur
	}
	return prev[len(b)]
}

// messageTrailers are the `yass:` trailers in a commit message, comment lines left out.
func messageTrailers(msg string) []string {
	var keep []string
	for _, l := range strings.Split(normalize(msg), "\n") {
		if !strings.HasPrefix(l, "#") {
			keep = append(keep, l)
		}
	}
	cmd := exec.Command("git", "interpret-trailers", "--parse")
	cmd.Stdin = strings.NewReader(strings.Join(keep, "\n"))
	out, _ := cmd.Output()
	var vals []string
	for _, l := range strings.Split(string(out), "\n") {
		if k, v, ok := strings.Cut(l, ":"); ok && strings.EqualFold(strings.TrimSpace(k), "yass") {
			vals = append(vals, strings.TrimSpace(v))
		}
	}
	return vals
}

// trailerProblems checks a message's trailers: problems fail under trailers: require, notes never do.
func trailerProblems(msg string, named map[string]string, ambiguous map[string]bool) (problems, notes []string) {
	vals := messageTrailers(msg)
	if len(vals) == 0 {
		return []string{"no `yass:` trailer naming its change (`yass use <change>` adds one to every commit here; `yass: none` for a commit that belongs to no change)"}, nil
	}
	for _, v := range vals {
		t, err := parseTrailer(v)
		if err != nil {
			problems = append(problems, fmt.Sprintf("`yass: %s` is malformed: %v", v, err))
			continue
		}
		if p := checkTarget(t, named, ambiguous); p != "" {
			problems = append(problems, fmt.Sprintf("`yass: %s`: %s", v, p))
		}
		for _, k := range t.unknown {
			notes = append(notes, fmt.Sprintf("`yass: %s`: this yass doesn't know the key '%s'", v, k))
		}
	}
	return problems, notes
}

// useFile is where `yass use` keeps this worktree's change: in its own git folder, never committed.
func useFile() string {
	out, ok := git("", "rev-parse", "--path-format=absolute", "--git-dir")
	if !ok {
		return ""
	}
	return filepath.Join(strings.TrimSpace(out), "yass-use")
}

// inferTarget works out a commit's trailer: `yass use`, else the branch named after a change or
// piece (exactly, or after a prefix like jaime/), else an earlier commit's trailer on the branch.
func (r *Repo) inferTarget(named map[string]string) string {
	if f := useFile(); f != "" {
		if v := strings.TrimSpace(read(f)); v != "" {
			return v
		}
	}
	if b, ok := git("", "symbolic-ref", "--short", "-q", "HEAD"); ok {
		b = strings.ToLower(strings.TrimSpace(b))
		for _, cand := range []string{b, b[strings.LastIndex(b, "/")+1:]} {
			if label, ok := named[cand]; ok {
				return label
			}
		}
	}
	root := &Root{}
	if len(r.Roots) > 0 {
		root = r.Roots[0]
	}
	if merged := r.mergedBranch(root); merged != "" {
		out, _ := git("", "log", "--format=%(trailers:key=yass,valueonly,separator=%x00)", merged+"..HEAD")
		for _, l := range strings.Split(out, "\n") {
			if v := strings.TrimSpace(strings.Split(l, "\x00")[0]); v != "" {
				return strings.ToLower(v)
			}
		}
	}
	return ""
}

// prepareMsg is the prepare-commit-msg hook: add the trailer, unless there's one already, it's a
// merge, or trailers are off. It never fails a commit.
func prepareMsg(file, source string) {
	if source == "merge" {
		return
	}
	if _, merging := git("", "rev-parse", "-q", "--verify", "MERGE_HEAD"); merging {
		return
	}
	r := loadRepo()
	if r.trailerMode() == "off" || len(messageTrailers(read(file))) > 0 {
		return
	}
	var named map[string]string
	if len(r.Roots) > 0 {
		named, _ = r.targets()
	}
	if t := r.inferTarget(named); t != "" {
		git("", "interpret-trailers", "--in-place", "--trailer", "yass: "+t, file)
	}
}

// commitMsg is the commit-msg hook: check the trailers; under trailers: require, refuse.
func commitMsg(file string) int {
	if _, merging := git("", "rev-parse", "-q", "--verify", "MERGE_HEAD"); merging {
		return 0
	}
	r := loadRepo()
	mode := r.trailerMode()
	if mode == "off" {
		return 0
	}
	var named map[string]string
	var ambiguous map[string]bool
	if len(r.Roots) > 0 {
		named, ambiguous = r.targets()
	}
	problems, notes := trailerProblems(read(file), named, ambiguous)
	for _, n := range notes {
		fmt.Fprintf(os.Stderr, "yass: %s\n", n)
	}
	if len(problems) == 0 {
		return 0
	}
	verb := "heads-up"
	if mode == "require" {
		verb = "refusing the commit (trailers: require)"
	}
	fmt.Fprintf(os.Stderr, "yass: %s: this commit should name its change, since the plans are kept apart from the code\n", verb)
	for _, p := range problems {
		fmt.Fprintf(os.Stderr, "  - %s\n", p)
	}
	if mode == "require" {
		return 1
	}
	return 0
}

// rangeTrailers checks the trailers of every non-merge commit in a range, for CI. names is false
// when the plans aren't here, so only the grammar is checked.
func (r *Repo) rangeTrailers(shas []string) (found []string, names bool) {
	var named map[string]string
	var ambiguous map[string]bool
	if len(r.Roots) > 0 {
		named, ambiguous = r.targets()
	}
	for _, sha := range shas {
		msg, _ := git("", "log", "-1", "--format=%B", sha)
		problems, _ := trailerProblems(msg, named, ambiguous)
		if len(problems) == 0 {
			continue
		}
		subj, _ := git("", "log", "-1", "--format=%h %s", sha)
		for _, p := range problems {
			found = append(found, strings.TrimSpace(subj)+": "+p)
		}
	}
	return found, named != nil
}

// cmdUse sets, shows or clears the change this worktree's commits name.
func cmdUse(a *args) error {
	f := useFile()
	if f == "" {
		return fmt.Errorf("yass use works inside a git repo")
	}
	if a.b["clear"] {
		os.Remove(f)
		fmt.Println("yass use: cleared; commits here get their change from the branch name or earlier commits")
		return nil
	}
	if len(a.pos) == 0 {
		if v := strings.TrimSpace(read(f)); v != "" {
			fmt.Println(v)
		} else {
			fmt.Println("none set (yass use <change>)")
		}
		return nil
	}
	r := loadRepo()
	c, err := r.resolve(a.pos[0], nil, false)
	if err != nil {
		return err
	}
	v := strings.ToLower(c.label())
	if ac := strings.ToLower(strings.ReplaceAll(a.v["ac"], " ", "")); ac != "" {
		v += " ac:" + ac
	}
	if err := write(f, v+"\n"); err != nil {
		return err
	}
	fmt.Printf("yass use: commits in this worktree now carry `yass: %s`\n", v)
	if r.trailerMode() == "off" {
		fmt.Println("(the plans are in this repo, so commits don't need trailers; it's kept, and used if that changes)")
	}
	return nil
}

// trailerCommit is a merged commit whose trailer names a change.
type trailerCommit struct{ sha, subject string }

// changeCode is a change's merged code, found by trailers (R16, R21): the commits naming it or one
// of its pieces, those commits by the criteria their ac: names, and warnings for an ac: naming a
// criterion the plan doesn't have. One git log over the merged branch, filtered by git.
func (r *Repo) changeCode(c *Change) (commits []trailerCommit, byAC map[string][]trailerCommit, branch string, warnings []string) {
	if r.trailerMode() == "off" {
		return nil, nil, "", nil
	}
	if branch = r.mergedBranch(c.Root); branch == "" {
		return nil, nil, "", nil
	}
	named, _ := r.targets()
	me := strings.ToLower(c.label())
	top := c
	if c.Parent != nil {
		top = c.Parent
	}
	criteria := map[string]bool{}
	for _, b := range top.ownBoxes() {
		if m := criterionRE.FindStringSubmatch(b.text); m != nil && b.file == "plan.md" {
			criteria["AC"+m[1]] = true
		}
	}
	out, _ := git(r.Top, "log", branch, "-i", "--grep=^yass:", "--format=%h%x1f%s%x1f%(trailers:key=yass,valueonly,separator=%x1e)%x00")
	byAC = map[string][]trailerCommit{}
	for _, rec := range strings.Split(out, "\x00") {
		f := strings.SplitN(strings.TrimLeft(rec, "\n"), "\x1f", 3)
		if len(f) < 3 {
			continue
		}
		tc := trailerCommit{f[0], f[1]}
		matched := false
		for _, v := range strings.Split(strings.TrimSpace(f[2]), "\x1e") {
			t, err := parseTrailer(v)
			if err != nil {
				continue
			}
			label := named[t.target]
			if label != me && !(c.Parent == nil && strings.HasPrefix(label, me+"/")) {
				continue
			}
			matched = true
			for _, ac := range t.ac {
				id := strings.ToUpper(ac)
				if len(criteria) > 0 && !criteria[id] {
					warnings = append(warnings, fmt.Sprintf("%s's trailer names %s, which %s's plan doesn't have", tc.sha, id, top.Name))
					continue
				}
				byAC[id] = append(byAC[id], tc)
			}
		}
		if matched {
			commits = append(commits, tc)
		}
	}
	return commits, byAC, branch, warnings
}
