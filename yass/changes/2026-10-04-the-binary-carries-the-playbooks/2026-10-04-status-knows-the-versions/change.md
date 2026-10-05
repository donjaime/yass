---
platforms: [all]
source: plan.md
follows: 
blocked: 2026-10-04-the-binary-carries-the-playbooks/2026-10-04-init-upgrades-by-version
---
# Status knows the versions

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
yass status adds one line when the binary and a repo's YASS files are out of step: upgrade your binary, or yass init would upgrade the repo.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC28–AC30 in [plan.md](../plan.md)

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `yass status`: the version line
- [ ] e2e: older, newer, equal, none

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
