---
platforms: [all]
source: 
follows: 
blocked:
created: 2026-11-14T16:01:44Z
---
# Tracker settings and card view

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
yass.yaml can name a yass folder's tracker: tracker.trello is validated and other trackers' keys are stored as-is; when a yass.yaml points outside the repo and git would commit it with settings beyond path: and ignore:, yass status notes it so a human can check it's intentional; yass status <change> shows a change's card and the column its state implies; and an unignored tracker.local.md is a warning. The binary never calls a tracker.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC9–AC12, AC21, AC22, AC28 in plan.md
- [ ] Given `tests/bench.sh`, when run before and after, then `yass status` stays within its targets, with timings quoted in the PR — verify: tests/bench.sh

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `tracker:` in `Config`: validate `trello` (board link, five list IDs, unknown keys), keep other keys as-is
- [ ] A folder's own `yass.yaml`: found beside `changes/`/`archive/`, not a pointer; its settings win; `path:` there warns
- [ ] Warn about non-pointer settings in the code repo's pointer when plans are separate
- [ ] `card:` line in `yass status <change>` with the expected column
- [ ] Warn about a `tracker.local.md` git doesn't ignore
- [ ] Unit tests, e2e flows, bench
- [ ] README `yass.yaml` settings and `docs/separate-plans.md`

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
