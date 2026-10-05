#!/usr/bin/env bash
# End-to-end test: installs YASS into throwaway repos and walks the lifecycle, including the optional hook.
# Usage: tests/e2e.sh [workdir]
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
W="${1:-$(mktemp -d)}"; rm -rf "$W/e2e"; mkdir -p "$W/e2e"
unset YASS_STRICT YASS_HOOK YASS_HOME
# Build the CLI (or use $YASS_BIN) and put it first on PATH, where the hook and install.sh look for it.
if [ -z "${YASS_BIN:-}" ]; then
  mkdir -p "$W/bin"; (cd "$ROOT" && go build -o "$W/bin/yass" ./cmd/yass) || { echo "build failed"; exit 1; }
  YASS_BIN="$W/bin/yass"
fi
export YASS_BIN; export PATH="$(dirname "$YASS_BIN"):$PATH"
pass=0; fail=0
ok()  { echo "  ok   $1"; pass=$((pass+1)); }
bad() { echo "  FAIL $1"; fail=$((fail+1)); }
run_ok()   { local d="$1"; shift; local o; if o="$("$@" 2>&1)"; then ok "$d"; else bad "$d"; sed 's/^/       /' <<<"$o" | head -20; fi; }
run_fail() { local d="$1"; shift; local o; if o="$("$@" 2>&1)"; then bad "$d (should have failed)"; sed 's/^/       /' <<<"$o" | head -20; else ok "$d"; fi; }
has()   { local d="$1" p="$2"; shift 2; local o; o="$("$@" 2>&1)"; if grep -qE -- "$p" <<<"$o"; then ok "$d"; else bad "$d (no /$p/)"; sed 's/^/       /' <<<"$o" | head -25; fi; }
hasnt() { local d="$1" p="$2"; shift 2; local o; o="$("$@" 2>&1)"; if grep -qE -- "$p" <<<"$o"; then bad "$d (found /$p/)"; sed 's/^/       /' <<<"$o" | head -25; else ok "$d"; fi; }
y() { yass "$@"; }
# portable in-place regex edit (GNU and BSD): sub FILE PATTERN REPLACEMENT [COUNT]
sub() { P="$2" R="$3" N="${4:-0}" perl -0777 -i -pe '
  BEGIN { ($p, $r, $n) = ($ENV{P}, $ENV{R}, $ENV{N}); $r =~ s/\\n/\n/g }
  if ($n) { my $c = 0; s/$p/$c++ < $n ? $r : $&/gme } else { s/$p/$r/gm }' "$1"; }
newrepo() { rm -rf "$1"; mkdir -p "$1"; cd "$1"; git init -q -b main; git config user.email t@t; git config user.name Sam
  echo app > app.txt; git add -A; git commit -q -m "existing app"; }
TODAY=$(date +%F)

newrepo "$W/e2e/solo"
INSTALL_OUT="$(y init)"

echo "1. install"
has   "a first install suggests the adopting commit" "chore: adopt YASS" echo "$INSTALL_OUT"
for f in tools/yass/githooks/pre-commit yass/README.md yass/changes/.gitkeep \
         yass/archive/.gitkeep AGENTS.md .agents/skills/yass-work/SKILL.md .agents/skills/yass-shape/SKILL.md \
         .agents/skills/yass-plan/SKILL.md .agents/skills/yass-status/SKILL.md .agents/skills/yass-log/SKILL.md; do
  [ -e "$f" ] && ok "has $f" || bad "missing $f"
done
[ ! -e .claude ] && ok "no Claude files without --claude" || bad ".claude written without --claude"
[ ! -e yass/config.yml ] && ok "no config file" || bad "a config file appeared"
has   "AGENTS.md has the YASS section" "yass:begin" cat AGENTS.md
hasnt "the hook is off by default" "githooks" git config core.hooksPath
has   "status on an empty repo" "no active changes" y
has   "init is idempotent" "already set up" y init
git add -A; run_ok "adopting commit" git commit -q -m "chore: adopt YASS"
echo "# My rules" > AGENTS.md; y init >/dev/null
has   "init keeps your AGENTS.md content" "# My rules" cat AGENTS.md
has   "…and adds its section once" "^1$" bash -c 'grep -c "yass:begin" AGENTS.md'
y init >/dev/null
has   "…even when run again" "^1$" bash -c 'grep -c "yass:begin" AGENTS.md'
git checkout -q AGENTS.md

echo "2. a small change"
P=$(y new "Fix double-tap save" --source gh#41 --platforms "ios, android" --goal "Tapping Save twice saves once.")
has "dated folder" "^yass/changes/$TODAY-fix-double-tap-save$" echo "$P"
has "source recorded" "^source: gh#41" cat "$P/change.md"
has "platforms recorded" "^platforms: \[ios, android\]" cat "$P/change.md"
has "goal written" "Tapping Save twice saves once." cat "$P/change.md"
has "title heading" "^# Fix double-tap save" cat "$P/change.md"
P2=$(y new "Fix double-tap save")
has "same title same day gets a suffix" "fix-double-tap-save-2$" echo "$P2"
rm -rf "$P2"
sub "$P/change.md" '^## Acceptance\n' '## Acceptance\n- [ ] Given Save tapped twice, when saving, then one entry — verify: unit SaveTests\n'
has   "a fresh change is not started" "fix-double-tap-save +0/1 +not started" y status
has   "…in the detail view too" "progress: 0/1  \(not started\)" y status double-tap
sub "$P/change.md" '^- \[ \] $' '- [x] Reproduce\n- [ ] Disable Save while saving'
hasnt "a ticked box starts it" "not started" y status
has "status shows progress and next" "fix-double-tap-save +1/3 +next: Given Save tapped twice" y status
printf '\n### %s (claude)\n- Did: reproduced\n- Next: disable the button\n' "$TODAY" >> "$P/change.md"
has "next comes from the Log when there is one" "next: disable the button" y status
has "detail view lists open boxes" "\[ \] Disable Save while saving" y status double-tap
has "detail view shows source" "source: gh#41" y status double-tap
git add -A; git commit -q -m "yass: new change"
sub "$P/change.md" '^- \[ \] Disable' '- [/] Disable'
has      "an in-progress box isn't done" "fix-double-tap-save +1/3" y status
has      "…and the detail view marks it" "\[/\] Disable Save while saving" y status double-tap
run_fail "archive refuses with open boxes" y archive double-tap
has      "…and says which, in progress included" "2 box\(es\) still open" y archive double-tap
sub "$P/change.md" '^- \[ \] Given' '- [x] Given'; sub "$P/change.md" '^- \[/\] Disable' '- [-] Disable'
has      "a dropped box doesn't count" "fix-double-tap-save +2/2" y status
has      "every box done or dropped: done" "fix-double-tap-save +2/2 +done" y status
has      "…in the detail view too" "progress: 2/2  \(done\)" y status double-tap
git commit -qam "progress"
run_ok   "archive once every box is done or dropped" y archive double-tap
[ -d "yass/archive/$TODAY-fix-double-tap-save" ] && ok "moved to the archive" || bad "not in the archive"
[ ! -e "$P" ] && ok "gone from changes" || bad "still in changes"
has      "the move is staged" "R.*fix-double-tap-save/change.md" git status --porcelain
has      "archived listing" "$TODAY-fix-double-tap-save" y status --archived
has      "an archived change in detail" "progress: 2/2  \(done\)" y status --archived double-tap
run_fail "…but not without --archived" y status double-tap
git commit -qm "yass: archive fix-double-tap-save"

echo "3. a large change with pieces"
L=$(y new "Offline sync" --large --design --goal "Never lose an entry.")
for f in change.md prd.md plan.md design.md; do [ -f "$L/$f" ] && ok "large has $f" || bad "large lacks $f"; done
hasnt "large head has no Steps" "^## Steps" cat "$L/change.md"
Q=$(y new "Offline queue" --in offline-sync)
B=$(y new "Sync badge" --in offline)
has "pieces live inside" "^$L/$TODAY-offline-queue$" echo "$Q"
run_fail "pieces nest one level deep" y new "Too deep" --in offline-queue
run_fail "a piece can't be large" y new "Big piece" --large --in offline-sync
has   "template prints one" "^## Options" y template design
run_fail "…and refuses an unknown one" y template nope
has "status nests pieces" "├ $TODAY-offline-queue" y status
has "large is labelled" "offline-sync  \(large\)" y status
printf '### M1\n- [x] AC1 (R1) Given no network — verify: e2e\n- [ ] AC2 (R2) Given a kill — verify: e2e\n' >> "$L/plan.md"
sub "$Q/change.md" '^- \[ \] $' '- [x] Queue table\n- [ ] Worker'
sub "$B/change.md" '^- \[ \] $' '- [ ] Badge'
has "large progress rolls up its pieces" "offline-sync  \(large\) +2/5" y status
has "pieces show their own" "offline-queue +1/2" y status
has   "a piece with no work is not started" "sync-badge +0/1 +not started" y status
hasnt "…but its change is, once any piece is" "offline-sync  \(large\) .*not started" y status
sub "$B/change.md" '^- \[ \] Badge' '- [/] Badge'
hasnt "an in-progress box starts it" "sync-badge .*not started" y status
has   "…and becomes next when the Log has none" "sync-badge .*next: Badge" y status
run_fail "a piece can't be archived alone" y archive offline-queue
has      "…it goes with its change" "archived with their change" y archive offline-queue
run_fail "archive refuses open boxes in pieces" y archive offline-sync
has      "…and names the piece" "Worker  \($TODAY-offline-queue/change.md\)" y archive offline-sync
git add -A; git commit -q -m "yass: offline sync"
run_ok   "--force archives anyway" y archive offline-sync --force
[ -f "yass/archive/$TODAY-offline-sync/$TODAY-sync-badge/change.md" ] && ok "pieces moved along" || bad "pieces left behind"
git commit -qm "yass: archive offline-sync"

echo "4. blocked, follows, warnings"
F=$(y new "Offline sync, web badge" --follows "$TODAY-offline-sync")
hasnt "follows an archived change: no warning" "warning" y status
sub "$F/change.md" '^blocked:$' 'blocked: waiting on design review'
sub "$F/change.md" '^- \[ \] $' '- [x] Spike'
has "blocked shows in status" "BLOCKED: waiting on design review" y status
run_fail "archive refuses a blocked change" y archive web-badge
G=$(y new "Something else" --follows 2020-01-01-nope)
has "follows something missing: warning" "warning: .*follows '2020-01-01-nope'" y status
run_fail "--strict fails on warnings" y status --strict
rm -rf "$G"
mkdir -p yass/changes/random-folder && echo "x" > yass/changes/random-folder/notes.md
has "a folder with no change.md" "random-folder: no change.md" y status
has "an undated folder name" "random-folder: name it" y status
rm -rf yass/changes/random-folder
mkdir -p "$Q" 2>/dev/null; mkdir -p "yass/changes/$TODAY-x/$TODAY-y/$TODAY-z"
for d in "$TODAY-x" "$TODAY-x/$TODAY-y" "$TODAY-x/$TODAY-y/$TODAY-z"; do printf -- '---\n---\n# t\n' > "yass/changes/$d/change.md"; done
has "nesting deeper than one level" "pieces nest one level deep" y status
rm -rf "yass/changes/$TODAY-x" "$Q"; rmdir "$L" 2>/dev/null || true
run_fail "unknown change" y status nope-nothing
E=$(y new "Empty one")
run_fail "archive refuses a change with no boxes" y archive empty-one
sub "$E/change.md" '^blocked:$' 'blocked:    # set when stuck'
sub "$E/change.md" '^follows:.*$' "follows: $TODAY-sync-badge   # an archived piece"
printf '### %s (claude)\n- **Next:** bold next step\n' "$TODAY" >> "$E/change.md"
hasnt "frontmatter comments are ignored" "empty-one .*BLOCKED|^warning" y status
has   "follows can name an archived piece" "empty-one" y status
has   "a bold **Next:** is read" "next: bold next step" y status
rm -rf "$E"
y new "Web cache" >/dev/null; y new "Web fonts" >/dev/null
has "ambiguous name" "matches [0-9]+ changes" y status web
rm -rf yass/changes/*web-cache yass/changes/*web-fonts
git add -A; git commit -qm "yass: follow-up"

echo "5. monorepo: several yass/ folders, no config"
mkdir -p services/payments && echo "# Payments" > services/payments/README.md
run_ok "init a team folder" y init services/payments
[ -d services/payments/yass/changes ] && ok "team yass/ created" || bad "team yass/ missing"
has    "AGENTS.md section not duplicated" "^1$" bash -c 'grep -c "yass:begin" AGENTS.md'
has    "new goes to the nearest yass/" "^services/payments/yass/changes/$TODAY-saved-cards-api$" bash -c 'cd services/payments && yass new "Saved cards API"'
has    "…and from the repo root, to the root yass/" "^yass/changes/$TODAY-three-tap-checkout$" y new "Three-tap checkout"
has    "status shows every yass/ folder" "services/payments/yass/" y status
has    "…root first" "^yass/$" bash -c 'yass status | head -1'
has    "detail by name across folders" "Saved cards API" y status saved-cards
git add -A; git commit -qm "monorepo"

echo "6. the optional hook"
git config core.hooksPath tools/yass/githooks
H=$(y new "Hook demo" --large)
printf '### M1\n- [ ] AC1 (R1) Given x, when y, then z — verify: unit\n' >> "$H/plan.md"
sub "$H/change.md" '^## Goal\n' '## Goal\nDemo the hook.\n'
git add -A; run_ok "intent-only commit" git commit -q -m "yass: plan hook demo"
hasnt "…without a warning" "yass:" bash -c "echo x >> README2.md; git add -A; git commit -q -m readme 2>&1"
echo "code1" >> app.txt; sub "$H/plan.md" '^- \[ \] AC1' '- [x] AC1'
printf '\n## Log\n### %s (claude)\n- Did: x\n- Next: y\n' "$TODAY" >> "$H/change.md"
git add -A
hasnt "ticking a plan box + Log + code: silent" "heads-up" git commit -q -m "feat: thing"
echo "code2" >> app.txt; echo "- **R9** new" >> "$H/prd.md"; git add -A
has   "prd edit + code: warns" "prd.md is intent" git commit -q -m "feat: sneaky"
has   "…but the commit went through" "feat: sneaky" git log -1 --format=%s
echo "code3" >> app.txt; echo "more" >> "$H/prd.md"; git add -A
run_fail "YASS_STRICT=1 refuses it" env YASS_STRICT=1 git commit -q -m "feat: sneaky 2"
run_ok   "YASS_HOOK=off skips it" env YASS_HOOK=off git commit -q -m "feat: skip"
echo "code4" >> app.txt; sub "$H/plan.md" 'when y, then z' 'when y, then maybe z'; git add -A
has   "rewording an acceptance criterion + code: warns" "only mark boxes in plan.md" git commit -q -m "feat: reword"
echo "code5" >> app.txt; sub "$H/change.md" 'Demo the hook.' 'Demo the hook, roughly.'; git add -A
has   "editing a Goal + code: warns" "title, Goal or Acceptance changed" git commit -q -m "feat: goal"
S=$(y new "Small one"); git add -A; git commit -q -m "yass: small one"
echo "code6" >> app.txt; sub "$S/change.md" '^- \[ \] $' '- [x] Step one\n- [ ] Step two'
sub "$S/change.md" '^## Decisions\n' '## Decisions\n- Do it simply - because (claude)\n'; git add -A
hasnt "adding Steps and Decisions + code: silent" "heads-up" git commit -q -m "feat: small"
echo "code7" >> app.txt; N=$(y new "Brand new"); git add -A
hasnt "a new change + code: silent" "heads-up" git commit -q -m "feat: with new change"
git add -A; git commit -q -m "progress" >/dev/null 2>&1 || true
y archive hook-demo --force >/dev/null; echo "code8" >> app.txt; git add -A
has   "archiving + code: warns" "archive a change in its own commit" git commit -q -m "feat: archive and code"
y archive brand-new --force >/dev/null; git add -A
hasnt "archiving alone: silent" "heads-up" git commit -q -m "yass: archive brand-new"
echo "x" > "yass/archive/$TODAY-fix-double-tap-save/notes.md"; git add -A
has   "adding a file to an archived change warns" "the archive is append-only" git commit -q -m "yass: add notes"
echo "edit" >> "yass/archive/$TODAY-fix-double-tap-save/change.md"; git add -A
has   "editing the archive warns, even alone" "the archive is append-only" git commit -q -m "yass: fix typo"
BASE=$(git rev-list --max-parents=0 HEAD)
has      "CI range mode finds the mixed commits" "feat: sneaky: .*prd.md is intent" yass hook --range "$BASE..HEAD"
run_fail "CI range mode with --strict fails" yass hook --range "$BASE..HEAD" --strict
D=$(y new "Drop demo"); sub "$D/change.md" '^## Acceptance\n' '## Acceptance\n- [ ] Given a, when b, then c — verify: unit\n'
git add -A; git commit -q -m "yass: drop demo"
echo "code9a" >> app.txt; sub "$D/change.md" '^- \[ \] Given a' '- [/] Given a'; git add -A
hasnt "marking a criterion in progress + code: silent" "heads-up" git commit -q -m "feat: start it"
echo "code9" >> app.txt; sub "$D/change.md" '^- \[/\] Given a' '- [-] Given a'; git add -A
has   "dropping an acceptance criterion + code: warns" "title, Goal or Acceptance changed" git commit -q -m "feat: drop it"
run_fail "a range CI can't read fails loudly" yass hook --range origin/nope..HEAD --strict
CLEAN=$(git rev-parse HEAD~1)   # "yass: drop demo": a new change, no code
run_ok   "a clean range passes" yass hook --range "$CLEAN~1..$CLEAN" --strict
git config --unset core.hooksPath

echo "7. edge cases"
echo "build/" > .gitignore; mkdir -p build/x
has "init warns when the folder is gitignored" "ignored by .gitignore" y init build/x --no-agents
rm -rf build .gitignore
mkdir -p infra/target && y init infra/target --no-agents >/dev/null
has "folders git doesn't ignore are found, whatever their name" "^infra/target/yass/changes/" bash -c 'cd infra/target && yass new "Infra thing"'
rm -rf infra
NG="$W/e2e/nogit"; rm -rf "$NG"; mkdir -p "$NG/sub/deeper"
(cd "$NG" && yass init --no-agents >/dev/null && yass new "Outside git" >/dev/null)
has "outside git, status from a subfolder finds yass/" "outside-git" bash -c "cd '$NG/sub/deeper' && yass status"
cd "$W/e2e/solo"
R=$(y new "Windows endings")
printf -- '---\r\nblocked: waiting on QA\r\n---\r\n# Windows endings\r\n\r\n## Steps\r\n- [x] a\r\n- [ ] b\r\n\r\n## Log\r\n### 2026-10-03 (c)\r\n- Next: from the log\r\n' > "$R/change.md"
has   "CRLF files: frontmatter is read" "windows-endings .*BLOCKED: waiting on QA" y status
sub "$R/change.md" '^blocked: waiting on QA' 'blocked:'
has   "…and the Log" "windows-endings .*next: from the log" y status
rm -rf "$R"
N=$(y new "With notes" --source "gh issue #41"); sub "$N/change.md" '^- \[ \] $' '- [x] The work'
mkdir -p "$N/notes" && printf -- '- [ ] an idea for later\n' > "$N/notes/ideas.md"
has      "a # inside a value isn't a comment" "source: gh issue #41" y status with-notes
has      "boxes in a subfolder that isn't a piece don't count" "with-notes .*1/1  done" y status
run_ok   "…for archive either" y archive with-notes
rm -rf "yass/archive/$TODAY-with-notes"; git add -A >/dev/null
A=$(y new "All dropped"); sub "$A/change.md" '^- \[ \] $' '- [-] Not needed after all'
has      "every box dropped: done" "all-dropped .*done" y status
run_ok   "…and it can be archived" y archive all-dropped
rm -rf "yass/archive/$TODAY-all-dropped"; git add -A >/dev/null
mkdir -p "apps/café"; y init "apps/café" --no-agents >/dev/null
has   "non-ASCII folder names: new goes to the nearest yass/" "^apps/café/yass/changes/$TODAY-accented$" bash -c 'cd "apps/café" && yass new "Accented" --large'
has   "…and status lists it" "^apps/café/yass/$" y status
git add -A; git commit -qm "yass: accented" >/dev/null
echo "code" >> app.txt; echo "- **R9** more" >> "apps/café/yass/changes/$TODAY-accented/prd.md"; git add -A
has   "…and the hook sees intent edits there" "café/yass/changes/$TODAY-accented/prd.md: prd.md is intent" yass hook
git commit -qm "feat: mixed" >/dev/null 2>&1
rm -rf "apps"; git add -A; git commit -qm "chore: tidy" >/dev/null

echo "8. install.sh installs the binary"
newrepo "$W/e2e/claude"
y init --claude --hooks >/dev/null
[ -f .claude/skills/yass-work/SKILL.md ] && ok "--claude copies the playbooks" || bad "no .claude/skills"
has "--claude imports AGENTS.md" "^@AGENTS.md" cat CLAUDE.md
has "--hooks sets the hook path" "tools/yass/githooks" git config core.hooksPath
git add -A; hasnt "the adopting commit isn't flagged" "heads-up" git commit -q -m "chore: adopt YASS"
BD="$W/e2e/bindir"; rm -rf "$BD" "$W/e2e/bindir2" "$W/e2e/bindir3" "$W/e2e/bindir4" "$W/e2e/onebin" "$W/e2e/nobin"
IOUT="$(bash "$ROOT/install.sh" --bin-dir "$BD")"
has   "--bin-dir copies the binary" "installed yass .* to .*/bindir/yass" echo "$IOUT"
[ -x "$BD/yass" ] && ok "…and it runs" || bad "no binary in --bin-dir"
[ -z "$(git status --porcelain)" ] && ok "…and, run in a repo that uses YASS, changes nothing there (joining a repo)" || bad "install.sh changed the repo: $(git status --porcelain)"
has   "…and says yass init sets up a repo" "yass init .*set it up" echo "$IOUT"
mkdir -p "$W/e2e/plain"; rm -rf "$W/e2e/plain/"*
run_ok "…run outside a repo too" bash -c 'cd "$1" && bash "$2" --bin-dir "$3"' _ "$W/e2e/plain" "$ROOT/install.sh" "$W/e2e/bindir3"
[ -z "$(ls -A "$W/e2e/plain")" ] && ok "…writing nothing where it's run" || bad "install.sh wrote into the folder it ran in"
has   "…and warns that another yass on PATH comes first" "is .*, not the one just installed" bash "$ROOT/install.sh" --bin-dir "$BD"
has   "…or that --bin-dir isn't on PATH" "bindir2 isn't on your PATH" \
      env PATH=/usr/bin:/bin SHELL=/bin/zsh bash "$ROOT/install.sh" --bin-dir "$W/e2e/bindir2"
has   "…with the fix for the shell" "Fix it with:  echo 'export PATH=\".*/bindir2:\\\$PATH\"' >> ~/.zshenv" \
      env PATH=/usr/bin:/bin SHELL=/bin/zsh bash "$ROOT/install.sh" --bin-dir "$W/e2e/bindir2"
hasnt "no warning when the installed yass is the one on PATH" "WARNING" env PATH="$BD:/usr/bin:/bin" bash "$ROOT/install.sh" --bin-dir "$BD"
has   "…and it says so" "it's on your PATH" env PATH="$BD:/usr/bin:/bin" bash "$ROOT/install.sh" --bin-dir "$BD"
run_fail "an old-style install (a repo and setup options) refuses" bash "$ROOT/install.sh" . --claude --bin-dir "$W/e2e/nobin"
[ ! -e "$W/e2e/nobin" ] && ok "…before installing anything" || bad "an old-style install installed the binary"
has   "…printing the commands to use, options carried over" "^  yass init --claude$" bash "$ROOT/install.sh" . --claude --bin-dir "$W/e2e/nobin"
has   "…a repo path becoming a cd" "^  cd apps/web && yass init --hooks --path \.\./p$" bash "$ROOT/install.sh" apps/web --hooks --path ../p
has   "…and --upgrade pointing at yass upgrade" "^  yass upgrade$" bash "$ROOT/install.sh" --upgrade
has   "…after the binary install" "^  install.sh --bin-dir ~/.local/bin$" bash "$ROOT/install.sh" --global
run_fail "without --bin-dir it refuses" bash "$ROOT/install.sh"
has   "…and says what to pass" "pass --bin-dir" bash "$ROOT/install.sh"
has   "a piped install without --bin-dir stops before downloading" "pass --bin-dir" \
      bash -c 'env -u YASS_BIN PATH=/usr/bin:/bin bash -s < "$1"' _ "$ROOT/install.sh"
U="$W/e2e/unpacked"; rm -rf "$U"; mkdir -p "$U"; cp "$ROOT/install.sh" "$U/"; cp "$YASS_BIN" "$U/yass"
has   "an unpacked release with no kit/ installs its binary" "installed yass .* to .*/bindir4/yass" \
      env -u YASS_BIN PATH=/usr/bin:/bin bash "$U/install.sh" --bin-dir "$W/e2e/bindir4"
K="$W/e2e/script-only"; rm -rf "$K"; mkdir -p "$K"; cp "$ROOT/install.sh" "$K/"
run_fail "no binary next to the script: refuses" env -u YASS_BIN PATH=/usr/bin:/bin bash "$K/install.sh" --bin-dir "$W/e2e/nobin"
has      "…and says how to get one" "no yass binary next to this script" env -u YASS_BIN PATH=/usr/bin:/bin bash "$K/install.sh" --bin-dir "$W/e2e/nobin"
newrepo "$W/e2e/oneliner"
run_ok "the one-liner's two commands set up a repo, with --bin-dir not on PATH" \
       env PATH=/usr/bin:/bin bash -c 'bash "$1" --bin-dir "$2" >/dev/null && "$2/yass" init >/dev/null' _ "$ROOT/install.sh" "$W/e2e/onebin"
[ -f .agents/skills/yass-work/SKILL.md ] && [ -x tools/yass/githooks/pre-commit ] && ok "…playbooks, hook and all" || bad "the one-liner didn't set up the repo"
newrepo "$W/e2e/bare"
run_fail "new before init explains itself" y new "x"
has      "…with the fix" "run .*yass init" y new "x"

echo "9. yass.yaml: the yass folder lives somewhere else"
newrepo "$W/e2e/ext"; rm -rf "$W/e2e/ext-yass" "$W/e2e/home-yass"
y init --path ../ext-yass >/dev/null
[ -f yass.yaml ] && ok "--path writes yass.yaml" || bad "no yass.yaml"
[ -L yass ] && [ -z "$(git status --porcelain -- yass)" ] && ok "…and yass/ in the repo is only an ignored link" || bad "yass/ isn't an ignored link"
[ -d "$W/e2e/ext-yass/changes" ] && ok "…and creates the folder it points to" || bad "no external folder"
has   "root prints it" "ext-yass$" y root
X=$(y new "Private thing")
has   "new puts changes there" "^/.*ext-yass/changes/$TODAY-private-thing$" echo "$X"
sub "$X/change.md" '^- \[ \] $' '- [x] Did it'
has   "status reads them" "private-thing +1/1 +done" y status
git add -A; git commit -q -m "chore: adopt YASS"
hasnt "none of it lands in the repo" "private-thing" git log --stat --format=
run_ok "archive works outside git" y archive private-thing
[ -d "$W/e2e/ext-yass/archive/$TODAY-private-thing" ] && ok "…and moves the folder" || bad "not archived"
MAIN_SHA=$(git rev-parse --short HEAD)
git switch -q -c feature; echo wip >> app.txt; git commit -qam "feat: wip"; FEAT_SHA=$(git rev-parse --short HEAD); git switch -q main
C=$(y new "Cited")
sub "$C/change.md" '^- \[ \] $' "- [x] Shipped — code: $MAIN_SHA\n- [/] Building — code: $FEAT_SHA"
hasnt "citing a merged commit when done, a branch commit in progress: fine" "warning" y status
sub "$C/change.md" '^- \[/\] Building' '- [x] Building'
has   "done, citing a commit that isn't merged: warns" "'Building' is marked done, but $FEAT_SHA isn't on main yet" y status
has   "…in the detail view too" "isn't on main yet" y status cited
printf "path: ../ext-yass\nbranch: feature\n" > yass.yaml
hasnt "branch: in yass.yaml sets what counts as merged" "isn't on" y status
printf "path: ../ext-yass\nbranch: nope\n" > yass.yaml
has   "…and warns when it doesn't exist" "branch 'nope' isn't in this repo" y status
printf "path: ../ext-yass\n" > yass.yaml
sub "$C/change.md" "code: $MAIN_SHA" 'code: deadbee'
has   "citing a commit that doesn't exist: warns" "cites deadbee, which isn't a commit here" y status
rm -rf "$C"
printf 'path: ${YASS_HOME}/proj\n' > yass.yaml
has   "an unset variable warns" "YASS_HOME isn't set" y status
run_fail "…and new refuses" y new "Nope"
run_ok "init creates the folder under the variable" env YASS_HOME="$W/e2e/home-yass" yass init --no-agents
has   "…and root resolves it" "home-yass/proj$" env YASS_HOME="$W/e2e/home-yass" yass root
printf 'path: proj\ncolor: blue\n' > yass.yaml; mkdir -p proj/changes
has   "unknown settings warn" "unknown setting 'color'" y status
rm -rf proj; printf 'path: planning\n' > yass.yaml; y init --no-agents >/dev/null
P=$(y new "Planned here" --large)
has   "a relative path is relative to yass.yaml" "^planning/changes/$TODAY-planned-here$" echo "$P"
git add -A; git commit -q -m "yass: shape planned here"
git config core.hooksPath tools/yass/githooks
echo code >> app.txt; echo "- **R9** more" >> "$P/prd.md"; git add -A
has   "the hook finds a yass folder through yass.yaml" "prd.md is intent" git commit -q -m "feat: sneaky"
echo code >> app.txt; git add -A
hasnt "…and treats yass.yaml as YASS, not code" "heads-up" git commit -q -m "feat: plain code"
git config --unset core.hooksPath
has   "a link left from before the plans moved into the repo warns" "yass/ is a link to .*, but yass.yaml points to planning; remove the link" y status
rm yass; mkdir -p yass/changes && touch yass/changes/.gitkeep
has   "a yass/ beside a yass.yaml that points elsewhere warns" "yass/: ignored, because yass.yaml points to" y status
rm -rf yass

echo "10. yass.yaml beside yass/: settings only, and ignore"
newrepo "$W/e2e/ign"
y init >/dev/null
mkdir -p examples/a/yass/archive/2026-01-01-old examples/b/svc/yass/changes/2026-01-02-thing vendor/x/yass/changes
printf '# Old\n\n## Goal\nOld.\n\n## Steps\n- [x] Done\n' > examples/a/yass/archive/2026-01-01-old/change.md
printf '# Thing\n\n## Goal\nA thing.\n\n## Steps\n- [ ] Do it\n' > examples/b/svc/yass/changes/2026-01-02-thing/change.md
touch vendor/x/yass/changes/.gitkeep
git add -A; git commit -q -m "chore: adopt YASS, with examples"
has   "without ignore, nested yass folders count" "examples/b/svc/yass" y root
printf 'ignore:\n  - examples/*\n  - vendor\n' > yass.yaml
has   "a yass.yaml without path: keeps yass/ next to it" "^$W/e2e/ign/yass$|/ign/yass$" y root
hasnt "…and ignored folders aren't roots" "examples|vendor" y root
hasnt "…or in status" "thing|examples" y status
hasnt "…and nothing warns" "warning|ignored, because" y status
X=$(y new "Top thing")
has   "new still goes to yass/" "^yass/changes/$TODAY-top-thing$" echo "$X"
has   "inside an ignored folder, it's a project of its own" "thing" bash -c 'cd examples/b && yass status'
hasnt "…without the outer yass/" "top-thing" bash -c 'cd examples/b && yass status'
has   "…and new goes to its nearest yass/" "^svc/yass/changes/$TODAY-inner$" bash -c 'cd examples/b/svc && yass new "Inner"'
rm -rf examples/b/svc/yass/changes/$TODAY-inner
git add -A; git commit -q -m "yass: top thing"
git config core.hooksPath tools/yass/githooks
echo code >> app.txt; echo "- [x] Rewritten" >> examples/a/yass/archive/2026-01-01-old/change.md
sub examples/b/svc/yass/changes/2026-01-02-thing/change.md '^A thing\.$' 'A different thing.'
git add -A
mv yass.yaml "$W/e2e/ign.yaml"
has   "without ignore, the hook flags those edits" "append-only" y hook
mv "$W/e2e/ign.yaml" yass.yaml
hasnt "the hook treats ignored folders as ordinary files" "heads-up" git commit -q -m "feat: code and example edits"
git config --unset core.hooksPath
printf 'ignore: [../elsewhere, ".", nope/*, missing]\n' > yass.yaml
has   "an ignore outside the folder warns" "'../elsewhere' isn't inside" y status
has   "…so does the folder itself" "'\.' is the folder yass.yaml is in" y status
has   "…and one that matches nothing" "'missing' doesn't match a folder" y status

echo "11. queue.md: the order to tackle changes in"
newrepo "$W/e2e/queue"
y init >/dev/null
mk() { mkdir -p "$1"; printf '# %s\n\n## Goal\nIt.\n\n## Steps\n- [%s] Do it\n' "$(basename "$1")" "${2:- }" > "$1/change.md"; }
mk yass/changes/2026-01-01-alpha; mk yass/changes/2026-02-01-bravo; mk yass/changes/2026-03-01-charlie; mk yass/changes/2026-04-01-delta x
mk yass/changes/2026-03-01-charlie/2026-03-02-piece; mk yass/archive/2025-12-01-old x
git add -A; git commit -q -m "chore: adopt YASS"
order() { yass status | grep -oE '^ *[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z]+' | tr -d ' ' | paste -sd, -; }
has   "without queue.md, changes are in date order" "^2026-01-01-alpha,2026-02-01-bravo,2026-03-01-charlie,2026-04-01-delta$" order
printf '# Queue\nTop first.\n\n1. 2026-03-01-charlie — first\n2. `2026-01-01-alpha`\n' > yass/queue.md
has   "queue.md order first, then the rest by date" "^2026-03-01-charlie,2026-01-01-alpha,2026-02-01-bravo,2026-04-01-delta$" order
hasnt "…and nothing warns" "warning" y status
git add -A; git commit -q -m "yass: queue"
printf '\n- 2026-09-09-nope\n- 2025-12-01-old\n- 2026-03-02-piece\n- 2026-01-01-alpha\n' >> yass/queue.md
has   "an unknown entry warns" "'2026-09-09-nope' isn't a change in yass/changes" y status
has   "…an archived one" "'2025-12-01-old' is archived" y status
has   "…a piece" "'2026-03-02-piece' is a piece of 2026-03-01-charlie" y status
has   "…and a repeat" "'2026-01-01-alpha' is listed more than once" y status
run_fail "…and --strict fails" y status --strict
git checkout -q yass/queue.md
mkdir -p svc && y init svc --no-agents >/dev/null; mk svc/yass/changes/2026-01-01-one; mk svc/yass/changes/2026-02-01-two
printf -- '- 2026-02-01-two\n' > svc/yass/queue.md
has   "each yass folder follows its own queue.md" "2026-02-01-two,2026-01-01-one" order
hasnt "…without warnings across folders" "warning" y status
rm -rf svc
printf '1. 2026-04-01-delta — done, ready\n2. 2026-03-01-charlie — first\n3. `2026-01-01-alpha`\n' > yass/queue.md
git add -A; git commit -q -m "yass: rank delta"
has   "archive takes a change off queue.md" "took it off yass/queue.md" y archive delta
has   "…keeping the other lines" "^2. 2026-03-01-charlie — first$" head -1 yass/queue.md
has   "…and stages the edit with the move" "^M  yass/queue.md$" git status --short
git commit -q -m "yass: archive delta"
git config core.hooksPath tools/yass/githooks
echo code >> app.txt; printf '1. `2026-01-01-alpha`\n2. 2026-03-01-charlie\n' > yass/queue.md; git add -A
has   "the hook flags reordering queue.md with code" "queue.md is intent" git commit -q -m "feat: sneaky reorder"
git rm -q yass/queue.md; git commit -q -m "yass: drop queue"
echo code >> app.txt; printf -- '- 2026-02-01-bravo\n' > yass/queue.md; git add -A
hasnt "…but not creating one" "heads-up" git commit -q -m "feat: code and a new queue"
git config --unset core.hooksPath

echo "12. blocked: naming changes is a dependency"
newrepo "$W/e2e/deps"
y init >/dev/null
mkb() { mkdir -p "$1"; printf -- '---\nblocked: %s\n---\n# %s\n\n## Goal\nIt.\n\n## Steps\n- [%s] Do it\n' "${3:-}" "$(basename "$1")" "${2:- }" > "$1/change.md"; }
mkb yass/changes/2026-01-01-alpha /; mkb yass/changes/2026-02-01-bravo x "2026-01-01-alpha"
mkb yass/changes/2026-03-01-big; mkb yass/changes/2026-03-01-big/2026-03-02-part
mkb yass/changes/2026-04-01-multi x "yass/changes/2026-01-01-alpha, 2026-03-01-big/2026-03-02-part"
git add -A; git commit -q -m "chore: adopt YASS"
has   "waiting on a change that isn't done" "2026-02-01-bravo .*waiting on: 2026-01-01-alpha" y status
run_fail "archive refuses while it waits" y archive bravo
has   "…and says why" "waiting on 2026-01-01-alpha" y archive bravo
has   "several, as a path and as change/piece" "2026-04-01-multi .*waiting on: 2026-01-01-alpha, 2026-03-01-big/2026-03-02-part" y status
sub yass/changes/2026-01-01-alpha/change.md '^- \[/\]' '- [x]'
hasnt "once it's done, nothing waits on it" "bravo .*(waiting|BLOCKED)" y status
has   "…the detail view suggests clearing it" "clear .blocked:" y status bravo
has   "…and still waiting on the rest" "2026-04-01-multi .*waiting on: 2026-03-01-big/2026-03-02-part$" y status
run_ok "archive works once it's met" y archive bravo
git commit -q -m "yass: archive bravo"
y archive alpha >/dev/null; git commit -q -m "yass: archive alpha"
hasnt "an archived dependency is met" "multi .*alpha" y status
mkb yass/changes/2026-05-01-free x "waiting on 2026-03-01-big and legal sign-off"
has   "free text, even mentioning a change, is a reason" "2026-05-01-free .*BLOCKED: waiting on 2026-03-01-big and legal" y status
run_fail "…and archive refuses" y archive free
mkb yass/changes/2026-05-01-free x "2026-09-09-nope"
has   "a dated name that isn't a change warns" "blocked: '2026-09-09-nope' looks like a change" y status
has   "…and stays a reason" "free .*BLOCKED: 2026-09-09-nope" y status
rm -rf yass/changes/2026-05-01-free
mkb yass/changes/2026-06-01-x "" "2026-06-02-y"; mkb yass/changes/2026-06-02-y "" "2026-06-01-x"
has   "a cycle warns" "waits on itself: 2026-06-01-x → 2026-06-02-y → 2026-06-01-x" y status
has   "…once" "^1$" bash -c 'yass status | grep -c "waits on itself"'
rm -rf yass/changes/2026-06-0*
mkdir -p svc; y init svc --no-agents >/dev/null; mkb svc/yass/changes/2026-07-01-api /
mkb yass/changes/2026-07-02-ui "" "svc/yass/changes/2026-07-01-api"
has   "dependencies work across yass folders" "2026-07-02-ui .*waiting on: 2026-07-01-api" y status

echo "13. yass paths: what's YASS's, for CI"
newrepo "$W/e2e/paths"; rm -rf "$W/e2e/paths-priv"
y init --no-agents >/dev/null; printf 'ignore:\n  - examples/*\n' > yass.yaml
mkdir -p services/payments services/search services/priv examples/demo/yass/changes
y init services/payments --no-agents >/dev/null
printf 'path: planning\n' > services/search/yass.yaml; mkdir -p services/search/planning/changes
printf 'path: ../../../paths-priv\n' > services/priv/yass.yaml; mkdir -p "$W/e2e/paths-priv/changes"
EXP=$'services/payments/yass/**\nservices/priv/yass.yaml\nservices/search/planning/**\nservices/search/yass.yaml\nyass.yaml\nyass/**'
[ "$(y paths)" = "$EXP" ] && ok "paths lists the yass folders in the repo and every yass.yaml, and nothing ignored or outside" || bad "paths: $(y paths | tr '\n' ' ')"
git add -A; git commit -q -m "chore: adopt YASS"
B=$(git rev-parse HEAD); y new "Plan only" >/dev/null; printf 'x\n' > services/payments/yass/changes/note.md; git add -A; git commit -q -m "yass: plan"
has   "--only: a range with only plans exits 0" "plans only: 2 file" y paths --only "$B..HEAD"
run_ok "…with status 0" y paths --only "$B..HEAD"
B=$(git rev-parse HEAD); echo more >> app.txt; echo y >> services/payments/yass/changes/note.md; git commit -qam "feat: code and plans"
run_fail "a range with any other file exits 1" y paths --only "$B..HEAD"
has   "…and names one" "1 of 2 changed file.* e.g. app.txt" y paths --only "$B..HEAD"
run_fail "an empty range runs the checks (exits 1)" y paths --only HEAD..HEAD
has   "a range it can't read exits 2 and says to fetch" "fetch history first" y paths --only nope..HEAD
bash -c 'yass paths --only nope..HEAD' >/dev/null 2>&1; [ $? -eq 2 ] && ok "…with status 2" || bad "not exit 2"
B=$(git rev-parse HEAD); sub yass/changes/*-plan-only/change.md '^- \[ \] $' '- [x] Done'; git commit -qam "yass: done"; y archive plan-only >/dev/null; git commit -q -m "yass: archive"
run_ok "archiving (a move inside yass/) is plans only" y paths --only "$B..HEAD"
cd "$W/e2e/paths-priv"; git init -q -b main; printf 'path: .\n' > yass.yaml
has   "a plans repo (path: .) is YASS's throughout" "^\*\*$" y paths

echo "16. worktrees and the yass/ link"
newrepo "$W/e2e/wt"; rm -rf "$W/e2e/wt-plans" "$W/e2e/wt-other" "$W/e2e/wts" "$W/e2e/wt-priv"*
y init --path ../wt-plans --no-agents >/dev/null; git add yass.yaml; git commit -q -m "chore: adopt YASS"
[ "$(readlink yass)" = "$(cd "$W/e2e/wt-plans" && pwd -P)" ] && ok "init links yass/ to the plans" || bad "no link: $(readlink yass)"
y status >/dev/null; y status >/dev/null
has   "…ignored through info/exclude, once" "^1$" grep -c '^/yass$' .git/info/exclude
[ -z "$(git status --porcelain)" ] && [ ! -e .gitignore ] && ok "…so git status shows nothing, and .gitignore is untouched" || bad "git status: $(git status --porcelain)"
y new "Linked" >/dev/null
has   "a change is listed once" "^1$" bash -c 'yass status | grep -c linked'
hasnt "…with no warnings" "warning" y status
git worktree add -q "$W/e2e/wts/deep/feat" -b feat
cd "$W/e2e/wts/deep/feat"
has   "a worktree elsewhere finds the main checkout's plans" "wt-plans$" y root
has   "…and lists its changes" "linked" y status
[ -L yass ] && [ -z "$(git status --porcelain)" ] && ok "…and gets its own ignored link" || bad "worktree link: $(ls -la yass 2>&1) $(git status --porcelain)"
cd "$W/e2e/wt"; git worktree add -q .claude/worktrees/n1 -b n1
has   "a worktree nested in the repo finds them too" "wt-plans$" bash -c 'cd .claude/worktrees/n1 && yass root'
mv "$W/e2e/wt-plans" "$W/e2e/wt-gone"
cd "$W/e2e/wts/deep/feat"
has   "plans missing from a worktree: the warning says where it looked" "isn't there from this worktree or the clone's other checkouts \(looked in .*wt-plans" y status
hasnt "…and never suggests yass init" "yass init" y status
run_fail "…root fails" y root
has   "…and init refuses rather than make a stray folder" "run .yass init. from the main checkout" y init --no-agents
[ ! -e "$W/e2e/wts/deep/wt-plans" ] && [ ! -e "$W/e2e/wts/wt-plans" ] && ok "…and made nothing" || bad "stray plans folder"
cd "$W/e2e/wt"; mv "$W/e2e/wt-gone" "$W/e2e/wt-plans"
printf 'path: ${WT_PLANS:-../wt-plans}\n' > yass.yaml
has   "\${VAR:-default}: the default when it's unset" "wt-plans$" y root
mkdir -p "$W/e2e/wt-other/changes"
has   "…the variable when it's set" "wt-other$" env WT_PLANS="$W/e2e/wt-other" yass root
case "$(readlink yass)" in *wt-other) ok "…and the link follows it";; *) bad "link not repointed: $(readlink yass)";; esac
y root >/dev/null
case "$(readlink yass)" in *wt-plans) ok "…and back";; *) bad "link not repointed back: $(readlink yass)";; esac
git checkout -q yass.yaml
rm yass; mkdir yass
has   "a real yass/ is left alone, with one warning" "^1$" bash -c 'yass status | grep -c "yass/: already there, so it isn.t a link"'
[ -d yass ] && [ ! -L yass ] && ok "…and kept" || bad "real yass/ replaced"
rmdir yass
newrepo "$W/e2e/wt-priv"; y init --path ../wt-priv-plans --no-agents >/dev/null
echo yass.yaml > .gitignore; git add .gitignore; git commit -q -m "keep the pointer private"
git worktree add -q "$W/e2e/wts/priv" -b feat
has   "a gitignored yass.yaml: a worktree uses the main checkout's" "wt-priv-plans$" bash -c "cd '$W/e2e/wts/priv' && yass root"
[ -L "$W/e2e/wts/priv/yass" ] && ok "…and gets the link" || bad "no link in the private-pointer worktree"
cd "$W/e2e"; rm -rf bare.git bare-wts; git clone -q --bare "$W/e2e/wt" bare.git
git -C bare.git worktree add -q "$W/e2e/bare-wts/main" main 2>/dev/null
git -C bare.git worktree add -q "$W/e2e/bare-wts/deep/feat2" -b feat2 main
mkdir -p "$W/e2e/bare-wts/wt-plans/changes"
has   "a bare clone's worktrees find plans next to another worktree" "bare-wts/wt-plans$" bash -c "cd '$W/e2e/bare-wts/deep/feat2' && yass root"

echo "22. private team folders: kept out of git, found through git config"
newrepo "$W/e2e/pv"; rm -rf "$W/e2e/pv-plans" "$W/e2e/pv-wts"
y init --no-agents >/dev/null; git add -A; git commit -q -m "chore: adopt YASS"
run_ok "init --private sets up a team folder" y init private --path ../../pv-plans --private --no-agents
y init private --path ../../pv-plans --private --no-agents >/dev/null
[ -f private/yass.yaml ] && [ -d "$W/e2e/pv-plans/changes" ] && [ -L private/yass ] && ok "…writes yass.yaml, creates the plans and links private/yass/" || bad "private setup incomplete"
has   "…adds /private to info/exclude once" "^1$" grep -c '^/private$' .git/info/exclude
has   "…and private to git config yass.include once" "^private$" git config --get-all yass.include
[ -z "$(git status --porcelain)" ] && ok "…and git status stays clean" || bad "git status: $(git status --porcelain)"
has   "status from the top lists it" "pv-plans/$" y status
has   "…and root" "pv-plans$" y root
hasnt "paths leaves it out" "private" y paths
P=$(cd private && yass new "Secret")
case "$P" in */e2e/pv-plans/changes/*-secret) ok "new inside private/ lands in the private plans";; *) bad "new went to $P";; esac
echo code >> app.txt; git add app.txt
hasnt "the hook ignores it" "." env YASS_STRICT=1 yass hook
git commit -q -m "feat: code"
git worktree add -q "$W/e2e/pv-wts/deep/a" -b a
cd "$W/e2e/pv-wts/deep/a"
has   "a worktree elsewhere lists the private plans" "pv-plans$" y root
[ -L private/yass ] && [ -z "$(git status --porcelain)" ] && ok "…gets its own private/yass link, and stays clean" || bad "worktree: $(ls -la private 2>&1) $(git status --porcelain)"
P=$(cd private && yass new "From a worktree")
case "$P" in */e2e/pv-plans/changes/*-from-a-worktree) ok "…and new inside its private/ lands there too";; *) bad "new went to $P";; esac
cd "$W/e2e/pv"; git worktree add -q .claude/worktrees/n -b n
has   "a nested worktree lists them too" "pv-plans$" bash -c 'cd .claude/worktrees/n && yass root'
git config --add yass.include gone
has   "an include with no yass.yaml anywhere warns, and says how to stop" "yass.include: 'gone' has no yass.yaml in any checkout .*git config --unset yass.include '.gone.'\)$" y status
git config --unset yass.include '^gone$'
run_fail "--private outside a folder refuses" y init --private --path ../x --no-agents

echo "23. change names end on a whole word"
newrepo "$W/e2e/slug"; y init --no-agents >/dev/null
P=$(y new "Paths that don't exist yet compare through symlinks")
has   "a long title ends on its last whole word" "/$TODAY-paths-that-don-t-exist-yet-compare$" echo "$P"
mkdir -p yass/archive/2026-01-01-paths-that-don-t-exist-yet-compare-throu
printf -- '# Paths that don'"'"'t exist yet compare through symlinks\n\n- [x] done\n' > yass/archive/2026-01-01-paths-that-don-t-exist-yet-compare-throu/change.md
has   "an archived change cut the old way still lists by name alone" "^2026-01-01-paths-that-don-t-exist-yet-compare-throu$" y status --archived

echo "24. yass init sets up a repo from the binary alone"
B="$W/e2e/alone-bin"; rm -rf "$B"; mkdir -p "$B"; cp "$YASS_BIN" "$B/yass"
V="$("$B/yass" --version | sed 's/^yass v\{0,1\}//')"
VR="$(printf '%s' "$V" | sed 's/[.+]/\\&/g')"   # the version as a regex: pseudo-versions have . and +
newrepo "$W/e2e/alone"
INIT_OUT="$(env -u YASS_BIN PATH="$B:/usr/bin:/bin" yass init)"
for f in .agents/skills/yass-log/SKILL.md .agents/skills/yass-plan/SKILL.md .agents/skills/yass-shape/SKILL.md \
         .agents/skills/yass-status/SKILL.md .agents/skills/yass-work/SKILL.md AGENTS.md yass/changes/.gitkeep; do
  [ -e "$f" ] && ok "writes $f" || bad "missing $f"
done
[ -x tools/yass/githooks/pre-commit ] && ok "…and an executable hook script" || bad "no executable hook"
[ ! -e .claude ] && [ ! -e CLAUDE.md ] && ok "…and no Claude files without --claude" || bad "Claude files without --claude"
hasnt "…and leaves the hook off" "githooks" git config core.hooksPath
has   "it lists what it wrote" "wrote .agents/skills/yass-work/SKILL.md" echo "$INIT_OUT"
same=1; for f in "$ROOT"/kit/.agents/skills/*/SKILL.md; do
  n="$(basename "$(dirname "$f")")"
  diff -q <(grep -v -e '^metadata:$' -e '^  yass-version: ' ".agents/skills/$n/SKILL.md") "$f" >/dev/null || same=0
done
diff -q <(grep -v '^# yass-version: ' tools/yass/githooks/pre-commit) "$ROOT/kit/tools/yass/githooks/pre-commit" >/dev/null || same=0
[ "$same" = 1 ] && ok "…each matching its source in kit/ but for the version stamp" || bad "an installed file differs from kit/ beyond its stamp"
has   "playbooks carry the version in their frontmatter" "^  yass-version: \"$VR\"$" cat .agents/skills/yass-work/SKILL.md
has   "…the AGENTS.md marker too" "<!-- yass:begin version=$VR " cat AGENTS.md
has   "…and the hook" "^# yass-version: $VR$" cat tools/yass/githooks/pre-commit
echo "changed" > .agents/skills/yass-work/SKILL.md
has   "re-running keeps what's there" "already set up" yass init
has   "…edits included" "^changed$" cat .agents/skills/yass-work/SKILL.md
newrepo "$W/e2e/alone-claude"; printf '# Our rules\n' > CLAUDE.md
yass init --claude --hooks >/dev/null; yass init --claude >/dev/null
[ -f .claude/skills/yass-work/SKILL.md ] && ok "--claude copies the playbooks for Claude Code" || bad "no .claude/skills"
has   "…imports AGENTS.md at the top of CLAUDE.md" "^@AGENTS.md$" head -1 CLAUDE.md
has   "…once, keeping what was there" "^1 1$" bash -c 'echo "$(grep -c "@AGENTS.md" CLAUDE.md) $(grep -c "# Our rules" CLAUDE.md)"'
has   "--hooks turns the hook on" "^tools/yass/githooks$" git config core.hooksPath
newrepo "$W/e2e/alone-claude2"; yass init --claude >/dev/null
has   "…and writes a CLAUDE.md when there's none" "^@AGENTS.md$" cat CLAUDE.md
newrepo "$W/e2e/alone-global"; H="$W/e2e/alone-home"; rm -rf "$H"
GL_OUT="$(HOME="$H" yass init --global --claude)"
[ -f "$H/.agents/skills/yass-work/SKILL.md" ] && [ -f "$H/.claude/skills/yass-work/SKILL.md" ] && ok "--global puts the playbooks (and Claude's) in the user folder" || bad "no user-folder playbooks"
[ ! -e .agents ] && [ ! -e .claude ] && ok "…none in the repo" || bad "--global wrote playbooks into the repo"
[ -x tools/yass/githooks/pre-commit ] && ok "…while the hook still goes in the repo" || bad "no hook with --global"
newrepo "$W/e2e/alone-skillsdir"; SD="$W/e2e/alone-skills"; rm -rf "$SD"
YASS_SKILLS_DIR="$SD" HOME="$H" yass init --global >/dev/null
[ -f "$SD/yass-work/SKILL.md" ] && ok "…or in \$YASS_SKILLS_DIR" || bad "\$YASS_SKILLS_DIR ignored"
newrepo "$W/e2e/alone-team"; yass init >/dev/null; git add -A; git commit -q -m "chore: adopt YASS"
mkdir -p svc; yass init svc >/dev/null
[ ! -e svc/.agents ] && [ ! -e svc/tools ] && ok "a team folder's init writes no playbooks or hook" || bad "team init wrote kit files"
newrepo "$W/e2e/alone-noagents"; yass init --no-agents >/dev/null
[ ! -e .agents ] && [ ! -e tools ] && [ ! -e AGENTS.md ] && ok "--no-agents skips AGENTS.md, the playbooks and the hook" || bad "--no-agents wrote agent files"

# vbin VERSION: a yass binary that reports VERSION ("dev" for none), built once, for checks that
# depend on versions; CI's own build reports whatever its checkout gives it.
vbin() { local d="$W/vbin/$1"
  if [ ! -x "$d/yass" ]; then mkdir -p "$d"
    if [ "$1" = dev ]; then (cd "$ROOT" && go build -buildvcs=false -o "$d/yass" ./cmd/yass)
    else (cd "$ROOT" && go build -ldflags "-X main.version=$1" -o "$d/yass" ./cmd/yass); fi
  fi; echo "$d/yass"; }

echo "25. agent files per folder, for monorepos"
newrepo "$W/e2e/mono"; yass init >/dev/null; git add -A; git commit -q -m "chore: adopt YASS"
ROOT_AGENTS="$(cksum < AGENTS.md)"
mkdir -p apps/web services/api
yass init services/api >/dev/null
[ -d services/api/yass/changes ] && ok "a folder without --agents gets its planning" || bad "no services/api/yass"
[ ! -e services/api/AGENTS.md ] && [ ! -e services/api/.agents ] && ok "…and no agent files" || bad "folder init wrote agent files"
[ "$(cksum < AGENTS.md)" = "$ROOT_AGENTS" ] && ok "…and leaves the root AGENTS.md alone" || bad "folder init changed the root AGENTS.md"
mkdir -p services/ext; yass init services/ext --path ../../../mono-ext-plans >/dev/null
[ -f services/ext/yass.yaml ] && [ ! -e services/ext/AGENTS.md ] && ok "…or its yass.yaml, with --path" || bad "folder --path init wrote the wrong files"
printf '# Web rules\n' > apps/web/AGENTS.md
WEB_OUT="$(yass init apps/web --agents --claude)"
has   "--agents puts the YASS section in the folder's AGENTS.md" "yass:begin version=" cat apps/web/AGENTS.md
has   "…keeping what was there" "# Web rules" cat apps/web/AGENTS.md
[ -f apps/web/.agents/skills/yass-work/SKILL.md ] && ok "…and the playbooks under the folder" || bad "no apps/web/.agents/skills"
[ -f apps/web/.claude/skills/yass-work/SKILL.md ] && has "…with Claude's copies and import there, with --claude" "^@AGENTS.md$" head -1 apps/web/CLAUDE.md || bad "no Claude files in apps/web"
[ ! -e apps/web/tools ] && ok "…and no second hook" || bad "--agents wrote a hook into the folder"
[ -d apps/web/yass/changes ] && ok "…along with its planning" || bad "no apps/web/yass"
[ "$(cksum < AGENTS.md)" = "$ROOT_AGENTS" ] && ok "…and the root AGENTS.md is untouched" || bad "--agents changed the root AGENTS.md"
has   "it lists what it wrote" "wrote apps/web/.agents/skills/yass-work/SKILL.md" echo "$WEB_OUT"
echo "Ours" > .agents/skills/yass-plan/SKILL.md; rm .agents/skills/yass-log/SKILL.md
REINIT="$("$(vbin 0.5.0)" init)"
has   "re-running init writes what's missing" "wrote .agents/skills/yass-log/SKILL.md" echo "$REINIT"
has   "…and keeps what's there" "^Ours$" cat .agents/skills/yass-plan/SKILL.md
has   "…and says yass upgrade would update files older than the binary (an unstamped one here)" "yass upgrade. updates them" echo "$REINIT"
git checkout -q -- .agents; git clean -qfd .agents
hasnt "a repo at the binary's version gets no upgrade note" "yass upgrade" yass init
sub AGENTS.md 'yass:begin version=\S+' 'yass:begin version=0.0.1'
has   "…an AGENTS.md section stamped older gets one" "yass upgrade. updates them" "$(vbin 0.5.0)" init
has   "…and init leaves the section as it is" "version=0.0.1 " cat AGENTS.md

echo "26. yass upgrade"
Y4="$(vbin 0.4.0)"; Y5="$(vbin 0.5.0)"; Y5D="$(vbin 0.5.0+dirty)"; YDEV="$(vbin dev)"
stamps() { grep -rhoE 'yass-version: "?[^" ]+|yass:begin version=[^ ]+' . --include=SKILL.md --include=AGENTS.md --include=pre-commit 2>/dev/null | sed -E 's/.*(version: "?|version=)//' | sort | uniq -c | tr -s ' '; }
newrepo "$W/e2e/up"; "$Y4" init --claude --hooks >/dev/null
printf '# Ours, before\n\n%s\n\n# Ours, after\n' "$(cat AGENTS.md)" > AGENTS.md; printf '\n# Our Claude notes\n' >> CLAUDE.md
"$Y4" new "Keep me" >/dev/null; git add -A; git commit -q -m "chore: adopt YASS"
KEEP="$(cat yass/changes/*-keep-me/change.md | cksum) $(grep -c 'Ours' AGENTS.md) $(grep -c 'Our Claude notes' CLAUDE.md)"
echo "edited" > .agents/skills/yass-work/SKILL.md; git commit -qam "edit a playbook"
UP="$("$Y5" upgrade)"
has   "upgrade says what it upgraded, from and to" "upgraded YASS's files from 0.4.0.* to 0.5.0" echo "$UP"
has   "…and lists each file" "wrote .claude/skills/yass-work/SKILL.md" echo "$UP"
has   "every stamp is the new version" "^ ?[0-9]+ 0.5.0$" stamps
hasnt "…none left at the old one" "0.4.0" stamps
[ -x tools/yass/githooks/pre-commit ] && ok "…and the hook stays executable" || bad "hook lost its mode"
[ "$(cat yass/changes/*-keep-me/change.md | cksum) $(grep -c 'Ours' AGENTS.md) $(grep -c 'Our Claude notes' CLAUDE.md)" = "$KEEP" ] && ok "changes, text outside the AGENTS.md markers and CLAUDE.md are untouched" || bad "upgrade touched what isn't YASS's"
has   "a hand edit is replaced, and the diff shows it" "^-edited$" git diff -- .agents/skills/yass-work/SKILL.md
git add -A; git commit -qm "chore: upgrade YASS"
has   "at the binary's version, it's already up to date" "already up to date: YASS's files are at 0.5.0" "$Y5" upgrade
[ -z "$(git status --porcelain)" ] && ok "…and changes nothing" || bad "an up-to-date upgrade changed files"
run_fail "an older binary refuses" "$Y4" upgrade
has   "…naming the newer version and the fix" "written by yass 0.5.0, newer than this one \(0.4.0\); upgrade your yass binary" "$Y4" upgrade
[ -z "$(git status --porcelain)" ] && ok "…and writes nothing" || bad "a refused upgrade changed files"
has   "a +dirty build rewrites its own version" "wrote AGENTS.md" "$Y5D" upgrade
git checkout -q -- .
run_fail "a binary with no version refuses to upgrade" "$YDEV" upgrade
has   "…saying how to get a versioned build" "has no version .*Go 1.24" "$YDEV" upgrade
newrepo "$W/e2e/up-dev"; run_fail "…or to init" "$YDEV" init
[ ! -e AGENTS.md ] && ok "…writing nothing" || bad "an unversioned init wrote files"
newrepo "$W/e2e/up-global"; H="$W/e2e/up-home"; rm -rf "$H"
has   "init labels files outside version control" "wrote .*up-home/.agents/skills/yass-work/SKILL.md \(outside version control\)" env HOME="$H" "$Y4" init --global
GUP="$(HOME="$H" "$Y5" upgrade)"
has   "upgrade upgrades user-folder playbooks, labeled outside version control" "up-home/.agents/skills/yass-work/SKILL.md \(outside version control\)" echo "$GUP"
has   "…to the new version" "yass-version: \"0.5.0\"" cat "$H/.agents/skills/yass-work/SKILL.md"
[ ! -e .agents ] && ok "…without adding repo copies" || bad "upgrade added repo playbooks"
newrepo "$W/e2e/up-legacy"
for f in "$ROOT"/kit/.agents/skills/*/SKILL.md; do n="$(basename "$(dirname "$f")")"
  mkdir -p ".agents/skills/$n" ".claude/skills/$n"; cp "$f" ".agents/skills/$n/"; cp "$f" ".claude/skills/$n/"; done
mkdir -p tools/yass/githooks yass/changes yass/archive; cp "$ROOT/kit/tools/yass/githooks/pre-commit" tools/yass/githooks/
"$Y5" template agents > AGENTS.md; printf '@AGENTS.md\n' > CLAUDE.md
has   "a repo set up by v0.2 (no stamps) upgrades" "from unstamped \(v0.2 or earlier\) to 0.5.0" "$Y5" upgrade
newrepo "$W/e2e/up-fresh"; "$Y5" init --claude --hooks >/dev/null
same=1; for f in .agents .claude tools AGENTS.md CLAUDE.md; do diff -r -q "$W/e2e/up-legacy/$f" "$f" >/dev/null || same=0; done
[ "$same" = 1 ] && ok "…ending up exactly like a fresh init" || bad "upgraded v0.2 repo differs from a fresh init: $(diff -rq "$W/e2e/up-legacy/.agents" .agents; diff -q "$W/e2e/up-legacy/AGENTS.md" AGENTS.md)"
NG2="$W/e2e/up-nogit"; rm -rf "$NG2"; mkdir -p "$NG2"
run_fail "upgrade outside a git repo refuses" bash -c 'cd "$1" && "$2" upgrade' _ "$NG2" "$Y5"
has   "…and says why" "works inside a git repo" bash -c 'cd "$1" && "$2" upgrade' _ "$NG2" "$Y5"
newrepo "$W/e2e/up-mono"; "$Y4" init >/dev/null; mkdir -p apps/web services/api vendor/x
"$Y4" init apps/web --agents >/dev/null; "$Y4" init services/api --agents >/dev/null
mkdir -p vendor/x/.agents/skills/yass-work; cp apps/web/.agents/skills/yass-work/SKILL.md vendor/x/.agents/skills/yass-work/
printf 'ignore:\n  - vendor/*\n' > yass.yaml
rm apps/web/.agents/skills/yass-log/SKILL.md; git add -A; git commit -q -m "chore: adopt YASS"
MUP="$(cd services/api && "$Y5" upgrade)"
has   "upgrade from a monorepo folder upgrades every copy in the repo" "wrote apps/web/AGENTS.md" echo "$MUP"
hasnt "…leaving none at the old version" "0.4.0" bash -c 'grep -rh "yass-version\|yass:begin" --include=SKILL.md --include=AGENTS.md --include=pre-commit apps services tools .agents AGENTS.md'
[ -f apps/web/.agents/skills/yass-log/SKILL.md ] && ok "…and adds a playbook missing from a skills folder" || bad "missing playbook not added"
has   "…but leaves folders yass.yaml ignores alone" "0.4.0" cat vendor/x/.agents/skills/yass-work/SKILL.md

echo "27. yass status knows the versions"
Y4="$(vbin 0.4.0)"; Y5="$(vbin 0.5.0)"; Y6="$(vbin 0.6.0)"
newrepo "$W/e2e/st"; "$Y5" init >/dev/null; git add -A; git commit -q -m "chore: adopt YASS"
has   "an older binary hears the repo is newer, and to upgrade the binary" "note: YASS's files here were written by yass 0.5.0, newer than this one \(0.4.0\); upgrade your yass binary" "$Y4" status
run_ok "…as a note, so --strict doesn't fail on it" "$Y4" status --strict
has   "a newer binary hears yass upgrade would upgrade the repo" "note: YASS's files here are older than this yass \(0.6.0\); .yass upgrade. would upgrade them" "$Y6" status
hasnt "the same version says nothing about versions" "YASS's files" "$Y5" status
newrepo "$W/e2e/st-none"; "$Y5" init --no-agents >/dev/null
hasnt "…nor does a repo with no YASS files" "YASS's files" "$Y6" status

echo "28. --hooks leaves existing hooks alone"
newrepo "$W/e2e/hk-none"
HO="$(yass init --hooks)"
has   "no hooks setup yet: --hooks turns the hook on" "^tools/yass/githooks$" git config core.hooksPath
has   "…and says so" "hook  core.hooksPath = tools/yass/githooks" echo "$HO"
has   "running it again: already on" "hook  already on" yass init --hooks
newrepo "$W/e2e/hk-husky"; mkdir -p .husky; git config core.hooksPath .husky
run_ok "a local core.hooksPath elsewhere: init still succeeds" yass init --hooks
has   "…and leaves core.hooksPath as it was" "^\.husky$" git config core.hooksPath
has   "…naming the setup" "already has a hooks setup \(core.hooksPath = \.husky\)" yass init --hooks
has   "…and how to run yass hook from husky" "add this line to \.husky/pre-commit:" yass init --hooks
[ -x tools/yass/githooks/pre-commit ] && [ -f .agents/skills/yass-work/SKILL.md ] && ok "…while writing everything else" || bad "init skipped files because of the hooks setup"
newrepo "$W/e2e/hk-custom"; git config core.hooksPath ci/hooks
has   "a custom hooks folder gets the line for its pre-commit" "add this line to ci/hooks/pre-commit .*tools/yass/githooks/pre-commit \"\\\$@\"" bash -c 'yass init --hooks | tr "\n" " "'
newrepo "$W/e2e/hk-global"; GC="$W/e2e/hk-gitconfig"; printf '[core]\n\thooksPath = %s\n' "$W/e2e/hk-global-hooks" > "$GC"
GO="$(GIT_CONFIG_GLOBAL="$GC" yass init --hooks)"
hasnt "a global core.hooksPath: no local one is added" "." git config --local --get core.hooksPath
has   "…and it says why, and how to switch anyway" "global core.hooksPath .*override it for this repo.*git config core.hooksPath tools/yass/githooks" bash -c 'tr "\n" " " <<<"$1"' _ "$GO"
newrepo "$W/e2e/hk-githooks"; printf '#!/bin/sh\nexit 0\n' > .git/hooks/pre-commit; cp .git/hooks/pre-commit .git/hooks/commit-msg; chmod +x .git/hooks/pre-commit .git/hooks/commit-msg
LO="$(yass init --hooks)"
hasnt "hooks in .git/hooks: core.hooksPath stays unset" "." git config --get core.hooksPath
has   "…naming them (not the samples)" "runs hooks from \.git/hooks \(commit-msg, pre-commit\)" echo "$LO"
has   "…with the line to add to .git/hooks/pre-commit" "^        tools/yass/githooks/pre-commit \"\\\$@\"$" echo "$LO"
newrepo "$W/e2e/hk-lefthook"; printf 'pre-push:\n  commands: {}\n' > lefthook.yml; printf '#!/bin/sh\n' > .git/hooks/pre-commit; chmod +x .git/hooks/pre-commit
has   "lefthook gets a lefthook.yml snippet" "run: yass hook" yass init --hooks
newrepo "$W/e2e/hk-precommit"; printf 'repos: []\n' > .pre-commit-config.yaml; printf '#!/bin/sh\n' > .git/hooks/pre-commit; chmod +x .git/hooks/pre-commit
has   "the pre-commit framework gets a local-hook snippet" "entry: yass hook" yass init --hooks
cd "$W/e2e/hk-husky"; git add -A; git commit -q -m "chore: adopt YASS" --no-verify
"$(vbin 0.5.0)" upgrade >/dev/null
has   "yass upgrade leaves core.hooksPath alone" "^\.husky$" git config core.hooksPath

echo "29. same-day changes list in creation order"
newrepo "$W/e2e/created"; y init --no-agents >/dev/null
PZ=$(y new "Zebra"); PA=$(y new "Apple"); PP=$(y new "Parent" --large); PC=$(y new "Piece zebra" --in Parent); PB=$(y new "Piece apple" --in Parent)
has   "yass new stamps created: in UTC" "^created: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$" cat "$PZ/change.md"
has   "…and keeps the dated folder name" "^yass/changes/$TODAY-zebra$" echo "$PZ"
has   "…a large change too" "^created: .*Z$" cat "$PP/change.md"
has   "…and a piece" "^created: .*Z$" cat "$PC/change.md"
sub "$PZ/change.md" '^created: .*$' "created: ${TODAY}T00:00:01Z"; sub "$PA/change.md" '^created: .*$' "created: ${TODAY}T00:00:02Z"
sub "$PP/change.md" '^created: .*$' "created: ${TODAY}T00:00:03Z"
sub "$PC/change.md" '^created: .*$' "created: ${TODAY}T00:00:04Z"; sub "$PB/change.md" '^created: .*$' "created: ${TODAY}T00:00:05Z"
mkdir -p "yass/changes/$TODAY-mango"; printf -- '---\nblocked:\n---\n# Mango\n\n- [ ] a\n' > "yass/changes/$TODAY-mango/change.md"
has   "same-day changes list in creation order, unstamped first" "mango .*zebra .*apple .*parent .*piece-zebra .*piece-apple " bash -c 'yass status | tr "\n" " "'
has   "an unstamped change still resolves" "# Mango|Mango" y status mango
hasnt "…and draws no warning" "created" y status
sub "$PA/change.md" '^created: .*$' "created: yesterday"
has   "a created: that isn't a time warns" "apple: created 'yesterday' isn't a time" y status
has   "…and sorts as unstamped (by date, then name)" "apple .*mango .*zebra " bash -c 'yass status | tr "\n" " "'

echo "30. AGENTS.md says intent and archives land apart from code"
Y5="$(vbin 0.5.0)"
newrepo "$W/e2e/apart"; "$Y5" init >/dev/null
has   "the section says intent stays out of a squashed pull request with code" "never changes in the same commit as code \(with squash merges, the same pull request\)" cat AGENTS.md
has   "…that archives land apart from code" "in its own commit, apart from code" cat AGENTS.md
has   "…and that pushing and pull requests need latitude" "rebase, push or open a pull request unless" cat AGENTS.md
git add -A; git commit -q -m "chore: adopt YASS"
sub AGENTS.md 'yass:begin version=0\.5\.0' 'yass:begin version=0.4.0'
sub AGENTS.md ', apart from code \(with squash merges, a pull request without code\)' ''
"$Y5" upgrade >/dev/null
has   "yass upgrade brings an older section up to it" "in its own commit, apart from code" cat AGENTS.md

echo; echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
