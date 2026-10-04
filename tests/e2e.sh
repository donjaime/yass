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
INSTALL_OUT="$(bash "$ROOT/install.sh" .)"

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

echo "8. installer options"
newrepo "$W/e2e/claude"
bash "$ROOT/install.sh" . --claude --hooks >/dev/null
[ -f .claude/skills/yass-work/SKILL.md ] && ok "--claude copies the playbooks" || bad "no .claude/skills"
has "--claude imports AGENTS.md" "^@AGENTS.md" cat CLAUDE.md
has "--hooks sets the hook path" "tools/yass/githooks" git config core.hooksPath
git add -A; hasnt "the adopting commit isn't flagged" "heads-up" git commit -q -m "chore: adopt YASS"
echo "changed" > .agents/skills/yass-work/SKILL.md
bash "$ROOT/install.sh" . >/dev/null
has "re-running keeps your edits" "^changed$" cat .agents/skills/yass-work/SKILL.md
UPGRADE_OUT="$(bash "$ROOT/install.sh" . --upgrade)"
has   "--upgrade says it upgraded" "YASS is upgraded.*chore: upgrade YASS" bash -c 'tr "\n" " " <<<"$1"' _ "$UPGRADE_OUT"
hasnt "…not the adoption steps" "chore: adopt YASS" echo "$UPGRADE_OUT"
has   "…and points to the release notes" "github.com/.*/releases" echo "$UPGRADE_OUT"
has "--upgrade replaces them" "^name: yass-work" cat .agents/skills/yass-work/SKILL.md
echo "changed" > .claude/skills/yass-work/SKILL.md
bash "$ROOT/install.sh" . --upgrade >/dev/null
has   "--upgrade refreshes Claude's copies without --claude" "^name: yass-work" cat .claude/skills/yass-work/SKILL.md
newrepo "$W/e2e/noclaude"; bash "$ROOT/install.sh" . >/dev/null; bash "$ROOT/install.sh" . --upgrade >/dev/null
[ ! -e .claude ] && ok "…and doesn't create them when there are none" || bad ".claude written by --upgrade"
cd "$W/e2e/claude"
has "--bin-dir copies the binary" "write  .*/bindir/yass" bash "$ROOT/install.sh" . --bin-dir "$W/e2e/bindir"
[ -x "$W/e2e/bindir/yass" ] && ok "…and it runs" || bad "no binary in --bin-dir"
has   "…and warns that another yass on PATH comes first" "is .*, not the one just installed" bash "$ROOT/install.sh" . --bin-dir "$W/e2e/bindir"
has   "…or that --bin-dir isn't on PATH" "yass isn't on your PATH" \
      env PATH=/usr/bin:/bin SHELL=/bin/zsh bash "$ROOT/install.sh" . --bin-dir "$W/e2e/bindir2"
has   "…with the fix for the shell" "Fix it with:  echo 'export PATH=\".*/bindir2:\\\$PATH\"' >> ~/.zshrc" \
      env PATH=/usr/bin:/bin SHELL=/bin/zsh bash "$ROOT/install.sh" . --bin-dir "$W/e2e/bindir2"
hasnt "no warning when the installed yass is the one on PATH" "WARNING" \
      env PATH="$W/e2e/bindir:/usr/bin:/bin" bash "$ROOT/install.sh" . --bin-dir "$W/e2e/bindir"
U="$W/e2e/unpacked"; rm -rf "$U"; mkdir -p "$U"; cp -R "$ROOT/install.sh" "$ROOT/kit" "$U/"; cp "$YASS_BIN" "$U/yass"
has   "an unpacked release with an older yass on PATH suggests --bin-dir, not a PATH edit" \
      "run this script again with:  --bin-dir .*/bindir$" \
      env -u YASS_BIN PATH="$W/e2e/bindir:/usr/bin:/bin" bash "$U/install.sh" .
hasnt "…and no PATH edit" "Fix it with" env -u YASS_BIN PATH="$W/e2e/bindir:/usr/bin:/bin" bash "$U/install.sh" .
K="$W/e2e/kit-only"; rm -rf "$K"; mkdir -p "$K"; cp -R "$ROOT/install.sh" "$ROOT/kit" "$K/"
has      "a web install with no --bin-dir and no yass stops before downloading" "pass --bin-dir" \
         bash -c 'env -u YASS_BIN PATH=/usr/bin:/bin bash -s -- . < "$1"' _ "$ROOT/install.sh"
run_fail "no binary anywhere: refuses" env -u YASS_BIN PATH=/usr/bin:/bin bash "$K/install.sh" .
has      "…and says how to get one" "no yass binary found" env -u YASS_BIN PATH=/usr/bin:/bin bash "$K/install.sh" .
newrepo "$W/e2e/global"
HOME="$W/e2e/home" bash "$ROOT/install.sh" . --global --claude >/dev/null
[ -f "$W/e2e/home/.agents/skills/yass-work/SKILL.md" ] && ok "--global puts the playbooks in the user folder" || bad "no user-level playbooks"
[ -f "$W/e2e/home/.claude/skills/yass-work/SKILL.md" ] && ok "…and Claude's, with --claude" || bad "no user-level Claude playbooks"
[ ! -e .agents ] && [ ! -e .claude ] && ok "…not in the repo" || bad "playbooks written into the repo"
[ -f tools/yass/githooks/pre-commit ] && [ -d yass/changes ] && ok "…while the hook and yass/ still are" || bad "repo files missing"
echo "changed" > "$W/e2e/home/.agents/skills/yass-work/SKILL.md"; echo "changed" > "$W/e2e/home/.claude/skills/yass-work/SKILL.md"
GOUT="$(HOME="$W/e2e/home" bash "$ROOT/install.sh" . --upgrade)"
has   "--upgrade without --global finds the user folder's playbooks" "upgrading the ones in your user folder" echo "$GOUT"
has   "…and replaces them" "^name: yass-work" cat "$W/e2e/home/.agents/skills/yass-work/SKILL.md"
has   "…and Claude's" "^name: yass-work" cat "$W/e2e/home/.claude/skills/yass-work/SKILL.md"
[ ! -e .agents ] && [ ! -e .claude ] && ok "…without writing any into the repo" || bad "--upgrade wrote playbooks into the repo"
newrepo "$W/e2e/bare"
run_fail "new before init explains itself" y new "x"
has      "…with the fix" "run .*yass init" y new "x"

echo "9. yass.yaml: the yass folder lives somewhere else"
newrepo "$W/e2e/ext"; rm -rf "$W/e2e/ext-yass" "$W/e2e/home-yass"
bash "$ROOT/install.sh" . --path ../ext-yass >/dev/null
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
bash "$ROOT/install.sh" . >/dev/null
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
bash "$ROOT/install.sh" . >/dev/null
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
bash "$ROOT/install.sh" . >/dev/null
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

echo; echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
