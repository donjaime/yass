---
name: yass-work
description: Work on a YASS change you've been pointed at. For work with no change, decide first whether it needs one (unambiguous, trivial work is just a good pull request); create it if it's new and small, resume from its Log, build against its acceptance criteria, keep progress (boxes marked in progress or done, Log, Decisions) up to date alongside the code, put needed plan changes on their own branch underneath the code instead of giving up, verify, and archive it when every box is checked. Use for "work on X", "keep going" on the change at hand, "fix this bug", and unattended runs that name a change.
metadata:
  yass-version: "0.5.0"
---

# yass-work

`yass` is the YASS CLI, on your PATH. If nobody is watching, don't ask questions: do one change (or one piece), and stop when you need a human.

**Work only on the change you've been pointed at.** Picking what to build next is a decision, and it belongs to whoever is directing the work, not to this playbook. Being in progress isn't a reason to pick a change: several can be, and a freshly planned one (`not started` in `yass status`) may still be waiting for someone to approve its plan.

**Git is up to whoever is driving.** Don't commit, branch, rebase, push or open a pull request unless the human or your harness has given you that latitude; pushing and pull requests are public. If you have it, do it yourself (plain `git`, or a stacking tool like `gh stack` if the repo uses one). If you don't, and someone's watching, give them the exact commands to run. Either way, keep the work shaped so that intent and code can land separately. "Separately" means apart from code: if the team squash-merges, that's a pull request with no code in it, which can still hold other intent, progress or an archive move.

**Write pull requests and commits for people.** A reviewer hasn't memorized the plan, so lead with what a person needs, and put YASS's codes last:
- **Title:** what changes, in plain words. No criterion IDs, milestone codes or change-folder names.
- **Description:** first the intent, in a few sentences (what changes for people, and why). Then what changed and how you checked it, in words a reviewer can follow without the plan open: describe behavior, not plan bullets. Then anything they should look at closely, or that's left.
- **Last, the tracking block,** collapsed so it stays out of the way:
  ```
  <details><summary>YASS tracking</summary>

  Change: 2026-09-14-offline-sync/2026-09-16-offline-queue (delivers AC1, AC3)
  offline-sync: 2/3 pieces done, 14/20 boxes · offline-queue: 6/6 boxes, done
  </details>
  ```
  The progress line is `yass status <change> --brief`; with plans kept elsewhere, the block also carries the `yass:` trailer line. `yass-log` and squash merges rely on it, so keep it, just not first.
- **Commit messages** follow the same order: a plain subject, the why in the body, the codes at the end.

1. **Orient.** Run `yass me` to know who you're working for and which yass folders are theirs. Find the change you were pointed at: named in the request (names can be shortened: `yass status queue`), or the one this session is already working on. Nothing else counts.
   - **Not pointed at one?** Show `yass status` and ask which. Unattended, stop and say so.
   - **Directing your own work?** If the harness or the human has put you in charge of choosing (a fully autonomous run), the choice is yours: pick deliberately, and before you start a `not started` change, check that its plan has been approved or approve it yourself as you've been allowed to. Record the choice, and any approval, in its `## Decisions` with `(<you>)` as who.
   - **No change yet? Decide whether it needs one.** Not every pull request does.
     - **Unambiguous intent, no change:** a trivial fix, a mechanical cleanup, a one-off that didn't come from the project management system: anything whose intent fits in the pull request's description and can be reviewed together with the code. Build it and open one pull request whose description says what and why. Trivial work goes ahead without asking; otherwise say in a line that you're skipping the ceremony. With plans kept elsewhere, its commits say `yass: none`. A card it came from moves as the Trello workflow says for work without a change.
     - **Intent that deserves discussion, review or approval** (a behavior users will notice, a design call, anything you'd want agreed before building): ask whether to start a change. Unattended, stop and ask, unless you were told when dispatched not to stop for that; then go ahead without one and say so in the pull request.
     - **Starting one,** for a small, clear request (a bug, a tweak): `yass new "<title>" [--source <issue link>]` and write its Goal and Acceptance. If there's an approved plan from the harness's plan mode, turn it into the Goal, Acceptance and Steps. Anything that changes what users can do in a big way, or needs a design call, goes to `yass-shape` first.
2. **Load.** `yass status <change>` lists its files and open boxes. Read `change.md` and resume from the last **Next:** in its Log. For a piece, also read the parent's `prd.md` and `plan.md`. Read the code and docs you'll touch.
3. **Build.** Alongside the code:
   - mark a box `[/]` when you start on it, and `[x]` once it's finished (Steps, Acceptance, and a large change's plan criteria when it has no pieces). If you stop partway, leave it `[/]` so the next session sees where you were.
   - working on a piece, change only that piece's folder: tick its own boxes, including its `Delivers` box, and leave the parent's files alone. The parent needs no closing commit: `yass status` counts the criteria its pieces deliver, and `yass archive` ticks them.
   - append real choices to `## Decisions`: `- <decision> - <why> (<who>, <YYYY-MM-DD>)`
   - keep `## Steps` current; it's your checklist
   - if `yass root` is outside this repo, cite the code commits; see **Plans in another folder** below
4. **Don't move the goalposts.** `prd.md`, `design.md`, plan text, a Goal and acceptance criteria (including dropping one) never change alongside code. If they're wrong, see **Intent changes mid-build** below.
5. **Out of scope?** Note it in the Log, or file it wherever this repo tracks issues. Don't build it.
   - **Waiting on another change?** Set `blocked: <its folder>` (several, comma-separated), say so in the Log, and stop. It clears itself once that change is done. A `yass status` line showing `waiting on:` means the same for the change you were pointed at: say so rather than building around it.
