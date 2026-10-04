#!/usr/bin/env bash
# Install (or upgrade) YASS in a git repository.
#
#   From a release:  tar -xzf yass_<os>_<arch>.tar.gz && yass_<os>_<arch>/install.sh [path/to/repo] [options]
#   From a clone:    go build -o bin/yass ./cmd/yass && ./install.sh [path/to/repo] [options]
#   From the web:    curl -fsSL https://raw.githubusercontent.com/donjaime/yass/main/install.sh | bash -s -- [path] [options]
#                    (downloads the latest release for this machine and checks it against the release's checksums)
#
# Options:
#   --bin-dir DIR  also copy the yass binary that came with this script into DIR (e.g. ~/.local/bin)
#   --path P       keep the yass folder outside the repo: write a yass.yaml pointing to P
#   --global       put the playbooks in your user folder (~/.agents/skills, or $YASS_SKILLS_DIR) for every
#                  repo, instead of in this repo's .agents/skills (the default, project scope)
#   --claude       also copy the playbooks to .claude/skills (~/.claude/skills with --global) and import
#                  AGENTS.md from CLAUDE.md (Claude Code)
#   --hooks        turn on the optional pre-commit hook (sets core.hooksPath for this clone)
#   --upgrade      replace tools/yass and the yass-* playbooks with this version
#
# Writes tools/yass/githooks/, .agents/skills/yass-*/ (unless --global), yass/ (or yass.yaml) and a section of AGENTS.md.
# Never touches your changes. Uses the yass binary from $YASS_BIN, next to this script, bin/, or PATH.
set -euo pipefail
REPO_SLUG="${YASS_REPO:-donjaime/yass}"
VERSION="${YASS_VERSION:-latest}"

DEST="."; CLAUDE=0; HOOKS=0; UPGRADE=0; GLOBAL=0; BIN_DIR=""; YPATH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --claude) CLAUDE=1; shift ;;
    --hooks) HOOKS=1; shift ;;
    --upgrade) UPGRADE=1; shift ;;
    --global) GLOBAL=1; shift ;;
    --bin-dir) BIN_DIR="${2:?--bin-dir needs a folder}"; shift 2 ;;
    --path) YPATH="${2:?--path needs a value}"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0" 2>/dev/null || true; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) DEST="$1"; shift ;;
  esac
done
die() { echo "yass: $*" >&2; exit 1; }

DEST="$(cd "$DEST" && git rev-parse --show-toplevel 2>/dev/null)" || die "$DEST is not inside a git repository (git init first)"

sha256() { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | awk '{print $1}'; }

# Find the kit: next to this script (a clone or an unpacked release), or download a release.
SRC=""; WEB=0
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/kit/.agents/skills/yass-work/SKILL.md" ]; then
  SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # The download lands in a temporary folder that's deleted on exit, so its binary has to be copied
  # somewhere (--bin-dir), or a yass already on PATH used instead. Check before downloading anything.
  WEB=1
  [ -n "$BIN_DIR" ] || command -v yass >/dev/null ||
    die "pass --bin-dir (e.g. --bin-dir ~/.local/bin) so the yass binary from the download is kept"
  case "$(uname -s)" in Linux) os=linux ;; Darwin) os=darwin ;; *) die "download a release by hand on this OS: https://github.com/$REPO_SLUG/releases" ;; esac
  case "$(uname -m)" in x86_64|amd64) arch=amd64 ;; arm64|aarch64) arch=arm64 ;; *) die "no release for $(uname -m); build from source" ;; esac
  asset="yass_${os}_${arch}.tar.gz"
  if [ "$VERSION" = latest ]; then url="https://github.com/$REPO_SLUG/releases/latest/download"
  else url="https://github.com/$REPO_SLUG/releases/download/$VERSION"; fi
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  echo "downloading $asset ($VERSION) from $REPO_SLUG …"
  curl -fsSL -o "$TMP/$asset" "$url/$asset"
  curl -fsSL -o "$TMP/checksums.txt" "$url/checksums.txt"
  want="$(awk -v f="$asset" '$2 == f {print $1}' "$TMP/checksums.txt")"
  got="$(sha256 "$TMP/$asset")"
  [ -n "$want" ] && [ "$want" = "$got" ] || die "checksum mismatch for $asset (expected ${want:-nothing}, got $got)"
  echo "checksum ok  $got"
  tar -xzf "$TMP/$asset" -C "$TMP"
  SRC="$TMP/yass_${os}_${arch}"
