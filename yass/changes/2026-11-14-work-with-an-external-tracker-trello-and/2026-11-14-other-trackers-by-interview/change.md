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
- [ ] Delivers AC25–AC27, AC29 in plan.md

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] Interview in `yass-init`: project, team, issue types, transitions, comments; links and IDs under `tracker:`
- [ ] Where the workflow goes: harness memory; `tracker.local.md` (gitignored) only when sure there's none; ask when unsure
- [ ] Lifecycle playbooks follow the remembered workflow at the same moments, and read `tracker.local.md` when present
- [ ] Manual: interview and follow-up session on Claude Code

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
