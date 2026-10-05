# The binary carries the playbooks: plan
<!-- Intent: how, and how we'll know it's done. With code, only mark boxes here ([/] in progress, [x] done);
     anything else is a plan revision in its own commit. -->

## Approach
<!-- The shape of the solution. Hard-to-undo calls go in design.md. -->
**The binary carries the kit.** `kit/` (the playbooks and the hook script) becomes a Go package with an `embed.go` (`//go:embed all:.agents tools`), so every `yass` binary, from a release, a clone or `go install`, carries the files for its own version. The files in `kit/` stay unstamped; the version is added as they're written.

**`yass init` writes everything.** [`cmdInit`](../../../internal/yass/commands.go) already writes the yass folder, `yass.yaml` and the `AGENTS.md` section. It takes over the rest of what [`install.sh`](../../../install.sh) does: the playbooks (`.agents/skills/`, or the user folder with `--global`), Claude Code's copies and the `CLAUDE.md` import (`--claude`), the hook script, and `core.hooksPath` (`--hooks`), with the same paths, so nothing moves in existing repos. Every file it writes is stamped as [design.md](design.md) §2 describes: `metadata.yass-version` in each playbook's frontmatter, `version=` in the `AGENTS.md` begin marker, and `# yass-version:` in the hook header.

**Re-running it upgrades.** Before writing, `yass init` reads the stamps of the YASS files already there, wherever they were installed. That means the repo's playbooks, Claude's copies, the user folder's when the repo has none, the hook and the marker: the same "refresh what's installed" rules `install.sh --upgrade` follows today. It compares each with its own version (design §1). Older or unstamped files get upgraded, files at the same version are left alone (unless the binary is `+dirty`), and newer ones stop it with "upgrade your binary". It prints whether it set up, upgraded (from which version) or found the repo up to date, and lists every file it wrote, labeling any outside version control. An option a repo was set up with keeps working on upgrade without being passed again.

