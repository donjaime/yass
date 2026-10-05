---
platforms: [all]
source: plan.md
follows: 
blocked:
created: 2026-10-05T20:06:03Z
---
# Delivered criteria count

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
A parent criterion counts as done in yass status and yass archive once every piece delivering it is done, yass archive marks those criteria [x], and an e2e scenario lands a three-piece change one squash-merged branch at a time.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC6–AC12 in [plan.md](../plan.md)

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] Parse `Delivers` boxes (lists, ranges, trailing words); go test
- [ ] Count delivered criteria in `status` progress and `next:`
- [ ] `yass archive`: don't refuse for them; mark them `[x]` in the archived `plan.md`
- [ ] e2e: each case, and the three-piece squash scenario

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
