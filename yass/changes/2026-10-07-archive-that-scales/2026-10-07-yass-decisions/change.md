---
platforms: [all]
source: 
follows: 
blocked: 2026-10-07-archive-into-months
created: 2026-10-07T17:34:55Z
---
# yass decisions

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
yass decisions lists dated decisions across active and archived changes, filtered and bounded, as text or JSON, and yass-log and yass-shape use it instead of reading archive/.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [/] Delivers AC19–AC30 in [plan.md](../plan.md)

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] `decisions.go`: entries from every change's and piece's `## Decisions`, active and archived, every yass folder; who and date from the last parenthesis; filters, newest first, `--limit` with a count of what's left out; `--json`; read warnings to stderr
- [x] `--change` follows `follows:` both ways and takes in pieces; a piece alone brings what its change is linked to
- [x] Change templates, the `AGENTS.md` section and `yass-work` ask for `(<who>, <YYYY-MM-DD>)`; `README.md` shows it and lists the command
- [x] `yass-log` and `yass-shape` (and `docs/skills.md`) look decisions up with `yass decisions`
- [x] go test (`TestParseEntry`), e2e section 32 (two yass folders, a piece, an archived change, a follows chain, JSON, templates)
- [/] AC29: `yass-log`'s "starting from code" step still greps every yass folder, archive included, for a commit sha in `code:` citations; Jaime to decide (see Log)
- [/] AC30: `yass decisions --about hooks` finds the decision; a real `yass-log` run needs this repo's installed playbooks refreshed, which happens at release

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->
- Decisions are newest first by their own date, else their change's archived date, else its created date; ties keep file order - "why did we…" is usually about recent calls, and an undated entry is placed as well as the record allows (claude, 2026-10-07)
- `yass decisions` prints only warnings about files it couldn't read, to stderr - its stdout may be JSON, and the repo's other warnings belong to `yass status` (claude, 2026-10-07)
- Text lines have the entry's own date first (blank when it has none), then the change, the decision, who, and the change's dates in brackets - one line per entry, as AC19 asks, with the date where scanning eyes look first (claude, 2026-10-07)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-10-07 (claude)
- Did: built and tested `yass decisions`, dated entries in the templates and playbooks, and switched `yass-log` and `yass-shape` to it. `go test`, `tests/e2e.sh` (450 ok), `tests/examples.sh` pass.
- Open (AC29): `yass-log` still finds a commit's decision by grepping every yass folder for `code:.*<sha>`, archive included. It's a needle search, so its output stays small, but it does walk `archive/`. Options: accept it and narrow AC29 to decision lookups (a plan revision), or add a citation search to the CLI (e.g. `yass decisions --cites <sha>`, searching boxes too). Jaime to choose.
- Next: Jaime's call on AC29; AC30 once the installed playbooks are refreshed (release, or `yass upgrade` with a local build).
