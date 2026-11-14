# Verify YASS for multi-team repos is designed properly: design
<!-- Intent: the calls that are hard to undo. Edit only in commits without code. -->

## Context
Two new files become public surface that people and teams will have on disk after 0.5.0: the personal memory (where it lives and what's at its top) and the team memory (its name). Moving either later means a migration in `yass upgrade` or a note telling everyone to move a file.

## 1. Where the personal memory lives, and how a clone is named

### Options
- **A. `${XDG_CONFIG_HOME:-~/.config}/yass/clones/<repo>-<id>.md` on macOS and Linux, and `%APPDATA%\yass\clones\…` on Windows.**
  - `<repo>` is the base name of the clone's top folder, so a person can find their file by eye.
  - `<id>` is the first 8 hex characters of a SHA-256 of the clone's git common dir (absolute, cleaned). Every linked worktree shares that dir, so they all find the same file, and a separate clone gets its own.
  - `$YASS_CONFIG_DIR` overrides the folder, as `$YASS_SKILLS_DIR` does for playbooks, for tests and unusual setups.
- **B. Go's `os.UserConfigDir()` everywhere.** That's `~/Library/Application Support/yass/…` on macOS: correct by Apple's rules, but awkward to find and edit by hand, and different from where YASS already puts user files (`~/.agents/skills/`).
- **C. Keyed by the remote URL.** It would survive re-cloning, but the PRD wants a separate clone set up again, and remote URLs change (forks, SSH vs HTTPS, renames).

### Decision
**A.** One predictable place a person can open, named after the repo, and shared by exactly the checkouts that share a git folder: a clone's worktrees, and nothing else. (claude, while planning; for review, 2026-11-14)

## 2. What's at the top of the personal memory

### Options
- **A. Markdown with YAML frontmatter,** like `change.md`. The binary reads only the frontmatter; agents read all of it.
  ```markdown
  ---
  name: Sam Rivera
  team: search
  folders: [services/search]
  ---
  # Notes for agents
  ```
  `folders:` are yass folders by path from the repo top, the same paths `yass status` prints. The first is where `yass new` puts a change from the repo root.
- **B. A YAML file plus a separate notes file.** It's cleaner for the binary, but means two files per clone to explain, against the PRD's one.

### Decision
**A** (Jaime chose one markdown file, 2026-11-14). An unknown key at the top is a note, not a warning, since it's a person's own file. A folder listed there that isn't a yass folder in this repo is a warning, naming it.

## 3. The team memory

### Options
- **A. `team.md` at the top of the yass folder,** beside `settings.yaml`. Plain markdown, no fields the binary reads. Agents read it before the lifecycle playbooks' tracker steps. Its project management workflow sits under a `## Project management` heading, in the same shape as the Trello table (moment → what to do).
- **B. A `workflow:` section in `settings.yaml`.** One file fewer, but prose in YAML is hard to review and edit, and `settings.yaml` stays identifiers only (the tracker change's decision).

### Decision
**A.** It's named for what it is, the team's shared memory, so it can grow past the workflow without a rename. YASS creates it only when there's something to put in it. (claude, while planning; for review, 2026-11-14)

## Consequences and rollback
- **Upgrade:** `yass upgrade` doesn't touch either file. No repo has either today, so nothing migrates.
- **Rollback:** before release, both are cheap to drop. After release, moving the personal memory means `yass me` would look in both places for a release.
- **Bench:** filtering `yass status` adds one small file read and no git calls; `tests/bench.sh` timings go in the pull request.
