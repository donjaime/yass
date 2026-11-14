---
platforms: [all]
source: https://trello.com/c/LOfrNUOX/9-personal-memory-and-your-work
follows: 
blocked:
created: 2026-11-14T19:53:58Z
---
# Personal memory and your work

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
A personal YASS memory per clone, in a global ~/.config/yass/settings.json and shared by the clone's worktrees, that yass me prints and sets (--json for agents), so agents never need to open a file outside the project; yass status lists just your work when it names your folders (your folders, changes waiting on yours, changes on your branches), with --all for everyone's and a note when there's nothing to filter by; and yass new from the repo root uses your first folder.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [x] Delivers AC1–AC4, AC7–AC10, AC19 in plan.md
- [x] Given docs/monorepo.md, when read, then it explains the personal memory, just your work, `--all` and where new changes go — verify: manual reading

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] The settings file (`$YASS_CONFIG_DIR`, XDG, Windows) and a clone's key from its git common dir
- [x] `yass me`: show, `--json`, set `--name`/`--team`/`--folders`/`--notes`, written atomically
- [x] Refuse folders that aren't yass folders; warn on a hand-edited one in `yass status`
- [x] Filter `yass status`: your folders, waiting on yours, your branches (email in the branch log); closing line; `--all`
- [x] The `yass me` note in repos with two or more yass folders
- [x] `yass new` from the repo root uses your first folder
- [x] Unit tests, e2e, bench
- [x] docs/monorepo.md, and `yass me` in the README's CLI list

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- `folders:` matches a yass folder by its own path (`services/search/yass`) or, for a team folder, the folder it serves (`services/search`); the repo top (`.`) names nothing - people think in team folders, and the root folder is named `yass` (claude, 2026-11-14)
- "Your branch" means an unmerged branch with a commit by your git `user.email` to that change's folder, read from the branch view's one `git log` (now with `%ae`), so it costs no extra git process; `--no-branches` drops that part of the filter (claude, 2026-11-14)
- `yass new` counts "the repo root" as any place where the nearest yass folder is the top-level one (or none), so a root team still gets its own changes when its first folder is the root one (claude, 2026-11-14)
- After Jaime's design change (one global `settings.json`, through the CLI only), `yass me` writes nothing until a field is set, keeps keys it doesn't know when it writes, and saves through a temp file and a rename; `--folders` refuses a folder that isn't a yass folder here instead of warning later. The bench wasn't rerun: the filter is unchanged, and the memory is still one small file read (claude, 2026-11-14)
- The test suites set `$YASS_CONFIG_DIR` to their work folder, so no test reads or writes a real `~/.config/yass` (claude, 2026-11-14)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-14 (claude)
- Did: started from card LOfrNUOX (checked in Planning, moved to Implementing, with the parent's card 7X5M8REf). me.go: the memory path from the clone's git common dir (`$YASS_CONFIG_DIR`, XDG, `%APPDATA%`), reading `name:`/`team:`/`folders:`, `yass me`, the note and warning; branches.go marks branches with your commits; `yass status` filters to your work with `--all` and a closing line, and notes how to narrow it in a multi-folder repo with no folders set; `yass new` from the repo root uses your first folder. Unit TestMyRoots; e2e section 18 (675 pass); bench adds "just your work" (1329ms on the 1,100-branch repo, all targets met); docs/monorepo.md "Just your work" and the README's CLI list. Unit, examples and site pass.
- Did: reworked for the design change (intent underneath): me.go reads and writes one global `settings.json` with `name` and an entry per clone (`team`, `folders`, `notes`), `yass me` shows it, sets fields and prints `--json`; the note now says `yass me --folders`; e2e section 18 rewritten (678 pass); the bench sets its memory with `yass me --folders`; docs/monorepo.md and the README's CLI list follow. Unit, examples and site pass.
- Next: piece done once its PR merges; then `2026-11-14-memory-in-setup-and-playbooks`.
