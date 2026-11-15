---
name: yass-work
description: Build a YASS change you've been pointed at. Resume from its Log, build against its acceptance criteria, keep boxes, Log and Decisions current alongside the code, verify, and archive it when every box is checked. Also decides whether work with no change needs one. Use for "work on X", "keep going" on the change at hand, "fix this bug", and unattended runs that name a change.
---

# yass-work

**Unattended** (nobody watching), do one change or one piece and don't ask questions: wherever this playbook says to ask, stop instead and say why in the Log.

**Work only on the change you've been pointed at.** Choosing what to build next belongs to whoever directs the work. Being in progress isn't a reason to pick a change, and a `not started` one may still be waiting for its plan to be approved.

**Git needs latitude.** Don't commit, branch, rebase, push or open a pull request unless the human or your harness lets you (pushing and pull requests are public); without it, give the human the exact commands. Either way, keep intent and code able to land separately: with squash merges, that's a pull request with no code in it. Archiving isn't intent: it rides with the code that finishes the change.

1. **Orient.** `yass me` says who you're working for and which yass folders are theirs. Your change is the one named in the request (names can be shortened: `yass status queue`) or the one this session is already on. Nothing else counts.
   - **Pointed at none:** show `yass status` and ask which.
   - **Work that has no change:** see "Work with no change" below.
   - **Put in charge of choosing** (a fully autonomous run): pick deliberately. Before starting a `not started` change, check its plan was approved, or approve it yourself if you've been allowed to. Record the choice, and any approval, in its `## Decisions` with yourself as who.
2. **Load.** `yass status <change>` lists its files and open boxes. Read `change.md` and resume from the last **Next:** in its Log. For a piece, also read the parent's `prd.md` and `plan.md`.
3. **Build,** keeping the files current alongside the code:
   - Mark a box `[/]` when you start it and `[x]` once it's verified (Steps, Acceptance, and a large change's plan criteria when it has no pieces). Stopping partway leaves it `[/]`. A Step you no longer need can be dropped (`[-]`), with a reason in Decisions.
   - On a piece, change only that piece's folder, its `Delivers` box included. The parent needs no closing commit: `yass status` counts the criteria its pieces deliver, and `yass archive` ticks them.
   - Append real choices to `## Decisions`: `- <decision> - <why> (<who>, <YYYY-MM-DD>)`.
   - `## Steps` is your checklist: keep it current.
4. **Don't move the goalposts.** `prd.md`, `design.md`, plan text, a Goal and acceptance criteria (dropping one included) never change alongside code. If they're wrong, see "Intent changes mid-build".
5. **Out of scope?** Note it in the Log, or file it wherever this repo tracks issues. Don't build it.
6. **Waiting on another change?** Set `blocked: <its folder>` (several, comma-separated), say so in the Log, and stop; it clears itself once that change is done. `waiting on:` in `yass status` means the same for your change: say so rather than building around it.
7. **Verify** each criterion the way its `verify:` says, re-running checks rather than trusting earlier output, and using the repo's reviewer or evaluator step if it has one. A box without evidence stays `[/]`.
8. **Before you stop,** append to `## Log`, so anyone can resume from the files alone:
   ```
   ### <YYYY-MM-DD> (<who>)
   - Did: …
   - Next: …
   ```
9. **Finish.** A merged branch doesn't finish a change; every box done or dropped does (`yass status` says `done`). Then run `yass archive <change>`. Pieces are archived with their change.
   - The archive is the last commit of the pull request that ticks the last box, code or not, so one review builds, finishes and archives.
   - If review reopens the work, take the archive commit off the branch, make the edits, and archive again. Never edit under `archive/`.
   - It goes on its own (with squash merges, a pull request without code) when the change was already finished on main, or when `yass archive` says it evicts old months.

## Write pull requests and commits for people
A reviewer hasn't memorized the plan. The title says what changes in plain words, with no criterion IDs, milestone codes or folder names. The description gives the intent first (what changes for people, and why), then what changed and how you checked it, as behavior rather than plan bullets, then anything to look at closely or left to do. YASS's codes go last, collapsed:
```
<details><summary>YASS tracking</summary>

Change: 2026-09-14-offline-sync/2026-09-16-offline-queue (delivers AC1, AC3)
offline-sync: 2/3 pieces done, 14/20 boxes · offline-queue: 6/6 boxes, done
</details>
```
The progress line is `yass status <change> --brief`; with plans kept elsewhere, the block also carries the `yass:` trailer line. `yass-log` and squash merges rely on the block, so keep it. Commit messages follow the same order: a plain subject, the why in the body, the codes at the end.

