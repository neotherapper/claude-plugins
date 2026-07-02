#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
OUTPUT_ROOT="$TMP/out" URL="https://msi.nga.mil/NavWarnings" bash "$DIR/scaffold.sh"
test -f "$TMP/out/INDEX.md" || { echo "FAIL: no INDEX.md"; exit 1; }
test -f "$TMP/out/.beacon/phase-checklist.md" || { echo "FAIL: no phase-checklist"; exit 1; }
test -f "$TMP/out/.beacon/recon-active.json" || { echo "FAIL: no active marker"; exit 1; }
python3 "$DIR/okf_validate.py" "$TMP/out" || { echo "FAIL: validator rejected fresh scaffold"; exit 1; }
echo "OK"
