---
platforms: [all]
source: Jaime, 2026-10-04: the curl install assumes ~/.local/bin is on PATH (it wasn't on Jaime's Mac) and doesn't say it must run inside your repo
follows: 
blocked:
---
# Install: say where to run it and how yass gets on your PATH

## Goal
<!-- Intent. What is true when this change is finished, in a paragraph. Edit it only in a commit without code. -->
Someone installing YASS knows two things before they start: the install runs from inside the repo they want to set up (or points at it), and the binary goes to `~/.local/bin`, which has to be on their PATH. If it isn't, `install.sh` ends with the line that adds it. Every install path says this: the README, `docs/install.md`, the agent prompt and the landing page. For zsh, that line goes in `~/.zshenv`, which every zsh reads, including the non-interactive shells agents and git hooks run, rather than `~/.zshrc`, which they skip. The docs and the page also make the two parts of an install plain: the `yass` binary goes on your PATH once per machine, and the repo setup (playbooks, the `AGENTS.md` section, the yass folder, the optional hook) happens once per repo and is committed, so teammates get it from git. With that model, the docs cover setting up another repo, joining a repo that already uses YASS (just the binary), and upgrading (the binary once, then each repo).

## Acceptance
<!-- Intent. Observable checks, one behavior each, e.g.
- [ ] Given …, when …, then … — verify: <test, flow, or manual steps> -->
- [ ] Given the README, `docs/install.md` and the landing page, then each install method that passes `--bin-dir ~/.local/bin` says that folder has to be on your PATH, and that `install.sh` ends with the line to add it if it isn't — verify: manual: read each install method in all three
- [ ] Given the one-line install in the README, `docs/install.md` and the page's Terminal tab, then it runs from inside your repo: `cd path/to/your-repo` comes first — verify: `tests/site.sh` (the page's block matches `docs/install.md` word for word); manual: the README
- [ ] Given zsh, and a `--bin-dir` that isn't on PATH, when `install.sh` finishes, then the fix it prints appends to `~/.zshenv`, not `~/.zshrc` — verify: e2e (the PATH-warning checks)
- [ ] Given `docs/install.md`, then it says why the line goes in `~/.zshenv`: agents and git hooks run shells that don't read `~/.zshrc` — verify: manual: review
- [ ] Given the agent install prompt, then it has the agent check that the folder it installs to is on PATH and, if not, show the line to add, without editing shell files itself — verify: `tests/site.sh` (the page's copy matches `docs/install.md`); manual: review
- [ ] Given the landing page's Terminal tab, then it says the command does two things: installs `yass` to `~/.local/bin`, once per machine, and sets up this repo, once per repo, committed — verify: manual: read the tab
- [ ] Given `docs/install.md`, then it opens with the two parts: the binary, once per machine on your PATH, and the repo setup, once per repo and committed — verify: manual: review
- [ ] Given `docs/install.md`, then it shows how to set up another repo when `yass` is already on your PATH: `install.sh` without `--bin-dir` — verify: manual: review; e2e (`install.sh` uses the `yass` on PATH)
- [ ] Given `docs/install.md`, then it shows how to join a repo that already uses YASS: only the binary, from a release archive or `go install`, and no `install.sh` — verify: manual: review; run the release steps once by hand
- [ ] Given the README, then its install section states the two parts in a sentence or two and links to `docs/install.md` for another repo and for joining one — verify: manual: review
- [ ] Given the README, then it has an Upgrading section: upgrade the binary once per machine, run `install.sh --upgrade` in each repo and commit it, teammates upgrade their binary when the repo's playbooks move ahead, with a link to `docs/install.md#upgrading` — verify: manual: review; the link's heading exists
- [ ] Given the change, then the existing e2e suite, `tests/examples.sh` and `tests/site.sh` pass — verify: CI on the branch

## Steps
<!-- Progress. Your working checklist: add, reorder and mark freely: [ ] not started, [/] in progress, [x] done, [-] dropped. -->
- [ ] `install.sh`: zsh fix goes to `~/.zshenv`; e2e expectation
- [ ] `docs/install.md`: `cd` first in the one-liner, PATH notes, why `~/.zshenv`, agent prompt step
- [ ] README: the same, briefly, in the install section
- [ ] Landing page: Terminal tab and notes, agent prompt copy
- [ ] `docs/install.md`: the two parts up front; another repo; joining a repo
- [ ] README: the two parts; an Upgrading section

## Decisions
<!-- Progress. "- <decision> - <why> (<who>)", appended as you go. -->
- A separate small change, not part of the landing page change - that change rules out README edits beyond its lead-in and changes to how YASS works; this touches both (Jaime)
- Folded in after review: explain the two parts of an install (the binary per machine, the repo setup per repo), cover another repo and joining one, and give upgrading its own README section; the landing page doesn't cover upgrading. Docs only - actually splitting the two steps (the binary carrying the playbooks) is a future large change, noted separately (Jaime)
- Clarify and fix the hint, don't change where the binary goes: `~/.local/bin` stays the documented default, and `install.sh` doesn't edit shell files itself - picking a folder that's already on PATH, or writing to dotfiles, is a bigger behavior change than this needs (claude)

## Log
<!-- Progress. Append before you stop, so anyone can resume:
### YYYY-MM-DD (<who>)
- Did: …
- Next: … -->
