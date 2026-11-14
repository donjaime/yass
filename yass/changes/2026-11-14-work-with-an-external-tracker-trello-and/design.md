# Work with an external tracker: Trello and others: design
<!-- Intent: the calls that are hard to undo. Edit only in commits without code. -->

## Context
Two choices here become public surface that teams commit to: how tracker settings are spelled in `yass.yaml`, and where a yass folder kept outside the repo keeps its settings. Both are hard to change after 0.5.0 ships, because repos and private plans repos will have files in that shape.

Today a `yass.yaml` is a pointer that sits where a `yass/` folder would go. Without `path:` the yass folder is the `yass/` beside it, and any `yass.yaml` found in the repo counts as a yass folder ([README: Keeping plans out of the repo](../../../README.md#keeping-plans-out-of-the-repo)). A separate plans folder, like a private plans repo, has `changes/` and `archive/` at its top and no `yass.yaml` of its own. So its only settings today are in the code repo's pointer, which an open source repo commits publicly.

## 1. Spelling the tracker settings

### Options
- **A. One `tracker:` section, with a key per tool.** `tracker.trello` has a fixed shape that YASS validates. Any other key under `tracker:` (`jira`, `linear`, `acme-pm`) is free-form YAML that YASS stores and never warns about.
  ```yaml
  tracker:
    trello:
      board: https://trello.com/b/AbC123/payments
      lists:            # Trello list IDs, by role
        ideas: 64f0…
        will-do: 64f1…
        planning: 64f2…
        implementing: 64f3…
        done: 64f4…
    jira:               # anything: YASS stores it, the agent's memory says what it means
      site: https://acme.atlassian.net
      project: PAY
  ```
- **B. Top-level `trello:` plus a free-form `properties:` map** for everything else. Trello sits beside YASS's own settings. Other trackers' keys get no namespace of their own, and a second Trello-shaped tool would need another top-level key.
- **C. Lists by name, not ID.** The agent finds lists by their names on every move. There's less to store, but renaming a list on Trello silently breaks every agent, and a board with two lists of similar names is ambiguous.

### Decision
**A, with list IDs.** Every tracker lives under one key, so YASS's own settings and the warning for unknown settings stay as they are, and teams can name their tool however their memory does. IDs survive renames. The agent writes them when it adopts the board (R4) and can re-match them by name if they're ever stale. (claude, while planning; for review, 2026-11-14)

A change's card stays in its existing `source:`, so changes need no new field.

## 2. A yass folder's own settings
R18: with plans kept outside the repo, the code repo's `yass.yaml` holds only the pointer. Everything else lives with the plans.

### Options
- **A. A `yass.yaml` at the top of a yass folder holds that folder's settings.** A `yass.yaml` whose own folder has `changes/` or `archive/` is a settings file for that yass folder, not a pointer. `path:` there is an error, and it's never counted as a yass folder of its own. For a separate plans folder, it's where everything but `path:` and `ignore:` goes. An inline yass folder can use it too (`yass/yass.yaml`), and when both exist its settings win over the pointer's.
- **B. A settings file with another name** (`yass/settings.yaml`, `yass/tracker.yaml`). There's no ambiguity with pointers, but it means two files to explain, and the PRD and the human asked for `yass.yaml`.
- **C. Keep settings in the pointer, and gitignore the pointer for private plans.** No new rule. But the default (commit `yass.yaml`) leaks the board, and one forgotten gitignore publishes private setup.

### Decision
**A.** Jaime chose a folder's own `yass.yaml`, and added that the public pointer should carry only the pointer (2026-11-14).
- **The pointer:** with plans separate, `branch:`, `archive:` or `tracker:` in the code repo's pointer still work this release, but `yass status` warns and names where to move them. A `tracker:` found there also says it may be public.
- **Inline repos:** these keep working unchanged. Their `yass.yaml` beside `yass/` is both pointer and settings, as today.

## Consequences and rollback
- **Discovery changes:** a `yass.yaml` next to `changes/` or `archive/` stops counting as a pointer. No repo has one today: a `yass.yaml` there with no `path:` would point at a `yass/` folder inside the yass folder, which doesn't exist. So nothing that works today breaks. A test pins this.
- **Rollback:** before release, rolling back means dropping the new rule. After release, a folder's own `yass.yaml` can't be taken back without a migration that `yass upgrade` would have to write. That's why it ships only once tests cover discovery from the code repo, from a linked worktree and from inside the plans repo.
- **Bench:** discovery runs on every `yass status`, so `tests/bench.sh` timings go in the pull request.
