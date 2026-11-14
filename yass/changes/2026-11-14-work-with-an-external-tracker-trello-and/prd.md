# Work with an external tracker: Trello and others: PRD
<!-- Intent: what should change or exist, and why. Not a description of the current system;
     the code and its docs are that. Edit this file only in commits without code. -->

## Why
YASS covers the inner part of a product and software development life cycle: shaping, planning and building one change, with progress next to the code. Most teams also have an outer loop it doesn't touch: an idea board or backlog where future work waits, and a project management system (Trello, Jira, Linear) where active work is tracked and that people outside the repo read. Agents can usually reach those systems through MCP, an API or a CLI.

Today YASS says issue tracking is something it [leaves to you](../../../README.md#what-yass-leaves-to-you): a change can carry a `source:` link and that's all. So the agent doesn't know which board governs a yass folder, which card a change belongs to, or when to update it. Each team writes that glue themselves, or the tracker drifts from the real state of the work. Two agents unaware of each other can also pick up the same card, and nothing notices.

YASS itself stays files in the repo, and files stay the source of truth for plans and progress. That doesn't change ([monorepos-at-scale](../../archive/2026/10/2026-10-04-monorepos-at-scale-and-plans-repos/prd.md) kept progress out of trackers). What's new is that YASS fits inside a workflow that has a tracker, without replacing it: the tracker hears about the few moments people outside the repo care about, and nothing else.

## Users and outcomes
- **Teams that track work on a Trello board**, and their agents.
  - Setting up a board, new or existing, takes one conversation with the agent, and records the board in `yass.yaml`.
  - Each card moves through Planning, Implementing and Done as its change does, with no one moving it by hand, and gets a comment only at the moments listed in R7–R10.
  - When a second agent finds a card already claimed, it stops and says so instead of duplicating the work.
- **Teams on Jira or another tracker with their own workflow.** After one interview, the agent updates their tracker the way their organization does, from what it remembers, without YASS knowing that workflow.
- **The `yass` binary stays offline.** It never calls a tracker; it validates what's in the files.

## Requirements
Setting up
- **R1** [M1] A repo is set up through the agent: a new `yass-init` playbook runs `yass init` as needed and, optionally, connects an external tracker. The install docs and README lead with asking the agent; `yass init` stays for doing it by hand.
- **R2** [M1] `yass init` and `yass-init` are idempotent: running either again keeps what's there, adds what's missing, and offers only the setup that hasn't been done (for example, connecting a tracker to an already set up repo).
- **R3** [M1] Each yass folder can name one governing Trello board in its `yass.yaml`, with the board's five lists: Ideas (the backlog), Will Do (ideas planned for), Planning, Implementing and Done.
- **R4** [M1] Given a board, `yass-init` adopts it. A blank board gets the five lists. A board with lists is matched to them by name. When the lists don't fit, the agent asks the human what to do and doesn't guess.

Validating (the binary)
- **R5** [M1] `yass status` validates the tracker settings in `yass.yaml` (a Trello board link and all five lists) and warns, without failing, about what's missing or malformed. A tracker section the binary doesn't own (R14) is never a warning.
- **R6** [M1] `yass status <change>` shows a change's card (its `source:`) and the column its state implies: Planning before any box is started, Implementing once one is, and Done once a piece is done or a top-level change is archived (a done top-level change shows that its card moves when the archive merges). The binary never calls Trello to check it.

The Trello workflow (the playbooks)
- **R7** [M1] A change starts from a card: asked to plan or shape one, the agent creates the change with the card as its `source:` and the card's title. `yass-status` (the playbook) lists the Will Do cards as work waiting to start.
- **R8** [M1] Starting to shape or plan a change whose card is in Will Do moves it to Planning with a comment that planning has begun. When the plan's pull request is up, the card gets a comment linking it for review; when it merges, a comment that the plan is accepted.
- **R9** [M1] Starting to build a change moves its card to Implementing. After that the card gets a comment only when a pull request is up for review and when one merges or closes; finer progress stays in the change's files.
- **R10** [M1] When a change's archive merges, its card moves to Done. Archiving cards on Trello is left to the human.
- **R11** [M1] Every move is a best-effort claim check: just before moving a card, the agent reads its column and compares it to the column it expected (R6). If the card has already moved, it assumes someone else claimed or advanced it, doesn't move it, and tells the human. This is optimistic, not a lock, and the playbooks say so.
- **R12** [M1] A piece can have its own card. When creating a piece that clearly covers an existing card, the agent links it as the piece's `source:`; when it's ambiguous, it asks. A piece's card moves through the columns as its piece is planned, built and finished, the same as a top-level change's. Pieces are archived with their parent, so a piece's card moves to Done when the piece's own pull request merges and its boxes are all done.
- **R13** [M1] When the human says a card changed on Trello, the agent reads it, compares it with the change's PRD and plan, and proposes revisions through `yass-shape` or `yass-plan`. Nothing flows from the board on its own.
- **R17** [M1] When a yass folder has a tracker and someone starts a change (or piece) with no card, the agent offers to create one, filled in by the tracker's workflow: the Trello workflow above, or the one learned for another tracker (R15). Declined, the board is left alone.
- **R18** [M1] A yass folder can keep its settings (the tracker's included) in an optional `settings.yaml` inside it, merged with its `yass.yaml`, the same way whether the folder is in the repo or outside it. With plans kept outside the repo, that puts private settings in the private plans folder, while the public `yass.yaml` keeps only the pointer. When a committed `yass.yaml` pointing outside the repo carries anything besides `path:` and `ignore:`, YASS notes it as possibly accidental. The playbooks write nothing about the tracker (board links, card links, workflow) into the code repo themselves.

Other trackers
- **R14** [M2] `yass.yaml` can hold open-ended key/value settings for any other tracker (a Jira project, a board or team link, whatever the workflow needs). YASS stores them and doesn't interpret them.
- **R15** [M2] For a tracker other than Trello, `yass-init` interviews the human about their organization's workflow (project, team, issue types, which transitions and comments, when) and saves the answers to the agent harness's memory, outside YASS: not in `yass.yaml`, not in the playbooks. The other playbooks follow that memory at the same moments as R8–R10. *(Superseded by `2026-11-14-verify-yass-for-multi-team-repos-is` R11: the workflow always goes in the yass folder's team memory.)*
- **R19** [M2] Only when the agent can tell for sure that its harness has no persistent memory, it saves the workflow instead to a gitignored local file in the yass folder; when it can't tell, it asks the human. Every playbook that touches the tracker reads that file when it exists. *(Superseded by `2026-11-14-verify-yass-for-multi-team-repos-is` R11: the workflow always goes in the yass folder's team memory.)*

Docs
- **R16** [M1] The README, docs and landing page say that YASS is files in the repo and fits inside a workflow with an external tracker without replacing it. A new doc covers the Trello workflow and how other trackers are set up.

## Non-goals
- The `yass` binary calling Trello, Jira or any tracker, or storing credentials or tokens anywhere.
- Two-way sync. Nothing changes the files because a card changed, except when the human asks the agent to (R13).
- Progress, boxes or Log entries on cards.
- Archiving or deleting cards on Trello.
- Any Jira (or other tracker) workflow built into YASS: no issue types, transitions or fields in the playbooks or `yass.yaml`.
- A hard lock on cards. The claim check is best effort.
- Opinions on more than one board per yass folder, or on Trello labels, members, checklists or due dates.

## Milestones
| Milestone | When it ships, a user can … |
|---|---|
| M1 | set a repo up through the agent, adopt a Trello board, and have cards follow their changes from Will Do to Done, with claims checked, and read docs that describe YASS inside a tracker's workflow |
| M2 | connect Jira or any other tracker through an interview, with its settings in `yass.yaml` and its workflow in the agent's memory |

## Open questions
None. The four raised while shaping were settled on 2026-11-14 (see `change.md` Decisions).
