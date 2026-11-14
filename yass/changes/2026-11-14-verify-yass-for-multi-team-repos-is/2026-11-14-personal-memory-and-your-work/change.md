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
- [ ] Delivers AC1–AC4, AC7–AC10, AC19 in plan.md
- [ ] Given docs/monorepo.md, when read, then it explains the personal memory, just your work, `--all` and where new changes go — verify: manual reading

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] Memory path from the clone's git common dir (`$YASS_CONFIG_DIR`, XDG, Windows)
- [ ] `yass me`: create from a template, print path and contents
- [ ] Read the top fields; note unknown keys, warn on folders that aren't yass folders
- [ ] Filter `yass status`: your folders, waiting on yours, your branches (email in the branch log); closing line; `--all`
- [ ] The `yass me` note in repos with two or more yass folders
- [ ] `yass new` from the repo root uses your first folder
- [ ] Unit tests, e2e, bench
- [ ] docs/monorepo.md, and `yass me` in the README's CLI list

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
