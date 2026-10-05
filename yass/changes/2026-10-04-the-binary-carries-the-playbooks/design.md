# The binary carries the playbooks: design
<!-- Intent: the calls that are hard to undo. Edit only in commits without code. -->

## Context
`yass init` decides, per file, whether to write, upgrade or refuse, so every file YASS installs has to say which version wrote it. Those stamps get committed into every repo that uses YASS, and future versions have to read them, so their format is public surface that's hard to change later. Two calls: how versions compare, and where the stamp goes. A third, noticing hand edits, was considered and dropped.

## 1. Versions and how they compare
**Options.**
- (a) **Semantic Versioning 2.0**, as the release tags already are (`v0.2.0`), with Go's pseudo-versions for builds from a clone (`v0.2.1-0.20261005022542-577e076bfe44`, plus `+dirty` for uncommitted changes), which Go stamps into the binary on its own.
- (b) Calendar versions (`2026.10.4`).
- (c) Commit SHAs only.

**Decision: (a)** (proposed; precedence rule from Jaime, 2026-10-04). It's what the tags, `go install` and `yass --version` already produce, so there's nothing new to learn. Precedence is SemVer's: a pre-release, which a pseudo-version is, sorts before its release, and build metadata (`+dirty`) is ignored when comparing. One YASS rule on top: when versions compare equal and the binary is `+dirty`, `yass init` writes anyway, since the content may differ. In practice:
- A clone build after `v0.2.0` (`v0.2.1-0.…`) upgrades a repo stamped `v0.2.0`.
- A release `v0.2.1` upgrades a repo stamped with that clone build.
- A `+dirty` build of the same version rewrites; a clean one of the same version says "already up to date".
- A binary with no version at all (`dev`, built outside a git checkout) refuses to write and says how to get a versioned build.

## 2. Where the stamp goes
**Options.**
- (a) **In each file,** using each format's own place for metadata:
  - Playbooks: the [Agent Skills](https://agentskills.io) frontmatter's `metadata` map, the spec's extension point for exactly this, so harnesses that read skills ignore it:
    ```yaml
    metadata:
      yass-version: "0.3.0"
    ```
  - The `AGENTS.md` section: attributes in its begin marker, as managed-block tools do (`<!-- yass:begin version=0.3.0 (managed by `yass init`; edit outside these markers) -->`).
  - The hook script: a header line (`# yass-version: 0.3.0`).
- (b) **A lockfile,** `tools/yass/yass.lock`, listing each installed file's path and version, as `go.sum` and `package-lock.json` do. The files stay as they are, and there's one place to look. But playbooks installed with `--global` live outside the repo and need a lockfile of their own, and a lockfile can drift from the files it describes.

**Decision: (a)** (Jaime, 2026-10-04: versions in the playbooks' frontmatter and the `AGENTS.md` section; claude, the hook header). Each file answers for itself wherever it lives, including the user folder, and nothing can drift apart. The plan checks the Agent Skills spec's `metadata` field (string keys and values) before building on it.

## 3. Noticing hand edits
**Options.**
- (a) A content hash stamped beside each version, checked on the next run, with a frozen table of v0.1 and v0.2 hashes for unstamped files; at a terminal, ask before overwriting an edited file.
- (b) **Don't detect edits.** Upgrading replaces YASS's files, as `install.sh --upgrade` does today.

**Decision: (b)** (Jaime, 2026-10-04). The playbooks, the hook and the `AGENTS.md` section are committed with the repo, so an upgrade that replaces an edited file shows up in `git diff` and review before it's committed; git already does the auditing. (a) added hashes, a frozen table, a prompt and its no-terminal fallback for little gain. Two cheap things stay (claude): `yass init` lists every file it writes, and labels any outside version control (playbooks in the user folder, with `--global`), the one place an edit could vanish unseen. A file with no stamp, as v0.1 and v0.2 wrote them, counts as older than any stamped version, so it's upgraded.

## Consequences and rollback
- Every repo gets a few lines of metadata in each playbook and the `AGENTS.md` marker, and they show up in diffs on upgrade, which is the point.
- Reading stays lenient: a file without a stamp is older than any stamped one, never an error, and unknown `metadata` keys or marker attributes are ignored. So a later format change can add fields without breaking older repos.
- Hand edits to YASS's files are replaced on upgrade. That's documented, and visible in the diff.
- Changing the stamp format later means teaching `yass init` both formats for a while.
