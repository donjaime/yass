# Work with an external tracker: Trello and others: plan
<!-- Intent: how, and how we'll know it's done. With code, only mark boxes here ([/] in progress, [x] done);
     anything else is a plan revision in its own commit. -->

## Approach
There are two halves, and only the small one is code.

**The binary validates and shows; it never calls a tracker.**
- **Settings.** `yass.yaml` gets a `tracker:` section ([design.md §1](design.md#1-spelling-the-tracker-settings)). `tracker.trello` is checked: a `trello.com/b/…` board link and an ID for each of the five lists. Any other key under `tracker:` is stored and never warned about. The check sits beside today's unknown-setting warnings in `loadConfig` ([config.go](../../../internal/yass/config.go)) and `findRoots` ([repo.go](../../../internal/yass/repo.go)).
- **`settings.yaml`.** A yass folder can have an optional `settings.yaml` at its top holding `branch:`, `archive:` and `tracker:`, merged setting by setting with its `yass.yaml`, the folder's winning. Inline or outside the repo, it works the same way; for private plans it's where the private settings go ([design.md §2](design.md#2-settings-for-private-plans)). A committed `yass.yaml` pointing outside the repo with settings beyond `path:` and `ignore:` gets a note suggesting `settings.yaml`.
- **The card view.** `showChange` ([commands.go](../../../internal/yass/commands.go)) prints a `card:` line when the yass folder has a Trello board. It shows the change's `source:` and the column `state()` implies, so an agent compares it with the real card before every move.
- **The fallback file.** It also warns when a `tracker.local.md` in a yass folder isn't gitignored (R19).

**The agent does everything else, in the playbooks.**
- **`yass-init` (new).**
  - Sets a repo up: it runs `yass init`, checking first what's already there, so running it again only offers what's missing.
  - Adopts a board: it bootstraps a blank one, matches an existing one by list names, and asks when the lists don't fit.
  - Holds the whole Trello workflow under one heading: the columns, the moments to move or comment, and the claim check.
  - For any other tracker, runs the interview and saves the result to the harness's memory, or, only when sure there's none, to a gitignored `tracker.local.md`.
  - The binary carries only each skill's `SKILL.md` ([kit.go](../../../internal/yass/kit.go)), so the workflow lives in that file's text.
- **The lifecycle playbooks** each get one short "If the yass folder has a tracker" step, with their own moments and the claim check, pointing at `yass-init` for the full workflow:
  - `yass-shape` and `yass-plan`: starting from a card, moving it to Planning, plan PR up, plan merged.
  - `yass-work`: moving it to Implementing, PR up, PR merged or closed, archive merged moving it to Done, and pieces' cards.
  - `yass-status`: listing the Will Do cards.

  How a playbook reaches the tracker (MCP, API, CLI) is the harness's business; the playbooks name the action, not the tool.
- **The claim check is optimistic.** Just before a move, the agent reads the card's column and compares it with what it expected (`yass status <change>` says what to expect). If they differ, it doesn't move the card and tells the human. It's best effort, and the playbook says that plainly.
- **Privacy with separate plans.** The playbooks never put board or card links in the code repo: not in commits, PR bodies or `AGENTS.md`.

**Docs.**
- The README's "What YASS leaves to you" becomes how YASS fits inside a team's tracker workflow without replacing it.
- A new `docs/trackers.md` covers the Trello workflow and setting up another tracker.
- `docs/install.md`, the README and the landing page lead with asking the agent to set up the repo; `yass init` stays for doing it by hand.

## Acceptance
### M1
- [ ] AC1 (R1) Given a repo with no YASS and an agent with the playbooks installed globally, when the human asks it to set up YASS, then `yass-init` runs `yass init` (with `--claude` on Claude Code) and lists what was written — verify: manual: fresh repo, Claude Code, "set up YASS here"; the files exist and the agent's summary lists them
- [ ] AC2 (R1) Given `docs/install.md`, the README and the landing page, when a reader looks for how to set up a repo, then the first way shown is the agent prompt, and `yass init` follows as the manual way — verify: `tests/site.sh` (the page's prompt block matches `docs/install.md` word for word) and manual reading of both docs
- [ ] AC3 (R2) Given a repo `yass init` already set up, when `yass init` runs again with the same options, then no file changes and it says nothing needed doing — verify: e2e: `init` twice, `git status --porcelain` empty after the second
- [ ] AC4 (R2) Given a repo already set up with no tracker, when the human runs `yass-init` again, then the agent says what's already set up, changes no files, and offers only connecting a tracker — verify: manual
- [ ] AC5 (R3, R4) Given a blank Trello board, when the human asks `yass-init` to adopt it, then the board gets lists Ideas, Will Do, Planning, Implementing, Done in that order, `yass.yaml` gets `tracker.trello` with the board link and each list's ID, and `yass status` warns about nothing — verify: manual with a scratch board
- [ ] AC6 (R4) Given a board whose lists match the five names (in any order or case), when it's adopted, then no list is created and their IDs are recorded — verify: manual
- [ ] AC7 (R4) Given a board with lists that don't fit the five (missing, extra or ambiguous), when it's adopted, then the agent shows the mismatch and asks what to do, and changes neither the board nor `yass.yaml` until the human answers — verify: manual
- [ ] AC8 (R1) Given `yass init`, `yass upgrade` and `yass deinit`, when each runs, then `yass-init` is installed, refreshed and removed beside the other playbooks, and the `AGENTS.md` section names it — verify: e2e and `kit_test`
- [ ] AC9 (R5) Given a `tracker.trello` with a list missing, a board link that isn't `trello.com/b/…`, or an unknown key under `trello`, when `yass status` runs, then it warns once for each problem, naming the setting, and exits 0 — verify: unit `config_test` and e2e
- [ ] AC10 (R5) Given `tracker:` with keys other than `trello` (any shape), when `yass status` runs, then nothing about them is a warning — verify: unit `config_test`
- [ ] AC11 (R6) Given a yass folder with a Trello board and a change whose `source:` is a card, when `yass status <change>` runs, then it prints `card: <link>` with the expected column: Planning with no box started, Implementing once one is `[/]` or `[x]`, Done for a done piece, and "Done when its archive merges" for a done top-level change — verify: e2e
- [ ] AC12 (R6) Given no tracker configured, or a change with no `source:`, when `yass status <change>` runs, then there's no `card:` line and the output is otherwise unchanged — verify: e2e
- [ ] AC13 (R7) Given a card in Will Do, when the human asks the agent to shape or plan it, then the change is created with the card's title and the card's link as `source:`; and when the human asks where things stand, `yass-status` lists the Will Do cards as waiting to start — verify: manual
- [ ] AC14 (R8) Given a Will Do card, when shaping starts, then it moves to Planning with a comment that planning began; when the plan's pull request is up, it gets a comment linking it; when that merges, a comment that the plan is accepted — verify: manual
- [ ] AC15 (R9) Given a change in Planning, when `yass-work` starts building it, then its card moves to Implementing; afterwards, ticking boxes and Log entries add nothing to the card, and only a pull request up, merged or closed adds a comment — verify: manual
- [ ] AC16 (R10) Given a done change, when its archive's pull request merges, then its card moves to Done and nothing is archived on Trello — verify: manual
- [ ] AC17 (R11) Given a card a second agent (or a person) has already moved out of the column expected, when the agent is about to move it, then it doesn't move or comment, and tells the human where the card is and that someone else may have claimed it — verify: manual: move the card by hand before asking the agent to start
- [ ] AC18 (R12) Given a new piece that clearly covers one existing card, when the piece is created, then the card is its `source:` and it moves through the columns with the piece, reaching Done when the piece is; given two cards that might fit, the agent asks — verify: manual
- [ ] AC19 (R13) Given the human says a card changed on Trello, when the agent reads it, then it proposes PRD or plan revisions through `yass-shape` or `yass-plan` and changes no file until a human agrees — verify: manual
- [ ] AC20 (R17) Given a configured board, when a top-level change is created with no card, then the agent asks whether to create one and creates it only on a yes; when a change that has a card is split into pieces, it creates no cards for them (they roll up to the change's card), linking a piece only to a card that already covers it — verify: manual
- [ ] AC21 (R18) Given a yass folder with a `settings.yaml` holding `branch:`, `archive:` and `tracker:`, when `yass status` runs, then those settings apply, for a folder inside the repo (under any name) and for one outside it, from the code repo, a linked worktree, and inside the plans folder; a setting it shares with `yass.yaml` takes the folder's value, and when the two differ `yass status` warns — verify: e2e
- [ ] AC22 (R18) Given a `yass.yaml` pointing outside the repo that git would commit (tracked, or not ignored) with `branch:`, `archive:` or `tracker:`, when `yass status` runs, then it notes them as possibly leaking private setup and suggests the folder's `settings.yaml`, without a warning (`--strict` passes); a gitignored one, one with only `path:` and `ignore:`, or one pointing inside the repo gets no note; and `path:` or `ignore:` in a `settings.yaml` warns that they belong in `yass.yaml` — verify: e2e
- [ ] AC23 (R18) Given plans kept separate with a Trello board, when an agent shapes, plans and builds a change through to a merged code PR, then no board or card link appears in the code repo's files, commits or PR bodies — verify: manual: grep the code repo's diff, `git log` and the PR body for `trello.com`
- [ ] AC30 (R18) Given any yass folder, when `yass-init` connects a tracker, then it writes the tracker's settings to the folder's `settings.yaml`, never to `yass.yaml`, so with plans outside the repo they land in the plans folder — verify: manual
- [ ] AC24 (R16) Given the README, `docs/trackers.md`, `docs/comparison.md` and the landing page, when read, then they say YASS is files in the repo and fits inside a tracker's workflow without replacing it, and `docs/trackers.md` covers the Trello workflow and setting up other trackers — verify: manual reading; `tests/site.sh` for links and anchors
### M2
- [-] AC25 (R14, R15) Given a Jira (or other) tracker, when the human runs `yass-init` to connect it, then the agent interviews them about project, team, issue types, transitions and comments, saves the workflow to the harness's memory, and writes only links and IDs under `tracker:` in `yass.yaml`; no playbook changes — verify: manual on Claude Code (superseded by `2026-11-14-verify-yass-for-multi-team-repos-is`, which keeps the workflow in a team memory committed in the yass folder)
- [-] AC26 (R15) Given that memory, when a later session starts shaping a change, then the agent updates the tracker as the memory says at the R8–R10 moments — verify: manual: new session (superseded by `2026-11-14-verify-yass-for-multi-team-repos-is`, which keeps the workflow in a team memory committed in the yass folder)
- [-] AC27 (R19) Given an agent sure its harness has no persistent memory, when the interview ends, then the workflow goes to `tracker.local.md` in the yass folder and that file is gitignored; given an agent that can't tell, it asks the human first — verify: manual (superseded by `2026-11-14-verify-yass-for-multi-team-repos-is`, which keeps the workflow in a team memory committed in the yass folder)
- [ ] AC28 (R19) Given a `tracker.local.md` in a yass folder that git doesn't ignore, when `yass status` runs, then it warns that the file should be gitignored — verify: e2e
- [-] AC29 (R19) Given a `tracker.local.md`, when any tracker-aware playbook runs, then it reads the file and follows it — verify: manual (superseded by `2026-11-14-verify-yass-for-multi-team-repos-is`, which keeps the workflow in a team memory committed in the yass folder)

## Pieces
Five pieces, in order:
1. **`2026-11-14-tracker-settings-and-card-view`**: all the binary work (AC9–AC12, AC21, AC22, AC28), and the `yass.yaml` docs in the README and `docs/separate-plans.md`. It goes first because the playbooks write and read the shape it validates. Run `tests/bench.sh` (discovery changes).
2. **`2026-11-14-yass-init-playbook`**: the new playbook (setup, adopting a board, the Trello workflow text), with install docs leading with the agent (AC1–AC8, AC30). It's blocked by piece 1, since adopting a board has to pass `yass status`.
3. **`2026-11-14-trello-in-the-lifecycle-playbooks`**: the tracker step in `yass-shape`, `yass-plan`, `yass-work` and `yass-status` (AC13–AC20, AC23). It's blocked by piece 2, whose workflow text these steps point at.
4. **`2026-11-14-other-trackers-by-interview`**: the interview, memory and `tracker.local.md` (AC25–AC27, AC29). It's blocked by piece 3: it edits the same playbooks, so it waits rather than conflicting.
5. **`2026-11-14-docs-yass-inside-a-tracker-s-workflow`**: the reframing in the README, `docs/trackers.md`, `docs/comparison.md`, the landing page and the 0.5.0 changelog (AC24). It goes last so it describes what shipped.

## Validation
- **Automated:** `go test ./...`, `tests/e2e.sh`, `tests/examples.sh` and `tests/site.sh` pass on Linux and macOS in CI. `tests/bench.sh` stays within its targets, with timings quoted in piece 1's PR.
- **Trello end to end:** one manual run on a scratch board with Claude Code and a Trello connector. Adopt the board, take one large change with two pieces from Will Do to Done, and force one claim conflict (AC17). Do it once with plans inline and once with plans separate (AC23).
- **Jira or another tracker:** one manual interview and a follow-up session on Claude Code (AC25, AC26).
- **0.5.0 changelog:** updated before the release is tagged.
