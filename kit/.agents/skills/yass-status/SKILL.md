---
name: yass-status
description: Report where YASS work stands. Summarize progress across active changes, what's blocked and why, decisions made recently, stale changes, and changes ready to archive, then list what needs a human decision. Read-only. Use when someone asks where things stand, what's next, or what needs them.
---

# yass-status

This playbook only reads: it changes no files and never moves or comments on a card. The human wants what needs them, not narration: fit it on one screen, and leave out any heading with nothing under it.

## Gather
- `yass me` says whose work this is. When it names their folders, `yass status` lists just their work: report that, and say how much else is in flight (`--all` when they ask about everyone's). With no folders, everything is theirs.
- `yass status <change>` for every change that isn't `not started`: its `[/]` boxes are what's actively being worked on, and it's where blocked and nearly done changes show their detail.
- What happened recently (ask since when, or use a week): git history of each folder `yass root` prints, Log entries, and decisions (`yass decisions --since <date>`).
- With plans kept apart from the code (`yass root -v` says `separate`), pull them first, and pass on what `yass status` says about them being behind or uncommitted.
- With a Trello board (`tracker:` in a yass folder's `settings.yaml` or `yass.yaml`) and a tool to read it: the cards in Will Do, and whether each change's card is in the column `yass status <change>` says it should be. Another tracker: what the folder's `team.md` workflow says to report.

## Report
- **Progress,** one line per change, in the order `yass status` lists them (a yass folder's `queue.md` ranks its changes). Keep changes in progress apart from ones `not started`, and name the `[/]` items.
- **Blocked** changes, with the question a human has to answer (if the answer changes intent, `yass-shape` or `yass-plan` makes the edit), and changes `waiting on:` others, with whether those are moving.
- **Decisions made recently,** with who made them, so the human can object. A reversal is recorded as a new decision, not by rewriting the old one.
- **Intent edits waiting underneath work in progress** (a plan or PRD revision on its own branch): they get reviewed first.
- **Ready to archive:** changes `yass status` marks `done` (`yass archive <change>`).
- **Stale:** no activity in a while. Resume with `yass-work`, or drop what's left (`[-]`, with a reason in Decisions) and archive.
- **The board:** Will Do cards, as work waiting to start, and cards in a different column from where their change says they should be. Someone may have picked those up: ask before anyone moves them.
- **Versions out of step** (a note at the end of `yass status`): `yass-update` sorts out both.

End by offering one next move, and don't make it until the human says so. Asked "what's next?", it's the first change in `yass status` order that isn't `done` or blocked; without a `queue.md`, say that nothing ranks the changes.
