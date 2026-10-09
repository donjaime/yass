---
platforms: [all]
source: 
follows: 
blocked:
---
# Pieces own their files

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
Parallel branches on different pieces of one change never touch the same YASS file: each piece's progress stays in its folder, the hook flags commits that reach outside it, and the parent needs no closing commit.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC10, AC11, AC14 in [plan.md](../plan.md)
- [ ] The README's section on large changes explains the rule, and that the parent needs no closing commit

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] 

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
