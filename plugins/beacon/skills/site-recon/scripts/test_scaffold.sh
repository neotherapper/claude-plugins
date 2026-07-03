#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
OUTPUT_ROOT="$TMP/out" URL="https://msi.nga.mil/NavWarnings" bash "$DIR/scaffold.sh"
test -f "$TMP/out/INDEX.md" || { echo "FAIL: no INDEX.md"; exit 1; }
test -f "$TMP/out/.beacon/phase-checklist.md" || { echo "FAIL: no phase-checklist"; exit 1; }
test -f "$TMP/out/.beacon/recon-active.json" || { echo "FAIL: no active marker"; exit 1; }
python3 "$DIR/okf_validate.py" "$TMP/out" || { echo "FAIL: validator rejected fresh scaffold"; exit 1; }

# ---- URL-safe render (FIX 2 / T4-m1): & and # in URL must not corrupt or abort scaffold ----
TMP2=$(mktemp -d)
URL2='https://ex.com/a?x=1&y=2#f'
OUTPUT_ROOT="$TMP2/out" URL="$URL2" bash "$DIR/scaffold.sh"
test -s "$TMP2/out/INDEX.md" || { echo "FAIL: INDEX.md empty/missing for &/# URL"; exit 1; }
grep -qF "resource: \"$URL2\"" "$TMP2/out/INDEX.md" || { echo "FAIL: resource: line missing literal &/# URL"; exit 1; }
python3 "$DIR/okf_validate.py" "$TMP2/out" || { echo "FAIL: validator rejected scaffold for &/# URL"; exit 1; }

echo "OK"
