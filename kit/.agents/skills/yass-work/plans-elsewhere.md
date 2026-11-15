# Plans in another folder

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
