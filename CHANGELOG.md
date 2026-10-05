# Changelog

## 0.3.0 (2026-10-05)
Installing and upgrading are now two plain steps. To install: get the `yass` binary, then run `yass init` in your repo. To upgrade: get the newer binary, then run `yass upgrade` in each repo.
- **The binary carries the playbooks and the hook.** `yass init` sets up a whole repo from the binary alone: the playbooks, the hook script, the `AGENTS.md` section and the yass folder, with `--claude`, `--global`, `--hooks` and `--path`. Nothing is downloaded after the binary. Running it again writes only what's missing, and it ends with the next steps (commit it, then ask your agent).
- **`yass upgrade`:** run anywhere in a repo, it finds every YASS file from the repo root down (playbooks in any `.agents/skills/` or `.claude/skills/`, each `AGENTS.md` section, the hook) and your user folder's playbooks, and brings them to the binary's version. It lists what it wrote, says when everything is already up to date, skips folders `yass.yaml` ignores, and never downgrades: if the repo is newer than your binary, it says to upgrade the binary.
- **Version stamps:** every file YASS installs records the version that wrote it: `metadata.yass-version` in a playbook's frontmatter, `version=` in the `AGENTS.md` marker, `# yass-version:` in the hook. `yass status` notes when your binary and a repo are out of step, and which to upgrade.
- **Monorepo folders with their own agent files:** `yass init <folder> --agents` puts the `AGENTS.md` section and the playbooks in that folder, and `yass upgrade` finds them there. The hook stays at the repo root.
- **`install.sh` only installs the binary,** into `--bin-dir` (now required), and says whether that folder is on your PATH, with the line to add it if not (for zsh, in `~/.zshenv`, which agents and git hooks read too). The one-line install runs `yass init` itself. Release archives no longer include `kit/`.
- **Worktrees find separate plans:** a relative `path:` in `yass.yaml` resolves from the clone's other checkouts, so linked worktrees, where agents usually run, find plans kept outside the repo. Paths accept `${VAR:-default}`, and with plans outside the repo, every `yass` command keeps an ignored `yass/` link to them.
- **Private team folders:** `yass init <folder> --path <plans> --private` sets up a folder git never sees, found through the clone's git config, from every worktree.
- **`yass paths`:** prints the repo paths that are YASS's; `--only <range>` exits 0 when a commit range touches nothing else, so CI can skip plan-only commits. [docs/monorepo.md](docs/monorepo.md) has recipes.
- Fixes: change names end on a whole word; paths that don't exist yet compare correctly through symlinks (macOS).
- Building from source needs Go 1.24 or later, so a build from a clone carries a version.

Migrating:
- **`install.sh` no longer sets up or upgrades repos.** An old-style call (a repo path, `--claude`, `--global`, `--hooks`, `--path` or `--upgrade`) installs nothing and prints the commands to use instead. Update scripts that call it: `install.sh --bin-dir <folder>`, then `yass init` or `yass upgrade`.
- **To upgrade a repo,** install the new binary, run `yass upgrade` in the repo, and commit the diff (`chore: upgrade YASS`). Files from 0.2 or earlier carry no version stamp; `yass upgrade` counts them as older and stamps them. As before, hand edits to YASS's own files are replaced, and the diff shows them.
- **`yass init <folder>`** (a team folder) now sets up only that folder's planning. It no longer adds the YASS section to the root `AGENTS.md`; pass `--agents` to give the folder its own agent files. And `yass init` no longer rewrites an existing `AGENTS.md` section; `yass upgrade` does.

## 0.2.0 (2026-10-03)
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
