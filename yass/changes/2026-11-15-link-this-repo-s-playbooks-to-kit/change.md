---
platforms: [all]
source: Jaime, 2026-11-15: the copies in .agents/skills and .claude/skills track the release, not the playbooks being edited in kit/
follows: 
blocked:
created: 2026-11-15T17:44:30Z
---
# Link this repo's playbooks to kit

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
In this repo, `.agents/skills` and `.claude/skills` are links to `kit/.agents/skills`, so an agent working here follows the playbooks as they are being edited, and there is one copy of each instead of three. Nothing about the links reaches the public toolchain: the one thing that needed fixing is that `yass status` compared versions in folders `yass.yaml` ignores, which `yass upgrade` already skips, so with `kit/` ignored as it is today the unstamped playbooks behind the links are left out and nothing ever writes a version stamp into `kit/`. The install and upgrade flows stay proven by the end-to-end tests in scratch repos and by use in other repos, not by this repo's own copies. The `AGENTS.md` section and the hook scripts here stay real, stamped files that `yass upgrade` keeps current.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [x] AC1: Given a fresh clone of this repo on macOS or Linux, then `.agents/skills` and `.claude/skills` are symlinks to `../kit/.agents/skills`, each playbook reads the same as its file in `kit/`, and no stamped copy of a playbook is left in the repo — verify: `git ls-files -s .agents .claude` shows two entries of mode 120000 and `launch.json`; `diff -r .agents/skills kit/.agents/skills`
- [x] AC2: Given a repo whose `yass.yaml` ignores a folder holding playbooks older than the binary (or unstamped), and whose `AGENTS.md` section and hook are at the binary's version, when you run `yass status`, then it prints no version note: playbooks whose real location is in an ignored folder don't count, as `yass upgrade` already leaves them alone — verify: e2e check in a scratch repo
- [x] AC3: Given this repo with the links in place and a `yass` at the version of its `AGENTS.md` section and hook, when you run `yass status` and `yass upgrade`, then status prints no version note, upgrade says everything is up to date, and `kit/` has no diff — verify: by hand, with this code built at that version
- [x] AC4: Given this repo with the links in place, when a new Claude Code session starts here, then it lists the seven `yass-*` skills and loads one from `kit/` — verify: manual, in Claude Code; other harnesses not checked
- [x] AC5: `CONTRIBUTING.md` says the playbooks here are links into `kit/`, how to get them on Windows (Developer Mode and `git config core.symlinks true` before cloning) and that only the agent's skills are missing without it; the comment in `yass.yaml` and the changelog say what changed — verify: read them

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] Go: `yass status`'s version note skips playbooks whose real location is in a folder `yass.yaml` ignores
- [x] e2e: a scratch repo with an ignored folder of old playbooks behind `.claude/skills`; status prints no version note
- [x] Replace this repo's `.agents/skills` and `.claude/skills` with the two links; check `go build`, `go test ./...` and `tests/e2e.sh` still pass
- [x] `CONTRIBUTING.md` (layout table, a Windows note), the `yass.yaml` comment, `CHANGELOG.md` (an unreleased entry: status honours `ignore:`)
- [x] Manual: a new Claude Code session here lists and loads the skills (AC4)

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- Link the two skills folders, not each playbook - two links instead of fourteen, and a new playbook in `kit/` shows up with no extra step (Jaime and Claude, 2026-11-15)
- Dogfood the install and upgrade flows in other repos and in the e2e tests' scratch repos, not through this repo's own copies - the copies made agents here follow the released playbooks instead of the ones being edited (Jaime, 2026-11-15)
- Accept that a Windows clone without symlinks gets no agent skills here - it affects contributors to this repo only; users' repos still get real copies from `yass init`, and the build embeds `kit/` directly (Jaime and Claude, 2026-11-15)
- The `AGENTS.md` section and the hook scripts stay stamped copies - a section of a file can't be a link, and the hook is a shim that rarely changes (Claude, 2026-11-15)
- Plan approved as written - reviewed in conversation before any code (Jaime, 2026-11-15)
- Dropped the rule that upgrade, status and deinit leave symlinked playbooks alone (the first AC2 to AC5) - it put this repo's own setup into the public toolchain; only status needed a fix here, and honouring `ignore:` there is a consistency fix to a setting that exists, since upgrade and deinit already skip ignored folders and already don't see a linked folder (Jaime, 2026-11-15)
- `yass status` checks a playbook's real location against `ignore:` - `ignore:` entries are already resolved through links when `yass.yaml` is read, so `kit` covers the playbooks behind both links with no new entry (Claude, 2026-11-15)
- `yass init`'s "older than this yass" note is left as it is - nobody runs `yass init` in this repo, and it has no ignore list loaded at that point (Claude, 2026-11-15)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-15 (Claude)
- Did: traced the code. `yass upgrade` lists files with `git ls-files`, so a linked folder shows as one entry and is skipped by accident today; a linked `SKILL.md` would be written through. `yass status` globs `.agents/skills/yass-*/SKILL.md` through the link, reads the unstamped kit files and would say "older than this yass" on every run. Wrote the Goal, Acceptance and Steps; nothing built.
- Next: once the plan's pull request merges, start with the Go helper and its tests.

### 2026-11-15 (Claude), plan revised
- Did: rewrote the Goal's middle sentence and the criteria after AC1 (now AC2 to AC5) on Jaime's review of the first build: no symlink rule in the CLI; status honours `ignore:`.
- Next: rebase the code branch onto this and rework it to match.

### 2026-11-15 (Claude), rebuilt to the revised plan
- Did: took the symlink rule back out (no `linkedIn`; upgrade, deinit and init as on main). `stampedFiles` in upgrade.go now leaves out playbooks whose real location `yass.yaml` ignores: ten lines. One e2e scenario under "27." (an ignored folder of unstamped playbooks behind `.agents/skills`). The links, CONTRIBUTING.md, the yass.yaml comment and an Unreleased changelog line. Checked here with this code built as 0.6.0: status prints no version note, upgrade says already up to date, `kit/` has no diff. Go tests pass; e2e passes but for the two checks under "46." that fail apart from this change (they upgrade with a binary pinned at 0.6.0, and a build made after the v0.6.0 tag reports 0.6.1).
- Found: the released 0.6.0 doesn't have the fix, so `yass status` here says "older than this yass" until the next release is installed.
- Next: AC4 by hand: start a new Claude Code session on this branch and check it lists the seven `yass-*` skills and loads one. Then archive.

### 2026-11-15 (Claude), AC4 checked
- Did: started a fresh headless Claude Code session (`claude -p`, 2.1.319) in this checkout on the branch with the links. Its startup listed all seven `yass-*` skills, and loading `yass-status` gave the base directory `.claude/skills/yass-status`, which is the link into `kit/`; no other copy of the playbooks is installed for this user. Checked through the CLI, not the desktop app's own session start.
- Next: nothing; every box is done. Archive.
