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
- [ ] Delivers AC12, AC13–AC18 in plan.md

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `team.md`: `yass-init`'s interview writes `## Project management` there, only when it's missing
- [ ] Lifecycle playbooks and `yass-status` read the workflow from `team.md`
- [ ] Remove the `tracker.local.md` check and its e2e; check it's silent now
- [ ] README, docs/project-management.md, docs/skills.md
- [ ] Manual: interview with GitHub Issues, then a fresh session following it
- [ ] Record the tracker change's AC17–AC20 checks in its Log as they pass

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
