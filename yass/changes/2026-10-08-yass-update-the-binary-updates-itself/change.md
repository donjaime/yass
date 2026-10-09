---
platforms: [all]
source: Jaime, 2026-10-08: users shouldn't have to download binaries by hand before yass upgrade; teach agents to check and update both
follows: 2026-10-04-the-binary-carries-the-playbooks
blocked:
created: 2026-10-08T12:48:58Z
---
# yass update: the binary updates itself

## Goal
<!-- Intent. One paragraph; the detail is in prd.md (why and what) and plan.md (how and acceptance). -->
Getting a newer `yass` is one command, and agents can do the whole upgrade. `yass update` downloads and verifies a release (checksums always, signed provenance when the GitHub CLI is there) and replaces the binary in place. Inside a repo it matches the version the repo's YASS files were upgraded to, and says when a newer release exists, how to get it, and that `yass upgrade` and a commit follow. A `yass-update` playbook checks both versions, asks before downloading, and does both steps.


## Decisions
<!-- Progress. "- <decision> - <why> (<who>)" for calls that span the whole change. -->
- Follows `the-binary-carries-the-playbooks`, which left self-update out; this brings it in - getting the binary is where upgrades stall, and agents can't help with it today (Jaime, 2026-10-08)
- `yass update` for the binary, `yass upgrade` for the repo, each pointing at the other in its messages - the conventional pair; the cross-references make mixing them up self-correcting (Jaime, 2026-10-08)
- Verify against the release's `checksums.txt` always, and its signed provenance through `gh attestation verify` when the GitHub CLI is installed, saying which ran; `--require-provenance` makes the second mandatory - provenance inside the binary would pull a large dependency into a small CLI (Jaime, 2026-10-08)
- Inside a repo newer than the binary, install the repo's version, and say when a newer release exists, how to get it (`--latest`), and the `yass upgrade` and commit that follow; otherwise the latest - teammates match the repo instead of jumping ahead of it, and still learn what's out there (Jaime, 2026-10-08)
- `yass update --check` only reports: it exits 0 whenever the check succeeds, update available or not - a non-zero code reads as failure to agents and `set -e` scripts, and nothing needs scripts to act on it yet; an opt-in flag (`--exit-code`, or `--json`) can come later (Jaime, 2026-10-08)
- PRD approved (Jaime, 2026-10-08)
- Plan: three pieces (decide, install, point agents at it); release builds carry a `main.channel=release` marker; versions from the `releases/latest` redirect, not the API; swap by rename in the binary's folder (aside on Windows); `YASS_RELEASES_URL` as an undocumented test seam (claude, 2026-10-08)
- Medium scope: `--check`, the version and verification calls above, source builds left alone with the right command, Windows, a `yass-update` playbook and pointers from `yass status`; no mirrors, Homebrew or in-binary Sigstore (Jaime, 2026-10-08)

## Log
<!-- Progress. Change-level notes; each piece keeps its own Log.
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-10-09 (claude)
- Did: 0.4.0 released (the first tagged run failed in e2e on the tag itself; fixed in #56 and the tag moved, nothing had been published). AC17 on macOS against github.com: the published 0.4.0 binary's `yass update --check` in this repo reports itself up to date, exit 0; a release-marked 0.3.9 build ran `yass update`, installed the latest with checksum and provenance (the real `gh`) verified, and ended up byte-identical to the published binary. This repo upgraded to 0.4.0 with it.
- Next: AC17 on Linux, and AC12 on Windows (Jaime); then archive.
