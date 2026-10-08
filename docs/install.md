# Installing YASS

YASS has two parts, and you set them up in two steps:

1. **The `yass` binary,** installed once per machine, on your PATH (and in CI if you use the hook there). It's a single Go binary with no runtime dependencies. `install.sh` puts it in the folder you pass to `--bin-dir`, and does nothing else.
2. **A few files in each repo,** set up once with `yass init` and committed, so everyone who clones the repo gets them: the playbooks in `.agents/skills/` (and `.claude/skills/` with `--claude`; or in your user folder with `--global`), the optional hook in `tools/yass/githooks/pre-commit`, a short section in `AGENTS.md`, and an empty `yass/` folder, or a `yass.yaml` pointing to one elsewhere with `--path`. The binary carries these files, so this step needs no download.

[Joining a repo that already uses YASS](#joining-a-repo-that-already-uses-yass) needs only step 1; [another repo](#another-repo) needs only step 2.

**The folder you pass to `--bin-dir` has to be on your PATH,** so you, your agents and the hook can run `yass`. The examples use `~/.local/bin`, which macOS doesn't put on PATH by default. If it isn't on yours, `install.sh` ends with the line that adds it. For zsh, that line goes in `~/.zshenv`, which every zsh reads, including the non-interactive shells agents and git hooks run; `~/.zshrc` is only read by interactive ones. Until you've added it, run the binary by its full path (`~/.local/bin/yass`).

`install.sh` is short; read it before you run it.

## From a release

Each release has an archive per platform (`yass_<os>_<arch>`, with `os` one of `darwin`, `linux`, `windows`, and `arch` one of `amd64`, `arm64`), a `checksums.txt`, and signed build provenance.

```bash
os=darwin arch=arm64   # or linux/amd64, linux/arm64, darwin/amd64
curl -fsSLO "https://github.com/donjaime/yass/releases/latest/download/yass_${os}_${arch}.tar.gz"
curl -fsSLO https://github.com/donjaime/yass/releases/latest/download/checksums.txt
grep "yass_${os}_${arch}.tar.gz" checksums.txt | shasum -a 256 -c    # or sha256sum -c
gh attestation verify "yass_${os}_${arch}.tar.gz" --repo donjaime/yass   # optional; needs the GitHub CLI
tar -xzf "yass_${os}_${arch}.tar.gz"
less "yass_${os}_${arch}/install.sh"
"yass_${os}_${arch}/install.sh" --bin-dir ~/.local/bin
```

Then [set up your repo](#setting-up-a-repo). To pin a version, replace `latest/download` with `download/v0.3.0`. On Windows, download the `.zip` and run `install.sh` from Git Bash, or copy `yass.exe` onto your PATH yourself.

## From source

With Go 1.24 or later (earlier versions build a `yass` with no version, which won't write YASS's files):

```bash
git clone https://github.com/donjaime/yass && cd yass
git checkout v0.3.0                       # optional: a released version rather than main
go build -o bin/yass ./cmd/yass
./install.sh --bin-dir ~/.local/bin
```

Or, for the binary alone, `go install github.com/donjaime/yass/cmd/yass@latest` puts it in `$(go env GOPATH)/bin`. Then [set up your repo](#setting-up-a-repo).

## Setting up a repo

From inside the repo:

```bash
yass init
```

It writes the playbooks, the `AGENTS.md` section, the yass folder and the hook script, and lists what it wrote; then commit it (`git add -A && git commit -m "chore: adopt YASS"`). Its options:

| Option | What it does |
|---|---|
| `--claude` | also copies the playbooks to `.claude/skills/` and imports `AGENTS.md` from `CLAUDE.md` |
| `--global` | puts the playbooks in your user folder (`~/.agents/skills/`, or `$YASS_SKILLS_DIR`; `~/.claude/skills/` with `--claude`) for every repo, instead of in this one. The default is project scope: the playbooks live in the repo, so everyone working on it gets the same version. Check that your harness reads the user folder you pick |
| `--hooks` | turns on the optional hook for this clone (`git config core.hooksPath tools/yass/githooks`), unless the repo already has a hooks setup (its own `core.hooksPath`, local or global, or hooks in `.git/hooks/`): then it leaves that alone and prints how to run YASS's check from it ([README](../README.md#already-have-hooks)) |
| `--path P` | keeps the yass folder outside the repo: writes a `yass.yaml` pointing to `P`, creates it, and links `yass/` to it (ignored through `.git/info/exclude`; see [the README](../README.md#keeping-plans-out-of-the-repo)) |
| `<folder> [--agents]` | sets up a folder of a monorepo instead: its own yass folder, and with `--agents` its own `AGENTS.md` section and playbooks, for a part of the codebase that keeps its own agent files. The hook stays at the repo root |

Running `yass init` again writes only what's missing and keeps the rest; to bring YASS's files up to a newer version, use [`yass upgrade`](#upgrading).

## With your agent

Paste this into your coding agent from inside the repo you want to set up. It does what a careful person would: verifies the download, reads the script, and asks before running anything.

```text
Install YASS (https://github.com/donjaime/yass) in this repository. Go step by step, show me
what you find, and don't run anything that changes files until I say so.

1. Work out this machine's OS (darwin, linux or windows) and CPU (amd64 or arm64).
2. In a temporary folder, download yass_<os>_<arch>.tar.gz (.zip on Windows) and checksums.txt
   from https://github.com/donjaime/yass/releases/latest/download/.
   If I've said "from source" instead: clone https://github.com/donjaime/yass, check out the
   latest release tag, and build it with `go build -o bin/yass ./cmd/yass` (Go 1.24 or later);
   skip step 3.
3. Check the archive's SHA-256 against its line in checksums.txt. If the GitHub CLI is installed,
   also run `gh attestation verify <archive> --repo donjaime/yass`. Stop if either check fails.
4. Unpack it and read install.sh in full. Tell me what it will do: it should only copy the yass
   binary into the folder I pick and say whether that folder is on my PATH. Point out anything
   that looks unexpected.
5. Ask me where to put the binary (--bin-dir, for example ~/.local/bin) and which options I want
   for this repo: Claude Code files (--claude), playbooks in my user folder rather than this repo
   (--global), the optional pre-commit hook (--hooks), or keeping the yass folder outside this
   repo (--path <folder>).
6. Once I say go, run install.sh --bin-dir <folder>. If that folder isn't on my PATH, show me
   the line that adds it (install.sh prints one); don't edit my shell files. Then, in this repo,
   run <folder>/yass init with my options, then yass status to check it works, and show me
   git status. Don't commit; I'll review it and commit it myself.
```

## In one line

From inside your repo, both steps at once:

```bash
cd path/to/your-repo
curl -fsSL https://raw.githubusercontent.com/donjaime/yass/main/install.sh | bash -s -- --bin-dir ~/.local/bin && ~/.local/bin/yass init
```

When `install.sh` is piped in like this, it downloads the latest release for your machine (or `YASS_VERSION=v0.3.0`) and checks it against the release's `checksums.txt` before installing it. That protects against a corrupted download, but not against the script itself: you're running code you haven't read. Prefer one of the ways above. The second command calls the binary by its full path, so it works before `~/.local/bin` is on your PATH; add `--claude`, `--hooks` or the rest to it.

## Another repo

With `yass` already on your PATH, just run `yass init` in the other repo, and commit what it wrote. Nothing is downloaded: the binary carries the files. If they'd be newer than a repo's existing YASS files, run [`yass upgrade`](#upgrading) there instead.

## Joining a repo that already uses YASS

The repo's files are already committed, so you only need the binary: [step 1](#from-a-release), without `yass init`. In one line:

```bash
curl -fsSL https://raw.githubusercontent.com/donjaime/yass/main/install.sh | bash -s -- --bin-dir ~/.local/bin
```

Or, with Go, `go install github.com/donjaime/yass/cmd/yass@latest`. Run `yass status` in the repo to check it works. If the repo has been upgraded to a newer YASS than your binary, `yass upgrade` says so; get that release (or a newer one). The repo's upgrade commit (`chore: upgrade YASS`) says when it moved.

## Upgrading

Upgrading has the same two parts as installing: the binary, once per machine, and each repo's files, once per repo.

1. **Get the newer binary** the way you got it: download and verify a [release](#from-a-release) and copy its `yass` onto your PATH (or run its `install.sh --bin-dir ~/.local/bin`), `go install github.com/donjaime/yass/cmd/yass@latest`, or pull and rebuild a clone. `yass --version` shows what you have.
2. **Run `yass upgrade` in each repo,** from anywhere in it:

   ```bash
   yass upgrade
   ```

   It finds every YASS file from the repo root down, with `git ls-files`: playbooks in any folder's `.agents/skills/` or `.claude/skills/` (so monorepo folders set up with `yass init <folder> --agents` are included), every `AGENTS.md` with the YASS section, and the hook. It adds your user folder's playbooks, if you installed them with `--global`. It skips folders `yass.yaml` lists under `ignore:`.
3. **Review the diff and commit it** (`chore: upgrade YASS`).

Then it brings each yass folder's layout up to date, including folders `yass.yaml` points to outside the repo and private team folders. Each step does only what's needed, says what it did, and prints how to commit that on its own, apart from the upgrade commit and from code:
- **archive-into-months:** moves changes sitting directly in `archive/` into `archive/<YYYY>/<MM>/`, by when they were archived (the commit that added them there, else the date in their name), and stamps `archived:` on each. Upgrade everyone's `yass` binary before committing it on a shared repo: older binaries don't know the month folders.

What it does with each file depends on the version stamped in it:
- **Older, or no stamp** (files written by v0.2 or earlier): replaced with this binary's version. A skills folder also gets any playbook it's missing.
- **The same version:** left alone. When nothing needs doing, it says everything is already up to date.
- **Newer:** nothing is written, and it says to upgrade your binary first. `yass upgrade` never downgrades.

Your changes, `yass.yaml` and anything outside the `yass:begin`/`yass:end` markers in `AGENTS.md` are left alone. Hand edits to YASS's own files are replaced; since they're committed, the diff shows them. Files outside version control (user-folder playbooks) are labeled as such in the list of what it wrote.

- **Read the [release notes](https://github.com/donjaime/yass/releases)** for what changed. Before 1.0, a minor version can change the file format or the CLI; the notes say how to migrate.
- **The binary is per machine; the files are per repo.** Upgrading the binary affects every repo on your machine, so upgrade each repo you use YASS in, and teammates should upgrade their binary when the repo moves ahead. `yass status` notes when your binary and a repo's YASS files are out of step, and which to upgrade.

## Removing it

Delete `tools/yass/`, `.agents/skills/yass-*/` (and `.claude/skills/yass-*/`), the `yass:begin`…`yass:end` section of `AGENTS.md`, and the binary. Run `git config --unset core.hooksPath` if you turned the hook on. Keep the `yass/` folder (or wherever `yass.yaml` points) if you want the history.
