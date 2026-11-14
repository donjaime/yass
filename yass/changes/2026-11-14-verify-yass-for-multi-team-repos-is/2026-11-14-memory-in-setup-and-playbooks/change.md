---
platforms: [all]
source: https://trello.com/c/kbC4OgjA/10-memory-in-setup-and-playbooks
follows: 
blocked: 2026-11-14-personal-memory-and-your-work
created: 2026-11-14T19:53:58Z
---
# Memory in setup and playbooks

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
yass-init asks who you are and which team you're on and writes the personal memory with yass me; the AGENTS.md section and the playbooks read it at the start of their work; yass-status reports your work by default and everyone's when asked.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC5, AC6, AC11 in plan.md

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `yass-init`: ask who and which team, write with `yass me`, show it when run again
- [ ] `AGENTS.md` section and lifecycle playbooks: read `yass me` at the start
- [ ] `yass-status`: your work by default, everyone's on request
- [ ] Manual: `yass-init` in this repo and a scratch multi-team repo, then a fresh session

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
