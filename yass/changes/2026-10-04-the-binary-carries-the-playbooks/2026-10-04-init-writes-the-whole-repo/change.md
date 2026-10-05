---
platforms: [all]
source: plan.md
follows: 
blocked:
---
# Init writes the whole repo

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
Every yass binary carries the kit (the playbooks and the hook script) for its version, and yass init writes all of a repo's YASS files from it, stamped with that version, with the --claude, --global and --hooks options install.sh has today. Files that already exist are kept, as install.sh does without --upgrade. install.sh is unchanged except that it passes --global on to yass init, so yass init doesn't add repo copies of playbooks that went to the user folder.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC1–AC8 in [plan.md](../plan.md)

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `kit/` as a Go package that embeds its files; go test lists them
- [ ] Stamp writers: playbook frontmatter `metadata`, `AGENTS.md` marker, hook header
- [ ] `yass init` writes playbooks, hook, Claude copies and `CLAUDE.md` import, `core.hooksPath`; `--claude`, `--global`, `--hooks`
- [ ] README CLI reference: `yass init` options
- [ ] e2e: `yass init` alone, each option, stamps

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->
- `install.sh` passes `--global` on to `yass init` - `yass init` now writes playbooks, and without it, an `install.sh --global` would get repo copies too; revised before building (claude)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
