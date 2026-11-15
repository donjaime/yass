---
platforms: [all]
source: https://trello.com/c/Vu1njypz
follows: 
blocked:
created: 2026-11-15T14:51:37Z
---
# Improve YASS ceremony gradient

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
YASS's ceremony has a rung it was missing, and its playbooks reach it naturally. Someone can start from a card, shape the work with their agent, and then land it as an ordinary pull request or a small stack with thoughtful descriptions, with no change folder, no intent reviewed apart from code, and no box-ticking, when none of that adds value; the card still moves through the board. `yass-shape` also interviews before it drafts, so a PRD, a `change.md` or a brief starts from answers, not guesses. The gradient is: just a pull request; shaped, then plain pull requests; one `change.md`; a PRD with a plan and pieces.


## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] AC1 Given a request to shape something, when an agent follows `yass-shape`, then it interviews before drafting, in rounds: each round asks every question that doesn't depend on one still unanswered, numbered, each with its recommended answer and worded so that "yes" accepts it; it finds facts itself (the code, the docs, the card) instead of asking for them; and it stops when no decision is left assumed, or another answer wouldn't change the outcome — verify: manual: review `kit/.agents/skills/yass-shape/SKILL.md`, and a trial shaping run by a headless agent, summarized in the Log
- [ ] AC2 Given the shaping conversation has settled what and why, when `yass-shape` decides where the work lands, then it picks among a PRD in a large change, a small change's `change.md`, and plain pull requests with no change; it says what points to a folder (someone outside the conversation must approve the intent, the work will span sessions or agents, or it's hard to undo) and what points to plain pull requests (the person deciding is in the conversation, and it fits a pull request or a small stack); it asks when that's ambiguous; and unattended it creates a folder — verify: manual: review the playbook
- [ ] AC3 Given the work lands as plain pull requests, then `yass-shape` writes a short brief (the problem, what changes, what's out of scope, how we'll know it worked), gets the person's go-ahead in the conversation, creates no change folder, and hands the brief to `yass-work` — verify: manual: review the playbook, and the trial run of AC1 ending this way with no folder created
- [ ] AC4 Given a brief from shaping and no change, when an agent follows `yass-work`, then it builds from the brief with no boxes, Log, Decisions or separate intent commits; the pull request's description leads with the brief (for a stack, the bottom one carries the whole brief and each one above says its part); commits say `yass: none` where plans are kept elsewhere; and work that came from the project management system is no longer said to need a change — verify: manual: review `kit/.agents/skills/yass-work/SKILL.md`
- [ ] AC5 Given a yass folder with a Trello board, when a card is shaped and lands without a change, then the card moves to Planning when shaping starts, with a comment that it will land as pull requests, to Implementing when building starts, and to Done when the last pull request merges, with the same check before each move; a card worked with no shaping still skips Planning — verify: manual: review the Trello workflow in `kit/.agents/skills/yass-init/SKILL.md` and `docs/project-management.md`
- [ ] AC6 Given the README's rules, the `AGENTS.md` section `yass init` writes, `docs/project-management.md` and each playbook's description, then they describe the same four-rung gradient in the same words, and the CHANGELOG has an Unreleased entry — verify: manual: review; `go test ./...` and `tests/e2e.sh` pass (the installed files match `kit/`)
- [ ] AC7 Given this repo's own installed playbooks and `AGENTS.md`, then they're left as they are, to pick the new text up at the next release's `yass upgrade` — verify: `git diff --stat` shows no change under `.agents/`, `.claude/` or the root `AGENTS.md`

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] Read grill-me's source before borrowing from it
- [ ] The ceremony path: `yass-shape` landing and brief, `yass-work` case, Trello row, README, AGENTS.md section, docs, CHANGELOG (first pull request)
- [ ] The interview in `yass-shape` (second pull request, stacked)
- [ ] Trial run with a headless agent

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- A small change, not shaped-then-plain-pull-requests - it changes how the playbooks behave for every user, so the acceptance criteria are approved first (Jaime, 2026-11-15)
- The brief's record is the pull request description; nothing is added to the card beyond its usual comments - `yass-log` already reads pull request descriptions for decisions made outside a change (claude, 2026-11-15; for review)
- Two pull requests in one stack: the ceremony path, then the interview - they're separable and review differently (claude, 2026-11-15; for review)
- No CLI change - everything here is playbook and doc text (claude, 2026-11-15; for review)
- Goal and acceptance criteria approved (Jaime, 2026-11-15)
- AC1 revised before any code: the interview runs in rounds, not one question at a time - grill-me's source (mattpocock/skills, `grilling`, MIT) asks every question whose prerequisites are settled in one round, each with a recommended answer worded so "yes" accepts; that's fewer round trips for the same rigor. Ideas borrowed, no text copied (claude, 2026-11-15; for review)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
