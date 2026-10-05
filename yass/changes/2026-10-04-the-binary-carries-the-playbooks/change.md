---
platforms: [all]
source: Jaime, 2026-10-04: installing the binary and setting up a repo are two steps that install.sh does as one, which confuses; noted while fixing the install docs (follows-up 2026-10-04-install-say-where-to-run-it-and-how-yass)
follows: 
blocked:
---
# The binary carries the playbooks

## Goal
<!-- Intent. One paragraph; the detail is in prd.md (why and what) and plan.md (how and acceptance). -->
Installing YASS is one step: get the `yass` binary. The binary carries the playbooks, the hook and the `AGENTS.md` section for its version, so `yass init` sets up a repo and `yass init --upgrade` (or similar) refreshes one, with no `install.sh` needed after the binary is on PATH. Upgrading becomes "new binary, then one command per repo", and a repo's files always match a binary someone can name. Noted, not shaped: the scope, the command names and what happens to `install.sh` are open, for `yass-shape` with Jaime.


## Decisions
<!-- Progress. "- <decision> - <why> (<who>)" for calls that span the whole change. -->
- Noted as a future large change rather than built now - it changes the CLI, `install.sh` and the release; the install docs were fixed first, explaining the two steps instead of splitting them (Jaime)

## Log
<!-- Progress. Change-level notes; each piece keeps its own Log.
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
