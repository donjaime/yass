---
platforms: [all]
source: plan.md
follows: 
blocked: 2026-10-04-the-binary-carries-the-playbooks/2026-10-04-init-writes-the-whole-repo
---
# Init upgrades by version

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
yass init reads the version stamps of the YASS files already installed, wherever they are, and compares them with its own: older or unstamped files are upgraded, the same version is up to date (unless the binary is +dirty), and newer files stop it with upgrade-your-binary. It says which it did, lists every file it wrote, and labels files outside version control. Builds from source need Go 1.24, so clone builds carry a version.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Delivers AC9–AC19 in [plan.md](../plan.md)

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `golang.org/x/mod/semver`; the version comparison and its decision table (go test)
- [ ] Find what's installed and read its stamps (repo, Claude copies, user folder, hook, marker)
- [ ] Upgrade / up to date / refuse, with the messages and exit codes; unversioned binaries refuse
- [ ] File listing, outside-version-control label
- [ ] `go 1.24` in `go.mod`; docs that say 1.22
- [ ] e2e: upgrade paths, a v0.2.0 fixture, identical-to-fresh check
- [ ] Dogfood: `yass init` in this repo

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
