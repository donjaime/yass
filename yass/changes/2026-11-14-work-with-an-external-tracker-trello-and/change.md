---
platforms: [all]
source: 
follows: 2026-10-04-monorepos-at-scale-and-plans-repos
blocked:
created: 2026-11-14T15:43:58Z
---
# Work with an external tracker: Trello and others

## Goal
<!-- Intent. One paragraph; the detail is in prd.md (why and what) and plan.md (how and acceptance). -->
YASS fits inside a team's outer loop without replacing it: a yass folder can name the Trello board that governs it, the agent sets the repo and board up through a new `yass-init` playbook, and cards move from Will Do through Planning and Implementing to Done as their changes do, with a best-effort check for cards someone else already claimed. Other trackers, like Jira, get open-ended settings in `yass.yaml` and a workflow the agent learns in an interview and keeps in its own memory. The binary only validates; it never calls a tracker. Files stay the source of truth, and the docs say how YASS sits inside a tracker's workflow. Wanted before the 0.5.0 release.


## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)" for calls that span the whole change. -->
- YASS fits inside a workflow with an external tracker rather than leaving tracking out entirely; it still doesn't replace the tracker, and files stay the source of truth. This refines, not reverses, the monorepos-at-scale call that kept progress out of trackers, and the docs change to say so - teams already run an outer loop, and agents can reach it (Jaime, 2026-11-14)
- The binary only validates tracker settings and shows a change's card and expected column; the agent harness does all tracker calls (MCP, API or CLI) - keeps the binary offline and simple (Jaime, 2026-11-14)
- Opinionated Trello workflow: one board per yass folder, lists Ideas, Will Do, Planning, Implementing, Done, one card per top-level change, comments only at plan-up, plan-merged, PR-up and PR-merged-or-closed - low noise on the card, detail stays in files (Jaime, 2026-11-14)
- Claim detection is optimistic concurrency, best effort and not a gate, built into the playbooks - Trello has no compare-and-move (Jaime, 2026-11-14)
- Pieces that clearly cover a card link it as `source:` (ask when ambiguous), and their cards move through the columns like a top-level change's (Jaime, 2026-11-14)
- `yass-init` adopts a board: bootstraps a blank one, matches an existing one's lists by name, asks when they don't fit; it and `yass init` are idempotent, and repo setup is documented as going through the agent (Jaime, 2026-11-14)
- Other trackers: open key/value settings in `yass.yaml`; the workflow comes from an interview and lives in harness memory, never in YASS (Jaime, 2026-11-14)
- No two-way sync; the human can tell the agent a card changed, and it proposes plan revisions (Jaime, 2026-11-14)
- Workflow memory for other trackers goes in the harness's memory; only when the agent is sure the harness has none does it use a gitignored local file in the yass folder, which every tracker-aware playbook reads when present; unsure, it asks - most harnesses have memory, and a guess could write workflow context where it isn't wanted (Jaime, 2026-11-14)
- With a tracker adopted, the agent offers to create a card for a change or piece that has none, per the tracker's workflow - keeps the board complete without forcing it (Jaime, 2026-11-14)
- A piece's card moves to Done when the piece's own PR merges and its boxes are done, since pieces archive with their parent (Jaime, 2026-11-14)
- Private plans keep their tracker setup private: settings in the plans folder's own `yass.yaml`, and no board, card or workflow details written into the code repo (Jaime, 2026-11-14)
- PRD approved for planning (Jaime, 2026-11-14)
- With separate plans, the public code repo's `yass.yaml` holds only the pointer (`path:`, plus `ignore:`, which is about the code repo's own folders); every other setting moves to the plans folder's own `yass.yaml` (R18 revised while planning) - a public repo shouldn't carry any of the private setup (Jaime, 2026-11-14)
- R6 reworded while planning: a piece's card shows Done once the piece is done, and a done top-level change says its card moves when the archive merges, since `yass status <change>` doesn't show archived changes - same intent, says what the binary can actually see (claude, 2026-11-14; for review)
- The Trello workflow lives in skill text: the full rules in `yass-init`'s SKILL.md, and a short tracker step with its own moments and the claim check in each lifecycle playbook - the binary carries only each skill's SKILL.md, and teaching it to carry more files would grow install, upgrade and deinit for no user-visible gain (claude, 2026-11-14; for review)
- Reversed while building piece 1: no yass folder's own `yass.yaml`. A `yass.yaml` points to its yass folder, any name, in the repo or outside it, and holds that folder's settings, as before this change. Private plans keep their settings in that one file, which can be kept out of git; when it points outside the repo and git would commit it with anything besides `path:` and `ignore:`, `yass status` notes it (not a warning) so a human checks it's intentional, and `yass-init` asks before writing settings there. This replaces the earlier call that moved every setting into the plans folder's own `yass.yaml` (R18, design §2, AC21, AC22 and AC30 revised) - two settings files, and the rules for which one wins, were more machinery than keeping private things private needs (Jaime, 2026-11-14)
- The CI-recipe and Windows/Linux `yass update` validations wait for a later minor release; this change goes in before 0.5.0 (Jaime, 2026-11-14)

## Log
<!-- Progress. Change-level notes; each piece keeps its own Log.
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
