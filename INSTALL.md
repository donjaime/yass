<!-- For maintainers: agents fetch this file from main, but it installs the latest release.
     Describe only what the latest release does; a step that needs an unreleased feature lands
     with that release. The page, the README and docs/install.md quote the one-line prompt below
     word for word (tests/site.sh checks), so change it everywhere or nowhere. -->
# Install YASS with your agent

For people: paste this into your coding agent, from inside the repo you want to set up.

```text
Install YASS and set it up in this repo by following https://raw.githubusercontent.com/donjaime/yass/main/INSTALL.md. Ask me before changing anything.
```

Your agent then follows the steps below: it gets the `yass` binary (verifying the download and reading the install script first), sets up the repo with `yass init`, and offers to connect your project management system. It asks before each step that changes anything, never edits your shell files, and never commits. [docs/install.md](docs/install.md) has every other way to install, by hand.

## For the agent

You're installing YASS (https://github.com/donjaime/yass) and setting it up in the repository you're running in. Go step by step, show the person what you find, and don't run anything that changes files until they say so.

### Part 1, the binary

1. Work out this machine's OS (`darwin`, `linux` or `windows`) and CPU (`amd64` or `arm64`).
2. In a temporary folder, download `yass_<os>_<arch>.tar.gz` (`.zip` on Windows) and `checksums.txt` from https://github.com/donjaime/yass/releases/latest/download/.
   If the person has said "from source" instead: clone https://github.com/donjaime/yass, check out the latest release tag, and build it with `go build -o bin/yass ./cmd/yass` (Go 1.24 or later); skip step 3.
3. Check the archive's SHA-256 against its line in `checksums.txt`. If the GitHub CLI is installed, also run `gh attestation verify <archive> --repo donjaime/yass`. Stop if either check fails.
4. Unpack it and read `install.sh` in full. Tell the person what it will do: it should only copy the `yass` binary into a folder (`~/.local/bin`, or the one passed to `--bin-dir`) and say whether that folder is on their PATH. Point out anything that looks unexpected.
5. Ask where to put the binary, then once they say go, run `install.sh` (with `--bin-dir <folder>` if they picked another). If the folder isn't on their PATH, show them the line that adds it (`install.sh` prints one); don't edit their shell files.

### Part 2, this repo

6. Ask which options they want: Claude Code files (`--claude`), playbooks in their user folder rather than this repo (`--global`), the optional pre-commit hook (`--hooks`), or a yass folder with another name or outside this repo (`--path <folder>`).
7. Run `<folder>/yass init` with their options, then `yass status` to check it works, and show them `git status`. Don't commit; they'll review it and commit it themselves.
8. Read the `yass-init` playbook it just installed and offer what's left from it, such as connecting a Trello board, Jira or another project management system to the yass folder.
