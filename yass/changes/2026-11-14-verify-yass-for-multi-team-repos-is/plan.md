# Verify YASS for multi-team repos is designed properly: plan
<!-- Intent: how, and how we'll know it's done. With code, only mark boxes here ([/] in progress, [x] done);
     anything else is a plan revision in its own commit. -->

## Approach
**The personal memory is a file the binary finds and reads; agents do the rest.**
- **Where it lives** is in [design.md §1](design.md#1-where-the-personal-memory-lives-and-how-a-clone-is-named): `~/.config/yass/clones/<repo>-<id>.md`, keyed by the clone's git common dir. That's the same git folder `yass use` already keeps state in ([trailers.go](../../../internal/yass/trailers.go)).
- **What's at its top** is in [§2](design.md#2-whats-at-the-top-of-the-personal-memory): `name:`, `team:`, `folders:`, read with the same frontmatter reader `change.md` uses ([text.go](../../../internal/yass/text.go)).
- **`yass me`** prints the file's path and contents. With no file yet, it creates one from a template: `name:` comes from git's `user.name`, and `folders:` stays empty for `yass-init` to fill.

**"Just your work" is a filter on `yass status`'s list, not a new view.**
- After `loadRepo` ([repo.go](../../../internal/yass/repo.go)), `cmdStatus` ([commands.go](../../../internal/yass/commands.go)) keeps the changes that are:
  - in your `folders:`;
  - waiting on one of yours (`blocked:` names it), so you see who depends on you;
  - on an unmerged branch whose commits are yours.
- **Branches:** the branch view's one `git log` ([branches.go](../../../internal/yass/branches.go)) already reads each commit's author name. It adds the email and marks a row yours when that matches git's `user.email`. `--no-branches` skips this part.
- **The closing line** says how many changes in how many other folders were left out, and that `--all` shows them.
- **When nothing is filtered:** no memory, or no `folders:`, filters nothing. When the repo has two or more yass folders, a note says `yass me` sets up the filter.
- **Naming a change** (`yass status <change>`) is never filtered.
- **`yass new`** uses your first folder when the yass folder nearest where you're standing (`rootForCwd`) is the repo's top-level one, or there's none. Inside a team's folder it behaves as today, and `--in` still overrides both.

**The team memory is a committed markdown file the agents read** ([design.md §3](design.md#3-the-team-memory)).
- It's `team.md` at the top of a yass folder, next to `settings.yaml`. With plans kept elsewhere, that's the plans folder.
- The binary doesn't read it, and the hook treats it like any other plan file.
- The project management workflow lives under `## Project management` there.
- The piece of binary work here is removing the `tracker.local.md` check (tracker.go), now that nothing writes that file.

**The playbooks:**
- **`yass-init`:**
  - asks who you are and which team, and writes the personal memory with `yass me`;
  - for a system other than Trello, reads the team memory's workflow, and interviews only when there's none. The interview's result goes into `team.md` as a change for the team to commit and review.
- **The `AGENTS.md` section and each lifecycle playbook** read the personal memory at the start (`yass me`), and the team memory's workflow at each tracker moment.
- **`yass-status`** reports your work by default.

**The tracker change.** Its AC25–AC27 and AC29 are already dropped, superseded here (R13). Its open Trello checks (AC17–AC20) get exercised on this change's own cards: pieces linked to cards or offered one, a card moved by hand mid-flight, a card edited. They're recorded in that change's Log as they pass.

## Acceptance
### M1
- [ ] AC1 (R1) Given a clone and a linked worktree of it, and a second clone of the same repo, when `yass me` runs in each, then the clone and its worktree print the same path under `~/.config/yass/clones/` (or `$YASS_CONFIG_DIR`) and the second clone prints a different one — verify: e2e
- [ ] AC2 (R1) Given `yass me` has created the memory, when `git status` runs, then nothing in the repo changed — verify: e2e
- [ ] AC3 (R2, R3) Given no memory, when `yass me` runs, then it creates one with `name:` from git's `user.name`, an empty `folders:` and a notes heading, and prints its path and contents; run again, it prints the same and changes nothing — verify: e2e
- [ ] AC4 (R2) Given a memory with an unknown key at the top, or a `folders:` entry that isn't a yass folder here, when `yass status` runs, then the first is a note and the second a warning naming the folder — verify: unit and e2e
- [ ] AC5 (R4) Given a repo with two team folders and no memory, when `yass-init` runs, then it asks who you are and which folders are yours and writes them with `yass me`; run again, it shows them and changes only what you correct — verify: manual
- [ ] AC6 (R5) Given a memory naming your folders, when an agent starts work in a fresh session, then it reads the memory (`yass me`) before choosing where a new change goes or whose work to report — verify: manual
- [ ] AC7 (R6) Given a memory with `folders: [services/search]`, a change in `services/web` waiting on a search change, a change in `yass/` with an unmerged branch you committed to, and other changes elsewhere, when `yass status` runs, then it lists the search changes, the waiting web change and the one with your branch, and ends with how many other changes, in how many folders, it left out and that `--all` shows them — verify: e2e
- [ ] AC8 (R7) Given the same repo, when `yass status --all` runs, then every change is listed with no closing line about what's left out, and `yass status <change>` shows any change, yours or not — verify: e2e
- [ ] AC9 (R8) Given no memory, or one with no `folders:`, when `yass status` runs, then everything is listed as today; a repo with two or more yass folders gets one note saying `yass me` sets up the filter, and a repo with one gets none — verify: e2e
- [ ] AC10 (R9) Given a memory whose first folder is `services/search`, when `yass new` runs at the repo root, then the change goes in `services/search/yass`; run inside `services/web`, in web's folder; with `--in`, where that says — verify: e2e
- [ ] AC11 (R10) Given a memory naming your folders, when the human asks the agent where things stand, then `yass-status` reports their work, and everyone's when they ask for it — verify: manual
- [ ] AC12 (R14) Given docs/monorepo.md, the README and docs/project-management.md, when read, then they explain the personal memory, just your work and `--all`, where new changes go, and that a team's workflow lives in its `team.md` — verify: `tests/site.sh` and manual reading
- [ ] AC19 (R1–R9) Given `tests/bench.sh`, when run with a memory naming one folder of the bench repo, then `yass status` stays within its targets — verify: tests/bench.sh, timings in the pull request
### M2
- [ ] AC13 (R15) Given a yass folder (inline, or a plans folder kept elsewhere), when its team's workflow is written, then it's in `team.md` at the top of that folder, under `## Project management`, and nowhere else — verify: manual
- [ ] AC14 (R11, R16) Given a yass folder whose tracker isn't Trello and a `team.md` with no workflow, when `yass-init` connects it, then the agent interviews the human, writes the workflow into `team.md`, shows it, and leaves it for the team to commit and review, writing nothing to the harness's memory, the personal memory or a `tracker.local.md` — verify: manual, using GitHub Issues as the system
- [ ] AC15 (R16) Given a `team.md` that already has the workflow, when a teammate runs `yass-init`, then it asks only who they are and which team, and nothing about the workflow — verify: manual
- [ ] AC16 (R12) Given that workflow, when a new session starts shaping a change in that folder, then the agent does what `team.md` says at that moment (for GitHub Issues: the issue's status or label, and the comment) — verify: manual
- [ ] AC17 (R12) Given a `tracker.local.md` in a yass folder, when `yass status` runs, then it says nothing about it — verify: e2e
- [ ] AC18 (R13) Given this change's pieces and their cards, when they're created, worked and finished, then the tracker change's AC17–AC20 are exercised and recorded in its Log: a piece linked to the card that covers it, or offered one (AC18, AC20); a card moved by hand mid-flight, which the agent stops for (AC17); a card edited, which the agent proposes plan revisions for (AC19) — verify: manual

## Pieces
Three pieces, in order:
1. **`personal-memory-and-your-work`:** all the binary work for M1 (AC1–AC4, AC7–AC10, AC19), and docs/monorepo.md's part of AC12. It goes first because the playbooks run `yass me`, and the filter is what people see.
2. **`memory-in-setup-and-playbooks`:** `yass-init` sets up the personal memory; the `AGENTS.md` section and the playbooks read it; `yass-status` reports your work (AC5, AC6, AC11). It's blocked by piece 1.
3. **`team-memory-and-workflow`:**
   - `team.md`, the interview writing into it, the lifecycle playbooks reading it, and the `tracker.local.md` check removed;
   - the README and docs/project-management.md;
   - recording the tracker change's checks (AC12's rest, AC13–AC18).

   It's blocked by piece 2: it edits the same playbooks.

## Validation
- **Automated:** `go test ./...`, `tests/e2e.sh`, `tests/examples.sh` and `tests/site.sh` pass on Linux and macOS in CI. `tests/bench.sh` stays within its targets with a memory in place, with timings quoted in piece 1's PR.
- **Personal memory:** one manual run of `yass-init` in this repo, which has two yass folders, the public `yass/` and the private plans folder, and in a scratch repo with team folders. Then a fresh session that uses the memory.
- **Team memory:** one manual interview using GitHub Issues as the other system, and a fresh session that follows `team.md`.
- **Board checks:** the tracker change's open Trello checks, run on this change's cards as they come up.
