---
platforms: [all]
source: 
follows: 
blocked:
---
# Upgrade message says upgrade

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
Running install.sh --upgrade ends with next steps for an upgrade, not the first-time adoption steps.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Given a repo with YASS installed, when `install.sh --upgrade` runs, then it says YASS is upgraded and suggests a `chore: upgrade YASS` commit, not `chore: adopt YASS` — verify: tests/e2e.sh
- [ ] Given a repo without YASS, when `install.sh` runs, then the first-time next steps are unchanged — verify: tests/e2e.sh

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
