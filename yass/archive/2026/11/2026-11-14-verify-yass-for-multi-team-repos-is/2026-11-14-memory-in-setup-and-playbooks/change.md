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
- [x] Delivers AC5, AC6, AC11 in plan.md

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] `yass-init`: ask who and which team, write with `yass me`, show it when run again
- [x] `AGENTS.md` section and lifecycle playbooks: read `yass me` at the start
- [x] `yass-status`: your work by default, everyone's on request
- [x] Manual: `yass-init` in this repo and a scratch multi-team repo, then a fresh session

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- `yass-init` asks for the personal memory as its own setup step (before trackers), and only offers it in a repo with one yass folder - with one folder there's nothing to filter or route, so asking would be noise (claude, 2026-11-14). Superseded below: the step asks whether teams share the repo first
- Teams are optional: `yass status` no longer notes how to set up the memory, `yass-init`'s step 3 asks whether teams share the repo and sets nothing for someone working alone, `yass me` on an empty memory says "nothing saved for this clone yet" without suggesting a field, and the `AGENTS.md` section says no folders means everything is the person's - per the intent revision underneath, after Jaime, working solo with public and private plans, got the note for folders that are all his (Jaime, 2026-11-14)
- The `AGENTS.md` section carries the `yass me` rule, so every agent sees it even without opening a playbook; each lifecycle playbook repeats it in one line at its start (claude, 2026-11-14)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-14 (claude)
- Did: card kbC4OgjA checked in Planning and moved to Implementing (piece 1's card moved to Done after #104). `yass-init` gains step 3, "You and your team" (`yass me`, then `--name/--team/--folders/--notes`, never the file); the `AGENTS.md` section and `yass-work`, `yass-shape`, `yass-plan` and `yass-status` start with `yass me`; `yass-status` reports the person's work by default and everyone's on request; docs/skills.md says how. e2e checks the `AGENTS.md` wording (679 pass); unit, examples and site pass.
- Did, manually: AC5 in a scratch repo with three yass folders: step 1 showed the memory empty and unsaved; step 3 saved name, team and folders, after which `yass status` showed only the search folder's work with the closing line; running it again changed only the corrected team.
- Did: teams are optional (intent revision underneath): the note is gone from `yass status`, `yass-init` step 3 is "Teams (optional)", `yass me` doesn't push a field on an empty memory, and the `AGENTS.md` section, `yass-status`, docs/skills.md and docs/monorepo.md say a solo developer sets nothing. e2e now checks there's no memory note in a three-folder repo (677 pass); unit, examples and site pass.
- Did, manually: AC5's solo path in this repo (Jaime works alone, with public and private plans): nothing to set; `yass status` shows both folders' work with no memory note, and `yass me` shows his git name with nothing saved.
- Next: AC11 (`yass-status` here) and AC6 (a fresh session, Jaime's); tick them and the Delivers box.
### 2026-11-14 (claude)
- Did, manually: AC11 here (solo: `yass me` has nothing saved, so `yass-status` reported everything as Jaime's, and all four linked cards were in the column their change implies). AC6 in a fresh session in the scratch repo `yass-trial` (Jaime's "Dark mode toggle" session): it ran `yass me` first and created the change in `services/web/yass` because `yass me` put Jaime on web. AC5's team path in another fresh session there (Jaime's "YASS setup and GitHub Issues connection"): it asked whether teams share the repo and saved team `web`, folder `services/web/yass`, through `yass me`.
- Next: done once this merges; the card moves to Done.
