---
name: yass-init
description: Set up YASS in this repo and connect it to a tracker. Check what's already set up, run `yass init` for what's missing, on a repo shared by teams record who you are and which team's yass folders are yours (`yass me`), and adopt a Trello board for a yass folder (bootstrap a blank board, match an existing one's lists, ask when they don't fit), writing its settings to the folder's settings.yaml. Safe to run again. Also holds the Trello workflow the other playbooks follow. Use for "set up YASS here", "connect our Trello board", "use this board for our plans", or when a playbook needs the Trello workflow. Also connects Jira or any other tracker through an interview about your team's workflow, kept in the yass folder's team.md ("connect Jira", "change how we update our tracker").
---

# yass-init

`yass` is the YASS CLI, on your PATH. This playbook sets a repo up and connects a yass folder to the tracker its team uses. It's safe to run again: check first, change only what's missing, and say what was already there. YASS is files in the repo; it never replaces the tracker and never calls it. You do, with whatever Trello tool your harness gives you (a connector, an API, a CLI).

## Set up
1. **Check what's there.** `yass root -v` lists each yass folder and whether its plans are inline or kept outside the repo; `yass status` says whether it all reads cleanly. Also run `yass me` (who this person is, and their team's yass folders, for this clone), look for the `AGENTS.md` section (`yass:begin`), the playbooks (`.agents/skills/`, `.claude/skills/` or the user folder), the hook (`git config core.hooksPath`), and a tracker: `tracker:` in a yass folder's `settings.yaml` (inside the folder) or in its `yass.yaml`. Tell the human in a few lines what's set up and what isn't. If everything is, say so and offer only what's missing (usually a tracker).
2. **Set the repo up,** if it isn't. Ask which options they want, suggesting what fits:
   - `--claude` when you're Claude Code; `--global` for the playbooks in their user folder instead of the repo; `--hooks` for the optional pre-commit hook.
   - The yass folder is `yass/` by default. `--path <folder>` names another (`--path specs`), in the repo or outside it; outside the repo is how plans are kept private.
   - Then run `yass init <options>`. Running it again writes only what's missing. Show what it wrote and run `yass status`.
   - Commit only with the latitude to (`chore: adopt YASS`); otherwise give the human the commands.
