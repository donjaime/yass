---
platforms: [all]
source: 
follows: 
blocked:
created: 2026-11-15T17:05:37Z
archived: 2026-11-15T17:14:49Z
---
# Archive in the pull request that finishes a change

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
Finishing a change takes one pull request fewer. The pull request that ticks a change's last box can also carry its archive move, even when it has code, so a change is built, finished and archived in one review, and its card moves to Done when that merges. What stays apart from code is what needs its own review: intent (a PRD, a plan, a Goal, acceptance criteria), edits to anything already archived, evicting old months, and migrating the archive's layout. A separate archive pull request still works for anyone who wants one.


## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [x] AC1 Given a commit that changes code and also moves a finished change from `changes/` into `archive/`, when the hook checks it (staged, or with `--range`), then it isn't flagged — verify: `tests/e2e.sh` (the "archiving + code" case flips from warns to passes)
- [x] AC2 Given the same commit, when a moved file's intent differs from what was there before beyond what `yass archive` writes itself (the `archived:` stamp, ticked boxes), then the hook flags it as intent changed alongside code, as it would outside the archive — verify: `tests/e2e.sh`
- [x] AC3 Given a commit with code, when it also edits, deletes or adds to a change already in the archive, evicts archived months, or migrates the archive into months, then the hook still flags it as it does today — verify: `tests/e2e.sh` (existing cases pass unchanged)
- [x] AC4 Given a change with pieces, when the commit that finishes the last piece also archives the whole change, then the hook doesn't flag it for reaching past the piece's folder — verify: `tests/e2e.sh`
- [x] AC5 Given `yass archive <change>` succeeds, then what it prints says the move can go in the pull request that finishes the change, as its own commit, and no longer says it has to be apart from code; the message after an eviction still asks for a commit of its own — verify: `tests/e2e.sh`
- [x] AC6 Given `yass-work`'s Finish step, the `AGENTS.md` section `yass init` writes, the squash-merge notes in `docs/monorepo.md` and the README, then they say the same thing: archive in the pull request that ticks the last box, as its last commit; a separate pull request is still fine, and is the way when the change was finished earlier or the archive evicts months; if review reopens the work, take the archive commit off the branch, make the edits, and archive again, never editing under `archive/`. The CHANGELOG has an Unreleased entry — verify: manual: review; `go test ./...` and `tests/e2e.sh` pass
- [x] AC7 Given plans kept outside the repo, then nothing changes for them: boxes wait for the merge and the archive goes in the plans commit that ticks them — verify: manual: review "Plans in another folder" in `yass-work` and `docs/separate-plans.md`
- [x] AC8 Given this repo's own installed playbooks and `AGENTS.md`, then they're left as they are, to pick the new text up at the next release's `yass upgrade` — verify: `git diff --stat` shows no change under `.agents/`, `.claude/` or the root `AGENTS.md`

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] Hook: the archive move rides with code; the moved files' intent is still checked
- [x] `yass archive` message
- [x] End-to-end cases
- [x] `yass-work`, the `AGENTS.md` section, docs, README, CHANGELOG

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- A small change, with criteria approved before building - it changes a rule every YASS user follows, and what the hook enforces (Jaime, 2026-11-15)
- The hook stops flagging the archive move alongside code outright, rather than only allowing it as a separate commit in the same pull request - under squash merges the two are the same commit on main, and `--range` checks those (claude, 2026-11-15; for review)
- Allowed and the default, not required - a team that wants archives reviewed apart can keep doing that with no setting (claude, 2026-11-15; for review)
- Goal and acceptance criteria approved; no Trello card for this one (Jaime, 2026-11-15)
- AC4 needed no hook change: a move into the archive is seen at its new path, so the piece check never looked at it; an end-to-end case now pins that (claude, 2026-11-15)
- This change archives itself in its own code pull request, as that pull request's last commit - the first use of the rule (claude, 2026-11-15)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->

### 2026-11-15 (claude)
- Did: the hook (`internal/yass/hook.go`): a finished change moved into the archive alongside code is no longer flagged; the moved files go through the same intent check as any yass file next to code (`intentEdit`), so an edited title, Goal, criterion, PRD, design or plan on the way in still warns. Editing the archive, evictions and the months migration are as before. `yass archive` now prints "Commit it as the last commit of the pull request that finishes the change, or on its own"; the eviction message is unchanged.
- Did: `yass-work` step 8 and its git paragraph, the `AGENTS.md` template, `docs/monorepo.md` squash notes, README rule 5 and the hook section, `docs/skills.md`, CHANGELOG. Plans kept elsewhere read as before (AC7): nothing there named the rule.
- Did: checks. `go test ./...` ok; `tests/e2e.sh` 681 passed, 0 failed, with five new cases (archive + code silent; + an edited title warns; + an edited PRD warns; `yass archive`'s message; the last piece's commit archiving the whole change) and the existing archive, eviction and migration cases unchanged; `tests/site.sh` 112 passed. Nothing under `.agents/`, `.claude/` or the root `AGENTS.md` changed (AC8).
- Next: nothing to build. The archive move is this pull request's last commit; if review reopens the work, take that commit off first. This repo's own playbooks pick the text up at the next release's `yass upgrade`.
