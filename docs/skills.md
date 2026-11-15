# The playbooks

YASS ships seven playbooks, as [Agent Skills](https://agentskills.io) in [`kit/.agents/skills/`](../kit/.agents/skills). Every `yass` binary carries them, and `yass init` writes them to `.agents/skills/` in your repo (project scope); `--claude` also copies them to `.claude/skills/`. With `--global`, they go in your user folder instead. `yass upgrade` brings them up to a newer binary's version. Agents pick one by matching your request against its `description`.

This page is an index for reviewing what each playbook lets an agent do. The `SKILL.md` files are the source of truth; if this page and a playbook disagree, the playbook wins and this page needs fixing.

| Playbook | Mode | Use it for | Writes files | Waits for a human |
|---|---|---|---|---|
| [`yass-init`](../kit/.agents/skills/yass-init/SKILL.md) | attended | "set up YASS here", "connect our Trello board", "connect Jira"; the Trello workflow the others follow | `yass init`'s files; a yass folder's `settings.yaml`; lists on a blank board | before options and before committing; when a board's lists don't fit |
| [`yass-update`](../kit/.agents/skills/yass-update/SKILL.md) | attended | "update YASS", or `yass status`'s version note | the `yass` binary; YASS's files in the repo | before downloading a binary, and before committing |
| [`yass-shape`](../kit/.agents/skills/yass-shape/SKILL.md) | conversation | a new feature, component or system; a harness plan to save; revising a PRD | `prd.md`, `change.md` | to pick a scope, and to approve the PRD |
| [`yass-plan`](../kit/.agents/skills/yass-plan/SKILL.md) | mostly automated | approach, acceptance criteria, pieces; a harness plan to save; revising a plan | `plan.md`, `design.md`, pieces | no; asks only about real choices the PRD leaves open |
| [`yass-work`](../kit/.agents/skills/yass-work/SKILL.md) | attended or unattended | building the one change it's pointed at | code, progress sections, stacked intent fixes | when it isn't pointed at a change, or isn't confident a plan fix is right |
| [`yass-status`](../kit/.agents/skills/yass-status/SKILL.md) | report | "where are we?" | nothing | no; it lists what needs one |
| [`yass-log`](../kit/.agents/skills/yass-log/SKILL.md) | report | "why did we…?", "why does this code…?", release notes, retros | nothing | no |

The usual flow is (plan mode →) shape → plan → work, with `yass-status` along the way and `yass-log` whenever someone asks why. Small changes skip straight to `yass-work`, and work whose intent is unambiguous skips YASS altogether: `yass-work` decides first, opening one good pull request for trivial or clear-cut work and asking before it starts a change for anything that deserves review. Each step ends where the next begins: shaping never plans, planning never builds.

**Starting work.** `yass-work` only builds a change it's been pointed at, by name or because the session is already on it. It never picks one because it's in progress. Boxes are `[ ]` not started, `[/]` in progress, `[x]` done, `[-]` dropped. `yass status` marks changes with no Log entry and no box in progress or done as `not started`, and changes whose boxes are all done or dropped as `done`; shaping and planning write neither, so a freshly planned change stays `not started` until someone starts it. In a fully autonomous run, where the harness or human has put the agent in charge, the agent makes that choice and any approvals itself, and records them in Decisions.

**Git.** No playbook commits on its own initiative, and none pushes, merges or opens pull requests. `yass-work` touches git only to stack an intent fix under the code, and `yass-update` and `yass-init` only to commit what they upgraded or set up, each when the human or the harness has given it that latitude; otherwise they hand the human the commands. The CLI never touches git. What a good commit looks like (intent apart from code) is in the README rules, the `AGENTS.md` section and the optional hook.

**Project management systems.** YASS covers the inner loop of a product and software development life cycle: shaping, planning and building one change. The outer loop (an idea backlog, and the board or project where the team and people outside the repo follow active work) usually lives in a project management system such as Jira, Linear, GitHub Issues and Projects, GitLab, Azure Boards, Asana, ClickUp or Trello. When a yass folder names one (`tracker:` in its `settings.yaml`), `yass-shape`, `yass-plan` and `yass-work` keep it in step at a few moments (planning started, a pull request up, merged or closed, building started, archived), checking before each update that the item is where they expect and stopping to ask if it isn't. For Trello they follow `yass-init`'s built-in workflow; for any other system, the workflow your agent learned from `yass-init`'s interview. `yass-status` only reads it. Finer progress stays in the files. The playbooks and settings call this a *tracker*.

**Pull requests for people.** Every pull request and commit a playbook writes leads with a plain-language title and the intent, then what changed and how it was checked. YASS's codes (the change's name, its progress line, criterion IDs, the `yass:` trailer) go last, in a collapsed "YASS tracking" block, where `yass-log` and squash merges still find them.

