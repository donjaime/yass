---
platforms: [all]
source: https://trello.com/c/UOyz3M0x/11-team-memory-and-workflow
follows: 
blocked: 2026-11-14-memory-in-setup-and-playbooks
created: 2026-11-14T19:53:59Z
---
# Team memory and workflow

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
A team.md at the top of each yass folder holds what the team shares, starting with its project management workflow; yass-init's interview writes into it, only when it has no workflow yet, for the team to commit and review; the lifecycle playbooks read it; the tracker.local.md check goes; the README and docs/project-management.md say so; and the tracker change's open Trello checks are recorded as this change's cards exercise them.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [/] Delivers AC12, AC13–AC18 in plan.md

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] `team.md`: `yass-init`'s interview writes `## Project management` there, only when it's missing
- [x] Lifecycle playbooks and `yass-status` read the workflow from `team.md`
- [x] Remove the `tracker.local.md` check and its e2e; check it's silent now
- [x] README, docs/project-management.md, docs/skills.md
- [ ] Manual: interview with GitHub Issues, then a fresh session following it
- [ ] Record the tracker change's AC17–AC20 checks in its Log as they pass

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- `yass-init` looks in `team.md` first and asks nothing about a workflow that's already there; when it writes one, it creates `team.md` if needed (`# <yass folder>: team memory`, then `## Project management`) and leaves it for the team to commit and review - the team's workflow is reviewed once, then every agent follows it (claude, 2026-11-14)
- `tracker.local.md` is gone everywhere, not just from `yass status`: the playbooks, `AGENTS.md`, the README, docs/project-management.md and docs/skills.md no longer mention it, and the tracker change's AC28 is dropped underneath - Jaime asked to remove it entirely now that `team.md` and `yass me` cover both of its jobs (Jaime, 2026-11-14)
- `team.md` is listed in the yass folder README template (and this repo's `yass/README.md`), and docs/project-management.md says a team of one keeps its workflow there too (claude, 2026-11-14)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-14 (claude)
- Did: card UOyz3M0x checked in Planning and moved to Implementing. Removed the `tracker.local.md` check (tracker.go) and its e2e checks, replaced by one that `yass status` ignores the file (AC17); `yass-init`'s "Connect another tracker" now reads and writes the workflow in `team.md`; the "Another tracker" lines in `yass-shape`, `yass-plan`, `yass-work` and `yass-status`, and the `AGENTS.md` section, point at `team.md`; the README, docs/project-management.md, docs/skills.md, the 0.5.0 changelog and the folder README template follow. Unit, e2e (676), examples and site pass; no bench, since this removes work from `yass status`.
- Next: the manual run (an interview with GitHub Issues as the other system, then a fresh session following `team.md`), and recording the tracker change's AC17–AC20 checks as they pass.
