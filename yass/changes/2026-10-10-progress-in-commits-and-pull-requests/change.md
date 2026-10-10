---
platforms: [all]
source: Jaime, 2026-10-10: PR descriptions, titles and commits should give a sense of a change's overall progress; light advice, no imposed process
follows: 
blocked:
created: 2026-10-10T12:09:18Z
---
# Progress in commits and pull requests

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
Commits and pull requests can say where their change stands as a whole: yass status <change> --brief prints one line with the change's progress (and, for a piece, its parent's), and yass-work suggests it for commit bodies, pull request descriptions and, in short, titles, without imposing a process.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Given a piece, when you run `yass status <piece> --brief`, then it prints one line: its parent's name, pieces done of all, boxes done of all, then the piece's name and its own boxes — verify: e2e
- [ ] Given a large change, or a small one, then `--brief` prints the same line without the piece part (a small change: just its boxes), and marks a change that's done — verify: e2e
- [ ] Given `--brief` without a change, then it says it needs one — verify: e2e
- [ ] Given `yass-work`, then it suggests the line for commit message bodies and pull request descriptions, and a short form for titles, as advice that doesn't impose a process — verify: manual: review
- [ ] Given the README's CLI list, then it shows `--brief` — verify: manual: review
- [ ] Given this repo's pull requests from this one on, then their descriptions start with the line — verify: manual: the next pull requests

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] 

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