**`install.sh` becomes a binary installer.** It downloads and verifies a release (when piped), or uses the binary next to it (a release folder or a clone's `bin/`), copies it to `--bin-dir`, and says where it went and whether that's on PATH. Given a path (`.` for the repo you're in), it then runs `yass init` with the setup options it was given (`--claude`, `--global`, `--hooks`, `--path`; `--upgrade` is accepted and does nothing extra). Without a path it stops after the binary, which is the joining-a-repo install. It checks the path is a git repo before installing anything. Release archives drop the kit files, since the binary carries them.

**`yass status`** (M2) reads the same stamps and adds one line when the binary and the repo are out of step.

**Docs.** The `yass init` options go in the README's CLI reference with the code that adds them. The install model in the README, `docs/install.md` and the landing page is rewritten in the piece that changes `install.sh`, so the docs never describe a flow that doesn't exist.

## Acceptance
<!-- Per milestone, one observable behavior each:
### M1
- [ ] AC1 (R1) Given …, when …, then … — verify: <test, flow, or manual steps> -->
### M1
- [ ] AC1 (R1) Given a fresh git repo and a `yass` binary with no release files beside it, when you run `yass init`, then it writes the five playbooks under `.agents/skills/`, an executable `tools/yass/githooks/pre-commit`, the `AGENTS.md` section and the yass folder — verify: e2e (binary copied alone into an empty folder on PATH)
- [ ] AC2 (R1) Given that repo, then each file matches its source in `kit/` (or `templates/agents.md`) except for its version stamp — verify: e2e (diff with the stamp lines removed)
- [ ] AC3 (R1) Given a binary built by `go install` or a release, then it carries all five playbooks and the hook — verify: go test (the embedded files list)
- [ ] AC4 (R2) Given `yass init --claude`, then it also writes the playbooks under `.claude/skills/` and puts `@AGENTS.md` at the top of `CLAUDE.md` once, keeping what was there — verify: e2e (with and without an existing `CLAUDE.md`, run twice)
- [ ] AC5 (R2) Given `yass init --global`, then the playbooks go to `~/.agents/skills/` (or `$YASS_SKILLS_DIR`), and to `~/.claude/skills/` with `--claude`, and none to the repo — verify: e2e (with a temporary `HOME`)
- [ ] AC6 (R2) Given `yass init --hooks`, then `core.hooksPath` is `tools/yass/githooks` for this clone — verify: e2e
- [ ] AC7 (R2) Given `--path`, `--private` and `--no-agents`, then they behave as they do today — verify: e2e (the existing sections, run through `yass init`)
- [ ] AC8 (R7) Given a fresh `yass init` by a binary at version V, then every playbook's frontmatter has `metadata.yass-version: "V"` and still has its `name` and `description`, the `AGENTS.md` begin marker has `version=V`, and the hook has `# yass-version: V` — verify: go test (the frontmatter parses as YAML); e2e (all three stamps)
- [ ] AC9 (R3) Given a repo whose YASS files are stamped with an older version, when you run `yass init`, then every one is rewritten at the binary's version, and it prints that it upgraded, from which version to which — verify: e2e
- [ ] AC10 (R3) Given a repo set up with `--claude`, or with playbooks only in the user folder, when you run `yass init` with no options, then those copies are upgraded too, where they are — verify: e2e
- [ ] AC11 (R3) Given changes, a `yass.yaml`, text outside the `AGENTS.md` markers and other content in `CLAUDE.md`, when `yass init` upgrades, then none of them changes — verify: e2e (checksums before and after)
- [ ] AC12 (R10) Given a repo already at the binary's version, when you run `yass init`, then no file changes, `git status` is clean, and it says the repo is already up to date at that version — verify: e2e
- [ ] AC13 (R11) Given a repo with any YASS file stamped newer than the binary, when you run `yass init`, then no file changes, it names the newer version and says to upgrade the binary, and it exits non-zero — verify: e2e
- [ ] AC14 (R12) Given versions to compare, then a clone build after a release (`v0.3.1-0.…`) is newer than that release, a later release is newer than the clone build, `+dirty` is ignored in comparing, and an equal version written by a `+dirty` binary is rewritten — verify: go test (a table of version pairs and the expected action)
- [ ] AC15 (R12) Given a binary with no version (`dev`), when you run `yass init`, then it writes nothing, says how to get a versioned build, and exits non-zero — verify: go test (the decision for an empty version); e2e (a binary built with `-buildvcs=false`)
- [ ] AC16 (R13) Given `yass init` writes files, then it prints each one, and marks those outside version control (user-folder playbooks) as such — verify: e2e
- [ ] AC17 (R13) Given a hand-edited playbook in a repo at an older version, when `yass init` upgrades, then the edit is replaced, and `git diff` shows it — verify: e2e
- [ ] AC18 (R14) Given a repo set up by v0.2.0's `install.sh` (no stamps), when you run `yass init`, then it upgrades every YASS file — verify: e2e (a fixture installed from v0.2.0's kit)
- [ ] AC19 (R4) Given that upgraded repo and a fresh `yass init` of an empty repo with the same options and binary, then their YASS files are identical — verify: e2e (`diff -r` of the YASS files, with `--claude` and `--hooks` too)
- [ ] AC20 (R5) Given `install.sh --bin-dir DIR` with no path, then it copies the binary to DIR, says where it put it and whether DIR is on PATH, says to run `yass init` in a repo, and writes nothing in the current folder — verify: e2e
- [ ] AC21 (R5) Given `install.sh --bin-dir DIR <path> [--claude] [--global] [--hooks] [--path P]`, then it installs the binary, then runs `yass init` with those options, and its output marks the two steps — verify: e2e
- [ ] AC22 (R5) Given `install.sh <path> --upgrade`, then it does what `install.sh <path>` does, and upgrades the repo — verify: e2e
- [ ] AC23 (R5) Given a path that isn't inside a git repo, then `install.sh` fails before installing anything — verify: e2e
- [ ] AC24 (R5) Given the piped one-liner, then it still downloads the latest release, checks it against `checksums.txt`, and then behaves as above — verify: manual: run the documented one-liner against a release candidate, in a repo and outside one
- [ ] AC25 (R1, R5) Given a release archive, then it has the binary, `install.sh` and the docs, and no `kit/` files, and its `install.sh` sets up a repo — verify: CI (GoReleaser snapshot build); e2e (an unpacked-release folder without `kit/`)
- [ ] AC26 (R6) Given a repo that already uses YASS, when a teammate runs the documented binary-only install (`install.sh` with no path, the one-liner without `.`, or `go install`), then the binary is installed and no file in the repo changes — verify: e2e (`git status` clean); manual: docs review
- [ ] AC27 (R9) Given the README, `docs/install.md` and the landing page, then they describe the model: get the binary, run `yass init` in each repo to set up or upgrade, and joining needs only the binary; the README's CLI reference lists `yass init`'s options — verify: manual: review; `tests/site.sh` (the page's commands match the docs)

### M2
- [ ] AC28 (R8) Given a repo whose YASS files are stamped newer than the binary, when you run `yass status`, then it warns which version wrote them and says to upgrade the binary — verify: e2e
- [ ] AC29 (R8) Given a repo whose YASS files are stamped older than the binary, when you run `yass status`, then it notes that `yass init` would upgrade the repo — verify: e2e
- [ ] AC30 (R8) Given a repo at the binary's version, or with no YASS files installed, then `yass status` says nothing about versions — verify: e2e

## Pieces
<!-- PR-sized pieces, each its own folder in here: `yass new "<title>" --in <this change>`.
     `yass status` lists them; say here what order they go in and why. -->
1. `init-writes-the-whole-repo` (M1): the kit embedded in the binary, the stamps, and `yass init` writing every file with the new options, keeping files that already exist (as `install.sh` does without `--upgrade`). It comes first because everything else builds on the binary carrying the kit. `install.sh` still works unchanged after it.
2. `init-upgrades-by-version` (M1): reading the stamps, comparing versions, upgrading or saying up to date or refusing, unstamped files, the Go 1.24 floor (design §5), and the file listing. It's split from piece 1 so the version rules can be reviewed on their own. Blocked on piece 1.
3. `install-sh-installs-the-binary` (M1): `install.sh` as a binary installer that runs `yass init` when given a path, release archives without the kit, the joining install, and the install docs and landing page rewritten to match. Blocked on piece 2, since its `--upgrade` relies on `yass init` upgrading.
4. `status-knows-the-versions` (M2): the `yass status` line. Blocked on piece 2 for the stamp reading; it can go before or after piece 3.

Once piece 3 lands, the monorepo change's `yass-trailers` piece (which waits on this change) ships its hooks through `yass init`.

## Validation
<!-- How the whole thing is verified before it's called done: suites, platforms, manual passes. -->
- CI on each piece: `go test`, `tests/e2e.sh`, `tests/examples.sh` and `tests/site.sh`, on Ubuntu and macOS, plus the GoReleaser snapshot build.
- Dogfood: after piece 2, `yass init` in this repo upgrades its own playbooks, Claude copies and hook. The diff should be stamps only, and `install.sh` is no longer needed here.
- A release candidate (`v0.3.0-rc.1`) before release: the piped one-liner in a repo and outside one (AC24), an unpacked archive on macOS and Linux, and upgrading a repo set up by v0.2.0.
- The release notes say how to upgrade: get the new binary, then run `yass init` in each repo.
