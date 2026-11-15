---
name: yass-log
description: Reconstruct the decision log from YASS change folders and git history. Who decided what, when and why, for a time range, a feature or a person, and which code carried a decision out or which decision is behind a piece of code. Use for "why did we…", "what did we decide about…", "why does this code look like this", release notes, retros, or reviewing decisions made without a human.
---

# yass-log

There's no separate log file. The record is the `## Decisions` sections of active and archived changes in every yass folder (`yass root` prints them), plus git history. Work that went through no change has its why in its pull request's description and commit messages.

## Where to look
- **`yass decisions`** lists every Decisions entry, newest first, with each change's created and archived dates. Narrow it with `--since`/`--until YYYY-MM-DD`, `--about "<words>"` and `--change <name>` (which takes in the changes it follows and that follow it); it shows 50 at a time (`--limit N`), and `--json` gives the same as data. Don't read `archive/` directly: it can hold thousands of changes, and evicted months are only in git, which `yass decisions` reads back (it says when a shallow clone is missing one).
- **Entries** read `- <decision> - <why> (<who>, <YYYY-MM-DD>)`. Older ones have no date of their own, so `yass decisions` shows the change's dates.
- **From code to its decision:** find the commits (`git log -- <file>`, `git log -S'<symbol>'`), then `yass decisions --cites <sha>` (any prefix; it searches active, archived and evicted changes). A hit names the change, file and box, whose Decisions and Log are the why. No hit means no change links that commit: read its message and pull request, and say so rather than guessing from dates.
- **From a decision to its code:** boxes cite the commits they rest on (`— code: a1b2c3d`). With plans kept apart from the code, each code commit also names its change in a `yass:` trailer, and `yass status <change>`, run in the code repo, lists the change's merged commits and, by their `ac:`, each criterion's. That survives squash merges. Say whether each cited commit is merged (into `branch:` from `yass.yaml`, else the default branch).
- **Decided outside any change:** search commit messages and pull request descriptions. Report those as from the commit or pull request, and say when that's all there is.
- **When and who:** the files say what, and git says when and who committed it. `git log -S'<distinctive words>'` finds the commit that added a decision line, and `git log -p` on a PRD, plan or design shows how the promise changed. An archived change was moved, so follow its `change.md` across the move (`--follow`).
- **Squash merges:** a subject ending in `(#N)` is pull request N. Name it next to the commit, and read its description and review when the decision line leaves the why unclear. The change's Goal, PRD and Log help there too.

## Report
Newest first, grouped by change, with the code that carried each decision out when it's cited:
```
2026-09-15  offline-sync  Sync is last-write-wins per entry - entries are append-only (sam)
            code: 4f2c1aa 2026-09-18 sam "feat: per-entry LWW merge" (merged)
```
Cite file paths and commit shas so every line can be checked. Don't infer decisions that aren't written down: say when the record is silent. Flag decisions with no recorded author, and goalposts that moved:
- **Plans in this repo:** intent edits that landed in the same commit as code.
- **Plans in another folder:** an acceptance criterion reworded or dropped (`[-]`) after a box citing its code was marked `[x]`.

## Plans in another folder
When `yass root` prints a folder outside this repo, the plans and the code have separate histories.
- **Run git for the plans in their folder,** limited to it, since it may share a repo with other projects' plans (`git -C <folder> log … -- .`), and for the code here. Say which repo each sha is from.
- **No git at all?** A plain folder's only dates are the Log headings (`### YYYY-MM-DD`): place a decision between the entries around it, and say the date is approximate.
