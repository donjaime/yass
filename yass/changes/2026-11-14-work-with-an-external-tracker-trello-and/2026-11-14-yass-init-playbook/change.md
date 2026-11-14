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
- [ ] Delivers AC1–AC8 in plan.md

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `kit/.agents/skills/yass-init/SKILL.md`: check what's set up, run `yass init`, offer a tracker
- [ ] Adopting a Trello board: bootstrap, match by name, ask on mismatch, write `tracker.trello`
- [ ] The Trello workflow section (columns, moments, claim check, pieces, privacy)
- [ ] `AGENTS.md` section template names `yass-init`; README playbook table and count
- [ ] e2e: `init` twice changes nothing; init/upgrade/deinit carry `yass-init`
- [ ] `docs/install.md`, README and landing page lead with the agent prompt; `tests/site.sh`
- [ ] Manual: AC1, AC4–AC7 on a scratch board

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
