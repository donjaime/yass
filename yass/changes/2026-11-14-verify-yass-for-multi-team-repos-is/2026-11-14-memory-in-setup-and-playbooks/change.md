---
platforms: [all]
source: https://trello.com/c/kbC4OgjA/10-memory-in-setup-and-playbooks
follows: 
blocked: 2026-11-14-personal-memory-and-your-work
created: 2026-11-14T19:53:58Z
---
# Memory in setup and playbooks

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
yass-init asks who you are and which team you're on and writes the personal memory with yass me; the AGENTS.md section and the playbooks read it at the start of their work; yass-status reports your work by default and everyone's when asked.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [/] Delivers AC5, AC6, AC11 in plan.md

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] `yass-init`: ask who and which team, write with `yass me`, show it when run again
- [x] `AGENTS.md` section and lifecycle playbooks: read `yass me` at the start
- [x] `yass-status`: your work by default, everyone's on request
- [/] Manual: `yass-init` in this repo and a scratch multi-team repo, then a fresh session

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- `yass-init` asks for the personal memory as its own setup step (before trackers), and only offers it in a repo with one yass folder - with one folder there's nothing to filter or route, so asking would be noise (claude, 2026-11-14)
- The `AGENTS.md` section carries the `yass me` rule, so every agent sees it even without opening a playbook; each lifecycle playbook repeats it in one line at its start (claude, 2026-11-14)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-14 (claude)
- Did: card kbC4OgjA checked in Planning and moved to Implementing (piece 1's card moved to Done after #104). `yass-init` gains step 3, "You and your team" (`yass me`, then `--name/--team/--folders/--notes`, never the file); the `AGENTS.md` section and `yass-work`, `yass-shape`, `yass-plan` and `yass-status` start with `yass me`; `yass-status` reports the person's work by default and everyone's on request; docs/skills.md says how. e2e checks the `AGENTS.md` wording (679 pass); unit, examples and site pass.
- Did, manually: AC5 in a scratch repo with three yass folders: step 1 showed the memory empty and unsaved; step 3 saved name, team and folders, after which `yass status` showed only the search folder's work with the closing line; running it again changed only the corrected team.
- Next: AC5 in this repo with Jaime's own answers, then AC11 (`yass-status` here) and AC6 (a fresh session); tick them and the Delivers box.
