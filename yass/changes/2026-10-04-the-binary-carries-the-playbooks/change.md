---
platforms: [all]
source: Jaime, 2026-10-04: installing the binary and setting up a repo are two steps that install.sh does as one, which confuses; noted while fixing the install docs (follows-up 2026-10-04-install-say-where-to-run-it-and-how-yass)
follows: 
blocked:
---
# The binary carries the playbooks

## Goal
<!-- Intent. One paragraph; the detail is in prd.md (why and what) and plan.md (how and acceptance). -->
Using YASS takes two steps that each say what they do: get the `yass` binary, once per machine, and run `yass init` in each repo. The binary carries the playbooks and the hook for its version, so `yass init` sets up a whole repo with no release download, re-running it upgrades the repo (or says it's already up to date), and a teammate joining a repo needs only the binary. The one-line install still does both in one go. Every file YASS installs records the version that wrote it, and `yass status` says when the binary and the repo are out of step.

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)" for calls that span the whole change. -->
- Noted as a future large change rather than built now - it changes the CLI, `install.sh` and the release; the install docs were fixed first, explaining the two steps instead of splitting them (Jaime)
- Scope: `yass init` does the whole repo setup from the binary, re-running it upgrades, the repo records its YASS version, and `install.sh` becomes a binary installer; Homebrew and self-update, and a minimal `install.sh`-modes version, were considered and left out (Jaime)
- The one-line install keeps working: it installs the binary, then runs `yass init` (with any setup flags) when run in or pointed at a repo, and says which step did what (Jaime)
- Versions live in the files YASS installs: the binary carries its version, the playbooks have it in their frontmatter, the `AGENTS.md` section in its markers (and the hook script in a header), and `yass init` reads them to decide what to do. That also covers playbooks installed with `--global` (Jaime; the hook header added by claude)
- `yass init` is idempotent and does the upgrade itself: no `--upgrade` flag. It detects an upgrade and says so, and says "already up to date" when there's nothing to do (Jaime)
- `yass init` never downgrades: newer files than the binary mean upgrade the binary (claude, for review)
- The monorepo change's `yass-trailers` piece waits for this change and ships its hook scripts through `yass init` (Jaime)
- Builds from a clone carry the release they follow plus a commit, and `+dirty`; a `+dirty` build rewrites files stamped with its own version, and a newer release upgrades over a clone build (Jaime). Versions compare as SemVer, with Go's pseudo-versions for clone builds (claude; design.md §1)
- No edit detection: upgrading replaces YASS's files, and since they're committed, the replacement shows up in `git diff` for review. Hashes, a prompt and `--force` were considered and dropped as more than the problem needs (Jaime). `yass init` lists what it writes and labels files outside version control (`--global` playbooks); unstamped files from v0.1 and v0.2 count as older and get upgraded (claude)
- PRD and design approved 2026-10-04 (Jaime)
- Planned in four pieces: `yass init` writes everything, then upgrades by version, then `install.sh` becomes a binary installer with the docs rewritten, and the `yass status` line (claude)
- `install.sh` runs `yass init` only when given a path (`.` for the repo you're in); without one it installs just the binary. That makes the PRD's "run from inside a repo" mean "with `.`", as the documented one-liner already does, and the same one-liner without `.` is the joining install (claude, while planning)
- Version comparison uses `golang.org/x/mod/semver` (design §4), and building from source needs Go 1.24, so clone builds carry a version (design §5) (claude, while planning; for review)

## Log
<!-- Progress. Change-level notes; each piece keeps its own Log.
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
