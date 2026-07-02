#!/usr/bin/env bash
set -euo pipefail
HOOKS=$(cd "$(dirname "$0")" && pwd)
SCAF="$HOOKS/../skills/site-recon/scripts"
TMP=$(mktemp -d); cd "$TMP"
OUTPUT_ROOT="$TMP/out" URL="https://example.com" bash "$SCAF/scaffold.sh" >/dev/null
# fresh scaffold is all draft → gate should pass (nothing claimed complete)
bash "$HOOKS/okf-gate.sh" || { echo "FAIL: gate rejected a valid draft bundle"; exit 1; }
# success path deletes the marker (spec: "on validation success: delete the marker") —
# recreate just the JSON marker (not via scaffold.sh, which would re-render INDEX.md
# and wipe the corruption below) so the second gate run has an active marker to find.
test -f "$TMP/out/.beacon/recon-active.json" && { echo "FAIL: marker not deleted on success"; exit 1; }
printf '{"output_root":"%s","retries":0}\n' "$TMP/out" > "$TMP/out/.beacon/recon-active.json"
# now corrupt a file: claim complete but leave a token
printf -- '---\ntype: site-index\ntitle: X\nstatus: complete\n---\n{{FRAMEWORK}}\n' > "$TMP/out/INDEX.md"
if bash "$HOOKS/okf-gate.sh"; then echo "FAIL: gate passed an invalid complete bundle"; exit 1; fi
# marker should still exist with retries incremented (blocked, not consumed)
test -f "$TMP/out/.beacon/recon-active.json" || { echo "FAIL: marker deleted on block"; exit 1; }
RETRIES=$(python3 -c "import json; print(json.load(open('$TMP/out/.beacon/recon-active.json'))['retries'])")
[ "$RETRIES" -eq 1 ] || { echo "FAIL: expected retries=1, got $RETRIES"; exit 1; }
# run it two more times to exhaust the retry cap — third block should allow stop (exit 0)
bash "$HOOKS/okf-gate.sh" >/dev/null 2>&1 || true
if ! bash "$HOOKS/okf-gate.sh" 2>"$TMP/okf-gate-failed.stderr"; then
  echo "FAIL: gate should allow stop after retry cap exhausted"; exit 1
fi
grep -q 'OKF-GATE-FAILED' "$TMP/okf-gate-failed.stderr" || { echo "FAIL: no OKF-GATE-FAILED message"; exit 1; }
test -f "$TMP/out/.beacon/recon-active.json" && { echo "FAIL: marker not cleared after retry cap"; exit 1; }
echo "OK"
