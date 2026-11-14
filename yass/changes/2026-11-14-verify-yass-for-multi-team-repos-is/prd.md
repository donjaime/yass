# Verify YASS for multi-team repos is designed properly: PRD
<!-- Intent: what should change or exist, and why. Not a description of the current system;
     the code and its docs are that. Edit this file only in commits without code. -->

## Why
In a repo with several teams, each team has its own yass folder ([docs/monorepo.md](../../../docs/monorepo.md#many-teams-in-one-repo)). But YASS doesn't know who you are, or which of those folders is yours:
- **`yass status` shows everyone's work.** In a big monorepo, your team's changes are a few lines among hundreds.
- **`yass new` uses the yass folder nearest where you're standing.** Most people open their agent at the repo root, so every new change lands in the root folder, whatever team it's for.
- **Agents start each session knowing nothing about you:** not your name, not your team, not where your work goes.

Project management has the same gap. The workflow an agent learns for Jira or another system ([the tracker change](../2026-11-14-work-with-an-external-tracker-trello-and/prd.md), R15 and R19) is meant to live in the harness's memory, or in a `tracker.local.md` in the yass folder when the harness has none. That splits YASS state across two places, depends on the harness, and still needs a gitignore. Worse, a team's workflow is the team's, not one person's: when each teammate's agent learns its own copy, the copies drift, and nobody reviews them. ([Trello card](https://trello.com/c/7X5M8REf))

## Users and outcomes
- **People and agents on a multi-team repo.**
  - With an agent open at the repo root, `yass status` shows only your work by default.
  - `yass new` puts a change in your team's folder, with no `--in` and no `cd`.
- **Teams on a project management system other than Trello.** The workflow is written down once, in the team's yass folder, reviewed like any plan, and followed by every teammate's agent, on any harness.
- **Setting up:** a person sets up once per clone, through `yass-init`, saying who they are and which team they're on. When the team already has a workflow, nothing else is asked.

## Requirements
The local memory
- **R1** [M1] Each person has one YASS memory per clone: a markdown file in their own user folder, outside every repo. Every worktree of the clone finds the same file. A separate clone has its own, set up again. It's never in the repo, so nothing needs gitignoring.
- **R2** [M1] Its top fields hold who you are (defaulting to git's `user.name`), your team, and your team's yass folders (one or more, by path). Its body holds your own notes for agents. It holds nothing your team shares: that goes in the team memory (R15).
- **R3** [M1] A `yass` command prints where the memory is and what it holds, and creates an empty one when there's none. The memory is plain markdown that people can edit by hand.
- **R4** [M1] `yass-init` sets the memory up as part of setup: it asks who you are and which team (which yass folders) you're on, and writes them. Running it again shows what's there and changes only what you correct.
- **R5** [M1] The playbooks read the memory at the start of their work, to know who they're working for and where that person's work goes, and from it, which team memory applies.

Just your work
- **R6** [M1] When the memory names your yass folders, `yass status` lists only your work: the changes in your folders, and any other change with an unmerged branch you've committed to. A closing line says how much it left out and that `--all` shows it.
- **R7** [M1] `yass status --all` shows everyone's work, as `yass status` does today.
- **R8** [M1] Without a memory, or with no folders in it, `yass status` shows everything, as today, and says once how to set up a memory.
- **R9** [M1] `yass new` run outside any yass folder's part of the repo (at the root, say) puts the change in your first yass folder. Inside a team's folder, it uses that folder, as today. `--in` still overrides both.
- **R10** [M1] The `yass-status` playbook reports your work by default, and everyone's when asked.

The team memory, and the project management workflow in it
- **R15** [M2] Each yass folder can hold a team memory: one markdown file, committed with the folder's plans, next to its `settings.yaml`. It holds what the team shares with every teammate's agent, starting with its project management workflow. With plans kept outside the repo, it sits in the plans folder, so it's as private as they are.
- **R11** [M2] The workflow for a project management system other than Trello always goes in the team memory of the yass folder it governs. It never goes in a harness's own memory, a `tracker.local.md`, or a person's local memory. This replaces R15 and R19 of the tracker change.
- **R16** [M2] When a yass folder has a tracker but its team memory has no workflow yet, `yass-init`'s interview writes one into the team memory as a proposed change for the team to review, committed like any plan, with latitude. When the workflow is there, setup asks nothing about it.
- **R12** [M2] The lifecycle playbooks read the workflow from the team memory of the change's yass folder. `yass status` no longer checks for a `tracker.local.md`.
- **R13** [M2] The tracker change drops the criteria R11 replaces (AC25–AC27 and AC29, superseded here), and this change delivers their replacements. While this change is built, its pieces' cards exercise the tracker change's open Trello checks (AC17–AC20).

Docs
- **R14** [M1] [docs/monorepo.md](../../../docs/monorepo.md) explains working as one team in a shared repo: the memory, "just your work", `--all`, and where new changes go. The README and docs/project-management.md say where the workflow is kept: the team memory.

## Non-goals
- Syncing the memory between machines, or between clones of the same repo.
- More than one team memory per yass folder, or a team memory that spans folders.
- Verifying identity. The memory says who you are; YASS believes it.
- Any credentials or tokens in either memory.
- Changing how a yass folder is found, or which folders exist.
- Plans kept outside the repo with a board (the tracker change's AC23): that's a separate card.

## Milestones
| Milestone | When it ships, a user can … |
|---|---|
| M1 | set up their own YASS memory once per clone, see just their work in a multi-team repo with `--all` for everyone's, and create changes in their team's folder from the repo root |
| M2 | keep their team's workflow for Jira or any other system in the team's yass folder, reviewed once and followed by every teammate's agent, with the tracker change's last open criteria settled |

## Open questions
- **Your folders and cross-team work.** Should "your work" also include a root, cross-team change whose pieces your folder delivers, or that's waiting on one of your changes? Settle while planning.
- **The team memory's name** (`team.md` in the yass folder is the working name).
- **Where exactly the memory lives** in the user folder on each OS (`~/.config/yass/`, `$XDG_CONFIG_HOME`, Windows), and how a clone is named. Settle while planning, in design.md.
