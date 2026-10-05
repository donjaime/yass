---
platforms: [all]
source: plan.md
follows: 
blocked:
created: 2026-10-05T20:06:03Z
---
# Squash notes

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
docs/monorepo.md and yass-work say what squash merges mean for YASS's rules (a commit that must stand alone needs its own PR), yass-work asks for latitude before pushing or opening a PR, and yass-log names a squash-merged commit's PR. No workflow guidance.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC1–AC5 in [plan.md](../plan.md)

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `docs/monorepo.md`: a short section on squash merges
- [ ] `yass-work`: the own-PR sentence; push and PRs need latitude
- [ ] `yass-log`: name a squash-merged commit's PR
- [ ] Review the diff: no workflow guidance

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
