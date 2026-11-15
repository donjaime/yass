---
name: yass-shape
description: Shape a change, in conversation with a human, and decide how much ceremony it needs. Turn a problem or opportunity, a card, or a plan already drafted in the harness's plan mode, into a prd.md (why, for whom, outcomes, non-goals, requirements, milestones) inside a new change folder; or, when a folder wouldn't add value, into a short brief that lands as plain pull requests. Also revises the PRD of an active change after feedback. Use when someone wants to build a new feature, component or system, wants to think a card through before building it, wants to save a plan as a YASS change, or when what a large change promises needs to change.
---

# yass-shape

`yass` is the YASS CLI, on your PATH. A PRD says what should change or exist, and why. It doesn't describe the current system; read the code and its docs for that, and link to them instead of restating them. The PRD is intent: keep code out of the edits you make here. Don't commit unless you've been asked to.

Shaping is a conversation. It's where a human decides what to build and why, so explore, offer options, and ask; don't rush to a finished document. It ends at an approved PRD, or at an approved brief when the work lands as plain pull requests: it never plans or builds. Record calls in `## Decisions`, not the Log; the first Log entry marks the start of work.

## Shaping something new
1. **Start from what exists.** If this session already has a plan (from the harness's plan mode, or a plan file the human points you to), it's your first draft: carry over its problem, scope, decisions and open questions rather than asking again. Ask only about what the PRD needs and the plan doesn't say. Otherwise, understand the problem first: who it's for, what evidence says it matters, and what success looks like.
   - Run `yass me` first: a new change goes in the person's yass folder (`yass new` does that from the repo root), and their team is who it's for.
   - Either way, read the relevant code and docs, check the archive for earlier work on the same thing (`yass status --archived`, and `yass decisions --about "<words>"` for what was decided), and `yass status` for anything in flight that overlaps.
2. **Frame options before requirements.** For a non-trivial problem, sketch 2–3 ways to scope it (appetite, rough solution, risks) and let a human pick. Skip this when the scope is already clear, or the human already picked one in their plan.
3. **Decide where it lands.** Once what and why are settled, pick the least ceremony that does the job:
   - **A large change** (a PRD here, then a plan): a new feature, component or system, more pull requests than a small stack, or intent that someone outside this conversation has to approve. Carry on with the next step.
   - **A small change** (one `change.md`): about one pull request's worth, whose Goal and Acceptance should still be agreed, or kept, apart from the code. Hand what you've settled to `yass-work`, which creates it.
   - **Plain pull requests, no change:** the person deciding is in this conversation, the work fits a pull request or a small stack, and nobody will need to resume it from files. See "Shaped, then plain pull requests" below.

   A folder earns its keep when someone outside the conversation must approve the intent, when the work will span sessions or agents, or when it's hard to undo. If the human has said which they want, that's the answer. If it's ambiguous, ask. Unattended, create the folder.
4. **Create it:** `yass new "<title>" --large [--source <link>] [--follows <archived change>]`. Fill in `prd.md`:
   - **Why:** the problem, with evidence.
   - **Users and outcomes:** who, and measurable targets.
   - **Requirements:** `- **R1** [M1] A user can …`. Observable, one behavior each. IDs are never reused.
   - **Non-goals:** everything you decided not to do. Agents treat these as walls.
   - **Milestones:** slices that each leave users better off.
   - **Open questions:** anything still undecided.
5. Write the change's one-paragraph Goal in `change.md`, and the big calls in its `## Decisions` with who made them. A choice the human made in their plan is theirs: credit them.
6. **Its pull request,** like any, leads in plain words with what's proposed and why; the requirement IDs go in the collapsed tracking block at the end (`yass-work`, "Write pull requests and commits for people").
7. **Show a human the PRD** and get their go-ahead before planning, unless your team has told you otherwise. If it came from an approved plan, say what you added or changed beyond that plan; the rest is already agreed. In a fully autonomous run, where you've been put in charge of approvals, approve it yourself and record that in `## Decisions`.
8. Offer `yass-plan` next. If the harness plan also covered the approach, `yass-plan` can use it too.

## Shaped, then plain pull requests
Some work deserves the thinking and none of the bookkeeping: you start from a card, work out what to build with a human, and land an ordinary pull request or a small stack. No change folder, no intent reviewed apart from the code, no boxes.
1. **Write a brief** in the conversation, a few lines: the problem, what changes, what's out of scope, and how we'll know it worked.
2. **Get the human's go-ahead** on it. Create no change folder and write no file for it.
3. **Hand it to `yass-work`** ("Shaped, no change"). The brief leads the pull request's description, which is its record: `yass-log` finds decisions there.

If the work outgrows that while it's built (more pull requests than a small stack, a call someone else has to approve), say so: that's the moment to give it a folder.

## With a tracker
When the change's yass folder names a Trello board (`tracker:` in its `settings.yaml`, or its `yass.yaml`), follow the Trello workflow in the `yass-init` playbook. For shaping:
- **From a card:** asked to shape one, start from its title and description. When the work lands in a change, create it with the card's title and link (`yass new "<card title>" --large --source <card link>`). A new change with no card: ask whether to create one in Planning, and create it only on a yes.
- **Planning starts:** check the card is still in Will Do, then move it to Planning with a comment that planning has begun, naming the change folder once there is one. If it's anywhere else, someone may have claimed it: don't move it or comment; tell the human where it is, and ask.
- **Landing as plain pull requests:** the card moved to Planning when shaping started, as above; once that's decided, comment that it will land as pull requests, with no change folder. `yass-work` moves it on from there.
- **The PRD's pull request** gets a comment on the card when it's up for review, with the link, and another when it merges, saying the plan is accepted. Nothing else goes on the card.
- **A card that changed:** when the human says so, read it and propose PRD revisions here.
- **Another tracker** (any other key under `tracker:`): at these same moments, do what the yass folder's `team.md` says under `## Project management`. None there? Run `yass-init`'s interview first, or ask.

## Plan mode
Harness plan modes (Claude Code's, and others') usually can't write files. Research and draft there; once the human approves the plan and you can write again, create the change as above. The harness plan lives with the session, the change folder lives with the repo.

## Revising an active change's PRD
Feedback, a failed assumption, or a cut in scope. Edit `prd.md` without touching code, record what changed and why in `change.md` `## Decisions`, and tell a human. Then update the plan to match (`yass-plan`).

A finished change is archived and never edited. New intent for archived work is a new change with `--follows`.
