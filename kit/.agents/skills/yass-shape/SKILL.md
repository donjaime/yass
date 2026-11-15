---
name: yass-shape
description: Shape a change in conversation with a human, and decide how much ceremony it needs. Turns a problem, a card or a plan from the harness's plan mode into a prd.md in a new change folder, or into a short brief that lands as plain pull requests. Also revises an active change's PRD. Use when someone wants to build a new feature, component or system, think a card through before building it, save a plan as a YASS change, or change what a large change promises.
---

# yass-shape

A PRD says what should change or exist, and why. It doesn't describe the current system: link to the code and its docs instead of restating them. The PRD is intent, so keep code out of the edits you make here, and commit only with the latitude to.

Shaping is a conversation in which a human decides what to build and why: explore, offer options, and ask, rather than rushing to a finished document. It ends at an approved PRD, or at an approved brief when the work lands as plain pull requests. It never plans or builds. Record calls in `## Decisions`, not the Log: the first Log entry marks the start of work.

## Shaping something new
1. **Start from what exists.** A plan this session already has (from the harness's plan mode, or a file the human points to) is your first draft: carry over its problem, scope, decisions and open questions, and ask only about what the PRD needs and the plan doesn't say. Otherwise, understand the problem first: who it's for, what evidence says it matters, and what success looks like.
   - `yass me` says whose yass folder a new change goes in, and their team is who it's for.
   - Check for earlier and overlapping work: `yass status --archived`, `yass decisions --about "<words>"`, and `yass status` for what's in flight.
2. **Frame options before requirements.** For a non-trivial problem, sketch 2–3 ways to scope it (appetite, rough solution, risks) and let the human pick. Skip this when the scope is already clear or already picked.
3. **Decide where it lands,** with the least ceremony that does the job. If the human has said which they want, that's the answer; if it's ambiguous, ask; unattended, create the folder.
   - **A large change** (a PRD here, then a plan): a new feature, component or system, more pull requests than a small stack, or intent that someone outside this conversation has to approve. Carry on below.
   - **A small change** (one `change.md`): about one pull request's worth, whose Goal and Acceptance should still be agreed, or kept, apart from the code. Hand what you've settled to `yass-work`, which creates it.
   - **Plain pull requests, no change:** the person deciding is in this conversation, the work fits a pull request or a small stack, and nobody will need to resume it from files. See "Shaped, then plain pull requests".

   A folder earns its keep when someone outside the conversation must approve the intent, when the work will span sessions or agents, or when it's hard to undo.
4. **Create it:** `yass new "<title>" --large [--source <link>] [--follows <archived change>]` (in plan mode, once you can write files again). Fill in `prd.md`:
   - **Why:** the problem, with evidence.
   - **Users and outcomes:** who, and measurable targets.
   - **Requirements:** `- **R1** [M1] A user can …`. Observable, one behavior each. IDs are never reused.
   - **Non-goals:** everything you decided not to do. Agents treat these as walls.
   - **Milestones:** slices that each leave users better off.
   - **Open questions:** anything still undecided.
5. **Write the change's one-paragraph Goal** in `change.md`, and the big calls in its `## Decisions` with who made them. A choice the human made in their plan is theirs: credit them.
6. **Its pull request** leads in plain words with what's proposed and why; requirement IDs go in the collapsed tracking block (`yass-work`, "Write pull requests and commits for people").
7. **Get a human's go-ahead on the PRD** before planning, unless your team has told you otherwise. If it came from an approved plan, say what you added or changed beyond it. In a fully autonomous run where approvals are yours, approve it and record that in `## Decisions`.
8. **Offer `yass-plan` next.** It can use the harness plan's approach too.

## Shaped, then plain pull requests
Some work deserves the thinking and none of the bookkeeping: no change folder, no intent reviewed apart from the code, no boxes.
1. **Write a brief** in the conversation, a few lines: the problem, what changes, what's out of scope, and how we'll know it worked. Write no file for it.
2. **Get the human's go-ahead** on it.
3. **Hand it to `yass-work`** ("Shaped, no change"). The brief leads the pull request's description, which is its record: `yass-log` finds decisions there.

If the work outgrows that while it's built (more pull requests than a small stack, a call someone else has to approve), say so: that's the moment to give it a folder.

## With a tracker
When the yass folder has a `tracker:` (in its `settings.yaml` or `yass.yaml`), update it at these moments and no others: shaping starts on a card, it's decided the work lands as plain pull requests, and the PRD's pull request goes up and merges. Asked to shape a card, start from its title and description, and give the change the card's title and link (`--source <card link>`). When the human says a card changed, read it and propose PRD revisions.
- **Trello:** what to move and say, and the check before every move, are in `yass-init`'s "The Trello workflow". Read that section; the rest of that playbook is setup.
- **Another tracker:** do what the yass folder's `team.md` says under `## Project management`. None there? Run `yass-init`'s interview first, or ask.

## Revising an active change's PRD
After feedback, a failed assumption or a cut in scope: edit `prd.md` without touching code, record what changed and why in `change.md` `## Decisions`, and tell a human. Then update the plan to match (`yass-plan`).

A finished change is archived and never edited. New intent for archived work is a new change with `--follows`.
