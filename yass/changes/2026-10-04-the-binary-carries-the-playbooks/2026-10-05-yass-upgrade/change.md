---
platforms: [all]
source: plan.md
follows: 
blocked: 2026-10-04-the-binary-carries-the-playbooks/2026-10-05-agent-files-per-folder
---
# yass upgrade

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
`yass upgrade`, run anywhere in a repo, finds every YASS file from the repo root down (playbooks in any `.agents/skills/` or `.claude/skills/`, every `AGENTS.md` with the YASS marker, the hook), plus the user folder's playbooks, and compares each one's stamp with its own version: older or unstamped files are upgraded where they are, the same version is up to date (unless the binary is +dirty), and any newer file stops it with upgrade-your-binary. It says which it did, lists every file it wrote, and labels files outside version control. Builds from source need Go 1.24, so clone builds carry a version. The README and docs/install.md say how to upgrade.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC9–AC19, AC34 and AC35 in [plan.md](../plan.md)

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `golang.org/x/mod/semver`; the version comparison and its decision table (go test)
- [ ] Discovery: `git ls-files` for nested playbooks, marked `AGENTS.md` files and the hook; the user folder's playbooks
- [ ] `yass upgrade`: upgrade / up to date / refuse, with the messages and exit codes; unversioned binaries refuse (in `yass init` too)
- [ ] File listing, outside-version-control label
- [ ] `go 1.24` in `go.mod`; docs that say 1.22
- [ ] README CLI reference and an Upgrading section in the README and `docs/install.md`
- [ ] e2e: upgrade paths, nested monorepo copies, a v0.2.0 fixture, identical-to-fresh check
- [ ] Dogfood: `yass upgrade` in this repo

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
