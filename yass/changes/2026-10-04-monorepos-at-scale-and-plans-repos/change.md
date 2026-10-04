---
platforms: [all]
source: 
follows: 
blocked:
---
# Large monorepos first, separate plans repo done right

## Goal
<!-- Intent. One paragraph; the detail is in prd.md (why and what) and plan.md (how and acceptance). -->
YASS works at a large company with one big monorepo, many teams and expensive CI. Plan-only commits cost no CI, each team owns its own plans, and the tools stay fast at that scale, so keeping plans next to the code is the clear recommendation. For projects that need private plans, a separate plans repo is a supported fallback. It works correctly in worktrees, with several code repos sharing it, and through archiving. Its link between code and plans is a `Yass-Change:` trailer that tooling enforces, and only in that setup.

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)" for calls that span the whole change. -->
- Monorepo with plans inline is the recommended path, including for large orgs; a separate plans repo is the fallback for privacy - CI cost and size are solvable inside the monorepo (path filters, affected-target builds, LFS), and inline keeps progress in the same commit as code (Jaime)
- No orphan branches, submodules or subtrees - they bring separate-repo semantics or submodule pain without solving privacy (Jaime)
- Trailers on code commits are enforced strictly, but only when plans are in a separate repo - they replace the same-commit guarantee that repo loses, and the monorepo setup stays as simple as it is (Jaime)
- Link code to plans with a trailer in the code commit, not only SHA citations in the plans - trailers can't be rewritten and survive squash merges, a lesson from Gerrit/Zuul `Depends-On:` (Jaime, claude)
- Assets (mocks, images) live in the change folder, with no tooling change - checked on 2026-10-04: archiving moves them as renames, status ignores them, and the archive's append-only rule covers them (claude)
- PRD approved, open questions to be settled during planning (Jaime, 2026-10-04)

## Log
<!-- Progress. Change-level notes; each piece keeps its own Log.
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
