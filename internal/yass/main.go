// Package yass is the YASS CLI: planned work as change folders.
//
// Planned work lives in yass/changes/<date>-<slug>/, finished work in yass/archive/. A small change
// is a change.md. A large one adds prd.md, plan.md, an optional design.md, and PR-sized pieces as
// folders inside it. Any folder named yass/ with changes/ or archive/ in it is picked up, so a
// monorepo can have several. A yass.yaml can stand in for a yass/ folder and point to one elsewhere.
package yass

import (
	"fmt"
	"os"
	"strings"
)

const usage = `yass: Yet Another Spec System. Planned work as change folders.

usage: yass <command> [options]

  init [dir] [--path P] [--agents]      set up YASS: the yass folder, and for the repo itself the
       [--claude] [--global] [--hooks]  AGENTS.md section, the playbooks and the hook script; for a
       [--no-agents] [--private]        folder (dir), only its planning, or with --agents its own
                                        AGENTS.md section and playbooks too (the hook stays at the root);
                                        --path writes a yass.yaml pointing to P;
                                        --claude adds Claude Code's copies and the CLAUDE.md import;
                                        --global puts the playbooks in your user folder; --hooks turns
                                        the hook on; --no-agents skips AGENTS.md, the playbooks and the
                                        hook; --private keeps dir out of git, for this clone only
  upgrade                               bring every YASS file in the repo (playbooks, AGENTS.md sections,
                                        the hook) and your user folder's playbooks up to this version
  new "<title>" [--large] [--design]    a change: a dated folder from a template
      [--in CHANGE] [--goal G] [--platforms P] [--source S] [--follows ARCHIVED]
  status [<change>] [--archived] [--strict]
                                        what's in flight, or one change in detail
  archive <change> [--force]            move a finished change to the archive
  decisions [--since D] [--until D] [--about TEXT] [--change C] [--limit N] [--json]
                                        past decisions, active and archived, newest first
  root                                  print the yass folder(s) this repo uses
  paths [--only RANGE]                  the repo paths that are YASS's, as globs (for CI filters);
                                        --only exits 0 if a commit range touches nothing else
  template <name>                       print a template: change, change-large, prd, plan, design
  hook [--range A..B] [--strict]        the optional pre-commit check (also for CI)
  version

With no command, yass runs status.
`

type spec struct {
	bools, values  []string
	minPos, maxPos int
	use            string
}

var specs = map[string]spec{
	"init":    {[]string{"no-agents", "private", "claude", "global", "hooks", "agents"}, []string{"path"}, 0, 1, "yass init [dir] [--path P] [--agents] [--claude] [--global] [--hooks] [--no-agents] [--private]"},
	"new":     {[]string{"large", "design"}, []string{"in", "goal", "platforms", "source", "follows"}, 1, 1, `yass new "<title>" [--large] [--design] [--in CHANGE] [--goal G] [--platforms P] [--source S] [--follows ARCHIVED]`},
	"status":  {[]string{"archived", "strict"}, nil, 0, 1, "yass status [<change>] [--archived] [--strict]"},
	"archive": {[]string{"force"}, nil, 1, 1, "yass archive <change> [--force]"},
	"decisions": {[]string{"json"}, []string{"since", "until", "about", "change", "limit"}, 0, 0,
		"yass decisions [--since YYYY-MM-DD] [--until YYYY-MM-DD] [--about TEXT] [--change C] [--limit N] [--json]"},
	"root":     {nil, nil, 0, 0, "yass root"},
	"paths":    {nil, []string{"only"}, 0, 0, "yass paths [--only RANGE]"},
	"template": {nil, nil, 1, 1, "yass template <change|change-large|prd|plan|design|readme|agents>"},
	"hook":     {[]string{"strict"}, []string{"range"}, 0, 0, "yass hook [--range A..B] [--strict]"},
	"upgrade":  {nil, nil, 0, 0, "yass upgrade"},
	"version":  {nil, nil, 0, 0, "yass version"},
}

type args struct {
	pos []string
	b   map[string]bool
	v   map[string]string
}

func contains(list []string, s string) bool {
	for _, x := range list {
		if x == s {
			return true
		}
	}
	return false
}

// parse reads options anywhere among the positionals: --flag, --name value, --name=value.
func parse(sp spec, argv []string) (*args, error) {
	a := &args{b: map[string]bool{}, v: map[string]string{}}
	for i := 0; i < len(argv); i++ {
		arg := argv[i]
		if arg == "--" {
			a.pos = append(a.pos, argv[i+1:]...)
			break
		}
		if !strings.HasPrefix(arg, "--") {
			a.pos = append(a.pos, arg)
			continue
		}
		name, val, hasVal := strings.Cut(arg[2:], "=")
		switch {
		case contains(sp.bools, name) && !hasVal:
			a.b[name] = true
		case contains(sp.values, name):
			if !hasVal {
				if i+1 >= len(argv) {
					return nil, fmt.Errorf("--%s needs a value", name)
				}
				i++
				val = argv[i]
			}
			a.v[name] = val
		default:
			return nil, fmt.Errorf("unknown option: %s", arg)
		}
	}
	if len(a.pos) < sp.minPos || len(a.pos) > sp.maxPos {
		return nil, fmt.Errorf("wrong number of arguments")
	}
	return a, nil
}

// Main runs the CLI and returns its exit code.
func Main(argv []string, version string) int {
	binVersion = version
	cmd, explicit := "status", false
	if len(argv) > 0 && !strings.HasPrefix(argv[0], "-") {
		cmd, argv, explicit = argv[0], argv[1:], true
	}
	for _, x := range argv {
		switch x {
		case "-h", "--help":
			if sp, ok := specs[cmd]; ok && explicit {
				fmt.Println("usage: " + sp.use)
			} else {
				fmt.Print(usage)
			}
			return 0
		case "--version":
			fmt.Println("yass " + version)
			return 0
		}
	}
	sp, ok := specs[cmd]
	if !ok {
		fmt.Fprintf(os.Stderr, "%syass: unknown command '%s'\n", usage, cmd)
		return 2
	}
	a, err := parse(sp, argv)
	if err != nil {
		fmt.Fprintf(os.Stderr, "usage: %s\nyass: %v\n", sp.use, err)
		return 2
	}
	code := 0
	switch cmd {
	case "init":
		err = cmdInit(a)
	case "new":
		err = cmdNew(a)
	case "status":
		code, err = cmdStatus(a)
	case "archive":
		err = cmdArchive(a)
	case "decisions":
		code, err = cmdDecisions(a)
	case "root":
		err = cmdRoot(a)
	case "paths":
		return cmdPaths(a)
	case "template":
		err = cmdTemplate(a)
	case "hook":
		return cmdHook(a)
	case "upgrade":
		code, err = cmdUpgrade(a)
	case "version":
		fmt.Println("yass " + version)
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "yass: %v\n", err)
		return 2
	}
	return code
}
