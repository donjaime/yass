---
name: yass-init
description: Set up YASS in a repo and connect a yass folder to its tracker. Runs `yass init` for what's missing, records who you are on a repo shared by teams, adopts a Trello board, or learns another tracker's workflow (Jira, Linear) by interview. Also holds the Trello workflow the other playbooks follow. Use for "set up YASS here", "connect our Trello board", "connect Jira", "change how we update our tracker".
---

# yass-init

`yass` is the YASS CLI, on your PATH. YASS is files in the repo: it never replaces the tracker and never calls it. You do, with whatever tool your harness has for it (a connector, an API, a CLI). This playbook is safe to run again: check first, change only what's missing, and say what was already there. Commit what it writes only with the latitude to; otherwise give the human the commands.

## Set up
1. **Check what's there:** `yass root -v` (each yass folder, and whether its plans are inline or outside the repo), `yass status` (whether it all reads cleanly), `yass me`, the `AGENTS.md` section (`yass:begin`), the playbooks (`.agents/skills/`, `.claude/skills/` or the user folder), the hook (`git config core.hooksPath`), and `tracker:` in a yass folder's `settings.yaml` or `yass.yaml`. Tell the human in a few lines, and offer only what's missing.
2. **Set the repo up,** if it isn't. Ask which options they want, run `yass init <options>` (it writes only what's missing), show what it wrote and run `yass status`. The commit is `chore: adopt YASS`.
   - `--claude` when you're Claude Code; `--global` puts the playbooks in their user folder instead of the repo; `--hooks` adds the optional pre-commit hook.
   - `--path <folder>` names a yass folder other than `yass/`, in the repo or outside it; outside is how plans are kept private.
3. **Teams,** once per clone, only when `yass root` lists more than one yass folder and `yass me` has no folders yet. Ask whether several teams share this repo.
   - **Working alone** (one person with public and private plans, say): set nothing. Everything is theirs.
   - **Teams:** ask who they are and which yass folders are their team's, then `yass me --name "<name>" --team <team> --folders <yass folder>[,<another>]`. New changes go in the first folder, and `yass status` shows just their work (`--all`: everyone's).
   - Anything they'd tell an agent every session can go in `yass me --notes "…"`. Never open the settings file itself.
4. **Offer a tracker** for any yass folder without one: Trello, which has a built-in workflow, or any other, whose workflow comes from an interview.

## Adopt a Trello board
1. **You need a Trello tool.** With none, say so and stop: the human adds one and asks again. Never ask for an API key or token in chat.
2. **Ask for the board** (its `https://trello.com/b/…` link) and which yass folder it governs: one board per yass folder.
3. **Match its open lists** to the five YASS uses, in this order: Ideas (the backlog), Will Do (ideas planned for), Planning, Implementing, Done.
   - **Blank board:** create the five, in that order.
   - **All five there and nothing else** (by name, ignoring case, spaces and hyphens): use them as they are.
   - **Anything else** (one missing, extras, two that could match): show which list maps to which use and what's left over, and ask: rename, create the missing ones, leave extras alone, or pick another board. Change neither the board nor any file until they answer.
4. **Write the settings** to `settings.yaml` at the top of that yass folder (`yass root` prints where), never to `yass.yaml`, keeping what's already in the file. With plans kept outside the repo, the code repo then never shows the board.
   ```yaml
   tracker:
     trello:
       board: https://trello.com/b/AbC123/payments
       lists:          # each list's Trello ID (the 24-character id), by role
         ideas: …
         will-do: …
         planning: …
         implementing: …
         done: …
   ```
5. **Check it:** `yass status` warns about nothing in the tracker settings. The commit goes where the yass folder lives (the plans repo, when it's elsewhere).

## Connect another tracker
For Jira or anything else, YASS learns the team's workflow once and keeps it in `team.md` at the top of the yass folder, beside `settings.yaml`. It's committed with the plans and reviewed like one, so every teammate's agent follows the same workflow, and it's as private as the plans are.
1. **Look first.** If `team.md` has a `## Project management` section, that's the workflow: tell the human it's there, follow it, and ask nothing about it.
2. **You need a tool for the tracker.** With none, say so and stop. Never ask for a key or token in chat.
3. **Interview the human,** briefly:
   - which project, team or board this yass folder's work belongs to;
   - how work maps: one issue per top-level change? Pieces as sub-tasks, stories under an epic, or nothing? Which issue types?
   - which status or transition matches each moment in the table in `trello.md` (beside this file);
   - what to comment, when, and what to leave alone (fields, assignees, sprints, anything their process owns);
   - whether, and how, to create an issue for a new top-level change that has none (pieces never get one).
4. **Write it into `team.md`** under `## Project management`: each of those moments with what to do in their system, plus any rule they gave. Create the file if there's none (`# <yass folder>: team memory`, then that section). Show it to them and fix what they correct.
5. **Store only identifiers** under `tracker:` in the folder's `settings.yaml`, named after the tool (`jira: {site: https://acme.atlassian.net, project: PAY}`): links and keys, nothing about the process. YASS never checks them.
6. **Nowhere else:** not your harness's memory, `yass me`, `AGENTS.md`, `yass.yaml` or a playbook. The workflow is the team's, so it lives with the team's plans.

The other playbooks then do what `team.md` says at each moment, with the same check before each change of status as `trello.md` describes: the issue should be where the last moment left it.

## The Trello workflow
It's in `trello.md`, beside this file: which moments move a card or add a comment, the check before every move, and the rules for cards. The other playbooks read it whenever a change's yass folder has a Trello board.
