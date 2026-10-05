# Installing YASS

YASS has two parts:

- **The `yass` binary,** installed once per machine, on your PATH (and in CI if you use the hook there). It's a single Go binary with no runtime dependencies.
- **A few files in each repo,** set up once and committed, so everyone who clones the repo gets them: the playbooks in `.agents/skills/` (and `.claude/skills/` with `--claude`; or in your user folder with `--global`), the optional hook in `tools/yass/githooks/pre-commit`, a short section in `AGENTS.md`, and an empty `yass/` folder, or a `yass.yaml` pointing to one elsewhere with `--path`.

`install.sh` does both: `--bin-dir` installs the binary, and the repo you point it at (`.` for the one you're in) gets the files. It's about a hundred lines of bash; read it before you run it. It never touches your changes, and it only installs the binary when you pass `--bin-dir`. Already have `yass` and setting up [another repo](#another-repo), or [joining a repo that already uses YASS](#joining-a-repo-that-already-uses-yass)? Those need only one of the two parts.

Two things to know before you start:
- **Run it for the repo you want to set up:** from inside it (that's the `.` in the one-line install), or with that repo's path last.
- **The folder you pass to `--bin-dir` has to be on your PATH,** so you, your agents and the hook can run `yass`. The examples use `~/.local/bin`, which macOS doesn't put on PATH by default. If it isn't on yours, `install.sh` ends with the line that adds it. For zsh, that line goes in `~/.zshenv`, which every zsh reads, including the non-interactive shells agents and git hooks run; `~/.zshrc` is only read by interactive ones.

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
"yass_${os}_${arch}/install.sh" --bin-dir ~/.local/bin path/to/your-repo
```

To pin a version, replace `latest/download` with `download/v0.1.0`. On Windows, download the `.zip` and run `install.sh` from Git Bash.

## From source

With Go 1.24 or later:

```bash
git clone https://github.com/donjaime/yass && cd yass
git checkout v0.1.0                       # optional: a released version rather than main
go build -o bin/yass ./cmd/yass
./install.sh --bin-dir ~/.local/bin path/to/your-repo
```

For the binary alone, `go install github.com/donjaime/yass/cmd/yass@latest` puts it in `$(go env GOPATH)/bin`. Then `./install.sh path/to/your-repo` from a clone finds it on your PATH.

## With your agent

Paste this into your coding agent from inside the repo you want to set up. It does what a careful person would: verifies the download, reads the script, and asks before running anything.

```text
Install YASS (https://github.com/donjaime/yass) in this repository. Go step by step, show me
what you find, and don't run anything that changes files until I say so.

1. Work out this machine's OS (darwin, linux or windows) and CPU (amd64 or arm64).
2. In a temporary folder, download yass_<os>_<arch>.tar.gz (.zip on Windows) and checksums.txt
   from https://github.com/donjaime/yass/releases/latest/download/.
   If I've said "from source" instead: clone https://github.com/donjaime/yass, check out the
   latest release tag, and build it with `go build -o bin/yass ./cmd/yass`; skip step 3.
3. Check the archive's SHA-256 against its line in checksums.txt. If the GitHub CLI is installed,
   also run `gh attestation verify <archive> --repo donjaime/yass`. Stop if either check fails.
4. Unpack it and read install.sh in full. Tell me exactly what it will do: which files it writes
   in this repo, anything it changes in git config, and anything it writes outside the repo.
   Point out anything that looks unexpected.
5. Ask me which options I want: copy the binary to ~/.local/bin (--bin-dir), Claude Code
   files (--claude), playbooks in my user folder rather than this repo (--global), the optional
   pre-commit hook (--hooks), or keeping the yass folder outside this repo (--path <folder>).
6. Once I say go, run install.sh with those options. If the folder the binary went to isn't on
   my PATH, show me the line that adds it (install.sh prints one); don't edit my shell files.
   Then run `yass status` to check it works, and show me `git status`. Don't commit; I'll
   review it and commit it myself.
```

## In one line

```bash
cd path/to/your-repo
curl -fsSL https://raw.githubusercontent.com/donjaime/yass/main/install.sh | bash -s -- --bin-dir ~/.local/bin .
```

When `install.sh` is piped in like this, it downloads the latest release for your machine (or `YASS_VERSION=v0.1.0`) and checks it against the release's `checksums.txt` before using it. That protects against a corrupted download, but not against the script itself: you're running code you haven't read. Prefer one of the ways above.

## Another repo

With `yass` already on your PATH, run the install again for the other repo. In one line, from inside it, drop `--bin-dir`: `install.sh` then uses the `yass` on your PATH.

```bash
curl -fsSL https://raw.githubusercontent.com/donjaime/yass/main/install.sh | bash -s -- .
```

From a clone or an unpacked release, run `./install.sh --bin-dir ~/.local/bin path/to/other-repo` as before; copying the same binary again is harmless. (Without `--bin-dir`, it uses the binary next to it and warns that the one on your PATH is a different one.)

Then commit what it added. Use the same release for every repo on a machine; if the playbooks it would install are newer than your binary, [upgrade](#upgrading) the binary first.

## Joining a repo that already uses YASS

The repo's files are already committed, so you only need the binary; don't run `install.sh`. Download and verify a release as in [From a release](#from-a-release), then copy the binary onto your PATH:

```bash
tar -xzf "yass_${os}_${arch}.tar.gz"
cp "yass_${os}_${arch}/yass" ~/.local/bin/
```

Or, with Go, `go install github.com/donjaime/yass/cmd/yass@latest`. Run `yass status` in the repo to check it works. If the repo has been upgraded to a newer YASS than the latest you can get, or an older one you need to match, pick that release by its tag (replace `latest/download` with `download/v0.2.0`); the repo's upgrade commit (`chore: upgrade YASS`) says when it moved.

## Options

| Option | What it does |
|---|---|
| `--bin-dir DIR` | copies the `yass` binary that came with the script (a release, or `bin/yass` in a clone) into `DIR` |
| `--global` | puts the playbooks in your user folder (`~/.agents/skills/`, or `$YASS_SKILLS_DIR`; `~/.claude/skills/` with `--claude`) for every repo, instead of in this one. The default is project scope: the playbooks live in the repo, so everyone working on it gets the same version. Check that your harness reads the user folder you pick |
| `--claude` | also copies the playbooks to `.claude/skills/` and imports `AGENTS.md` from `CLAUDE.md` |
| `--hooks` | turns on the optional hook for this clone (`git config core.hooksPath tools/yass/githooks`) |
| `--path P` | keeps the yass folder outside the repo: writes a `yass.yaml` pointing to `P`, creates it, and links `yass/` to it (ignored through `.git/info/exclude`; see [the README](../README.md#keeping-plans-out-of-the-repo)) |
| `--upgrade` | replaces the playbooks and the hook with this version's |

Without `--bin-dir`, `install.sh` uses a `yass` it finds next to it, in `bin/`, on your PATH, or in `$YASS_BIN`, and stops if there's none.

## Upgrading

Upgrading has the same two parts as installing: the binary, once per machine, and each repo's files, once per repo.

1. **Get the newer binary** the way you got it: download and verify a [release](#from-a-release) and copy its `yass` onto your PATH (or run its `install.sh --bin-dir ~/.local/bin`), `go install github.com/donjaime/yass/cmd/yass@latest`, or pull and rebuild a clone. `yass --version` shows what you have.
2. **Run `yass upgrade` in each repo,** from anywhere in it:

   ```bash
   yass upgrade
   ```

   It finds every YASS file from the repo root down, with `git ls-files`: playbooks in any folder's `.agents/skills/` or `.claude/skills/` (so monorepo folders set up with `yass init <folder> --agents` are included), every `AGENTS.md` with the YASS section, and the hook. It adds your user folder's playbooks, if you installed them with `--global`. It skips folders `yass.yaml` lists under `ignore:`.
3. **Review the diff and commit it** (`chore: upgrade YASS`).

What it does with each file depends on the version stamped in it:
- **Older, or no stamp** (files written by v0.2 or earlier): replaced with this binary's version. A skills folder also gets any playbook it's missing.
- **The same version:** left alone. When nothing needs doing, it says everything is already up to date.
- **Newer:** nothing is written, and it says to upgrade your binary first. `yass upgrade` never downgrades.

Your changes, `yass.yaml` and anything outside the `yass:begin`/`yass:end` markers in `AGENTS.md` are left alone. Hand edits to YASS's own files are replaced; since they're committed, the diff shows them. Files outside version control (user-folder playbooks) are labeled as such in the list of what it wrote.

- **Read the [release notes](https://github.com/donjaime/yass/releases)** for what changed. Before 1.0, a minor version can change the file format or the CLI; the notes say how to migrate.
- **The binary is per machine; the files are per repo.** Upgrading the binary affects every repo on your machine, so upgrade each repo you use YASS in, and teammates should upgrade their binary when the repo moves ahead.

## Removing it

Delete `tools/yass/`, `.agents/skills/yass-*/` (and `.claude/skills/yass-*/`), the `yass:begin`…`yass:end` section of `AGENTS.md`, and the binary. Run `git config --unset core.hooksPath` if you turned the hook on. Keep the `yass/` folder (or wherever `yass.yaml` points) if you want the history.
