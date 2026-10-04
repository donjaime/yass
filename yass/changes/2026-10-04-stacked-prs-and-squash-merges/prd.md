# Stacked PRs and squash merges: PRD
<!-- Intent: what should change or exist, and why. Not a description of the current system;
     the code and its docs are that. Edit this file only in commits without code. -->

## Why
Large YASS changes are split into pieces, and building them produces a stack of feature branches. At companies with mature review, each piece lands on main as its own pull request, one at a time, usually squash-merged, and the rest of the stack is rebased on top (`gh stack`, Graphite and similar tools exist for this). YASS should make that flow easy, not push people toward one big merge at the end.

Most of YASS already fits: one piece is one PR, plan revisions go in their own branch underneath the code, and progress rides in the same commit as its code, which a squash keeps. Building `2026-10-04-monorepos-at-scale-and-plans-repos` in this repo showed where it rubs:
- **Rules assume commits survive.** Intent edits, archive moves and `queue.md` reorders each "get their own commit", and the hook checks commit by commit. A squash merge folds a PR's commits into one, so a PR with an intent commit and a code commit lands as one mixed commit. The hook passed it, and `yass-log` can no longer tell intent from code.
- **Closing commits multiply PRs.** With pieces owning their files, a parent's criteria are marked in a separate closing commit, so every finished piece costs an extra plan-only PR.
- **Separate plans cite SHAs a squash rewrites.** Citations to branch commits stop resolving after a squash merge.
- **Stacks get deeper than they need to be.** Here, pieces that didn't depend on each other were stacked anyway, which means more rebasing and more waiting.

## Users and outcomes
Teams that land YASS work through pull requests, stacked or not, with squash merges or merge commits. And the CI owners who pay for each run.
- **The basic rule** (Jaime): a pull request that only changes YASS files (PRDs, plans, designs, archive moves, queue reorders) runs no build or tests. Code and the YASS progress it delivers (boxes, Log, Decisions) land together, in pull requests that run CI.
- A large change with N pieces lands as N code PRs plus at most one closing PR, plus one plan-only PR for each plan revision. No extra PR per finished piece.
- In a simulated stack where every PR is squash-merged and the rest are rebased onto main, YASS files cause no conflicts, and main's history passes the hook.

## Requirements
- **R1** [M1] `docs/monorepo.md` states the basic rule and shows how to apply it. A PR that only touches YASS paths skips build and tests, and a PR with code runs them, its YASS progress included.
- **R2** [M1] `docs/monorepo.md` explains how YASS work lands as PRs: which kinds of PR there are (plan-only, code with progress, closing), how they stack, and what changes with squash merges.
- **R3** [M2] `merges: squash | commits` in `yass.yaml` says how the repo merges, and defaults to `squash`. With squash merges, `yass hook --range A...B` checks the whole range as the single commit it will become: intent with code, an archive move with code, or a `queue.md` reorder with code is reported.
- **R4** [M2] With squash merges, the pre-commit hook warns when a commit would mix intent and code within its branch: committing code on a branch that already changes intent since it left its base, or the other way round.
- **R5** [M2] A parent criterion counts as done in `yass status` and `yass archive` once every piece delivering it (by its `Delivers AC…` box) is done, so no closing commit is needed per piece.
- **R6** [M2] `yass archive` marks a large change's delivered parent criteria `[x]` as part of the archive move, so the one closing PR is the archive itself.
- **R7** [M2] `yass-work` starts a piece's branch from main, unless the piece's `blocked:` names a piece that hasn't landed yet. Then it stacks the branch on that piece's branch.
- **R8** [M2] `yass-work` and `yass-plan` keep plan revisions, archives and queue reorders in their own plan-only PRs, and progress in the PR of the code it describes. A PR description names the change or piece (and, with separate plans, carries the `yass:` trailer).
- **R9** [M2] `yass-log` reads squash-merged history: it attributes a squash commit to its PR, and judges intent against code per PR rather than per commit.
- **R10** [M3] An e2e scenario lands a three-piece stack one squash-merged PR at a time, rebasing the rest onto main after each. It checks that YASS files cause no conflicts, that `yass status` is right after each landing, and that `yass hook --range` passes on main's history and flags a mixed PR before it lands.
- **R11** [M3] This repo lands its next pieces through squash merges, and records what worked and what didn't in the Log.

## Non-goals
- A stacking tool. Rebasing a stack after a squash is the job of `gh stack`, Graphite and similar tools; YASS only stays out of their way.
- Opening, updating or merging pull requests from `yass`. It never talks to a code host's API.
- Limits on PR size or stack depth.
- Changing the rule that progress rides in the same commit (or PR) as the code it describes.
- The `yass:` trailer itself, and how it survives squash merges. That's `2026-10-04-monorepos-at-scale-and-plans-repos` (M3); this change only makes sure the PR guidance carries it.

## Milestones
| Milestone | When it ships, a user can … |
|---|---|
| M1 | set CI up so that plan-only PRs cost nothing and code PRs carry their progress, from one page of docs |
| M2 | land a large change as a stack of squash-merged PRs, one per piece, with YASS checking each PR as the commit it becomes, and no closing PR per piece |
| M3 | trust it: an e2e stack lands cleanly, and this repo works that way |

## Open questions
None. Both raised while shaping were settled on 2026-10-04 (see `change.md` Decisions).
