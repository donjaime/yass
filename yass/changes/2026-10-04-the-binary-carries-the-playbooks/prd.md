# The binary carries the playbooks: PRD
<!-- Intent: what should change or exist, and why. Not a description of the current system;
     the code and its docs are that. Edit this file only in commits without code. -->

## Why
<!-- The problem, with evidence. -->
(Seed notes for shaping; not yet discussed.) `install.sh` does two jobs at once: it puts the binary on PATH (`--bin-dir`) and sets up a repo (the path argument). People can't tell which part does what, and the PATH half fails quietly when the folder isn't on PATH. Some flows need only one part: a second repo on the same machine, or joining a repo that already uses YASS, which today has no binary-only install and falls back to copying a binary out of a release by hand. Upgrading needs a matching release for each repo, rather than the binary you already have.

## Users and outcomes
<!-- Who it's for, and measurable targets ("p50 time to log < 5s"). -->

## Requirements
<!-- One line each: "- **R1** [M1] A user can …". IDs are never reused. -->

## Non-goals
<!-- What this change will not do. Agents treat these as walls. -->

## Milestones
| Milestone | When it ships, a user can … |
|---|---|

## Open questions
- Does `install.sh` remain (as "get the binary, then `yass init`"), shrink to a binary installer, or go away in favor of a package manager (Homebrew, `go install`)?
- Command shape: `yass init` sets up and `yass init --upgrade` refreshes, or a separate `yass upgrade`, or `yass setup`?
- How does a repo record which YASS version its files came from, so `yass status` can say the binary is older or newer than the repo's playbooks?
- `--global` and `--claude` playbook locations: same flags on `yass init`?
