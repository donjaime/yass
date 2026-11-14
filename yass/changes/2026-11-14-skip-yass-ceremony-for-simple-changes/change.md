---
platforms: [all]
source: https://trello.com/c/uH69ZiZB/1-skip-yass-ceremony-for-simple-changes-and-or-changes-whose-intentions-dont-require-discussion-and-review
follows: 
blocked:
created: 2026-11-14T18:51:32Z
---
# Skip YASS ceremony for simple changes and/or changes whose intentions don't require discussion and review

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
Not every pull request needs a YASS change. Before starting work, an agent makes a short assessment: when the intent is unambiguous and fits in a pull request's description (a trivial fix, a mechanical cleanup, a one-off that didn't come from the project management system), it skips the ceremony and opens one good pull request; when the intent deserves discussion, review or approval, it asks the human whether to start a change. Trivial work goes ahead without asking. Unattended, an agent that finds work truly warrants a change it doesn't have stops and asks, unless it was told when dispatched not to stop for that. A card worked without a change moves Will Do to Implementing to Done with its pull request. `yass-log` looks in pull request descriptions and commit messages for decisions made outside any change. The docs and rules say so.

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [x] Given the `AGENTS.md` section, when an agent reads it, then it says to assess each request first: unambiguous intent that fits a pull request description gets no change, intent that deserves discussion, review or approval gets the human asked whether to start one, and trivial work goes ahead without asking — verify: e2e (the section written by `yass init` says so) and manual reading
- [x] Given `yass-work` asked to do something with no change yet, when it orients, then it makes that assessment: a trivial or unambiguous request goes straight to a pull request with a good description (with plans kept elsewhere, its commits say `yass: none`), and anything that warrants ceremony goes to the human; unattended, it stops and asks unless its dispatch said not to — verify: manual reading of the playbook
- [x] Given a card in Will Do worked without a change, when it's picked up, then the Trello workflow moves it to Implementing (after the usual check), comments on its pull request, and moves it to Done when that merges; another project management system does the same through its remembered workflow — verify: manual reading of `yass-init`'s Trello workflow
- [x] Given a question about a decision made in a pull request with no change, when `yass-log` looks for it, then it searches commit messages and pull request descriptions (with the GitHub CLI when it's there) and says that's where it came from — verify: manual reading of the playbook
- [x] Given the README, `docs/skills.md` and the landing page, when read, then they say a change is for work whose intent deserves review, and that a simple or unambiguous change is just a good pull request — verify: `tests/site.sh` and manual reading

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [x] 

## Decisions
<!-- Progress. "- <decision> - <why> (<who>, <YYYY-MM-DD>)", appended as you go. -->
- Guidance only: no CLI change, and no record kept of pull requests made without a change; `yass-log` searches git and pull request history for those instead - the card asks for less ceremony, and searching what git already holds closes the decision-history gap without new machinery (Jaime, 2026-11-14)
- Trivial work goes ahead without asking; borderline work asks. Unattended, an agent that finds work truly needs a change it doesn't have stops and asks, unless its dispatch said not to stop for that (Jaime, 2026-11-14)
- A card worked without a change goes Will Do, then Implementing, then Done when its pull request merges, skipping Planning (Jaime, 2026-11-14)
- The assessment lives in the `AGENTS.md` section and `yass-work` (where work without a change arrives); `yass-shape` is left as it is, since being asked to shape something is already a request for ceremony (claude, 2026-11-14)
- A small change, not a large one: it's guidance and docs, with the calls already made here (Jaime, 2026-11-14)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
### 2026-11-14 (claude)
- Did: started from Trello card uH69ZiZB, which moved Will Do to Planning (with a comment) and then to Implementing, each after checking where it was. The assessment is now in the `AGENTS.md` section template and `yass-work` (unattended: stop and ask unless told not to; `yass: none` with plans elsewhere); `yass-init`'s Trello workflow covers a card worked without a change; `yass-log` searches commit messages and pull request descriptions for decisions outside any change; the README intro and rules, docs/skills.md and the landing page say a change is for work worth reviewing. e2e checks the section (757 pass); unit, site and examples pass.
- Next: open the stack (intent, then code); comment on the card when each pull request is up and when it merges; when this is archived, move the card to Done.
