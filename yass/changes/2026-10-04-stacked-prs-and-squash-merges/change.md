---
platforms: [all]
source: design discussion with Jaime, 2026-10-04
follows: 
blocked:
---
# Stacked PRs and squash merges

## Goal
<!-- Intent. One paragraph; the detail is in prd.md (why and what) and plan.md (how and acceptance). -->
YASS work lands well as a stack of pull requests, one per piece, landed one at a time and usually squash-merged. Plan-only PRs run no CI, and code PRs carry the progress they deliver. YASS checks each PR as the single commit it will become, a large change needs no closing PR per piece, and stacks only go as deep as real dependencies require.

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)" for calls that span the whole change. -->
- Its own change, not part of `2026-10-04-monorepos-at-scale-and-plans-repos` - it cuts across inline and separate plans, and is mostly rules, skill guidance and the hook (Jaime)
- The basic rule: YASS-only PRs (PRDs, plans, archives) skip CI; code and its YASS progress land together in PRs that run CI; the large-monorepo docs say so (Jaime)
- Under squash merges, the unit YASS rules apply to is the PR, not the commit - a squash keeps a PR's content and drops its commit boundaries (Jaime, claude)
- `merges: squash | commits` in `yass.yaml`, defaulting to `squash` - most orgs squash, and the per-PR rules are the stricter reading; repos that keep merge commits opt out to the per-commit rules (Jaime)
- This change takes over counting delivered parent criteria as done (R5, R6) from `2026-10-04-monorepos-at-scale-and-plans-repos` piece 5, which keeps only "pieces own their files" (the rule and the hook's heads-up); its AC12 is dropped there in favour of R5 here (Jaime)
- PRD approved (Jaime, 2026-10-04)

## Log
<!-- Progress. Change-level notes; each piece keeps its own Log.
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