3. **Teams (optional),** once per clone, only when `yass root` lists more than one yass folder and `yass me` has no folders yet. Ask whether several teams share this repo.
   - **Working alone** (one person with public and private plans, say): set nothing. Everything is theirs: `yass status` shows it all, and new changes go in the yass folder nearest where they stand, as without a memory.
   - **Teams:** ask who they are and which team they're on, meaning which of `yass root`'s yass folders are theirs, and save it: `yass me --name "<name>" --team <team> --folders <yass folder>[,<another>]`. The first folder is where a new change goes from the repo root, and `yass status` then shows just their work (`--all`: everyone's).
   - Either way, anything they'd tell an agent every session can go in `yass me --notes "…"`. Never open or edit the settings file itself: `yass me` is the way in.
4. **Offer a tracker** for any yass folder without one. Trello has a built-in workflow (below). Any other tracker (Jira, Linear, Asana, your own) gets its workflow from a short interview, since how it's used depends on your organization. Ask which, if any.

## Adopt a Trello board
1. **You need a Trello tool.** If your harness has none, say so and stop: the human adds one (Trello's connector, for one) and asks again. Never ask for an API key or token in chat.
2. **Ask for the board** (its `https://trello.com/b/…` link) and which yass folder it governs: one board per yass folder.
3. **Read its open lists**, then match them to the five YASS uses, in this order: Ideas (the backlog), Will Do (ideas planned for), Planning, Implementing, Done.
   - **Blank:** create the five, in that order.
   - **All five there,** by name, ignoring case, spaces and hyphens, and nothing else: use them as they are.
   - **Anything else** (one missing, extra lists, two that could match): show the human which list maps to which role and what's left over, and ask what to do: rename, create the missing ones, leave extras alone, or pick another board. Change neither the board nor any file until they answer.
4. **Write the settings** to `settings.yaml` at the top of that yass folder (`yass root` prints where it is), never to `yass.yaml`. With plans kept outside the repo, that puts them in the plans folder, so the code repo never shows the board.
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
   Keep any other settings already in the file.
5. **Check it:** `yass status` warns about nothing in the tracker settings. Commit where the yass folder lives (the plans repo, when it's elsewhere), with the latitude to; otherwise give the human the commands.

## Connect another tracker
For Jira or anything else, YASS has no workflow of its own: it learns your team's, once, and keeps it in the team's memory, `team.md` at the top of the yass folder, beside `settings.yaml`. It's committed with the plans and reviewed like any plan, so every teammate's agent follows the same workflow; with plans kept outside the repo, it's in the plans folder and as private as they are.
1. **Look first.** If `team.md` has a `## Project management` section, that's the workflow: follow it, and ask nothing about it. Tell the human it's there.
2. **You need a tool for it** in your harness (a connector, an API, a CLI). With none, say so and stop. Never ask for a key or token in chat.
3. **Interview the human,** briefly, and only about what they know:
   - which project, team or board this yass folder's work belongs to;
   - how work maps: one issue per top-level change? Pieces as sub-tasks, stories under an epic, or nothing? Which issue types?
   - which status or transition matches each moment YASS has: planning starts, the plan's pull request is up and merges, building starts, a code pull request is up and merges or closes, a piece is done, the change is archived;
   - what to comment, when, and what to leave alone (fields, assignees, sprints, anything their process owns);
   - whether, and how, to create an issue for a new top-level change that has none (pieces never get one: they roll up to their change's).
4. **Write it into `team.md`,** under `## Project management`: the same moments as the Trello table below, each with what to do in their system, plus any rule they gave. Create `team.md` if there's none (`# <yass folder>: team memory`, then that section). Show it to them and fix what they correct. It's a change for the team to review: commit it like a plan, with the latitude to; otherwise give them the commands.
5. **Store only identifiers** under `tracker:` in the yass folder's `settings.yaml`, named after the tool (`jira: {site: https://acme.atlassian.net, project: PAY}`): links and keys the workflow needs, nothing about the process. YASS stores them and never checks them.
6. **Never anywhere else:** not your harness's own memory, not `yass me`, not `AGENTS.md`, `yass.yaml` or a playbook. The workflow is the team's, so it lives with the team's plans.

The lifecycle playbooks then do what `team.md` says at each moment, with the same check before each change of status: the issue should be where the last moment left it; if it's elsewhere, someone may have picked it up, so stop and ask.

## The Trello workflow
The other playbooks follow this whenever a change's yass folder has a Trello board. Work flows from the board into YASS: changes start from cards and keep them moving, and a card is added only for a top-level change the human says yes to. The card is the change's `source:`; `yass status <change>` prints it with the column the change's state puts it in (`card: <link>  (column: Planning)`). The card hears only about the moments below. Everything finer (boxes, the Log, decisions) stays in the change's files.

| When | Move the card | Comment |
|---|---|---|
| Shaping or planning starts on a card in Will Do | to Planning | planning has begun, naming the change folder |
| The plan's pull request is up | | that the plan is ready for review, with the link |
| The plan's pull request merges | | that the plan is accepted |
| Building starts | to Implementing | |
| A code pull request is up | | that it's up for review, with the link |
| A code pull request merges or closes | | which, with the link |
| A top-level change's archive merges | to Done | |
| A piece is done and its pull request merged | to Done | |

- **A card worked without a change** (its intent was unambiguous enough to skip YASS): check it's in Will Do, then move it to Implementing; comment on its pull request when it's up and when it merges or closes; move it to Done when it merges. Planning is skipped.
- **One card per top-level change.** A piece can have its own card, which moves the same way as its piece. When a new piece, or change, clearly covers a card that already exists, make that card its `source:`, so the same work isn't tracked twice; when two might fit, ask.
- **Starting from a card:** asked to shape or plan one, create the change with the card's title and its link as `source:` (`yass new "<card title>" --source <card link>`).
- **No card:** a new top-level change with no card, in a folder with a board: ask whether to create one, and create it, in the column its state implies, only on a yes. A piece never gets a card created for it: it rolls up to its change's card, so decomposing a card's work adds no noise to the board. Otherwise never create cards, issues or lists.
- **Check before every move (best effort).** Just before moving a card, read which list it's in now. It should be in the column before the move: Will Do before Planning, Planning before Implementing, Implementing before Done. If it's anywhere else, someone (another agent, or a person) has probably claimed or moved it already: don't move it or comment, tell the human where it is, and ask. Trello can't move a card only if it's still where you saw it, so this catches most clashes, not all; say so if asked.
- **A card changed on Trello:** when the human says so, read the card (description, comments, checklists), compare it with the change's PRD and plan, and propose revisions through `yass-shape` or `yass-plan`. Nothing flows from the board on its own.
- **Privacy:** with plans kept outside the repo, never put a board or card link in the code repo (commits, pull request descriptions, `AGENTS.md`). Link the card from the plans.
- **Trello's archive is the human's.** Never archive or delete cards or lists.
