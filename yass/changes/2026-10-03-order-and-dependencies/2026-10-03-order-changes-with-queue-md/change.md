---
platforms: [all]
source: 
follows: 
blocked:
---
# Order changes with queue.md

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
A yass folder's optional queue.md ranks its changes, yass status follows it, yass archive keeps it tidy, and the hook treats reordering as intent.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC1, AC2, AC3, AC4, AC5, AC6, AC7 and AC8 of the plan.

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] Parse `queue.md` per yass folder (list items only, notes ignored), with a unit test
- [ ] Sort each folder's changes in `yass status` by queue position, unlisted after by date
- [ ] Warn about unknown, archived, piece and duplicate entries
- [ ] `yass archive` drops the change's line and stages it
- [ ] Hook: modifying `queue.md` with code is intent
- [ ] e2e checks
- [ ] README, yass README template, `yass-status`, solo-app example `queue.md`

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