6. **Verify** each criterion the way it says (`verify:`). Re-run checks rather than trusting earlier output. If the repo has a separate reviewer or evaluator step, use it. Only mark `[x]` what has evidence; anything without it stays `[/]`.
7. **Before you stop,** append to `## Log`, so anyone can resume from the files alone:
   ```
   ### <YYYY-MM-DD> (<who>)
   - Did: …
   - Next: …
   ```
8. **Finish.** Merging a branch doesn't finish a change; a large change spans many branches. When every box is done or dropped (`yass status` says `done`), run `yass archive <change>` (it prints how to commit the move). Commit it apart from code; with squash merges, in a pull request with no code, which can carry the change's last progress too. Pieces are archived with their change.
   - A Step you no longer need can be dropped (`[-]`) any time, with a reason in Decisions.

## With a tracker
When the change's yass folder names a Trello board (`tracker:` in its `settings.yaml`, or its `yass.yaml`; `yass status <change>` then prints its `card:`), follow the Trello workflow in the `yass-init` playbook. The card hears only about these moments; boxes, the Log and decisions stay in the files.
- **Building starts:** check the card is in Planning, then move it to Implementing. A piece with its own card moves the same way. If the card is anywhere else, someone may have claimed it: don't move it or comment; tell the human where it is and ask. Unattended, stop, and say so in the Log.
- **A pull request** for the change: comment on its card with the link when it's up for review, and again when it merges or closes.
- **Done:** a piece's card moves to Done when the piece is done and its pull request merged; a top-level change's, when its archive merges. Each time, check it's in Implementing first.
- **No card:** for a new top-level change, ask whether to create one, and create it only on a yes. Never create a card for a piece: it rolls up to its change's card.
- **Plans kept elsewhere:** never put a board or card link in the code repo (commits, pull request descriptions). The plans link the card.
- **Another tracker** (any other key under `tracker:`): at these same moments, do what the yass folder's `team.md` says under `## Project management`. None there? Run `yass-init`'s interview first, or ask.

## Intent changes mid-build
Building often shows the plan is wrong. Don't quietly fix it next to the code, and don't give up either: stack it.

1. **Reason it out.** What exactly should change in the PRD, design, plan, Goal or Acceptance, and why? Write that down.
2. **Not confident?** Set `blocked: <reason>` in the frontmatter, say what and why in the Log, and stop for a human.
3. **Confident?** (Plans in another folder? See below instead.) Put the intent edit on its own branch, cut from where your work branched off, with the reason in `change.md` `## Decisions`. Then rebase your work on top of it and keep building against the new plan. Reviewers see the intent change in its own pull request, below the code that depends on it, and can reject it without untangling anything.
   ```bash
   git switch -c <work-branch>-intent <base>     # with your in-progress work committed or stashed
   # edit prd.md / design.md / plan.md / Goal / Acceptance, and add the Decision
   git commit -m "yass: revise <change>" -- <the intent files>
   git switch <work-branch>
   git rebase <work-branch>-intent
   ```
   With `gh stack` or a similar tool, use its commands for the same shape.
4. **Lowering the bar** (dropping or weakening an acceptance criterion) is still an intent change, stacked the same way, but say so plainly in the Decision and the pull request: a human has to agree before it merges.
5. **Who runs it:** if you're allowed to drive git, run it yourself. If someone's watching but you aren't allowed, make the edits, then show them the commands. If nobody's watching and you can't commit, leave the edits in place, put the commands in the Log's **Next:**, and stop.

## Plans in another folder
When `yass root -v` says `separate` (a `yass.yaml` points outside this repo), plans and code are committed separately, often in different repos. Nothing can carry progress in the same commit as the code, so the routine changes:

- **Start by updating the plans.** Pull them (`git -C <plans folder> pull --ff-only`) before reading the change; `yass status` notes when they have uncommitted files or are behind. A plans repo with no upstream (local only) has nothing to pull: carry on with it as it is. Then resume from the Log as usual.
- **If the plans folder isn't there, stop and say so.** Never run `yass init` to fix it: it would create an empty plans folder that only this checkout sees. The fix is the human's: clone the plans where `yass.yaml` expects them, or set the variable its `path:` uses. From a linked worktree, YASS already looks in the clone's other checkouts.
- **Name the change in every code commit.** Run `yass use <change>` when you start (`--ac ac2,ac5` adds the criteria you're working toward); the hooks then add a `yass: <change>` trailer to each commit. It's per worktree, so parallel worktrees can work on different changes. Without the hooks, write the trailer yourself. A commit that belongs to no change gets `yass: none`.
- **Commit the code first, then the plans.** The code commit carries the trailer; the plans commit marks boxes and cites the code commits they rest on: `- [/] Disable Save while saving — code: a1b2c3d`. Name them in the Log entry too.
- **`[x]` waits for the merge.** A box is done when its code is on the main branch: cite the commit there (after a squash merge, the squash commit). Until then it's `[/]`, citing the branch commits. `yass status` warns about a cited commit it can't find, and about a done box whose code isn't merged (`branch:` in `yass.yaml` says which branch counts).
- **Boxes with no code** (a decision, a manual check) need no citation.
- **Cross-link them.** The code pull request's tracking block (see "Write pull requests and commits for people") names the change, its progress (`yass status <change> --brief`) and carries the `yass:` trailer line, so a squash merge keeps it; the plans commit or pull request names the code's. Never a board or card link in the code repo: the plans link the card.
- **Latitude is per repo.** Being allowed to commit, push or open pull requests in the code repo says nothing about the plans repo, and the other way round; without it in one, show the human that repo's commands.
- **Intent changes go where the plans live,** as their own commit or pull request in that folder's repo, linked from the code's pull request. There's nothing to stack under the code; keep building against the revised plan once you're confident, as above.
- **The plans stay on one branch** there, usually main.
