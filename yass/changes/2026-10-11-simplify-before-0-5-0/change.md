---
platforms: [all]
source: Jaime, 2026-10-11: a critical look at the growing complexity before 0.5.0; drop multi-repo plans
follows: 2026-10-04-monorepos-at-scale-and-plans-repos
blocked:
created: 2026-10-11T15:55:12Z
---
# Simplify before 0.5.0

## Goal
<!-- Intent. One paragraph; the detail is in prd.md (why and what) and plan.md (how and acceptance). -->
0.5.0 ships a simpler YASS than main holds today. Plans kept outside the code repo have one link to the code, `yass:` trailers, and one rule: a commit for a change kept outside its repo names it. Multi-repo plans (`repo@sha`, `repos:`, repo naming) and the trailer modes are gone, `code:` citations are back to 0.4.0's plain note, and the docs and playbooks say only what ships. Smaller by measure, then released.


## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)" for calls that span the whole change. -->
- Simplify before releasing 0.5.0, adding no features until it ships - the separate-plans half of monorepos-at-scale outgrew its purpose as a privacy fallback, and everything since 0.4.0 is still unreleased (Jaime, 2026-10-11)
- Drop shared plans for several code repos - it was the design being thorough, not a need (Jaime, 2026-10-11)
- Trailers are the one link for plans kept elsewhere (written from the code side, they survive squash merges); `code:` citations go back to 0.4.0's plain note (Jaime agreed to claude's proposal, 2026-10-11)
- Trailers follow one rule tied to where the change lives, not a repo-wide mode, and only CI requires them (`--require-trailers`), so a repo with both kinds of plans needs no special case (Jaime agreed to claude's proposal, 2026-10-11)
- `yass archive` stops refusing a change over its citations, but warns about missing or unmerged ones as it archives (Jaime, 2026-10-11)
- PRD approved (Jaime, 2026-10-11)
- Plan: no pieces, three pull requests, one per milestone; no design.md, since removing unreleased surface is easy to undo from git (claude, 2026-10-11)
- Measure before and after, so "simpler" can be checked (claude, 2026-10-11)
- A change of its own, following monorepos-at-scale, rather than a revision of it: the archive keeps what was built, this records what was removed and why (claude, 2026-10-11)

## Log
<!-- Progress. Change-level notes; each piece keeps its own Log.
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
