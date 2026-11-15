# The Trello workflow

The other playbooks follow this whenever a change's yass folder has a Trello board. The card is the change's `source:`; `yass status <change>` prints it with the column the change's state puts it in (`card: <link>  (column: Planning)`). That's where the card should be, not where it is: only the board says where it is. The card hears only about these moments. Everything finer (boxes, the Log, decisions) stays in the change's files.

| When | Move the card | Comment |
|---|---|---|
| Shaping or planning starts on a card in Will Do | to Planning | planning has begun, naming the change folder |
| The plan's (or PRD's) pull request is up | | that the plan is ready for review, with the link |
| The plan's pull request merges | | that the plan is accepted |
| Building starts | to Implementing | |
| A code pull request is up | | that it's up for review, with the link |
| A code pull request merges or closes | | which, with the link |
| A top-level change's archive merges | to Done | |
| A piece is done and its pull request merged | to Done | |

- **Check before every move.** Read which list the card is in now. It should be in the column before the move: Will Do before Planning, Planning before Implementing, Implementing before Done. A card already where the move would put it stays as it is. Anywhere else, someone has probably claimed it: don't move it or comment, tell the human where it is, and ask (unattended: stop, and say so in the Log). Trello can't make the move conditional, so this catches most clashes, not all.
- **A card worked without a change** (unambiguous intent, YASS skipped): from Will Do straight to Implementing when building starts, with the same pull request comments, and to Done when its pull request merges.
- **A card shaped without a change** (`yass-shape`, landing as plain pull requests): to Planning when shaping starts, with a comment once it's decided that it will land as pull requests with no change folder; to Implementing when building starts; to Done when its last pull request merges.
- **Starting from a card:** create the change with the card's title and its link as `source:` (`yass new "<card title>" --source <card link>`).
- **One card per top-level change.** A piece can have its own card, which moves as its piece does. When a new piece or change clearly covers an existing card, make that card its `source:`; when two might fit, ask.
- **No card:** for a new top-level change, ask whether to create one, in the column its state implies, and create it only on a yes. Never create a card for a piece: it rolls up to its change's card. Otherwise never create cards, issues or lists.
- **A card changed on Trello:** when the human says so, read it (description, comments, checklists), compare it with the PRD and plan, and propose revisions through `yass-shape` or `yass-plan`. Nothing flows from the board on its own.
- **Privacy:** with plans kept outside the repo, never put a board or card link in the code repo (commits, pull request descriptions, `AGENTS.md`). The plans link the card.
- **Never archive or delete** cards or lists: Trello's archive is the human's.
