---
name: yass-plan
description: Plan a YASS change. Writes plan.md (approach, acceptance criteria per milestone, validation), splits a large change into PR-sized pieces, records hard-to-undo calls in design.md, and revises the plan after feedback. Use after shaping a PRD, before building a large change, to save a plan from the harness's plan mode as a YASS plan, or when the approach must change.
---

# yass-plan

The plan says how, and how we'll know it's done. Plan text is intent, so keep code out of the edits you make here, and commit only with the latitude to.

Planning mostly runs on its own. The human made the big calls while shaping: turn the approved PRD into a plan without a back-and-forth, and ask only when the PRD leaves a real choice open. It ends at a written plan and never starts building: the change stays `not started` until someone points `yass-work` at it. Record calls in `## Decisions` (or `design.md`), not the Log: the first Log entry marks the start of work.

## Write the plan
1. **Read** `yass me` (who you're planning for, and their yass folders), the change's `prd.md`, and the code and docs it touches. A plan this session already has (from the harness's plan mode, or a file the human points to) is your starting point: its approach, steps and risks become the Approach, pieces and design calls. Don't redo its research; check it still matches the code and the PRD. In plan mode, write it into the change once you can write files again.
   - **No change folder yet?** For something large, run `yass-shape` first (it can start from the same plan). For something small, `yass new "<title>"` and turn the plan into its Goal, Acceptance and Steps: it needs no `plan.md`.
2. **Approach:** the shape of the solution, in a few paragraphs, pointing at existing modules and docs rather than restating them.
3. **Acceptance,** per milestone:
   `- [ ] AC1 (R1) Given …, when …, then … — verify: <test id, e2e flow, or manual: steps + expected>`
   - Observable behavior only, one behavior each, with at least one criterion per requirement in the milestone.
   - Cover the edges that matter: empty, error, offline, slow, denied permission, killed mid-way.
   - Prefer automated checks; `manual:` only when automation is unreasonable.
   - A harness plan is usually a list of steps. Write criteria; don't relabel the steps.
4. **Hard-to-undo calls** (data model, dependencies, architecture, security, public API) go in `design.md`, with at least two real options and who decided. `yass new … --design` creates it with a new change; for an existing one, `yass template design > <change folder>/design.md` and replace `{{title}}`.
5. **Validation:** how the whole change is verified before it's called done.
6. **Its pull request** leads in plain words with the approach and what will count as done; criterion and piece IDs go in the collapsed tracking block (`yass-work`, "Write pull requests and commits for people").
7. **Hand it back.** Say the plan is ready and that building starts when someone points `yass-work` at it. If it came from an approved harness plan, say what you added or changed beyond it.

## Split into pieces
For anything bigger than one pull request. A small change needs neither pieces nor a plan: its `change.md` Steps and Acceptance are enough.
- `yass new "<piece title>" --in <change> [--goal "…"]` for each piece. Pieces nest one level deep.
- One reviewable story per piece, with the main branch green after each. Thin vertical slices beat layers; shared foundations go first.
- A branch working on a piece changes only that piece's folder (and code), so parallel branches never touch the same file; the hook warns when a commit with code reaches past it.
- In each piece's `## Acceptance`, name the plan criteria it delivers (`Delivers AC1, AC3–AC5`), plus anything specific to the piece. `yass status` counts a criterion done once every piece delivering it is, and `yass archive` ticks it, so don't plan a closing commit for the parent.
- Under `## Pieces` in `plan.md`, say what order they go in and why. When a piece truly can't start before another is done, also set its `blocked:` to that piece's folder.

## With a tracker
When the yass folder has a `tracker:` (in its `settings.yaml` or `yass.yaml`), update it at these moments and no others: planning starts on a card that shaping hasn't already moved, and the plan's pull request goes up and merges. For each new piece, look for a card that clearly covers it and make that its `source:`; if two might fit, ask; with none, leave it, and never create one. When the human says a card changed, read it and propose plan revisions.
- **Trello:** what to move and say, and the check before every move, are in `trello.md` in the `yass-init` playbook's folder (next to this playbook's). Read that file; the playbook itself is setup.
- **Another tracker:** do what the yass folder's `team.md` says under `## Project management`. None there? Run `yass-init`'s interview first, or ask.

## Revise the plan
When reality disagrees: edit `plan.md` (and pieces) without touching code, record what changed and why in `change.md` `## Decisions`, and tell a human. Rewording, removing or dropping (`[-]`) an acceptance criterion lowers the bar, so call it out explicitly. If code is already in progress, the revision goes underneath it: see "Intent changes mid-build" in `yass-work`.
