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
- [ ] Delivers AC20–AC27 in [plan.md](../plan.md)

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `install.sh`: binary install and PATH report only; refuse old-style repo arguments, printing the commands to use (`yass upgrade` for `--upgrade`)
- [ ] `.goreleaser.yaml`: archives without `kit/`
- [ ] e2e: rework the `install.sh` sections; unpacked release without `kit/`
- [ ] README, `docs/install.md`, landing page: the new model and joining
- [ ] Release candidate: the one-liner in a fresh repo (AC24)

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
