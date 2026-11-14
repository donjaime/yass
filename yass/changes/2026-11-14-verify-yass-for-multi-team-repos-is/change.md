---
platforms: [all]
source: https://trello.com/c/7X5M8REf/8-verify-yass-for-multi-team-repos-is-designed-properly
follows: 
blocked:
created: 2026-11-14T19:39:57Z
---
# Verify YASS for multi-team repos is designed properly

## Goal
<!-- Intent. One paragraph; the detail is in prd.md (why and what) and plan.md (how and acceptance). -->
YASS knows who you are in a repo with many teams. Each person has one unversioned YASS memory per clone, in their own user folder and shared by the clone's worktrees, saying who they are and which team (yass folders) they're on. `yass-init` sets it up. What a team shares, starting with its project management workflow, goes in a team memory committed in the team's yass folder, reviewed once and followed by every teammate's agent. `yass status` shows just your work by default (`--all` for everyone's), and `yass new` from the repo root puts a change in your folder. The workflow for Jira and other systems always lives in that team memory, never in a harness's memory or a `tracker.local.md`, which settles the tracker change's open criteria for it.


## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)" for calls that span the whole change. -->
- A large change, started from Trello card 7X5M8REf, that also takes over the tracker change's open criteria for other systems (simplifying its AC27) - per-person state belongs in one place, and the card asks for the same memory (Jaime, 2026-11-14)
- The memory is a file per clone in the user's own folder, outside the repo; every worktree of the clone shares it, and a separate clone is set up again - nothing to gitignore, and a clone is the natural unit (Jaime, 2026-11-14)
- The personal memory is a global `settings.json` in the user's config folder, with an entry per clone, read and written only through `yass me` (R1–R3, design §1 and §2, AC1–AC4 and piece 1's Goal revised while building piece 1) - an agent's permissions usually stop at the project's folders, so it couldn't read a file in `~/.config` without asking; going through the CLI it never has to. This replaces the per-clone markdown file planned first (Jaime, 2026-11-14)
- One markdown file: a few fields at the top that the binary reads, and a body for the person's own notes for agents (Jaime, 2026-11-14). Superseded below: a global settings file, through the CLI
- `yass status` shows just your work by default when the memory names your folders, and `--all` shows everyone's (Jaime, 2026-11-14)
- `yass-init` sets the memory up during setup, asking once per clone (Jaime, 2026-11-14)
- Two layers: a personal memory per clone (who you are, which team) and a team memory committed in each yass folder (the project management workflow and anything else the team shares). The workflow for systems other than Trello always goes in the team memory, never a harness's memory, a `tracker.local.md` or the personal memory - a team's workflow is the team's: written once, reviewed like a plan, followed by every agent, and private when the plans are (Jaime, 2026-11-14)
- PRD approved for planning (Jaime, 2026-11-14)
- "Your work" is the changes in your folders, changes waiting on one of yours, and changes with an unmerged branch whose commits are yours (your git email); naming a change is never filtered - the PRD left cross-team work open: seeing who waits on you is the useful part, without pulling in every root change (claude, while planning; for review, 2026-11-14)
- The "set up `yass me`" note appears only in repos with two or more yass folders - with one, there's nothing to filter, so the note would be noise (claude, while planning; for review, 2026-11-14). Superseded below: no note at all
- The personal memory's command is `yass me` (claude, while planning; for review, 2026-11-14)
- Teams are an optional addition: `yass status` never notes how to set up the memory, and `yass-init` asks whether teams share the repo before asking anything about them; a solo developer sets nothing and keeps today's view, even with several yass folders (R4, R8, AC5, AC9 revised while building piece 2) - Jaime works solo with public and private plans, and the note nagged him about folders that are all his (Jaime, 2026-11-14)
- Plans kept separate with a board (the tracker change's AC23) stays out of this change; Jaime takes it as its own card (Jaime, 2026-11-14)

## Log
<!-- Progress. Change-level notes; each piece keeps its own Log.
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
