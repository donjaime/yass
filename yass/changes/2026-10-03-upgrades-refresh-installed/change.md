---
platforms: [all]
source: 
follows: 
blocked:
---
# Upgrades refresh what's installed

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
Upgrading YASS updates every copy of the playbooks a repo already has, without having to remember the flags it was installed with, and tells people where to read what changed. The upgrade path, including the one-line form, is documented.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Given a repo installed with `--claude`, when `install.sh --upgrade` runs without `--claude`, then `.claude/skills/yass-*` are replaced too — verify: tests/e2e.sh
- [ ] Given a repo without `.claude/skills/yass-*`, when `install.sh --upgrade` runs without `--claude`, then none are created — verify: tests/e2e.sh
- [ ] Given playbooks installed with `--global` (none in the repo, some in the user folder), when `install.sh --upgrade` runs without `--global`, then it replaces the user folder's copies, says so, and writes none into the repo — verify: tests/e2e.sh
- [ ] Given any upgrade, when it finishes, then its message points to the release notes for what changed and how to migrate — verify: tests/e2e.sh
- [ ] Given docs/install.md, when someone looks up upgrading, then it says the flags are detected, shows the one-line upgrade, and says to read the release notes — verify: manual: read docs/install.md "Upgrading"

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `--upgrade` detects `.claude/skills/yass-*` in the repo and refreshes them
- [ ] `--upgrade` with no playbooks in the repo but some in the user folder refreshes those
- [ ] Release notes link in the upgrade message
- [ ] e2e checks
- [ ] docs/install.md "Upgrading", and the README's install paragraph

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->
- Detect what's installed instead of recording install flags in a file - the installed copies already say where the playbooks live; a record could drift from them (claude)
- Out of scope for now: stamping a version into the playbooks so `yass status` can warn when they don't match the binary - more machinery; revisit if mismatches bite (claude)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