fi

# Find the binary.
BIN=""
CANDIDATES=("${YASS_BIN:-}")
# A downloaded binary is only used when it's being copied out of the temporary folder.
if [ "$WEB" = 0 ] || [ -n "$BIN_DIR" ]; then CANDIDATES+=("$SRC/yass" "$SRC/yass.exe" "$SRC/bin/yass" "$SRC/bin/yass.exe"); fi
for c in "${CANDIDATES[@]}"; do
  if [ -n "$c" ] && [ -f "$c" ] && [ -x "$c" ]; then BIN="$c"; break; fi
done
if [ -n "$BIN_DIR" ]; then
  [ -n "$BIN" ] || die "no yass binary came with this script to copy into $BIN_DIR (from a clone: go build -o bin/yass ./cmd/yass)"
  mkdir -p "$BIN_DIR"; cp "$BIN" "$BIN_DIR/"; BIN="$BIN_DIR/$(basename "$BIN")"; chmod +x "$BIN"
  echo "write  $BIN"
fi
[ -n "$BIN" ] || BIN="$(command -v yass || true)"
[ -n "$BIN" ] || die "no yass binary found. Install one first (https://github.com/$REPO_SLUG#install), or pass --bin-dir to copy the one from a release"

place() {  # place <src> <dst>
  if [ -e "$2" ] && [ "$UPGRADE" != 1 ]; then echo "keep   ${2#$DEST/}"; return; fi
  mkdir -p "$(dirname "$2")"; cp "$1" "$2"; echo "write  ${2#$DEST/}"
}

# Playbooks: in this repo (project scope, the default), or in your user folder (--global).
has_playbooks() { compgen -G "$1/yass-*/SKILL.md" >/dev/null; }
# An upgrade refreshes what's already installed, whatever flags it was installed with: the user
# folder's playbooks when the repo has none, and Claude's copies wherever they are.
if [ "$UPGRADE" = 1 ] && [ "$GLOBAL" = 0 ] && ! has_playbooks "$DEST/.agents/skills" &&
   has_playbooks "${YASS_SKILLS_DIR:-$HOME/.agents/skills}"; then
  GLOBAL=1; echo "note   no playbooks in this repo, so upgrading the ones in your user folder (as --global)"
fi
SKILLS="$DEST/.agents/skills"; CLAUDE_SKILLS="$DEST/.claude/skills"
if [ "$GLOBAL" = 1 ]; then SKILLS="${YASS_SKILLS_DIR:-$HOME/.agents/skills}"; CLAUDE_SKILLS="$HOME/.claude/skills"; fi
if [ "$UPGRADE" = 1 ] && [ "$CLAUDE" = 0 ] && has_playbooks "$CLAUDE_SKILLS"; then CLAUDE=1; fi

(cd "$SRC/kit" && find tools -type f | sort) | while read -r rel; do
  place "$SRC/kit/$rel" "$DEST/$rel"
done
chmod +x "$DEST/tools/yass/githooks/pre-commit"
for f in "$SRC"/kit/.agents/skills/yass-*/SKILL.md; do
  place "$f" "$SKILLS/$(basename "$(dirname "$f")")/SKILL.md"
done

