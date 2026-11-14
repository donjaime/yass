# Verify YASS for multi-team repos is designed properly: design
<!-- Intent: the calls that are hard to undo. Edit only in commits without code. -->

## Context
Two new files become public surface that people and teams will have on disk after 0.5.0: the personal memory (where it lives and what's in it) and the team memory (its name). Moving either later means a migration in `yass upgrade` or a note telling everyone to move a file.

## 1. Where the personal memory lives, and how a clone is named

### Options
- **A. One global `${XDG_CONFIG_HOME:-~/.config}/yass/settings.json`** (`%APPDATA%\yass\settings.json` on Windows; `$YASS_CONFIG_DIR` overrides the folder), with an entry per clone, read and written only by the `yass` CLI.
  - A clone's key is the first 8 hex characters of a SHA-256 of its git common dir (absolute, cleaned). Every linked worktree shares that dir, so they share the entry, and a separate clone gets its own.
  - Agents never open the file: they run `yass me`, which they can run anywhere their shell can. An agent's file permissions usually stop at the project's folders, so a file outside it would need a prompt every session, or an extra allowed directory set up by every person.
- **B. A markdown file per clone in `~/.config/yass/clones/`**, which agents read directly. This was the first plan. It's easy to edit by hand, but agents usually can't reach it without asking.
- **C. Keyed by the remote URL.** It would survive re-cloning, but the PRD wants a separate clone set up again, and remote URLs change (forks, SSH vs HTTPS, renames).

### Decision
**A** (Jaime, 2026-11-14, after B was planned): the file lives where personal state belongs, and the CLI is the way in, so permissions never get in the agent's way.

## 2. What the personal memory holds

### Options
- **A. JSON, written by the CLI:**
  ```json
  {
    "name": "Sam Rivera",
    "clones": {
      "3f9a1c2e": { "repo": "/Users/sam/src/acme", "team": "search",
                    "folders": ["services/search"], "notes": "…" }
    }
  }
  ```
  - `name` is yours across every repo; `team`, `folders` and `notes` are per clone.
  - `repo` is only there so a person reading the file can tell entries apart.
  - `folders` are yass folders by path from the repo top, as `yass status` prints them, or the folder a team's yass folder serves (`services/search`). The first is where `yass new` puts a change from the repo root.
  - Keys YASS doesn't know are kept as they are when it writes.
- **B. Markdown with frontmatter per clone** (the first plan). It's friendlier to edit by hand, but the CLI would have to parse and rewrite prose to change a field.

### Decision
**A** (Jaime chose a global settings file through the CLI, 2026-11-14). `yass me --json` gives agents exactly what the binary reads. The notes are one string per clone, enough for things an agent should hear every session.

## 3. The team memory

### Options
- **A. `team.md` at the top of the yass folder,** beside `settings.yaml`. Plain markdown, no fields the binary reads. Agents read it before the lifecycle playbooks' tracker steps. Its project management workflow sits under a `## Project management` heading, in the same shape as the Trello table (moment → what to do).
- **B. A `workflow:` section in `settings.yaml`.** One file fewer, but prose in YAML is hard to review and edit, and `settings.yaml` stays identifiers only (the tracker change's decision).

### Decision
**A.** It's named for what it is, the team's shared memory, so it can grow past the workflow without a rename. YASS creates it only when there's something to put in it. (claude, while planning; for review, 2026-11-14)

## Consequences and rollback
- **Upgrade:** `yass upgrade` doesn't touch either file. No repo has either today, so nothing migrates.
- **Rollback:** before release, both are cheap to drop. After release, the settings file's shape is public: a change to it means `yass me` reading the old shape for a release.
- **Bench:** filtering `yass status` adds one small file read and no git calls; `tests/bench.sh` timings go in the pull request.
