---
platforms: [all]
source: 
follows: 
blocked:
---
# Worktrees find the plans

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
In any linked worktree, YASS finds the same plans folder as the main checkout and never suggests yass init there. Paths in yass.yaml accept ${VAR:-default}, and with separate plans each checkout gets a gitignored yass/ symlink to the plans folder.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC23–AC29 in [plan.md](../plan.md)
- [ ] Resolving from the main worktree is covered for a bare-repo clone too, or the code says why it isn't

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