## Work with no change
Not every pull request needs one. Pick the least ceremony that fits:
- **Unambiguous intent** (a trivial fix, a mechanical cleanup, a one-off: its intent fits in the pull request's description and can be reviewed with the code): build it and open one pull request that says what and why. Trivial work needs no question; otherwise say in a line that you're skipping the ceremony.
- **Shaped, no change** (`yass-shape` ended in a brief the human approved): build from the brief, with no change folder, boxes, Log, Decisions or separate intent commits. The pull request's description leads with the brief (the problem, what changes, what's out of scope), then how it was checked; in a stack, the bottom one carries the whole brief and each one above says its part. If the work outgrows the brief, stop and say so rather than widening it quietly.
- **Intent that deserves discussion, review or approval** (behavior users will notice, a design call, anything you'd want agreed before building): ask whether to start a change, or to shape it and land plain pull requests (`yass-shape` does either). Unattended and told when dispatched not to stop for this: go ahead without one, and say so in the pull request.
- **Starting a small change** (a bug, a tweak): `yass new "<title>" [--source <issue link>]`, then write its Goal and Acceptance; an approved plan from the harness's plan mode becomes its Goal, Acceptance and Steps. Anything that changes what users can do in a big way, or needs a design call, goes to `yass-shape` first.

## With a tracker
When the change's yass folder has a `tracker:` (in its `settings.yaml` or `yass.yaml`; `yass status <change>` then prints its `card:`), update it at these moments and no others: building starts, each code pull request goes up and merges or closes, and the change or piece is done. Work without a change has its own rows.
- **Trello:** what to move and say, and the check before every move, are in `yass-init`'s "The Trello workflow". Read that section; the rest of that playbook is setup.
- **Another tracker:** do what the yass folder's `team.md` says under `## Project management`. None there? Run `yass-init`'s interview first, or ask.

## Intent changes mid-build
Building often shows the plan is wrong. Don't quietly fix it next to the code, and don't give up either: stack it.

1. **Reason it out.** Write down what should change in the PRD, design, plan, Goal or Acceptance, and why.
2. **Not confident?** Set `blocked: <reason>` in the frontmatter, say what and why in the Log, and stop for a human.
3. **Confident?** Put the intent edit on its own branch, cut from where your work branched off, with the reason in `change.md` `## Decisions`. Then rebase your work onto it and keep building against the new plan. Reviewers see the intent change in its own pull request, below the code that depends on it, and can reject it without untangling anything. (Plans in another folder work differently: see below.)
   ```bash
   git switch -c <work-branch>-intent <base>     # with your in-progress work committed or stashed
   # edit prd.md / design.md / plan.md / Goal / Acceptance, and add the Decision
   git commit -m "yass: revise <change>" -- <the intent files>
   git switch <work-branch>
   git rebase <work-branch>-intent
   ```
   With `gh stack` or a similar tool, use its commands for the same shape.
4. **Lowering the bar** (dropping or weakening an acceptance criterion) is stacked the same way, but say so plainly in the Decision and the pull request: a human has to agree before it merges.
5. **Unattended without git latitude:** leave the edits in place, put the commands in the Log's **Next:**, and stop.

## Plans in another folder
When `yass root -v` says `separate` (a `yass.yaml` points outside this repo), plans and code are committed separately, often in different repos, so nothing can carry progress in the same commit as the code:

- **Pull the plans first** (`git -C <plans folder> pull --ff-only`), unless their repo has no upstream. `yass status` notes when they're behind or have uncommitted files.
- **If the plans folder isn't there, stop and say so.** Never run `yass init` to fix it: that creates an empty plans folder only this checkout sees. The human clones the plans where `yass.yaml` expects them, or sets the variable its `path:` uses. From a linked worktree, YASS already looks in the clone's other checkouts.
- **Name the change in every code commit.** `yass use <change>` when you start (`--ac ac2,ac5` adds the criteria you're working toward) makes the hooks add a `yass: <change>` trailer; it's per worktree. Without the hooks, write the trailer yourself. A commit that belongs to no change, or to a change in this repo, gets none.
- **Commit the code first, then the plans.** The plans commit marks boxes and cites the code commits they rest on (`- [/] Disable Save while saving — code: a1b2c3d`), and the Log entry names them too. Boxes with no code (a decision, a manual check) need no citation.
- **`[x]` waits for the merge.** A box is done when its code is on the main branch (`branch:` in `yass.yaml` says which): cite the commit there, which after a squash merge is the squash commit. Until then it's `[/]`, citing the branch commits.
- **Cross-link them.** The code pull request's tracking block names the change, so a squash merge keeps it; the plans commit or pull request names the code's. Never put a board or card link in the code repo.
- **Latitude is per repo:** being allowed to commit or push in one says nothing about the other.
- **Intent changes go where the plans live,** as their own commit or pull request there, linked from the code's pull request. There's nothing to stack under the code.
- **The plans stay on one branch** there, usually main.
