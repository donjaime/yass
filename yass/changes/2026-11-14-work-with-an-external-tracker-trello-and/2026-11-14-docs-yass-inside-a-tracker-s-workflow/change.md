---
platforms: [all]
source: 
follows: 
blocked: 2026-11-14-other-trackers-by-interview
created: 2026-11-14T16:01:44Z
---
# Docs: YASS inside a tracker's workflow

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
The README, a new docs/trackers.md, docs/comparison.md, the landing page and the 0.5.0 changelog say that YASS is files in the repo and fits inside a team's tracker workflow without replacing it, and how to set up Trello or another tracker.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [x] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [x] Delivers AC24 in plan.md
- [x] Given the 0.5.0 changelog, when read, then it describes tracker support and the separate-plans settings move under Migrating — verify: manual

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] README: "What YASS leaves to you" becomes YASS inside a tracker's workflow
- [x] `docs/trackers.md`: the Trello workflow, other trackers, privacy with separate plans
- [x] `docs/comparison.md` and the landing page
- [x] CHANGELOG 0.5.0 entries and migration note
- [x] `tests/site.sh`

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- The README's "What YASS leaves to you" becomes "YASS inside your workflow", keeping the rest of that section (guardrails, CI, approvals) as things YASS still doesn't own - tracking moved from "left to you" to "fits inside", the rest didn't (claude, 2026-11-14)
- The 0.5.0 changelog entry keeps its date line; it's re-dated when the release is tagged (claude, 2026-11-14)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-14 (claude)
- Did: docs/trackers.md (where settings go, Trello's lists and moments, two agents on one board, Jira and others by interview, privacy with plans elsewhere); the README section "YASS inside your workflow" and a link from its tracker settings; docs/comparison.md "Alongside a tracker" (and seven playbooks); a line on the landing page; the 0.5.0 changelog: trackers, `yass-init`, `settings.yaml`, and a Migrating note for settings in a committed pointer. All suites pass (755 e2e).
