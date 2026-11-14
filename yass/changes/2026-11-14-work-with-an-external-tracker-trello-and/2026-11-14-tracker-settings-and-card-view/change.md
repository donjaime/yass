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
A yass folder can name its tracker: tracker.trello is validated and other trackers' keys are stored as-is. Settings can live in an optional settings.yaml inside the yass folder, merged with its yass.yaml (the folder's winning, differences warned), the same way inline or outside the repo, so private plans keep private settings in the private folder; a committed yass.yaml pointing outside the repo with settings beyond path: and ignore: gets a note. yass status <change> shows a change's card and the column its state implies, and an unignored tracker.local.md is a warning. The binary never calls a tracker.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [x] Delivers AC9–AC12, AC21, AC22, AC28 in plan.md
- [x] Given `tests/bench.sh`, when run before and after, then `yass status` stays within its targets, with timings quoted in the PR — verify: tests/bench.sh

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] `tracker:` in `Config`: validate `trello` (board link, five list IDs, unknown keys), keep other keys as-is
- [-] A folder's own `yass.yaml`: found beside `changes/`/`archive/`, not a pointer; its settings win; `path:` there warns
- [x] Note a `yass.yaml` pointing outside the repo that git would commit with settings beyond `path:` and `ignore:`
- [x] `card:` line in `yass status <change>` with the expected column
- [x] Warn about a `tracker.local.md` git doesn't ignore
- [x] Unit tests, e2e flows, bench
- [x] README `yass.yaml` settings and `docs/separate-plans.md`

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- A yass folder's own `yass.yaml` is `yass/yass.yaml` in an inline folder, or a plans folder's `yass.yaml` with `path: .` (the convention `yass paths` already knew); a `yass.yaml` beside some other `changes/` isn't one - a repo with an unrelated top-level `changes/` folder would otherwise have its pointer taken for a yass folder. A folder's own `path:` other than `.` warns and is ignored, rather than being an error as design §2 sketched (claude, 2026-11-14). Superseded below: no folder's own `yass.yaml` at all
- `tracker:` is read from the raw YAML, not the typed struct - a malformed tracker section is then a warning, not a `yass.yaml` that fails to parse and loses `path:` (claude, 2026-11-14)
- The card's column follows the change's `yass status` state: a Log entry counts as started, as it does everywhere else (claude, 2026-11-14)
- Unit tests cover only logic that needs no files: the Trello checks on YAML parsed in memory, and (until it was dropped below) the settings merge as a pure `overlay()`; the card column, discovery and warnings are left to e2e section 17, which already runs them end to end - after Jaime's review, so the unit tests pay their freight (Jaime, 2026-11-14)
- Dropped the folder's own `yass.yaml` step and the code behind it (discovery, `overlay()`, the warnings about settings in the pointer); the yass.yaml that points to a folder holds its settings, and a note asks to check one pointing outside the repo that git would commit with settings beyond `path:` and `ignore:` - Jaime's reversal, recorded in the parent's Decisions and design §2, merged first as its own intent commit underneath (Jaime, 2026-11-14)
- The checks for committed private settings and for `tracker.local.md` run in `check()`, so every command that loads changes sees them, not only `yass status` (claude, 2026-11-14)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-14 (claude)
- Did: `tracker:` settings and Trello checks (config.go), a folder's own `yass.yaml` in discovery and `Root.settings()` (repo.go), pointer and `tracker.local.md` checks and the card view (tracker.go, commands.go); unit tests and e2e section 17 (740 e2e checks pass; unit, examples and site pass); README and docs/separate-plans.md.
- Did: `tests/bench.sh`, main vs this branch: status 868 vs 795ms, with 100 branches 813 vs 813ms, with 1000 remote branches 1435 vs 1447ms, status <change> 216 vs 222ms, hook 103 vs 100ms; all targets met.
- Did: after review on #88, unit tests no longer touch the disk: `trackerProblems` on in-memory YAML, `overlay()` pulled out of `Root.settings()` and tested pure, and the card-column test dropped as a repeat of e2e section 17.
- Did: reworked after Jaime's reversal: removed the folder's own `yass.yaml` (repo.go and config.go back to one settings file, `Root.settings()` just caches it), the pointer warning became a note in `checkSettings` (tracker.go), e2e 17b/17c rewritten (plans outside the repo, committed vs gitignored pointer, `--strict`, a `specs/` folder), README and docs/separate-plans.md updated. 743 e2e checks pass.
- Did: reran unit, examples, site and `tests/bench.sh` after the rework: status 799ms, with 100 branches 818ms, with 1000 remote branches 1418ms, status <change> 231ms, hook 102ms; all targets met.
