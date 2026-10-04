---
platforms: [all]
source: 
follows: 
blocked: 2026-10-04-separate-plans-mode, 2026-10-04-repo-qualified-citations
---
# yass: trailers

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
With separate plans, every code commit names its change in a `yass:` trailer that the hooks add automatically and check (a warning by default, enforced with `trailers: require`), and yass status lists each change's and each criterion's code from those trailers.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC40–AC52 in [plan.md](../plan.md)
- [ ] `install.sh --hooks` and `--upgrade` install the new `prepare-commit-msg` and `commit-msg` scripts beside `pre-commit`

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
