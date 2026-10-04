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

  init [dir] [--path P] [--no-agents]   create the yass folder (in dir, for a team folder) and the
                                        AGENTS.md section; --path writes a yass.yaml pointing to P
  new "<title>" [--large] [--design]    a change: a dated folder from a template
      [--in CHANGE] [--goal G] [--platforms P] [--source S] [--follows ARCHIVED]
  status [<change>] [--archived] [--strict]
                                        what's in flight, or one change in detail
  archive <change> [--force]            move a finished change to the archive
  root                                  print the yass folder(s) this repo uses
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
	"init":     {[]string{"no-agents"}, []string{"path"}, 0, 1, "yass init [dir] [--path P] [--no-agents]"},
	"new":      {[]string{"large", "design"}, []string{"in", "goal", "platforms", "source", "follows"}, 1, 1, `yass new "<title>" [--large] [--design] [--in CHANGE] [--goal G] [--platforms P] [--source S] [--follows ARCHIVED]`},
	"status":   {[]string{"archived", "strict"}, nil, 0, 1, "yass status [<change>] [--archived] [--strict]"},
	"archive":  {[]string{"force"}, nil, 1, 1, "yass archive <change> [--force]"},
	"root":     {nil, nil, 0, 0, "yass root"},
	"template": {nil, nil, 1, 1, "yass template <change|change-large|prd|plan|design|readme|agents>"},
	"hook":     {[]string{"strict"}, []string{"range"}, 0, 0, "yass hook [--range A..B] [--strict]"},
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
	case "root":
		err = cmdRoot(a)
	case "template":
		err = cmdTemplate(a)
	case "hook":
		return cmdHook(a)
	case "version":
		fmt.Println("yass " + version)
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "yass: %v\n", err)
		return 2
	}
	return code
}