**Who you are.** Every playbook starts with `yass me`: who it's working for in this clone and, on a repo shared by teams, which yass folders are their team's. New changes go there, and `yass-status` reports that person's work unless asked for everyone's. Teams are optional: a solo developer sets nothing, and everything is theirs. Agents read and set it only through `yass me`, never by opening its file in the user's config folder.

**Plan mode.** `yass-shape`, `yass-plan` and `yass-work` can each start from a plan the harness's plan mode produced, carrying over its decisions instead of asking again, and telling the human what they added beyond it.

## yass-init

Sets a repo up through the agent and connects a yass folder to its project management system (a tracker, in the playbooks). Safe to run again: it checks first and offers only what's missing.

- **Reads:** `yass root -v`, `yass status`; the `AGENTS.md` section, the playbooks, the hook setting; `tracker:` in each yass folder's `settings.yaml` or `yass.yaml`; the board's open lists, through the harness's Trello tool.
- **Runs:** `yass me` (and, once per clone, `yass me --name … --team … --folders …` with what the human says); `yass init` with the options the human picks (`--claude`, `--global`, `--hooks`, `--path` for another folder name or plans outside the repo).
- **Writes:** what `yass init` writes; the board's five lists when the board is blank; `tracker.trello` (board link, list IDs) in the yass folder's `settings.yaml`, never `yass.yaml`, so private plans keep their board out of the code repo.
- **Human gates:** asks for options before `yass init`; asks before changing a board whose lists don't fit the five, and changes nothing until answered; commits only with latitude. Never asks for a Trello key or token: with no Trello tool in the harness, it stops.
- **Another project management system** (Jira, Linear, GitHub Projects, Azure Boards…): reads the team's workflow from the yass folder's `team.md`; when there's none, interviews the human (project, how work maps, which status matches each moment, what to comment and leave alone), writes it into `team.md` under `## Project management`, shows it back, and leaves it for the team to commit and review. Only identifiers go under `tracker:` in `settings.yaml`.
- **Also holds** the Trello workflow the other playbooks follow: which moments move a card or add a comment, the check before every move, pieces' cards, and keeping board links out of a public code repo.

## yass-update

Brings YASS up to date on two levels: the `yass` binary on this machine, and YASS's files in the repo.

