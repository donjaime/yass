#!/usr/bin/env bash
# Speed at scale: generates large repos in a temporary folder, times `yass status` and the
# pre-commit hook against the targets in the plan, and cleans up. Exits 1 if a target is missed.
# Usage: tests/bench.sh [workdir]   (BENCH_KEEP=1 keeps the generated repos)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
W="${1:-$(mktemp -d)}"; mkdir -p "$W"
[ -n "${BENCH_KEEP:-}" ] || trap 'rm -rf "$W/bench"' EXIT
rm -rf "$W/bench"; mkdir -p "$W/bench"
unset YASS_STRICT YASS_HOOK YASS_HOME
if [ -z "${YASS_BIN:-}" ]; then
  mkdir -p "$W/bin"; (cd "$ROOT" && go build -o "$W/bin/yass" ./cmd/yass) || { echo "build failed"; exit 1; }
  YASS_BIN="$W/bin/yass"
fi
FOLDERS="${BENCH_FOLDERS:-200}" CHANGES="${BENCH_CHANGES:-2000}" ARCHIVED="${BENCH_ARCHIVED:-10000}" FILES="${BENCH_FILES:-100000}" RUNS="${BENCH_RUNS:-5}"
fail=0

# median wall time of RUNS runs of a command, in milliseconds, after one untimed warm-up run
# (freshly generated files are slow to read at first: the OS is still caching and indexing them)
ms() { perl -MTime::HiRes=time -e '
  my $n = shift; my @t;
  open my $out, ">&", \*STDOUT; open STDOUT, ">", "/dev/null"; open STDERR, ">", "/dev/null";
  system(@ARGV);
  for (1..$n) {
    my $s = time; my $rc = system(@ARGV);   # exit 1 is a finding (a warning), not a failure
    if ($rc == -1 || ($rc >> 8) > 1) { print $out "failed: @ARGV\n"; exit 1 }
    push @t, (time - $s) * 1000;
  }
  @t = sort { $a <=> $b } @t; printf $out "%d\n", $t[int($n / 2)]' "$RUNS" "$@"; }
check() { # name, measured ms, target ms
  if [ "$2" -lt "$3" ]; then echo "  ok   $1: ${2}ms (target < ${3}ms)"; else echo "  MISS $1: ${2}ms (target < ${3}ms)"; fail=1; fi; }
newrepo() { mkdir -p "$1"; cd "$1"; git init -q -b main; git config user.email b@b; git config user.name Bench; }

echo "status: $FOLDERS yass folders, $CHANGES changes, $ARCHIVED archived"
newrepo "$W/bench/status"
FOLDERS=$FOLDERS CHANGES=$CHANGES perl -e '
  my ($f, $c) = ($ENV{FOLDERS}, $ENV{CHANGES}); my $per = int($c / $f) || 1; my $n = 0;
  for my $i (1..$f) {
    my $y = sprintf("teams/t%03d/yass", $i); system("mkdir", "-p", "$y/archive");
    for my $j (1..$per) {
      last if $n++ >= $c;
      my $d = sprintf("%s/changes/2026-%02d-%02d-change-%d", $y, ($j % 12) + 1, ($j % 28) + 1, $j);
      system("mkdir", "-p", $d); open my $o, ">", "$d/change.md" or die;
      print $o "---\nplatforms: [all]\nsource:\nfollows:\nblocked:\n---\n# Change $i.$j\n\n## Goal\nDo the thing.\n\n## Acceptance\n";
      print $o "- [", ($_ % 3 ? " " : "x"), "] Given $_, when $_, then $_ - verify: test $_\n" for 1..8;
      print $o "\n## Steps\n", map("- [/] step $_\n", 1..4), "\n## Decisions\n- chose a - because b (bench)\n\n## Log\n### 2026-10-01 (bench)\n- Did: things\n- Next: more things\n";
    }
  }'
# Archived changes, spread over the folders and over months, as yass archive files them; some
# active changes follow one, so names are resolved across the archive.
FOLDERS=$FOLDERS ARCHIVED=$ARCHIVED perl -MFile::Path=make_path -e '
  my ($f, $c) = ($ENV{FOLDERS}, $ENV{ARCHIVED}); my $per = int($c / $f) || 1; my $n = 0;
  for my $i (1..$f) {
    my $y = sprintf("teams/t%03d/yass", $i);
    for my $j (1..$per) {
      last if $n++ >= $c;
      my $m = ($j % 12) + 1;
      my $d = sprintf("%s/archive/2025/%02d/2025-%02d-%02d-done-%d", $y, $m, $m, ($j % 28) + 1, $j);
      make_path($d); open my $o, ">", "$d/change.md" or die;
      printf $o "---\nplatforms: [all]\nsource:\nfollows:\nblocked:\narchived: 2025-%02d-28T12:00:00Z\n---\n# Done %d.%d\n\n## Goal\nDid the thing.\n\n## Acceptance\n", $m, $i, $j;
      print $o "- [x] Given $_, when $_, then $_ - verify: test $_\n" for 1..8;
      print $o "\n## Decisions\n- chose a - because b (bench)\n\n## Log\n### 2025-01-01 (bench)\n- Did: things\n";
    }
    my $first = sprintf("%s/changes/2026-02-02-change-1/change.md", $y);
    if (-f $first) { local @ARGV = ($first); local $^I = ""; while (<>) { s/^follows:\s*$/follows: 2025-02-02-done-1/; print } }
  }'
mkdir -p yass/changes yass/archive; touch yass/changes/.gitkeep
git add -A >/dev/null; git commit -q -m "bench: plans"
echo "  $(git ls-files | wc -l | tr -d ' ') files, $("$YASS_BIN" status | grep -c ' not started\| in progress\|  [0-9]*/[0-9]*') status lines"
check "yass status" "$(ms "$YASS_BIN" status)" 1000

echo "hook: $FILES files, one-file commit"
newrepo "$W/bench/hook"
FILES=$FILES perl -e '
  my $n = $ENV{FILES}; my $per = 500;
  for my $i (0..int(($n - 1) / $per)) {
    my $d = sprintf("src/m%04d", $i); system("mkdir", "-p", $d);
    for my $j (1..$per) { last if $i * $per + $j > $n; open my $o, ">", "$d/f$j.go" or die; print $o "package m\n" }
  }'
for t in a b c; do mkdir -p "teams/$t/yass/changes/2026-10-01-x"; printf -- '# X\n\n- [ ] box\n' > "teams/$t/yass/changes/2026-10-01-x/change.md"; done
git add -A >/dev/null; git commit -q -m "bench: a big repo"
echo "edit" >> src/m0000/f1.go; echo "- [x] box" >> teams/a/yass/changes/2026-10-01-x/change.md; git add -A
echo "  $(git ls-files | wc -l | tr -d ' ') files"
check "yass hook (staged, one code file and one plan)" "$(ms "$YASS_BIN" hook)" 200

echo; [ "$fail" -eq 0 ] && echo "all targets met" || echo "some targets missed"
exit $fail
