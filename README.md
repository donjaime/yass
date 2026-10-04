# YASS! Yet Another Spec System

**A sassy "yes" to building with coding agents, without losing the plot.**

YASS is a lightweight way to plan and track work with coding agents, in plain files next to your code. Each piece of work is a **change**: a folder that carries as much ceremony as its scope needs, from a one-file bug fix to a feature with a PRD, a plan and a dozen pull requests. Progress, decisions and notes live in the folder, so any person or agent, on any harness, can pick up where the last one stopped.

```
yass/
├── changes/                                active work
│   ├── 2026-10-02-fix-double-tap-save/
│   │   └── change.md                       small: goal, acceptance, steps, decisions, log
│   └── 2026-09-14-offline-sync/
│       ├── change.md                       large: a slimmer head file (goal, decisions, log)…
│       ├── prd.md                          …plus why and what
│       ├── plan.md                         …how, and acceptance criteria
│       ├── design.md                       …the hard-to-undo calls (optional)
│       ├── 2026-09-16-offline-queue/       …and PR-sized pieces, one level deep
│       └── 2026-09-24-sync-badge/
└── archive/                                finished changes, moved here as they were
```

That's the whole system: no database, no server, and no config unless you want one ([`yass.yaml`](#keeping-plans-out-of-the-repo)). A small CLI (`init`, `new`, `status`, `archive`), five playbooks your agent follows, and an optional git hook.

YASS doesn't commit for you. The CLI never commits (archiving only stages the move), and the playbooks only commit, branch or rebase when you or your harness have given the agent that latitude; otherwise they hand you the commands. The rules below are about what lands on your main branch, and the hook checks them.

## The rules

1. **YASS describes change, not the current system.** Your code and its docs say what exists today. YASS says what you're changing, why, and how it went. A project that uses YASS from day one ends up with an archive that tells the story of the whole product; a project that adopts it later just starts recording from there.
2. **A change is a folder, and ceremony scales with scope.** A bug fix is one `change.md`. A new feature, component or system adds `prd.md` and `plan.md`, maybe `design.md`, and splits into PR-sized pieces inside it.
3. **Progress travels with the code.** Marking boxes in progress or done and appending to `## Log` and `## Decisions` go in the same commits as the code they describe.
4. **Intent changes get their own commit.** The PRD, the design, the plan's text, and a change's title, Goal and Acceptance, including dropping an acceptance criterion. If the plan turns out wrong, change it on purpose, in a commit someone can review, not quietly next to the code. Mid-build, that means a stacked branch: the intent change underneath, the code rebased on top, so work keeps moving and decisions can still be reviewed apart from execution.
5. **Done means every box is checked.** Then `yass archive` moves the folder to `archive/`. Finishing is separate from merging: a large change spans many branches and pull requests, and feedback can reopen the plan before it's done.
6. **The archive is append-only.** Follow-up work is a new change with `follows: <archived folder>`.

## Install