- **Reads:** `yass update --check` (the binary's version and how it was built, the repo's YASS version, the latest release, what would be installed).
- **Runs:** `yass update` (with `--latest` only when the human wants the repo upgraded past the team's version), then `yass upgrade`; `git status` and a diff summary.
- **Writes:** the `yass` binary, through `yass update`, which verifies it first; YASS's files in the repo, through `yass upgrade`. Commits only with latitude: a layout migration in its own commit, then `chore: upgrade YASS`.
- **Human gates:** asks before downloading a binary, unless it has latitude to; never works around a failed checksum or provenance check, and never fetches a binary another way. A source build's update command (`go install`, a clone rebuild) runs only when the human says so.

## yass-shape

A conversation where a human decides what to build and why. Turns a problem, or an approved harness plan, into a large change with a PRD, and stops there. Also revises the PRD of an active change.

- **Reads:** a harness plan if there is one; the relevant code and docs; the archive (`yass status --archived`, `yass decisions --about …`) for earlier work; `yass status` for overlapping work.
- **Runs:** `yass new "<title>" --large [--source …] [--follows …]`.
- **Writes:** `prd.md` (why, users and outcomes, requirements `R1…`, non-goals, milestones, open questions); the Goal and `## Decisions` in `change.md`, crediting the human for choices made in their plan. A revision also records its reason in Decisions.
- **Human gates:** picks among 2–3 scoping options for non-trivial problems, unless the plan already picked; shows the PRD and waits for a go-ahead before planning, *unless your team has told it otherwise*, or a fully autonomous run has put it in charge of approvals (it records that in Decisions). From an approved plan, it points out only what it added. Tells a human about revisions.
- **Never:** mixes code into PRD edits; edits an archived change (new intent is a new change with `--follows`).

## yass-plan

Mostly automated: turns an approved PRD into the how (approach, acceptance criteria, design calls, PR-sized pieces) without a back-and-forth, and stops at a written plan. The change stays `not started` until someone points `yass-work` at it. Also revises a plan when reality disagrees.

- **Reads:** a harness plan if there is one (checked against the code and PRD, not redone); the change's `prd.md`, the code it touches, its docs. With no change folder yet, hands large work to `yass-shape` and creates small work itself.
- **Runs:** `yass new "<piece>" --in <change> [--goal …]`; `yass new … --design`, or `yass template design` for an existing change.
- **Writes:** `plan.md` (approach, `AC1 (R1) Given … — verify: …` per milestone, piece order, validation); `design.md` for hard-to-undo calls (at least two options, who decided); each piece's `change.md`, naming the criteria it delivers. Turns a harness plan's steps into real criteria rather than relabeling them.
- **Human gates:** asks only when the PRD leaves a real choice open. Tells a human about any revision, and calls out reworded, removed or dropped criteria as lowering the bar. Doesn't wait for approval of a new plan.
- **Never:** mixes code into plan edits. A revision during a build goes underneath the code (see `yass-work`).

## yass-work

Builds the one change it's pointed at and keeps its progress next to the code. Also runs unattended: one change (or piece) per run, stopping instead of asking.

- **Picks:** only the change named in the request, or the one the session is already on. Otherwise it shows `yass status` and asks (unattended: stops). When it's been put in charge of choosing, it picks, checks or gives the plan's approval, and records both in Decisions.
- **Reads:** the change's `change.md` from the last **Next:** in its Log; for a piece, the parent's `prd.md` and `plan.md`; the code and docs it touches.
- **Runs:** `yass status [<change>]`; `yass new "<title>" [--source …]` for a small, clear request (from a harness plan, if there is one); `yass archive <change>` when the change is `done`, in the pull request that ticks its last box.
- **Writes:** code; boxes marked `[/]` when started and `[x]` when verified (Steps, Acceptance, and plan criteria the work delivers); `## Decisions`; `## Steps`; a `## Log` entry before stopping. For a new small change, its Goal and Acceptance.
- **When the plan is wrong:** reasons out the fix. Not confident: sets `blocked:` and stops. Confident: puts the intent edit on its own branch from the work's base, with the reason in Decisions, rebases the work on top, and keeps going. Lowering the bar is stacked the same way but flagged as needing a human before merge.
- **Plans in another folder** (`yass root -v` says `separate`): pulls the plans first, and stops rather than running `yass init` when they're missing. Names the change in every code commit (`yass use <change>`, so the hooks add the `yass:` trailer), commits code first, then the plans, citing the code commits a box rests on (`— code: a1b2c3d`) and marking it `[x]` only once that code is merged. Cross-links the code PR (with `yass status <change> --brief` and the trailer) and the plans commit. Latitude for git is per repo. Intent changes go in the plans' own repo, linked from the code PR.
- **Git:** only for that stack, and only with latitude from the human or harness (plain `git`, or `gh stack` and similar). Attended without latitude: shows the commands. Unattended without latitude: leaves the edits, writes the commands into the Log's **Next:**, and stops.
- **Never:** changes intent alongside code; builds out-of-scope work (it notes it in the Log or the repo's issue tracker); marks a box `[x]` without evidence from its `verify:`.

## yass-status

A one-screen report, then a list of what needs a human. Read-only.

- **Reads:** `yass status`, then `yass status <change>` for every change that's been started (for its `[/]` items, and blocked or nearly done detail); `git log --since=<date>` over each folder `yass root` prints, and Log entries since then (it asks since when, or uses a week); recent decisions, the way `yass-log` finds them.
- **Reports:** progress per change (in progress apart from `not started`), blocked changes and why, recent decisions with who made them, changes ready to archive, stale changes, and intent revisions stacked under work in progress.
- **Then lists:** each item that needs a human, with the playbook or command that handles it, and one suggested next move. It acts on none of them.

## yass-log

Reconstructs decisions from the files and git, and links them to code through `code:` citations. Read-only.

- **Reads:** `## Decisions` in every yass folder `yass root` prints (in the repo, team folders, or wherever `yass.yaml` points) via `yass decisions`, never by reading `archive/` directly; `git log` for when and who, `git log -S` for the commit that added a line, `git log -p` for how a PRD or plan changed; the commits boxes cite, from the code repo (date, author, subject, merged or not); Goal, PRD and Log for context. Can start from code instead: a file's or symbol's commits, looked up with `yass decisions --cites <sha>`.
- **Reports:** newest first, grouped by change, with the cited code under each decision, citing file paths and commit shas (and which repo each sha is from). Flags decisions with no author, and moved goalposts: intent edits in the same commit as code when the plans are in the repo; acceptance criteria reworded or dropped after their code's box was marked `[x]` when they're in another folder.
- **Plans in another folder:** runs git for the plans with `git -C <folder> … -- .` (the folder may share a repo) and for the code here. With no git history, dates decisions only approximately, from the Log headings around them, and says so.
- **Never:** infers a decision that isn't written down; it says when the record is silent.
