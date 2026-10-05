---
platforms: [all]
source: plan.md
follows: 
blocked:
---
# Agent files per folder

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
yass init <folder> --agents puts the AGENTS.md section and the playbooks (and Claude's copies with --claude) in that folder, for a monorepo part with its own agent files; the hook stays at the repo root. Without --agents, yass init <folder> sets up only the folder's planning and touches no AGENTS.md. yass init on a set-up repo or folder writes only what's missing and points at yass upgrade when files are older.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC31–AC33 in [plan.md](../plan.md)

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `yass init`: the agent files' folder separate from the repo root's hook; `--agents` for a folder
- [ ] `yass init <folder>` without `--agents` leaves `AGENTS.md` alone (it used to write the root's)
- [ ] `yass init` on a set-up repo or folder: keep what's there, point at `yass upgrade` when files are older
- [ ] README CLI reference and usage: `--agents`
- [ ] e2e: monorepo folder with and without `--agents`, `--claude` in a folder, re-running init

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
