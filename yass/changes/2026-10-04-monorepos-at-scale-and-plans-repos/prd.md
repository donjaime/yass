# Large monorepos first, separate plans repo done right: PRD
<!-- Intent: what should change or exist, and why. Not a description of the current system;
     the code and its docs are that. Edit this file only in commits without code. -->

## Why
YASS has to work at a large company with one big monorepo, many teams, and expensive, complicated CI. That's where its main promise matters most: plans sit next to the code, and progress lands in the same commit. Teams there worry that planning files, which change often and can carry mocks and images, will add CI runs, slow the merge queue, bloat clones and clutter history. Most of that can be solved inside the monorepo, but YASS doesn't show how yet, so the easy wrong answer is to move the plans out.

Some projects really do need plans in a separate repo, usually for privacy (an open source project with private plans). That setup exists today ([README: Keeping plans out of the repo](../../../README.md#keeping-plans-out-of-the-repo)), but trying it on 2026-10-04 found it fragile:
- In a linked git worktree, which is where agents usually run, a relative `path:` resolves from the worktree and finds nothing. The warning then suggests `yass init`, which would create a stray, empty plans folder.
- When two code repos share one plans repo, each repo warns about the other's citations as missing commits, and a repo-qualified citation (`code: web@e1553ee`) isn't checked at all.
- `yass archive` archives a change whose `[x]` boxes cite unmerged code.
- `yass status` run from the plans repo flags every citation, so the plans repo can't check itself in CI.
- Nothing warns about uncommitted plans or a plans repo that's behind its remote.
- Plans cite code by SHA, and a squash merge invalidates those SHAs, so they have to be fixed by hand.

## Users and outcomes
- **Teams in a large monorepo** (the primary path), and the platform or CI owners who decide whether YASS is allowed in.
  - With the documented setup, a commit that touches only yass folders runs no build or test jobs, and doesn't block merging with a check stuck waiting.
  - `yass status` takes under 1s on a repo with 200 yass folders and 2,000 changes. The pre-commit hook adds under 200ms on a repo of 100,000 files.
  - A platform owner can roll YASS out from one page of docs, without writing their own glue.
- **Projects that keep plans in a separate repo for privacy** (the fallback), and the agents working in them.
  - Every merged code commit in a separate-repo setup names its change, and tooling enforces it.
  - `yass status` gives no false warnings when two code repos share one plans repo.
  - An agent in any linked worktree resolves the same plans folder as the main checkout.

## Requirements
- **R1** [M1] A CI owner can tell which paths are YASS's from `yass paths`, and use that list in pipeline filters instead of hard-coding folder layouts.
- **R2** [M1] The docs give tested recipes for skipping build and test jobs on plan-only commits: GitHub Actions (including required checks that would otherwise wait forever when a path filter skips them), Bazel or another affected-targets build, and one generic CI.
- **R3** [M1] The docs explain how plan-only PRs go through a merge queue without full test runs.
- **R4** [M1] The docs show CODEOWNERS for each team's yass folder, so plan reviews go to the owning team.
- **R5** [M1] `yass status` in a sparse checkout reports on the yass folders that are checked out. A `blocked:` that names a change outside the checkout says it can't see that change, instead of calling it unknown.
- **R6** [M1] The docs give Git LFS rules for binary assets under yass folders, and say that assets live in the change folder and move with it when it's archived.
- **R7** [M1] When agents on parallel branches each append a Log entry to the same `change.md`, or edit `queue.md`, those branches rebase without conflicts in the common case.
- **R8** [M1] The docs give commands for leaving YASS paths out of `git log`, `blame` and diff views.
- **R9** [M1] `yass status` and the pre-commit hook meet the speed targets above.
- **R10** [M2] `yass status` and `yass root` say whether the plans are inline (in the same git repo as the code) or separate.
- **R11** [M2] In a linked worktree, a relative `path:` resolves to the same folder as in the main checkout. When the plans folder is missing, YASS never suggests `yass init` from a linked worktree.
- **R12** [M2] Citations can name their repo (`code: web@a1b2c3d`). Each code repo checks its own citations and says which ones it didn't check, without warning about them. An unqualified citation keeps today's behavior.
- **R13** [M2] `yass archive` refuses (unless forced) a change whose done boxes cite commits that are missing or unmerged, and lists any citations it couldn't check from where it runs.
- **R14** [M2] With separate plans, `yass status` warns when the plans repo has uncommitted changes or is behind its upstream.
- **R15** [M3] With separate plans, every code commit carries a `Yass-Change:` trailer naming its change, or an explicit opt-out. A commit-msg hook rejects commits without one, and a CI check catches merged commits that lack one (squash merges included). With inline plans, nothing asks for trailers.
- **R16** [M3] `yass status` lists each change's code commits from its trailers on the merged branch, so finding a change's code doesn't depend on SHAs that a squash merge rewrites.
- **R17** [M3] A plans repo can map repo names to code checkouts (`repos:` in its `yass.yaml`), so `yass status` run there, locally or in CI, checks every citation and trailer.
- **R18** [M3] The `yass-work` skill's separate-plans guidance covers the whole routine. At session start, pull the plans and check their state. Commit code first, then plans. Cross-link the code PR and the change. Treat git latitude separately for each repo. Never run `yass init` to fix a missing plans folder.

## Non-goals
- Orphan branches, git submodules, subtrees, or manifest tools (`repo`, `west`) as a home for plans.
- Version control other than git (Piper, Perforce, Sapling).
- Trailers, or any new rule, for inline plans. The monorepo setup stays as simple as it is.
- CI plugins or integrations to install. YASS ships recipes and `yass paths`, not per-CI products.
- Moving plans out of the monorepo to save CI cost. That's solved inside the repo.
- Automatically rewriting SHA citations after a squash merge.

## Milestones
| Milestone | When it ships, a user can … |
|---|---|
| M1 | roll YASS out across a large monorepo with many teams, with plan-only commits costing no CI, owned per team, and fast at scale |
| M2 | keep plans in a separate repo, with worktrees, shared plans repos and archiving all working correctly |
| M3 | rely on enforced trailers to link code to plans in a separate-repo setup, and check everything from the plans repo, including in CI |

## Open questions
- Trailer name and opt-out: is it `Yass-Change: <folder>`, with what for commits that belong to no change (`Yass-Change: none`)? (Jaime)
- With trailers in place (M3), do `code:` citations on boxes stay recommended, or become optional detail? (Jaime)
- R7 mechanism: a Log shape that rebases cleanly, a `.gitattributes` merge driver for the Log only, or guidance alone? (decide in yass-plan)
- Which affected-targets build tool should the second recipe in R2 use: Bazel, Nx, or both? (Jaime)
- Are the speed targets in R9 the right ones for the company you have in mind? (Jaime)
