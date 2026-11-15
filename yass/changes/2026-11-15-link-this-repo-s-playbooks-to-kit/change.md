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
In this repo, `.agents/skills` and `.claude/skills` are links to `kit/.agents/skills`, so an agent working here follows the playbooks as they are being edited, and there is one copy of each instead of three. YASS's own commands leave a playbook they reach through a link in a repo alone, so nothing ever writes a version stamp into `kit/`. The install and upgrade flows stay proven by the end-to-end tests in scratch repos and by use in other repos, not by this repo's own copies. The `AGENTS.md` section and the hook scripts here stay real, stamped files that `yass upgrade` keeps current.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] AC1: Given a fresh clone of this repo on macOS or Linux, then `.agents/skills` and `.claude/skills` are symlinks to `../kit/.agents/skills`, each playbook reads the same as its file in `kit/`, and no stamped copy of a playbook is left in the repo — verify: `git ls-files -s .agents .claude` shows two entries of mode 120000 and `launch.json`; `diff -r .agents/skills kit/.agents/skills`
- [ ] AC2: Given a repo whose `.agents/skills` or `.claude/skills` (or a playbook inside one) is a symlink, when you run `yass upgrade`, then it writes nothing through the link and the files the link points to are unchanged, while the `AGENTS.md` section and the hook are still upgraded — verify: e2e check in a scratch repo, plus a Go unit test for the per-file and per-folder cases
- [ ] AC3: Given the same repo, when you run `yass status`, then playbooks reached through a link don't count toward the version note: with the `AGENTS.md` section and hook at the binary's version there is no "older than this yass" note — verify: e2e check, and `yass status` in this repo prints no version note
- [ ] AC4: Given the same repo, when you run `yass deinit`, then it removes nothing through a link (the files the link points to stay) — verify: Go unit test or e2e check
- [ ] AC5: Given the user folder's playbooks (`~/.agents/skills`, `~/.claude/skills`) reached through a symlink, when you run `yass upgrade`, then they are upgraded as today: the rule is for files in a repo only — verify: e2e check or Go unit test
- [ ] AC6: Given this repo with the links in place, when a new Claude Code session starts here, then it lists the seven `yass-*` skills and loads one from `kit/` — verify: manual, in Claude Code; other harnesses not checked
- [ ] AC7: `CONTRIBUTING.md` says the playbooks here are links into `kit/`, how to get them on Windows (Developer Mode and `git config core.symlinks true` before cloning) and that only the agent's skills are missing without it; the comment in `yass.yaml` and the changelog say what changed — verify: read them

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] Go: one helper that says whether a path in the repo is reached through a symlink; use it in `findYassFiles` (upgrade), `stampedFiles` (status, `repoVersion`) and deinit's search. Leave the user-folder paths as they are.
- [ ] Go unit tests: linked folder, linked playbook folder, linked `SKILL.md`, user folder through a link
- [ ] e2e: a scratch repo with `.claude/skills` linked to a folder outside what `yass upgrade` manages; upgrade, status and deinit leave it alone
- [ ] Replace this repo's `.agents/skills` and `.claude/skills` with the two links; check `go build`, `go test ./...` and `tests/e2e.sh` still pass
- [ ] `CONTRIBUTING.md` (layout table, a Windows note), the `yass.yaml` comment, `CHANGELOG.md` (an unreleased entry: linked playbooks are left alone)
- [ ] Manual: a new Claude Code session here lists and loads the skills (AC6)

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- Link the two skills folders, not each playbook - two links instead of fourteen, and a new playbook in `kit/` shows up with no extra step (Jaime and Claude, 2026-11-15)
- Dogfood the install and upgrade flows in other repos and in the e2e tests' scratch repos, not through this repo's own copies - the copies made agents here follow the released playbooks instead of the ones being edited (Jaime, 2026-11-15)
- Accept that a Windows clone without symlinks gets no agent skills here - it affects contributors to this repo only; users' repos still get real copies from `yass init`, and the build embeds `kit/` directly (Jaime and Claude, 2026-11-15)
- The `AGENTS.md` section and the hook scripts stay stamped copies - a section of a file can't be a link, and the hook is a shim that rarely changes (Claude, 2026-11-15)
- Plan approved as written - reviewed in conversation before any code (Jaime, 2026-11-15)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-15 (Claude)
- Did: traced the code. `yass upgrade` lists files with `git ls-files`, so a linked folder shows as one entry and is skipped by accident today; a linked `SKILL.md` would be written through. `yass status` globs `.agents/skills/yass-*/SKILL.md` through the link, reads the unstamped kit files and would say "older than this yass" on every run. Wrote the Goal, Acceptance and Steps; nothing built.
- Next: once the plan's pull request merges, start with the Go helper and its tests.
