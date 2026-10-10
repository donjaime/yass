---
platforms: [all]
source: 
follows: 
blocked: 2026-10-04-check-from-the-plans-repo
---
# Agent guidance for separate plans

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
The skills give agents the whole routine for separate plans: state checks at session start, commit order with trailers, cross-links, per-repo git latitude, worktrees.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [/] Delivers AC55, AC56 in [plan.md](../plan.md)
- [/] The README's separate-plans section and `docs/skills.md` match the skills

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] AC55: `yass-work`'s "Plans in another folder" is the whole routine: pull the plans first; stop, never `yass init`, when they're missing (worktrees already look in the clone's other checkouts); `yass use` so the hooks add the trailer; code first, then plans, citing (`repo@sha` too); `[x]` after the merge; cross-link with `--brief` and the trailer line; latitude per repo
- [x] `yass-log` and `yass-status` find a change's code by trailers (`yass status <change>`, `%(trailers:key=yass)`)
- [x] README bullet and `docs/skills.md` match; e2e (700 ok) still finds the installed skills
- [ ] Jaime reviews the wording (AC55, README, docs/skills.md)
- [ ] AC56: one fresh agent session in a linked worktree of a code repo with separate plans, told "keep going" on a change (Jaime)

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-10-10 (claude)
- Did: AC55: the separate-plans routine in `yass-work`, trailers in `yass-log` and `yass-status`, README and `docs/skills.md`. `tests/e2e.sh` (700 ok), `tests/site.sh` pass.
- Next: Jaime reviews the wording, and runs AC56: a fresh agent session in a linked worktree of a code repo with separate plans, told "keep going"; it should pull the plans, build, commit code with the trailer, record progress in the plans repo, and never run `yass init`.
