# Work with an external tracker: Trello and others: design
<!-- Intent: the calls that are hard to undo. Edit only in commits without code. -->

## Context
Two choices here become public surface that teams commit to: how tracker settings are spelled in `yass.yaml`, and where a yass folder kept outside the repo keeps its settings. Both are hard to change after 0.5.0 ships, because repos and private plans repos will have files in that shape.

Today a `yass.yaml` points to a yass folder, in the repo under any name (`path: specs`) or outside it, and holds that folder's settings ([README: Keeping plans out of the repo](../../../README.md#keeping-plans-out-of-the-repo)). A private plans setup can keep that file out of git, but nothing notices when one with private settings is about to be committed to a public repo.

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

## 2. Settings for private plans
R18: private plans keep their tracker setup private, without a second place for settings.

### Options
- **A. One `yass.yaml`, as today, with a check before it's published.** The `yass.yaml` that points to a yass folder holds its settings, whatever the folder is called and wherever it is. When it points outside the repo and git would commit it (tracked, or not ignored) with anything besides `path:` and `ignore:`, `yass status` adds a note asking to check that's intentional. It's a note, not a warning, so `--strict` passes once it is. `yass-init` asks before writing settings into such a file. A private setup keeps the file out of git, which [already works](../../../README.md#keeping-plans-out-of-the-repo), worktrees included.
- **B. A yass folder's own `yass.yaml`,** at the top of a plans folder, holding everything but the pointer, with its settings winning over the pointer's. Private settings then travel with the plans. But it means two settings files per folder, a rule for which one wins, and a discovery rule for telling a settings file from a pointer.

### Decision
**A.** This was first decided as B while planning; building B in piece 1 showed it was more machinery than the goal needs, and Jaime reversed it (2026-11-14). The note covers `branch:` and `archive:` as well as `tracker:`, so anything beyond the pointer gets a second look (Jaime). (A plans repo's own `yass.yaml` with `path: .`, for running `yass` inside it, works as before and isn't part of this.)

## Consequences and rollback
- **Nothing changes in discovery,** so existing repos read their settings exactly as before.
- **The note is advisory.** It never blocks a commit and never fails `--strict`. Keeping the file out of git, or keeping only `path:` and `ignore:` in it, makes it go away.
- **Rollback is cheap:** the note can be dropped without changing a file anyone has written.
