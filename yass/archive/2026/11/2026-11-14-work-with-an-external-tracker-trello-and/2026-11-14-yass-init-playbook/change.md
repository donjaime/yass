---
platforms: [all]
source: 
follows: 
blocked: 2026-11-14-tracker-settings-and-card-view
created: 2026-11-14T16:01:44Z
---
# yass-init playbook

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
A new yass-init playbook sets a repo up through the agent, idempotently, by running yass init; adopts a Trello board (bootstraps a blank one, matches an existing one's lists, asks when they don't fit); and holds the full Trello workflow. Install docs, the README and the landing page lead with asking the agent.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [x] Delivers AC1–AC8, AC30 in plan.md

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] `kit/.agents/skills/yass-init/SKILL.md`: check what's set up, run `yass init`, offer a tracker
- [x] Adopting a Trello board: bootstrap, match by name, ask on mismatch, write `tracker.trello`
- [x] The Trello workflow section (columns, moments, claim check, pieces, privacy)
- [x] `AGENTS.md` section template names `yass-init`; README playbook table and count
- [x] e2e: `init` twice changes nothing; init/upgrade/deinit carry `yass-init`
- [x] `docs/install.md`, README and landing page lead with the agent prompt; `tests/site.sh`
- [x] Manual: AC1, AC4–AC7 on a scratch board

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- The install prompt's repo part ends by handing off to the `yass-init` it just installed, and `yass init`'s next steps name it - before `yass init` runs, a repo has no playbooks (unless they're in the user folder), so the prompt is the way in and `yass-init` finishes setup and connects a tracker (claude, 2026-11-14)
- The claim check compares the card's list with the column before the move (Will Do before Planning, Planning before Implementing, Implementing before Done), rather than with `yass status <change>`'s column, which is where the card belongs after it - the card is checked before the move happens (claude, 2026-11-14)
- With no Trello tool in the harness, `yass-init` stops and says to add one, and never asks for a key or token in chat - credentials stay with the harness (claude, 2026-11-14)
- Lists are matched by name ignoring case, spaces and hyphens, so "Will Do", "will-do" and "WillDo" all match - teams name them differently; anything less certain goes to the human (claude, 2026-11-14)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-14 (claude)
- Did: `kit/.agents/skills/yass-init/SKILL.md` (setup, adopting a board, the Trello workflow); the `AGENTS.md` section, README, docs/skills.md and the landing page name it (seven playbooks); docs/install.md, the README and the page lead setup with the agent, and the install prompt hands off to `yass-init`; `yass init`'s next steps mention it. e2e: `init` twice changes no file, upgrade adds `yass-init` back, deinit removes it, the AGENTS.md section names it (755 pass); kit_test and site.sh list it.
- Did, manually: AC1 (scratch repo, `yass init --claude` writes `yass-init` beside the others); AC4 (this repo: everything set up, both yass folders have a board, so nothing to offer but `yass upgrade` at release); AC5 and AC30 (two blank boards bootstrapped with the five lists, settings in each folder's `settings.yaml`, the private one in the plans folder, `yass status` clean), done by these same steps before the playbook was written; AC6 (the public board, already matching, adopted again with no list created and the same IDs).
- Did, manually: AC7 on a scratch board Jaime OK'd (lists Backlog, Doing, done, Archive): the adopt step matched only `done` to Done, showed the four missing roles and the three left over, and asked what to do; no list was created or renamed and no file changed. Jaime closes the scratch board.
- Next: piece done once its PR merges; then `2026-11-14-trello-in-the-lifecycle-playbooks`.
