#!/usr/bin/env bash
set -uo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
HOOK="$DIR/fleet-sweep.sh"
FLEET="$DIR/../skills/site-recon/scripts/fleet.py"

# case 1: no active.json -> exit 0, no-op
T1=$(mktemp -d); ( cd "$T1" && bash "$HOOK" ); [ $? -eq 0 ] || { echo "FAIL case1"; exit 1; }

# case 2: all-terminal fleet -> exit 0 AND active.json removed
T2=$(mktemp -d)
( cd "$T2" && python3 "$FLEET" init https://a.com >/dev/null
  mkdir -p docs/sites/a-com/research
  printf -- '---\ntype: site-index\nstatus: complete\n---\n' > docs/sites/a-com/research/INDEX.md
  python3 "$FLEET" update a-com --status complete --verdict complete >/dev/null
  bash "$HOOK" )
rc=$?; [ $rc -eq 0 ] || { echo "FAIL case2 rc=$rc"; exit 1; }
[ ! -f "$T2/docs/sites/.fleet/active.json" ] || { echo "FAIL case2 not deactivated"; exit 1; }

# case 3: unresolved fleet -> exit 2 with [FLEET-SWEEP-PENDING]
T3=$(mktemp -d)
out=$( cd "$T3" && python3 "$FLEET" init https://a.com >/dev/null
       python3 "$FLEET" update a-com --status reconning >/dev/null
       bash "$HOOK" 2>&1 )
rc=$?; [ $rc -eq 2 ] || { echo "FAIL case3 rc=$rc"; exit 1; }
grep -q "\[FLEET-SWEEP-PENDING:" <<<"$out" || { echo "FAIL case3 no marker: $out"; exit 1; }

# case 4: paused fleet -> exit 0 no-op, active.json preserved
T4=$(mktemp -d)
( cd "$T4" && python3 "$FLEET" init https://a.com >/dev/null
  python3 "$FLEET" update a-com --status reconning >/dev/null
  python3 "$FLEET" pause >/dev/null
  bash "$HOOK" )
rc=$?; [ $rc -eq 0 ] || { echo "FAIL case4 rc=$rc"; exit 1; }
[ -f "$T4/docs/sites/.fleet/active.json" ] || { echo "FAIL case4 dropped handle"; exit 1; }

echo "OK"