YASS is one `yass` binary on your PATH, plus a few files in your repo: the playbooks in `.agents/skills/`, an empty `yass/` folder (or a [`yass.yaml`](#keeping-plans-out-of-the-repo) pointing elsewhere), a short section in `AGENTS.md`, and the optional hook in `tools/yass/githooks/`. `install.sh` sets up both, and it's short enough to read first. Pick one way; [docs/install.md](docs/install.md) has the details.

**From a release.** Prebuilt for macOS, Linux and Windows, with checksums and signed build provenance:

```bash
curl -fsSLO https://github.com/donjaime/yass/releases/latest/download/yass_darwin_arm64.tar.gz   # your OS and CPU
curl -fsSLO https://github.com/donjaime/yass/releases/latest/download/checksums.txt
grep yass_darwin_arm64.tar.gz checksums.txt | shasum -a 256 -c
tar -xzf yass_darwin_arm64.tar.gz && less yass_darwin_arm64/install.sh
yass_darwin_arm64/install.sh --bin-dir ~/.local/bin path/to/your-repo
```

**From source.** With Go 1.22 or later:

```bash
git clone https://github.com/donjaime/yass && cd yass
go build -o bin/yass ./cmd/yass
./install.sh --bin-dir ~/.local/bin path/to/your-repo
```

**With your agent.** Paste [the install prompt](docs/install.md#with-your-agent) into your coding agent. It downloads a release (or builds from source), verifies it, reads `install.sh` and tells you what it will change, and asks before running it.

**In one line,** if you've read the script and trust it: `curl -fsSL https://raw.githubusercontent.com/donjaime/yass/main/install.sh | bash -s -- --bin-dir ~/.local/bin .` downloads the latest release for your machine and checks its checksum, but runs a script you haven't looked at.

Then commit what it added: `git add -A && git commit -m "chore: adopt YASS"`. Add `--claude` for Claude Code, `--hooks` to turn on the hook, `--path <folder>` to keep the yass folder out of the repo, and `--global` to put the playbooks in your user folder instead of the repo. Re-run a newer release with `--upgrade` to update the playbooks and the hook; your changes are never touched.

Then talk to your agent:

| You say | Playbook | What happens |
|---|---|---|
| "Save this plan as a change" | `yass-shape` or `yass-plan` | the plan from your harness's plan mode becomes a change folder |
| "Fix the double-tap crash" | `yass-work` | a small change: goal, acceptance, build, tick, log |
| "Keep going" | `yass-work` | the change this session is already on; `yass-work` never picks one by itself |
| "Let's build offline sync" | `yass-shape` | a conversation that ends in a PRD you approve |
| "Plan it" | `yass-plan` | approach, acceptance criteria, PR-sized pieces, without much back-and-forth; nothing gets built yet |
| "Work on offline-queue" | `yass-work` | builds that change, resuming from its Log's last **Next:**; a wrong plan gets fixed on a branch underneath the code |
| "Where are we?" | `yass-status` | progress, blockers, recent decisions, what's ready to archive; changes nothing |
| "Why did we pick SQLite?" | `yass-log` | the decision, who made it and when, from the folders and git, with the code that carried it out |
| "Why does sync.go merge like this?" | `yass-log` | from the file's commits back to the change and decision that cite them |

## The CLI

```
yass init [dir]                 create yass/ (in dir, for a team folder) and the AGENTS.md section
          [--path <folder>]     …or a yass.yaml pointing to a yass folder somewhere else
yass new "<title>"              a small change
         [--large] [--design]   …with prd.md and plan.md, and design.md
         [--in <change>]        …as a piece of a large change
         [--source gh#41] [--follows <archived>] [--platforms "ios, android"] [--goal "…"]
yass status [<change>]          what's in flight, progress, next steps, what's blocked, not started or done
            [--archived] [--strict]
yass archive <change>           move a finished change to archive/ (refuses while boxes are open)
yass root                       print the yass folder(s) this repo uses
yass template <name>            print a template (design, prd, plan, …), e.g. to add design.md later
yass hook [--range A..B]        the optional hook's check, for CI
```

`yass status` looks like this:

```
2026-10-02-fix-double-tap-save      1/4  next: disable Save while saving, then the unit test.
2026-09-14-offline-sync  (large)   5/16  next: offline-queue first; sync-badge needs it.
  ├ 2026-09-16-offline-queue        4/8  next: drain on `online` for the web, then batch the drain.
  └ 2026-09-24-sync-badge           0/5  BLOCKED: does the web get the badge too?
```

Changes are listed oldest first, unless the yass folder has a [`queue.md`](#the-queue) saying what order to tackle them in.

The CLI is one Go binary with no runtime dependencies. It reads the files and moves folders; it never commits, branches or merges.

## The files

Every change has a `change.md`:

```markdown
---
platforms: [ios, android]
source: gh#41
follows:
blocked:
---
# Fix double-tap save crash

## Goal
Tapping Save twice quickly saves one entry and never crashes.

## Acceptance
- [ ] Given the picker, when Save is tapped twice within 300ms, then one entry is saved — verify: unit SaveTests.doubleTap

## Steps
- [x] Reproduce on Android
- [ ] Disable Save while a save is in flight

## Decisions
- Disable the button rather than dedupe in the store - fixes the cause (claude)

## Log
### 2026-10-02 (claude)
- Did: reproduced; two inserts race on the same id.
- Next: disable Save while saving, then the unit test.
```

- **Frontmatter:** `platforms` is what "done" has to cover. `source` is the issue, alert or request it came from. `follows` names the archived change it follows up. `blocked` holds a reason when work can't continue. All optional.
- **Intent:** the title, `## Goal` and `## Acceptance`. They change only in commits without code.
- **Progress:** `## Steps` (your working checklist), `## Decisions` (`- <decision> - <why> (<who>)`) and `## Log` (ending in `- Next:`, which `yass status` shows). These change with the code.

A large change has a slimmer `change.md` (goal, decisions, log) and adds:
- **`prd.md`:** why, for whom, measurable outcomes, requirements (`R1`), non-goals, milestones, open questions.
- **`plan.md`:** approach, acceptance criteria per milestone (`AC1 (R1) Given … — verify: …`), the order of the pieces, validation.
- **`design.md`** (optional): context, at least two options, the decision and who made it, rollback.
- **Pieces:** PR-sized changes in their own dated folders inside it. Each names the plan criteria it delivers.

### The queue

A yass folder can hold a `queue.md`: the order you want to tackle its changes in, top first. It's optional, and it doesn't have to list everything.

```markdown
# Queue

1. 2026-10-02-fix-double-tap-save — a crash; before more sync work
2. 2026-09-14-offline-sync
```

- **Each list item names a change folder** (`1.` or `-`, plain, in backticks, or as a link). Anything after the name is a note. Headings and prose are ignored.
- **`yass status` follows it:** listed changes first, in order, then the rest, oldest first. It warns about a name that isn't an active change there, an archived change, a piece (a large change's `plan.md` orders its pieces), or a repeat.
- **Reordering is a decision,** so it's intent: commit it without code, and the hook checks that. Creating a queue alongside code is fine, like any new intent file.
- **`yass archive` takes the change off the list** and stages that with the move.
- **The queue informs whoever directs the work.** `yass-work` still works only on the change it's pointed at.

Checkboxes: `[ ]` not started, `[/]` in progress, `[x]` done, `[-]` dropped (say why in Decisions). Progress counts are just these boxes: `[/]` isn't done yet, and `[-]` doesn't count. The same boxes give each change its state in `yass status`: `not started` (no Log entry, nothing in progress or done), in progress, or `done` (every box done or dropped, ready to archive). Archived means finished.

## The optional hook

`tools/yass/githooks/pre-commit` runs `yass hook`, which warns when a commit mixes code with edits to existing intent: `prd.md`, `design.md`, `plan.md` beyond ticking boxes, or a change's title, Goal or Acceptance. Dropping an acceptance criterion (`[-]`) counts as an intent edit. It also warns on any edit or addition to an already-archived change. Ticked or in-progress boxes, Log and Decisions next to code are expected and never flagged.

- **Turn it on for a clone:** `git config core.hooksPath tools/yass/githooks`. This replaces your `.git/hooks`; if you already use a hook manager (husky, lefthook, pre-commit), call `yass hook` from it instead. Without `yass` on the PATH, the hook skips itself with a note.
- **It only warns.** `YASS_STRICT=1` makes it refuse the commit; `YASS_HOOK=off` skips it.
- **In CI**, install `yass` (a release, or `go install github.com/donjaime/yass/cmd/yass@<version>`) and check a whole branch: `yass hook --range origin/main..HEAD --strict`. CI needs the history for that range (with GitHub Actions, `actions/checkout` with `fetch-depth: 0`); the hook fails loudly if it can't read it.

It's a heuristic over markdown diffs. It catches the common way goalposts move (reworded acceptance criteria next to the code that "meets" them). Review and CI do the rest.

## Keeping plans out of the repo

Not every project wants its work in progress in the repo; an open source project might keep it private, or somewhere else entirely. Put a `yass.yaml` where the `yass/` folder would go, pointing to the folder you want:

```yaml
path: ../my-project-plans        # relative to this file
# path: ~/plans/my-project
# path: ${YASS_HOME}/my-project  # an environment variable, with a path under it
```

`yass init --path <folder>` (or `install.sh --path <folder>`) writes it and creates the folder. From then on everything works as before: `yass new` puts changes there, `yass status` reads them, and `yass root` prints where it resolved. If a variable it uses isn't set, `yass status` says so.

- **Commit the `yass.yaml`** so everyone finds the plans the same way (each person sets the variable for their machine), or **gitignore it** to keep even the pointer private. `yass` still reads one at the top of the repo or in the folder you're in.
- **The folder can be a git repo of its own,** private if you like. Then no commit can mix code and plans, so the hook has nothing to check; commit intent changes there on their own, as usual. Its history is where Decisions get their dates and authors.
- **Boxes cite the code they rest on,** since progress can't ride in the same commit as the code: `- [x] Disable Save while saving — code: a1b2c3d`. A box is `[x]` once its code is merged, citing the commit on the main branch, and `[/]` until then. `yass status` warns about a cited commit this repo doesn't have, and about a done box whose code isn't merged. `branch:` in `yass.yaml` says which branch counts (default: `origin/HEAD`, then `main`, then `master`).
- **Run your agent from the code repo** and give it the plans folder as an extra directory (Claude Code: `claude --add-dir <folder>`, or `permissions.additionalDirectories`). It finds the files through `yass`, so it only needs permission to write there.
- **A path inside the repo works too,** under any name (`path: planning`), and the hook recognizes it.

`yass.yaml` is also where YASS settings go as they're added (`path`, `branch` and [`ignore`](#folders-that-arent-yours) so far). It doesn't have to point anywhere: without `path:`, the yass folder is the `yass/` next to it, so a `yass.yaml` beside your `yass/` folder just holds settings. A setting your version doesn't know is a warning, not an error.

## Monorepos

Any folder named `yass/` with `changes/` or `archive/` inside counts, and so does any `yass.yaml`, so teams opt in by running `yass init services/payments`. `yass status` shows every `yass/` folder in the repo, and `yass new` puts a change in the nearest one to where you're standing. Cross-team work is links, not copies: a root change's plan names the team changes that deliver each criterion, and each team change names the criterion it delivers. Ownership and review rules belong in your CODEOWNERS. See [examples/monorepo](examples/monorepo).

### Folders that aren't yours

Some `yass/` folders belong to something else: examples, test fixtures, a vendored project. List them under `ignore:` in a `yass.yaml` next to your `yass/` folder:

```yaml
ignore:                    # folders or glob patterns, relative to this file
  - examples/*
  - third_party/some-lib
```

Their `yass/` folders and `yass.yaml` files are left out of `yass status`, `yass root` and `yass new`, and the hook treats their files as ordinary files. From inside one, it's a project of its own: `cd examples/solo-app && yass status` shows that example's changes, not yours. That's why `examples/*` beats `examples` when each folder is a separate project. An entry that matches no folder, or one outside the folder `yass.yaml` is in, is a warning. This repo uses it for its [examples](examples).

## Harnesses

The playbooks are [Agent Skills](https://agentskills.io) in `.agents/skills/`, which Codex, OpenCode and pi read natively. Claude Code reads `.claude/skills/`, so `install.sh --claude` copies them there and imports `AGENTS.md` from `CLAUDE.md`. The rules themselves live in `AGENTS.md` and the files, so any agent that can read files and run a shell command can follow them.

### Plan mode

YASS is meant to sit next to your harness's plan mode (Claude Code's, or any other), not replace it. Plan mode is good at a session's worth of research and a plan the human approves; a YASS change is where that plan lives after the session ends, with progress and decisions next to it.

- **Plan first, then save it.** Use plan mode as usual. Once you approve the plan, ask the agent to save it as a change: `yass-shape` turns it into a `prd.md` for large work, `yass-plan` into a `plan.md` (or a small change's Goal, Acceptance and Steps). They start from what the plan already says and only ask about what's missing.
- **Plan mode can't write files**, in most harnesses. The playbooks draft there and write once you've approved.
- **Mid-build, plan mode is a good way to rethink.** Whatever it decides becomes an intent change, stacked under the code like any other.

## What YASS leaves to you

Guardrails, approvals, CI, verification gates, merge strategy, issue tracking and unattended agent loops differ from team to team, so YASS doesn't own them. It gives you places to record their results (acceptance criteria with `verify:`, Decisions with who made them, `source:` links to your tracker) and one optional hook for the rule it cares most about. See [docs/comparison.md](docs/comparison.md) for how YASS relates to OpenSpec, Spec Kit and others.

## Examples

- [examples/solo-app](examples/solo-app): a mobile app built by one developer and agents, using YASS from day one. One large change in progress with two pieces, a small bug fix, and an archive.
- [examples/monorepo](examples/monorepo): three teams, one cross-team change, and a team that adopted YASS late.

## Status

**v0.1, early.** The CLI and hook are covered by Go unit tests and an end-to-end test suite (`tests/e2e.sh`), run in CI on Linux and macOS; the Windows builds compile but aren't tested yet. The playbooks have been written for Claude Code, Codex, OpenCode and pi, but haven't been battle-tested in each. Feedback and war stories are very welcome.

## License

MIT. See [LICENSE](LICENSE).
