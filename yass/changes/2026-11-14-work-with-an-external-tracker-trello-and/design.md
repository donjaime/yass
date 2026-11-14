# Work with an external tracker: Trello and others: design
<!-- Intent: the calls that are hard to undo. Edit only in commits without code. -->

## Context
Two choices here become public surface that teams commit to: how tracker settings are spelled in `yass.yaml`, and where a yass folder kept outside the repo keeps its settings. Both are hard to change after 0.5.0 ships, because repos and private plans repos will have files in that shape.

Today a `yass.yaml` points to a yass folder, in the repo under any name (`path: specs`) or outside it, and holds that folder's settings ([README: Keeping plans out of the repo](../../../README.md#keeping-plans-out-of-the-repo)). A private plans setup can keep that file out of git, but then each clone has its own copy, unversioned and unshared, and nothing notices when one with private settings is about to be committed to a public repo.

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
R18: private plans keep their tracker setup private, the same way public ones keep theirs.

### Options
- **A. One `yass.yaml`, with a note before it's published.** The `yass.yaml` that points to a yass folder holds its settings. A private setup keeps it out of git, and `yass status` notes one pointing outside the repo that git would commit with settings beyond the pointer. One file, but each clone keeps its own uncommitted copy of the private settings, so every teammate recreates them and they have no history.
- **B. A yass folder's own `yass.yaml`** at the top of the plans folder. Private settings travel with the plans, but a `yass.yaml` there is ambiguous with a pointer, so discovery needs a rule to tell the two apart.
- **C. An optional `settings.yaml` inside every yass folder.** It holds `branch:`, `archive:` and `tracker:`, and merges with `yass.yaml` setting by setting, the folder's winning. `path:` and `ignore:` stay in `yass.yaml`, since they're about where the folder is and the repo around it. It works the same inline and outside the repo. For private plans, the settings are committed in the private plans repo, shared and versioned, and the public `yass.yaml` can stay committed with just the pointer. A distinct name means discovery doesn't change.

### Decision
**C** (Jaime, 2026-11-14). B was planned first and built in piece 1, then replaced by A as simpler; A left private settings unversioned on each clone, and C fixes that without B's ambiguity.
- **Merging:** setting by setting; the folder's `settings.yaml` wins. A setting in both with different values is a warning, so a conflict is never silent.
- **Misplaced settings:** `path:` or `ignore:` in `settings.yaml` warn that they belong in `yass.yaml`. Its unknown settings warn like `yass.yaml`'s.
- **The note stays from A:** a committed `yass.yaml` pointing outside the repo with `branch:`, `archive:` or `tracker:` gets a note, not a warning, suggesting `settings.yaml`.
- **Agents:** `yass-init` always writes tracker settings to the folder's `settings.yaml`.
- **Unchanged:** a plans repo's own `yass.yaml` with `path: .`, for running `yass` inside it, works as before.

## Consequences and rollback
- **Discovery doesn't change.** `settings.yaml` is read only from yass folders already found, so existing repos read their settings exactly as before.
- **One more file read per yass folder** when its settings are first needed; `tests/bench.sh` timings go in the pull request.
- **`settings.yaml` becomes public surface in 0.5.0.** Dropping it later would need `yass upgrade` to move its settings back into `yass.yaml`.
