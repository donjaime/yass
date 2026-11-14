---
platforms: [all]
source: 
follows: 
blocked: 2026-11-14-yass-init-playbook
created: 2026-11-14T16:01:44Z
---
# Trello in the lifecycle playbooks

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
yass-shape, yass-plan, yass-work and yass-status each follow the Trello workflow at their own moments: start from a card, move it to Planning, Implementing and Done, comment only when a plan or code PR is up, merged or closed, check the card's column before every move, link and move pieces' cards, offer cards for changes without one, read a changed card on request, and keep board and card links out of a public code repo.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [/] Delivers AC13–AC20, AC23 in plan.md

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] `yass-shape` and `yass-plan`: start from a card, Planning, plan PR up, plan merged
- [x] `yass-work`: Implementing, PR up and merged or closed, archive merged moves to Done, pieces' cards (cards only for top-level changes, on a yes, per the R17 revision)
- [x] `yass-status`: Will Do cards as waiting to start
- [x] Claim check before every move, in each playbook
- [x] A changed card on request: propose revisions
- [x] No board or card links in a public code repo
- [/] Manual end to end on a scratch board, inline and separate

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- Each lifecycle playbook gets one "With a tracker" section holding only its own moments and the check before each move, pointing at `yass-init`'s Trello workflow for the rest - one source for the workflow, and each playbook stays short (claude, 2026-11-14)
- `yass-status` reads the board (Will Do cards, cards out of step with their change) but never moves or comments - it's the read-only playbook (claude, 2026-11-14)
- Unattended, a failed claim check stops the run and says so in the Log - with nobody to ask, building past a card someone else holds is the clash the check exists to catch (claude, 2026-11-14)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-14 (claude)
- Did: "With a tracker" in `yass-shape`, `yass-plan`, `yass-work` and `yass-status` (the moments, the claim check, pieces' cards, offering cards, a changed card, privacy with plans elsewhere); docs/skills.md says how the playbooks use a board. Unit, e2e, examples and site pass.
- Tried, manually: on the scratch board, creating cards was refused (Trello 403 BOARD_PERMISSION_DENIED); the board had just been closed, so the card flows (AC13–AC20, AC23) couldn't be run there.
- Next: Jaime: run the card flows on a scratch board (from a card, Planning, a claim conflict, a plan and a code PR, archive to Done), inline and with plans kept separate; tick AC13–AC20 and AC23 as they pass.
### 2026-11-14 (claude)
- Did, live on the public board, with card uH69ZiZB and the small change `2026-11-14-skip-yass-ceremony-for-simple-changes` (#97 intent, #98 code):
  - AC13, first half: the change was created from the card with its title and link as `source:`, and `yass status` showed `card: … (column: Planning)`. The `yass-status` half (listing Will Do cards) isn't checked yet.
  - AC14: the card was checked still in Will Do, then moved to Planning with a comment naming the change; it got a comment when the plan's PR (#97) was up and another when it merged.
  - AC15: the card was checked in Planning, then moved to Implementing when building started; ticking boxes added nothing; it got a comment when the code PR (#98) was up and when it merged.
  - AC11, live: after #98, `yass status` showed "Implementing, until its archive merges: then Done".
- Next: AC16 when the archive PR merges (the card should move to Done); then AC13's `yass-status` half, AC17 to AC20 and AC23.
### 2026-11-14 (claude)
- Did: per the R17 revision (intent underneath), work flows from the board into YASS: `yass-init`'s Trello workflow, `yass-shape` and `yass-work` ask whether to create a card only for a new top-level change, and create it only on a yes; `yass-plan` and the workflow never create cards for pieces, which roll up to their change's card; linking to a card that already covers the work stays, for deduplication; the interview for other systems asks only about issues for top-level changes; docs/project-management.md says so up front. Unit, e2e, examples and site pass.
- Next: AC20 as revised (ask for a top-level change, never a card for a piece) gets checked on the next change and pieces worked.
