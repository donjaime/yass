---
platforms: [all]
source: plan.md
follows: 
blocked: 2026-10-04-the-binary-carries-the-playbooks/2026-10-05-yass-upgrade
---
# install.sh installs the binary

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
install.sh only installs the yass binary, and says where, whether it's on PATH, and that yass init sets up a repo; the documented one-liner chains yass init itself. Given old-style repo arguments, install.sh installs nothing and prints the two commands instead. Release archives drop the kit files. The README, docs/install.md and the landing page describe the new model.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [/] Delivers AC20–AC27 in [plan.md](../plan.md)

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] `install.sh`: binary install and PATH report only; refuse old-style repo arguments, printing the commands to use (`yass upgrade` for `--upgrade`)
- [x] `.goreleaser.yaml`: archives without `kit/`
- [x] e2e: rework the `install.sh` sections; unpacked release without `kit/`
- [x] README, `docs/install.md`, landing page: the new model and joining
- [ ] Release candidate: the one-liner in a fresh repo (AC24)

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->
- `install.sh` requires `--bin-dir`: installing the binary is all it does, so without a folder there's nothing to do (claude)
- The "YASS is set up; commit it, then ask your agent" steps `install.sh` used to print now come from `yass init`, when it sets up a repo for the first time (claude)
- The agent prompt now has the agent run `install.sh --bin-dir`, then `yass init` with your options; the page's copy changed with it (claude)
- `docs/install.md` is reorganized around the two steps: get the binary (a release, source, `go install`), then "Setting up a repo" with `yass init`'s options, which replaces the old `install.sh` options table (claude)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->

### 2026-10-05 (claude)
- Did: `install.sh` only installs the binary: from `$YASS_BIN`, the binary next to it (a release folder or a clone's `bin/`), or a downloaded release checked against `checksums.txt`; it reports PATH and points at `yass init`; old-style arguments (a repo path, `--claude`, `--global`, `--hooks`, `--path`, `--upgrade`) install nothing and print the commands to use. Release archives drop `kit/`. e2e §8 rewritten for it; every e2e and `tests/examples.sh` setup now uses `yass init`. README install section, `docs/install.md`, `CONTRIBUTING.md`, `docs/skills.md` and the landing page's install tabs describe the two steps. Checks: e2e 355, examples, `tests/site.sh` 60, `go test`; a GoReleaser snapshot build, whose archive's `install.sh` installed the binary and whose `yass init` set up a fresh repo.
- Next: AC24, the piped one-liner against a real release candidate (`v0.3.0-rc.1`), which needs the branches merged and a tag; then piece 5, `status-knows-the-versions`.
