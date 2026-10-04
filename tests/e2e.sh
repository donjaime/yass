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
bash "$ROOT/install.sh" . >/dev/null

echo "1. install"
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
bash "$ROOT/install.sh" . --upgrade >/dev/null
has "--upgrade replaces them" "^name: yass-work" cat .agents/skills/yass-work/SKILL.md
has "--bin-dir copies the binary" "write  .*/bindir/yass" bash "$ROOT/install.sh" . --bin-dir "$W/e2e/bindir"
[ -x "$W/e2e/bindir/yass" ] && ok "…and it runs" || bad "no binary in --bin-dir"
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
newrepo "$W/e2e/bare"
run_fail "new before init explains itself" y new "x"
has      "…with the fix" "run .*yass init" y new "x"

echo "9. yass.yaml: the yass folder lives somewhere else"
newrepo "$W/e2e/ext"; rm -rf "$W/e2e/ext-yass" "$W/e2e/home-yass"
bash "$ROOT/install.sh" . --path ../ext-yass >/dev/null
[ -f yass.yaml ] && ok "--path writes yass.yaml" || bad "no yass.yaml"
[ ! -e yass ] && ok "…and no yass/ in the repo" || bad "yass/ in the repo"
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
mkdir -p yass/changes && touch yass/changes/.gitkeep
has   "a yass/ beside a yass.yaml that points elsewhere warns" "yass/: ignored, because yass.yaml points to" y status
rm -rf yass

echo; echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
