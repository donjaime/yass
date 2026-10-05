# The binary carries the playbooks: PRD
<!-- Intent: what should change or exist, and why. Not a description of the current system;
     the code and its docs are that. Edit this file only in commits without code. -->

## Why
<!-- The problem, with evidence. -->
Using YASS takes two things: the `yass` binary on your PATH, once per machine, and a few files in each repo, set up once and committed. Today one script, [`install.sh`](../../../install.sh), does both, and the playbooks and the hook only reach a repo through a downloaded release folder. That causes four problems:
- **The two jobs blur.** People can't tell which part of the command does what. The binary half fails quietly when its folder isn't on PATH, which happened on a stock Mac and needed [a docs fix](../../archive/2026-10-04-install-say-where-to-run-it-and-how-yass/change.md) to explain.
- **Joining a repo has no real path.** A teammate who clones a repo that already uses YASS needs only the binary. The docs fall back to copying it out of a release archive by hand ([install.md](../../../docs/install.md#joining-a-repo-that-already-uses-yass)).
- **Upgrading every repo needs the release every time.** `install.sh --upgrade` has to run from a release folder (or the piped download) for each repo, even though the binary you just upgraded could do it.
- **Nothing knows which version wrote a repo's files.** A teammate with an older binary and a repo with newer playbooks get no warning that they're out of step.

The binary already does part of the repo setup: `yass init` writes the yass folder, the `AGENTS.md` section and `yass.yaml`, it embeds the change templates, and it knows its version.

## Users and outcomes
<!-- Who it's for, and measurable targets ("p50 time to log < 5s"). -->
- **Someone adopting YASS** in a repo. Outcome: two steps, each saying what it did: get the binary, then `yass init`. The one-line install still does both in one go.
- **A teammate joining a repo that already uses YASS.** Outcome: they get the binary and they're done; nothing in the repo needs to change.
- **Someone who uses YASS in several repos.** Outcome: setting up another repo, or upgrading one, needs no download: `yass init` in each.
- **Anyone whose binary and repo are out of step.** Outcome: `yass status` says so, and says which to upgrade.

Targets:
- Setting up a second repo, or upgrading any repo after the binary: 0 downloads, 1 command.
- Joining a repo: 1 step (get the binary), no `install.sh`.
- Every repo set up by today's `install.sh` upgrades with `yass init`, with no manual cleanup.

## Requirements
<!-- One line each: "- **R1** [M1] A user can …". IDs are never reused. -->
- **R1** [M1] A user with `yass` on their PATH sets up a repo with `yass init`: the playbooks, the hook script, the `AGENTS.md` section and the yass folder (or `yass.yaml`), the same files `install.sh` writes today, from the binary alone.
- **R2** [M1] `yass init` takes the setup options `install.sh` has today: `--claude` (Claude Code's copies and the `CLAUDE.md` import), `--global` (playbooks in the user folder), `--hooks` (turn on the hook for this clone) and `--path`, alongside the options it already has.
- **R3** [M1] `yass init` is idempotent. Run on a repo that's already set up, it upgrades the YASS files that are there, wherever they were installed, to the binary's version, and says it upgraded and from which version. It never touches changes, `yass.yaml` or anything outside the `AGENTS.md` markers.
- **R4** [M1] A repo set up by an earlier `install.sh` upgrades with `yass init` and ends up exactly as a fresh `yass init` at the same version would leave it.
- **R5** [M1] `install.sh` installs the binary and says so: where it put it, and whether that folder is on PATH. Run from inside a repo, or given a repo's path, it then runs `yass init` with any setup options it was given, so today's one-line install keeps working (its `--upgrade` flag too), and its output says which step did what.
- **R6** [M1] A teammate joining a repo that already uses YASS installs only the binary, with a documented one-liner or `go install`, and doesn't run `yass init`.
- **R7** [M1] Every file YASS installs records the version that wrote it, committed with it: the playbooks in their frontmatter, the `AGENTS.md` section in its marker, the hook script in a header. `yass init` decides what to do by comparing those versions with its own. `yass --version` reports the binary's.
- **R8** [M2] `yass status` warns when the binary is older than the version that wrote a repo's YASS files (upgrade your binary), and notes when it's newer (`yass init` would upgrade the repo).
- **R9** [M1] The README, `docs/install.md` and the landing page describe the new model: get the binary, run `yass init` in each repo to set it up or upgrade it, and joining needs only the binary.
- **R10** [M1] When a repo's YASS files are already at the binary's version, `yass init` changes nothing and says the repo is already up to date.
- **R11** [M1] `yass init` never downgrades. When a repo's YASS files are newer than the binary, it changes nothing, says which version wrote them, and says to upgrade the binary.
- **R12** [M1] A build from a clone stamps its own version (the release it follows plus a commit, and `+dirty` with uncommitted changes) and upgrades a repo stamped with an older release; a newer release then upgrades over it; a `+dirty` build rewrites files stamped with its own version. A binary with no version refuses to write.
- **R13** [M1] Upgrading replaces YASS's files, hand edits included. `yass init` lists every file it writes, so the change shows up for review in `git diff`, and it labels any it writes outside version control (playbooks in the user folder, with `--global`).
- **R14** [M1] A file without a version stamp, as written by v0.1 and v0.2, counts as older than any stamped version, so `yass init` upgrades it.

## Non-goals
<!-- What this change will not do. Agents treat these as walls. -->
- No Homebrew tap, other package manager or `yass self-update`. Getting the binary stays a release download, the one-liner or `go install`.
- No editing of shell startup files. Installers say what to add to PATH; the user adds it.
- No change to the playbooks' content, the hook's checks or the change file formats; only how they get into a repo.
- No detecting or preserving hand edits to YASS's files. They're committed with the repo, so an upgrade that replaces one shows up in review; `install.sh --upgrade` behaves the same way today.
- No change to where files land in a repo. Same paths as today, so existing repos upgrade in place.
- No new installer for Windows. `yass init` works there natively; getting the binary stays a release download or `go install`.
- No changes to the monorepo change's trailer hooks themselves. Its `yass-trailers` piece waits for this change and ships its hook scripts through `yass init`.

## Milestones
| Milestone | When it ships, a user can … |
|---|---|
| M1 | set up or upgrade any repo with `yass init`, with no download after the binary, and see which it did (or that it was already up to date); join a repo with just the binary; and read docs that describe it that way. The one-line install still works. |
| M2 | see from `yass status` when their binary and a repo's YASS files are out of step, and which to upgrade |

## Open questions
- None. The version format and comparison are in [design.md](design.md).