if [ "$CLAUDE" = 1 ]; then
  for f in "$SRC"/kit/.agents/skills/yass-*/SKILL.md; do
    place "$f" "$CLAUDE_SKILLS/$(basename "$(dirname "$f")")/SKILL.md"
  done
  if ! grep -qs '@AGENTS.md' "$DEST/CLAUDE.md"; then
    { echo "@AGENTS.md"; if [ -f "$DEST/CLAUDE.md" ]; then echo; cat "$DEST/CLAUDE.md"; fi; } > "$DEST/CLAUDE.md.yass"
    mv "$DEST/CLAUDE.md.yass" "$DEST/CLAUDE.md"
    echo "write  CLAUDE.md (imports AGENTS.md)"
  fi
fi

cd "$DEST"
if [ -n "$YPATH" ]; then "$BIN" init --path "$YPATH"; else "$BIN" init; fi
if [ "$HOOKS" = 1 ]; then
  git config core.hooksPath tools/yass/githooks
  echo "hook   core.hooksPath = tools/yass/githooks (undo: git config --unset core.hooksPath)"
fi
if [ "$UPGRADE" = 1 ]; then
cat <<'EOF'

YASS is upgraded; your changes weren't touched. Next:
  1. Review and commit it:  git add -A && git commit -m "chore: upgrade YASS"
  2. `yass status` checks your changes with the new version.
EOF
echo "  3. What changed, and how to migrate if anything needs it: https://github.com/$REPO_SLUG/releases"
else
cat <<'EOF'

YASS is set up. Next:
  1. Commit it:  git add -A && git commit -m "chore: adopt YASS"
  2. Ask your agent to start something:
       small:  "use yass-work to fix <bug>"
       large:  "use yass-shape to plan <feature>"
  3. `yass status` shows what's in flight.
EOF
fi

# Last, so it isn't scrolled away: you, the hook and your agents run `yass` from PATH, so say if
# that finds nothing, or a different yass than the one just installed, and how to fix it.
BIN_DIR_ABS="$(cd "$(dirname "$BIN")" && pwd)"
ON_PATH="$(command -v yass || true)"
home() { case "$1" in "$HOME"/*) echo "\$HOME${1#"$HOME"}" ;; *) echo "$1" ;; esac; }
if [ -n "$ON_PATH" ] && [ -z "$BIN_DIR" ] && [ "$(cd "$(dirname "$ON_PATH")" && pwd)" != "$BIN_DIR_ABS" ]; then
  # Nothing was copied anywhere; BIN is next to this script (an unpacked release or a clone), so
  # don't suggest putting that folder on PATH. Replacing the yass that's already there is the fix.
  echo
  echo "WARNING: \`yass\` on your PATH is $ON_PATH, not the one this script used ($BIN)."
  echo "  To replace it, run this script again with:  --bin-dir $(home "$(dirname "$ON_PATH")")"
elif [ -z "$ON_PATH" ] || [ "$(cd "$(dirname "$ON_PATH")" && pwd)" != "$BIN_DIR_ABS" ]; then
  d="$(home "$BIN_DIR_ABS")"
  case "$(basename "${SHELL:-}")" in
    zsh)  fix="echo 'export PATH=\"$d:\$PATH\"' >> ~/.zshrc" ;;
    bash) if [ "$(uname -s)" = Darwin ]; then rc="~/.bash_profile"; else rc="~/.bashrc"; fi
          fix="echo 'export PATH=\"$d:\$PATH\"' >> $rc" ;;
    fish) fix="fish_add_path $d" ;;
    *)    fix="echo 'export PATH=\"$d:\$PATH\"' >> ~/.profile" ;;
  esac
  echo
  if [ -z "$ON_PATH" ]; then echo "WARNING: yass isn't on your PATH, so you, the hook and your agents can't run it."
  else echo "WARNING: \`yass\` on your PATH is $ON_PATH, not the one just installed in $BIN_DIR_ABS."; fi
  echo "  Fix it with:  $fix"
  echo "  then open a new terminal."
fi
