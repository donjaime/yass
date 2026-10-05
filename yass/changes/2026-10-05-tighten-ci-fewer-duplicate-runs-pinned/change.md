---
platforms: [all]
source: Jaime, 2026-10-05: sanity check of CI while reviewing the binary-carries-the-playbooks stack; fix after the stack lands
follows: 
blocked:
---
# Tighten CI: fewer duplicate runs, pinned release actions, required checks

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
CI stays as safe for outside contributors as it is today (fork PRs get a read-only token and no secrets, first-time contributors need approval, and only `main` and `v*` tags reach anything that writes), and gets cheaper and harder to tamper with. Each commit on a PR is tested once, superseded runs stop when a branch is pushed again, the release cross-build runs only where it's worth its cost, the actions that can write releases are pinned to commit hashes, and `main` requires the `ci-ok` gate before a PR merges.


## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Given a push to a PR's branch, then `ci` runs once for that commit (for the PR), not also for the branch push; pushes to `main` and merge-queue runs still run it — verify: manual: push to a PR branch and list the runs for its commit (`gh run list --commit <sha>`)
- [ ] Given a PR branch pushed again while its `ci` run is in progress, then the older run is cancelled; runs on `main` are never cancelled — verify: manual: push twice in a row to a PR branch and check the first run's status
- [ ] Given a PR that touches none of `.goreleaser.yaml`, `go.mod`, `go.sum`, `cmd/`, `kit/` or `.github/workflows/`, then the GoReleaser snapshot build is skipped and `ci-ok` still passes; on `main`, and on a PR that touches any of them, it runs — verify: manual: one PR of each kind
- [ ] Given `release.yml`, then every third-party action is pinned to a full commit hash (with the version in a comment), and the GoReleaser version is pinned exactly — verify: manual: review; `grep -E 'uses: .*@' .github/workflows/release.yml` shows only 40-character hashes
- [ ] Given `ci.yml` and `pages.yml`, then their actions are pinned the same way — verify: manual: review
- [ ] Given a PR into `main` whose `ci-ok` hasn't passed, then GitHub won't merge it — verify: manual: a ruleset on `main` requiring `ci-ok`; try merging a PR while CI runs
- [ ] Given a new PR branch that changes only plans (for example, an archive move), when it's pushed and its PR opens, then no run tests or builds anything: only the `changes` gate and `ci-ok` run — verify: manual: open a plans-only PR from a new branch and list the jobs of every run for its commit
- [ ] Given the change, then no workflow uses `pull_request_target` or `workflow_run`, workflow tokens default to read, and fork PRs from first-time contributors still need approval — verify: manual: `gh api repos/donjaime/yass/actions/permissions/workflow` and `…/fork-pr-contributor-approval`; review

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `ci.yml`: `push` on `main` only; `concurrency` per PR with `cancel-in-progress` (not on `main`)
- [ ] `ci.yml`: the snapshot build only on `main`, the merge queue, or PRs touching release inputs (a paths check in the `changes` job); `ci-ok` treats a skipped build as passing
- [ ] Pin actions to commit hashes in `release.yml`, `ci.yml` and `pages.yml`; GoReleaser version exact
- [ ] Repo settings (Jaime): a ruleset on `main` requiring `ci-ok`; optionally a `v*` tag ruleset, and approval for all outside contributors rather than first-timers only
- [ ] Note the required check in `docs/monorepo.md`'s CI recipe if it changes
- [ ] Look at the gate's own cost (a runner, `setup-go`, building `yass` for `yass paths --only`, about 10 s plus queueing) and whether a cache or a prebuilt binary is worth it; it's also this repo's dogfood of the `docs/monorepo.md` recipe, so keep that working

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->
- A separate small change, after the binary-carries-the-playbooks stack lands - found during a CI sanity check while reviewing that stack; nothing in it is a security hole today, so it doesn't block the stack (Jaime)
- Findings it starts from (claude, 2026-10-05): no `pull_request_target` or `workflow_run`; `ci.yml` has `contents: read` and the repo default is read; fork-PR approval is `first_time_contributors`; `release.yml` runs only on `v*` tags and `pages.yml` only on `main`, whose environment allows only `main`; the one event value used in a script goes through `env:`. Costs and gaps: `ci` runs on both `push` (every branch) and `pull_request`, so each PR commit runs twice; no `concurrency`; the six-target snapshot build runs on every PR; actions are pinned by movable tags, which matters most in `release.yml` (`contents: write`, `id-token: write`, `attestations: write`); `main` has no branch protection or ruleset, so `ci-ok` isn't required
- Seen on donjaime/yass#10, an archive-only PR (Jaime, 2026-10-05): its `pull_request` run did the right thing (gate about 10 s, tests and build skipped, `ci-ok` 3 s), but the `push` run for the new branch ran the full tests and the release build, because a branch's first push has no `before` commit to compare with, so the gate falls back to running everything. `push` on `main` only fixes it; the new criterion checks it (claude)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
