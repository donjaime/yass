# Changelog

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
