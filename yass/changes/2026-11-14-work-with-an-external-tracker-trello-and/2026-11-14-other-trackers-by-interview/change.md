---
platforms: [all]
source: 
follows: 
blocked: 2026-11-14-trello-in-the-lifecycle-playbooks
created: 2026-11-14T16:01:44Z
---
# Other trackers by interview

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
For Jira or any other tracker, yass-init interviews the human about their organization's workflow and saves it to the harness's memory (or, only when sure there's none, a gitignored tracker.local.md in the yass folder), and the lifecycle playbooks follow it at the same moments as Trello's.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [/] Delivers AC25–AC27, AC29 in plan.md

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] Interview in `yass-init`: project, team, issue types, transitions, comments; links and IDs under `tracker:`
- [x] Where the workflow goes: harness memory; `tracker.local.md` (gitignored) only when sure there's none; ask when unsure
- [x] Lifecycle playbooks follow the remembered workflow at the same moments, and read `tracker.local.md` when present
- [ ] Manual: interview and follow-up session on Claude Code

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- The interview asks only about the moments YASS already has (planning starts, plan PR up and merged, building starts, code PR up and merged or closed, piece done, archived), and the playbooks act at those moments for any tracker - one set of moments for every tracker keeps the lifecycle playbooks the same; what changes is the action (claude, 2026-11-14)
- "Sure there's no memory" means no memory tool and no memory folder named in the agent's instructions; anything less is "not sure", so the agent asks - a wrong guess either loses the workflow or writes it where it isn't wanted (claude, 2026-11-14)
- Kept as planned: the workflow is per person, in each agent's memory. Jaime raised whether a team should be able to commit one shared workflow; that's left for after this change, noted in the PR (claude, 2026-11-14; for review)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-14 (claude)
- Did: "Connect another tracker" in `yass-init` (the tool, the interview, writing the workflow down, where it's remembered, identifiers only under `tracker:`, telling teammates); an "Another tracker" bullet in each lifecycle playbook's tracker section, reading `tracker.local.md` when present; `yass-status` reports for another tracker read-only; the `AGENTS.md` section and docs/skills.md cover it. Unit, e2e, examples and site pass.
- Next: Jaime: run the interview once with a real Jira project (or any tracker) on Claude Code, then shape a change in a new session to see the remembered workflow followed (AC25, AC26); AC27 and AC29 need a harness without memory, or `tracker.local.md` written by hand to check it's read.
