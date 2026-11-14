# YASS and your tracker

YASS is files in the repo: a change folder holds what's changing, why, how, and how far it's got. It covers the inner loop of building software: shaping one change, planning it, building it.

Most teams also have an outer loop: an idea board or backlog where future work waits, and a tracker (Trello, Jira, Linear, Asana) where active work is visible to people outside the repo. YASS doesn't replace that tracker. It fits inside it: your agent keeps the tracker up to date at the few moments people outside the repo care about, and everything finer stays in the files.

- **The `yass` binary never calls a tracker.** Your agent does, through whatever its harness can reach: a connector (MCP), an API, a CLI. The binary only checks the settings and says where a change's card should be.
- **Files stay the source of truth.** Nothing on the board changes your plans on its own. When something changes there, tell your agent, and it proposes how to revise the plan.
- **Ask your agent to connect it.** "Connect our Trello board", or "connect Jira", runs the [`yass-init`](../kit/.agents/skills/yass-init/SKILL.md) playbook.

## Where the settings go

A yass folder names its tracker under `tracker:`, in a `settings.yaml` inside the folder (or in the `yass.yaml` that points to it). One tracker per yass folder; a repo with several yass folders (a monorepo, or public and private plans) can give each its own.

```yaml
# yass/settings.yaml
tracker:
  trello:
    board: https://trello.com/b/AbC123/payments
    lists: { ideas: 64f0…, will-do: 64f1…, planning: 64f2…, implementing: 64f3…, done: 64f4… }
```

A change's card or issue is its `source:` (`yass new "<title>" --source <link>`).

**Private plans keep their tracker private.** With plans kept outside the repo, the tracker's settings go in the plans folder's `settings.yaml`, committed with the plans. The public repo's `yass.yaml` says only where the plans are, and `yass status` notes it when a committed one carries more ([details](separate-plans.md#settings-stay-with-the-plans)). Agents never put a board or card link in the code repo in that setup.

## Trello: built in

YASS has opinions about a Trello board, so there's nothing to design:

| List | Holds |
|---|---|
| Ideas | the backlog |
| Will Do | ideas you plan to work on |
| Planning | changes being shaped or planned; their PRD and plan may be in review |
| Implementing | changes being built; pull requests may be up |
| Done | finished changes; archive the list on Trello whenever it gets long |

`yass-init` adopts a board you give it: a blank one gets the five lists, an existing one is matched by list names, and when the lists don't fit it shows you the mismatch and asks. The settings land in the yass folder's `settings.yaml`.

One card per top-level change. As the change moves, the agent moves the card and comments only at these moments:

| When | The card |
|---|---|
| shaping or planning starts on a card in Will Do | moves to Planning, with a comment that planning has begun |
| the plan's pull request is up, then merges | a comment linking it for review, then one saying the plan is accepted |
| building starts | moves to Implementing |
| a code pull request is up, then merges or closes | a comment each time, with the link |
| the change's archive merges | moves to Done |

A large change's pieces can have cards of their own, which move the same way (a piece's moves to Done when the piece is done and its pull request merged). When a new piece clearly covers an existing card, the agent links it; when it's unclear, it asks. A change with no card gets an offer to create one.

**Two agents, one board.** Before every move, the agent checks the card is where it should be: in Will Do before Planning, in Planning before Implementing. If it's somewhere else, someone else (another agent, or a person) has probably picked it up, so the agent stops and asks instead of duplicating the work. `yass status <change>` prints the column a change's card belongs in (`card: … (column: Implementing)`), and `yass-status` points out cards that are out of step. It's optimistic, not a lock: Trello can't move a card only if it's still where you last saw it.

## Jira, and everything else: your workflow

Jira and similar tools are set up differently in every organization: projects, issue types, hierarchies, statuses, required fields. So YASS bakes none of it in. Instead, `yass-init` interviews you once:

- which project or team this yass folder's work belongs to, and how work maps (an issue per change; pieces as sub-tasks or stories under an epic, or not at all);
- which status or transition matches each YASS moment (planning starts, a pull request up or merged, building starts, archived);
- what to comment, and what to leave to your process (fields, assignees, sprints).

The agent writes that down as a workflow, shows it to you, and remembers it in its harness's memory, outside YASS. Only when it's sure its harness has no memory does it keep the workflow in a gitignored `tracker.local.md` in the yass folder instead (`yass status` warns if git doesn't ignore it). The playbooks then follow it at the same moments as Trello's, with the same check before each change of status.

Only identifiers go in `settings.yaml`, named after the tool; YASS stores them as they are and never checks them:

```yaml
tracker:
  jira:
    site: https://acme.atlassian.net
    project: PAY
```

The workflow belongs to each person: every teammate's agent learns it once, from its own interview, and running `yass-init` again changes it.
