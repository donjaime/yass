---
platforms: [all]
source: 
follows: 
blocked: 2026-10-04-separate-plans-mode, 2026-10-04-repo-qualified-citations, 2026-10-04-the-binary-carries-the-playbooks
---
# yass: trailers

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
With separate plans, every code commit names its change in a `yass:` trailer that the hooks add automatically and check (a warning by default, enforced with `trailers: require`), and yass status lists each change's and each criterion's code from those trailers.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [/] Delivers AC40–AC52 in [plan.md](../plan.md)
- [x] `yass init` (with `--hooks` to turn them on) installs and upgrades the new `prepare-commit-msg` and `commit-msg` scripts beside `pre-commit`

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] 9a: `trailers.go`: the grammar (`parseTrailer`), targets (active, archived, evicted, `<change>/<piece>`, an unambiguous piece; the closest names suggested), when trailers apply (`plansSeparate`, `trailers:` warn, require, off)
- [x] 9a: `yass hook --prepare-msg` (from `yass use`, the branch name, an earlier commit's trailer; never over yours, never on merges), `--commit-msg` (heads-up, or refuse under `require`), `--range` (reported; fails with `--strict` or `require`; form only without the plans)
- [x] 9a: `yass use [<change>] [--ac] [--clear]`, kept in the worktree's own git folder
- [x] 9a: `prepare-commit-msg` and `commit-msg` scripts, installed by `yass init` and added by `yass upgrade`
- [x] 9a: `git` calls for a particular folder drop the hook's `GIT_DIR` (and `GIT_INDEX_FILE`), so a hook in a linked worktree finds the plans repo rather than the code worktree
- [x] 9a: go test (`TestParseTrailer`, `TestCheckTarget`); e2e §45 (681 ok); husky wired in a scratch repo; `docs/separate-plans.md`, README
- [/] 9a: Jaime reviews the docs (AC49)
- [ ] 9b: `yass status <change>` lists its merged commits from trailers (AC50), and each criterion's (AC51); the 50,000-commit bench (AC52)

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->
- Built in two pull requests: 9a, the trailer itself (AC40–AC49), and 9b, status listing code from trailers (AC50–AC52) - thirteen criteria and two new hooks are more than one reviewable pull request (claude, 2026-10-10)
- Trailers apply only when every yass folder the code repo uses is outside it (or its `yass.yaml` points outside to a folder that isn't checked out, as in CI); a repo with inline plans and a private separate folder, like this one, treats them as off (claude, 2026-10-10)
- The branch-name source matches the whole branch or the part after its last `/`, against change and piece folder names, not the slug without the date - names are what the trailer writes, and a loose match could pick the wrong change (claude, 2026-10-10)
- Found by e2e: hooks in a linked worktree run with `GIT_DIR` set, so every `git -C <plans repo>` call was answered by the code worktree; `git` now drops the repo-pinning variables when it's given a folder, which fixes it for every hook, not just trailers (claude, 2026-10-10)
- AC49's manual check used husky (installed with npm in a scratch repo): `yass use` gave the commit its trailer through `.husky/prepare-commit-msg`, and without it `.husky/commit-msg` gave the heads-up. lefthook and pre-commit weren't available; their configs follow those tools' documented formats, and the doc says husky is the one tested (claude, 2026-10-10)
- Waits for 2026-10-04-the-binary-carries-the-playbooks and ships its hook scripts through `yass init`, which installs and upgrades everything a repo gets once that change lands; this criterion said `install.sh` before (Jaime)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-10-10 (claude)
- Did: 9a, the `yass:` trailer: grammar, hooks, `yass use`, range checks, scripts, docs. `go test`, `tests/e2e.sh` (681 ok), `tests/examples.sh`, `tests/site.sh` pass.
- Next: 9b: `yass status <change>` lists commits from trailers, per change and per criterion, and the 50,000-commit bench. Jaime reviews the docs (AC49).
