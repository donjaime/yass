---
platforms: [all]
source: 
follows: 
blocked:
---
# Dependencies through blocked:

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
blocked: can name the changes a change waits on; yass status shows what it's waiting on until they're done, and yass archive respects it.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC9, AC10, AC11, AC12, AC13, AC14 and AC15 of the plan.

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] Resolve `blocked:` items to changes across yass folders; all resolve means dependencies
- [ ] `waiting on:` in `yass status`, and the clear-it hint in `yass status <change>`
- [ ] `yass archive` refuses only on a reason or an unmet dependency
- [ ] Warn about unresolved dated names and cycles
- [ ] e2e checks
- [ ] README, `yass-work`, `yass-plan`, `yass-status`, monorepo example

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
