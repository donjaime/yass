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
- [ ] Delivers AC13–AC20, AC23 in plan.md

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `yass-shape` and `yass-plan`: start from a card, Planning, plan PR up, plan merged
- [ ] `yass-work`: Implementing, PR up and merged or closed, archive merged moves to Done, pieces' cards, offering cards
- [ ] `yass-status`: Will Do cards as waiting to start
- [ ] Claim check before every move, in each playbook
- [ ] A changed card on request: propose revisions
- [ ] No board or card links in a public code repo
- [ ] Manual end to end on a scratch board, inline and separate

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
