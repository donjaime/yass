---
platforms: [all]
source: Jaime, 2026-11-15: an audit of the playbooks for clarity and token cost; two sections load far more often than they are used
follows: 
blocked:
created: 2026-11-15T20:24:05Z
---
# Ship playbook reference files, read on demand

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
A playbook can ship with reference files beside its `SKILL.md`, which an agent reads only when the playbook points at them. `yass init` writes them, `yass upgrade` keeps them current and `yass deinit` removes them, in the repo's skills folders and the user folder alike, so they are always at the same version as the playbook they belong to. Two sections move out of the playbooks into such files: the Trello workflow leaves `yass-init` for `yass-init/trello.md`, and "Plans in another folder" leaves `yass-work` for `yass-work/plans-elsewhere.md`. A tracker moment then costs the workflow alone (about 560 words) instead of all of `yass-init` (about 1,550), and a `yass-work` run in a repo whose plans are inline no longer loads about 420 words it doesn't use. No rule changes: the moved text says what it says today, and every playbook that relied on it names the file to read and when.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] AC1: Given a repo with no YASS files, when you run `yass init` (and with `--claude`, `--global`, or `<folder> --agents`), then every skills folder it writes holds each playbook's reference files beside its `SKILL.md`, reading the same as the files in `kit/`, and init lists them among what it wrote — verify: e2e
- [ ] AC2: Given a repo set up by an older yass, with no reference files, when you run `yass upgrade`, then it writes them in every skills folder it upgrades (the repo's, a monorepo folder's, the user folder's) and lists each — verify: e2e
- [ ] AC3: Given a repo at the binary's version in which a reference file was edited by hand or deleted, when you run `yass upgrade` from a newer yass, then the file reads as the binary's again; and from a yass at the same version, a deleted one is written back and nothing else changes — verify: e2e
- [ ] AC4: Given a repo whose playbooks were written by a newer yass, when you run `yass upgrade`, then it refuses as it does today and writes no reference file — verify: e2e
- [ ] AC5: Given a repo with reference files, when you run `yass deinit`, then they are gone with their playbooks' folders, and a `yass-*` skill that isn't YASS's keeps all its files — verify: e2e
- [ ] AC6: Given the playbooks as shipped, then `yass-init` no longer holds the Trello workflow and `yass-work` no longer holds "Plans in another folder"; each of `yass-work`, `yass-shape`, `yass-plan`, `yass-status`, `yass-log` and the `AGENTS.md` section that relied on one names the file and when to read it; and every rule in the two moved sections is in its file, worded as before — verify: read the diff, moved text against removed text
- [ ] AC7: `docs/skills.md` and the changelog say that playbooks can carry reference files, which ones exist, and that `yass upgrade` adds them — verify: read them

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] Go: the kit lists each playbook's reference files; `yass init` places them; `yass upgrade` targets them, following their playbook's version stamp, and writes a missing one
- [ ] e2e: AC1 to AC5 in scratch repos
- [ ] Move the two sections into `kit/.agents/skills/yass-init/trello.md` and `kit/.agents/skills/yass-work/plans-elsewhere.md`; point the playbooks and the `AGENTS.md` section at them
- [ ] `docs/skills.md`, `CHANGELOG.md`

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- Reference files beside `SKILL.md`, not an eighth playbook - covers both sections and adds nothing to the text loaded in every session; an eighth playbook would add a description to every session and leave "Plans in another folder" where it is (Jaime, 2026-11-15)
- A reference file carries no version stamp and follows its playbook's - one stamp per playbook folder keeps the files plain markdown and `yass status`'s version check unchanged (Claude, 2026-11-15)
- The Trello workflow stays in `yass-init`'s folder - the `AGENTS.md` section and the docs already call it `yass-init`'s, and the playbooks are always installed together, so the others can name a sibling folder's file (Claude, 2026-11-15)
- `yass upgrade` doesn't remove a reference file a later version drops - nothing drops one yet; decide it when something does (Claude, 2026-11-15)
- Plan approved as written - reviewed in conversation before any code (Jaime, 2026-11-15)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
