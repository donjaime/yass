# YASS in a large monorepo

YASS works best with plans next to the code, in the same repo, so progress lands in the same commit as the code it describes. That holds in a monorepo with many teams and expensive CI too. This page shows how to keep plans cheap there. For the folder layout (a `yass/` per team, cross-team changes as links), see [Monorepos in the README](../README.md#monorepos).

## Plan-only commits run no CI

Most YASS edits ride along with code: a box ticked in the same commit as the change it describes. The commits that touch *only* plans are intent changes (a new PRD, a revised plan) and archives. They have nothing to build or test.

`yass paths` prints what's YASS's in this repo, as globs: each yass folder inside the repo, and each `yass.yaml`. Folders a `yass.yaml` ignores aren't listed, and neither is a plans folder outside the repo. With a range, it answers the question CI needs:

```bash
yass paths                       # e.g. yass/**, services/payments/yass/**, yass.yaml
yass paths --only "$BASE...$HEAD"
```

`--only` exits **0** when every file changed in the range is YASS's (skip the build), **1** when anything else changed, or nothing did (run it), and **2** when it can't read the range (usually a shallow clone: fetch history first). Use three dots, so a branch is compared with where it left its base, not with commits that landed there since.

Run the check in one small job at the start, and gate everything else on it. Don't skip whole pipelines with your CI's own path filters unless you've checked what that does to required checks (below).

### GitHub Actions

GitHub treats the two ways of skipping differently ([troubleshooting required status checks](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks)):

- A **workflow** skipped by `paths:`, `branches:` or a commit message leaves its checks **Pending**, and a pull request that requires them can't merge.
- A **job** skipped by `if:` reports **Success**.

So filter with a job, not with `on: paths`, and make one always-running job the check you require:

```yaml
on:
  push:
    branches: [main]   # your default branch; a PR's commits are checked as the PR
  pull_request:
  merge_group:

# A new push to a PR supersedes its checks still running; the default branch and the queue finish theirs.
concurrency:
  group: ci-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      code: ${{ steps.only.outputs.code }}
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Install yass
        run: |
          v=vX.Y.Z   # pin a release that has `yass paths`
          curl -fsSLO "https://github.com/donjaime/yass/releases/download/$v/yass_linux_amd64.tar.gz"
          curl -fsSLO "https://github.com/donjaime/yass/releases/download/$v/checksums.txt"
          grep yass_linux_amd64.tar.gz checksums.txt | sha256sum -c
          tar -xzf yass_linux_amd64.tar.gz && echo "$PWD/yass_linux_amd64" >> "$GITHUB_PATH"
      - id: only
        env:
          BASE: ${{ github.event.pull_request.base.sha || github.event.merge_group.base_sha || github.event.before }}
        run: |
          # Plans only: skip. Anything else, or no usable base (a new branch): run everything.
          if [ -n "$BASE" ] && [ "$BASE" != 0000000000000000000000000000000000000000 ] &&
             yass paths --only "$BASE...$GITHUB_SHA"; then
            echo code=false >> "$GITHUB_OUTPUT"
          else
            echo code=true >> "$GITHUB_OUTPUT"
          fi

  test:
    needs: changes
    if: needs.changes.outputs.code == 'true'
    runs-on: ubuntu-latest
    steps:
      - run: echo "your build and tests"

  # Require this one in branch protection, not the jobs it gates.
  ci-ok:
    if: always()
    needs: [changes, test]
    runs-on: ubuntu-latest
    steps:
      - if: contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled')
        run: exit 1
      - run: echo "ok"
```

Limit `push` to your default branch: on any other branch, a first push has no `before` commit to compare with, so the check falls back to running everything, and the PR's own run would check the same commit again. A job that `needs:` a skipped job is skipped too, so a whole chain of jobs behind `test` drops out on a plan-only change, and `ci-ok` still reports. This repo's own [ci.yml](../.github/workflows/ci.yml) works this way, building `yass` from source instead of downloading it.

If you'd rather not install `yass` in CI, paste the output of `yass paths` into a plain diff check, and update it when a team adopts YASS:

```bash
! git diff --name-only "$BASE...$GITHUB_SHA" | grep -qvE '^(yass/|services/payments/yass/|yass\.yaml$|services/[^/]+/yass\.yaml$)'
```

### Merge queues

> **Not tested on a real merge queue yet.** This section follows GitHub's documentation; if you run it, please [tell us how it went](https://github.com/donjaime/yass/issues).

A merge queue runs your checks again on the `merge_group` event. That event takes `branches` filters but no `paths` filters ([events that trigger workflows](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#merge_group)), so a workflow can't skip itself there by path. The gate job above handles it: on `merge_group` it compares the queue's base with the merge group's commit, so a plan-only pull request still passes through the queue, but without running the build. It still takes its turn in the queue; it just doesn't hold the queue up for long.

### Bazel

> **Not tested end to end yet.** If you try this on a Bazel repo, please [tell us how it went](https://github.com/donjaime/yass/issues).

YASS folders hold Markdown and images, never build files, so:

- **List every yass folder in `.bazelignore`** (the output of `yass paths`, without the `/**`), so `bazel build //...` and `bazel query` never look inside them.
- **Keep them out of targets.** A `glob(["**"])` in a root `BUILD` file (a docs bundle, say) would pull plans into a target, and every plan edit would invalidate it. Exclude them, or glob only what the target needs.
- **Affected-target tools** ([bazel-diff](https://github.com/Tinder/bazel-diff), [target-determinator](https://github.com/bazel-contrib/target-determinator)) then find no affected targets for a plan-only change, so nothing builds. You can also skip running them at all with `yass paths --only` first, the same way as the gate job above.

### Any other CI

Tried YASS with Buck, Pants, Nx, Buildkite, GitLab CI or something else? [Tell us](https://github.com/donjaime/yass/issues) what worked, and we'll list it here.

The same three lines work in Buildkite, Jenkins, GitLab CI or a shell script. Decide on a base (the target branch's merge base for a change under review, the previous commit for a push) and:

```bash
if yass paths --only "$BASE...$HEAD"; then
  echo "plans only: skipping build and tests"
  exit 0
fi
# …the build and tests
```

In Buildkite, run this as the step that uploads the rest of the pipeline, and upload nothing when it exits 0.

## Squash merges

A squash merge folds a pull request into one commit on main. YASS's rules are about commits: intent (a PRD, a design, plan text, a change's Goal or Acceptance), an archive move and a `queue.md` reorder each land apart from code, and progress (boxes, Log, Decisions) lands with the code it describes. With squash merges, "apart from code" means a pull request apart from code:

- **A plan revision, an archive move or a queue reorder goes in a pull request with no code in it.** It can share that pull request with other intent, progress or an archive: a PRD revision with its plan, or a change's last progress with its archive move. These are the pull requests [the recipes above](#plan-only-commits-run-no-ci) let skip build and tests.
- **Progress goes in the pull request of the code it describes,** as it would in a single commit.

The hook checks commit by commit, so it can't see a pull request that will squash an intent commit and a code commit together; keeping them apart is up to whoever opens it. How you get there (separate branches, a stack of pull requests, a stacking tool) is your team's call.

## Big archives

Each yass folder's `archive/` keeps finished changes in `<YYYY>/<MM>/` folders, by the month `yass archive` moved them, so no one folder grows without bound and GitHub can still list them all (it shows up to 1,000 entries in a folder). A team archiving more than about 1,000 changes a month in one yass folder should split it into team folders (`yass init <team folder>`): each team's archive then stays small on its own, and the repo's scales with them. A month that occasionally passes 1,000 is fine.
