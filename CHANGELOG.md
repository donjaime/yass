# Changelog

## 0.2.0 (unreleased)
- **`queue.md`:** an optional file in a yass folder that ranks its changes, top first. `yass status` follows it (unlisted changes come after, oldest first) and warns about entries that aren't active changes there; `yass archive` takes the change off the list; the hook treats reordering alongside code as intent.
- **Dependencies through `blocked:`:** naming one or more changes (a folder name, a path ending in one, or `<change>/<piece>`, comma-separated) means waiting on them. `yass status` shows `waiting on:` until they're done or archived, then nothing; `yass archive` refuses only while it's still waiting. Warnings for names that look like a change but aren't, and for changes that wait on each other.
- **`ignore:` in `yass.yaml`:** folders or glob patterns (`examples/*`) whose `yass/` folders belong to something else. They're left out of `status`, `root`, `new` and the hook; from inside one, it's a project of its own. A `yass.yaml` without `path:` beside a `yass/` folder just holds settings.
- **Upgrades:** `install.sh --upgrade` refreshes the playbooks wherever they're installed (Claude's copies, or your user folder's when the repo has none) without the original flags, and ends with upgrade steps and a link to the release notes. docs/install.md covers upgrading, including the one-line form.
- The playbooks know about the queue and dependencies: `yass-status` answers "what's next?" from them, `yass-work` sets `blocked: <change>` when work has to wait, and `yass-plan` can use it between pieces. Examples: solo-app has a `queue.md`; the monorepo's web change waits on payments through `blocked:`.

Migrating: nothing to do. One behavior changes: a `blocked:` whose value is only change names now clears itself once they're done, where before it stayed until someone cleared it. Run `install.sh --upgrade` for the new playbooks.

## 0.1.0 (2026-10-03)
First public version.
- Changes as dated folders under `yass/changes/`, with ceremony that scales: `change.md` for small work; `prd.md`, `plan.md`, optional `design.md` and PR-sized pieces for large work.
- `yass/archive/` for finished changes; append-only, with `follows:` for follow-ups.
- CLI: one Go binary with no runtime dependencies. `init`, `new`, `status`, `archive`, `root`, and `hook` (the optional pre-commit check, also for CI). `status` marks changes `not started` or `done`.
- `yass.yaml`: keep the yass folder outside the repo (or under another name), by relative path, `~`, or environment variables. Also the home for future settings.
- Boxes can cite code commits (`— code: a1b2c3d`); `yass status` warns about commits the repo doesn't have, and about done boxes whose code isn't on the merged branch (`branch:` in `yass.yaml`).
- Releases for macOS, Linux and Windows (amd64, arm64) with checksums and build provenance, built by GoReleaser from tags.
- Checkboxes: `[ ]` not started, `[/]` in progress, `[x]` done, `[-]` dropped.
- An optional pre-commit hook that warns when code and edits to existing intent share a commit; `yass hook --range … --strict` for CI.
- Playbooks (Agent Skills): yass-shape, yass-plan, yass-work, yass-status, yass-log.
- `install.sh`, with `--bin-dir`, `--path`, `--global`, `--claude` and `--hooks`. Install from a release, from source, or with an agent prompt that verifies before it runs (docs/install.md).
- Examples: a solo mobile app and a three-team monorepo.
