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

# ---- T5-m1: marker is well-formed JSON even when OUTPUT_ROOT contains a double-quote ----
# The gate reads output_root back via json.load(marker); a printf'd path with a " breaks
# the JSON and the gate fails open (no-op). Assert the round-trip the gate performs, not
# merely "a marker exists" — extract output_root and require it equals the input path.
TMP3=$(mktemp -d)
QROOT="$TMP3/o\"q"
OUTPUT_ROOT="$QROOT" URL="https://ex.com" bash "$DIR/scaffold.sh"
GOT=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['output_root'])" "$QROOT/.beacon/recon-active.json" 2>/dev/null || true)
[ "$GOT" = "$QROOT" ] || { echo "FAIL: marker round-trip mismatch for quote-bearing path: [$GOT] != [$QROOT]"; exit 1; }

# ---- T6-m1: default-form scaffold deterministically flags a pre-0.7.0 legacy workspace ----
# Positive: no OUTPUT_ROOT given (default form) + legacy docs/research/{slug}/ present → emit.
TMP4=$(mktemp -d)
LEG_LOG=$( cd "$TMP4" && mkdir -p "docs/research/ex-com" && URL="https://ex.com" bash "$DIR/scaffold.sh" 2>&1 )
grep -qF "[LEGACY-WORKSPACE" <<<"$LEG_LOG" || { echo "FAIL: legacy folder present on default path but no [LEGACY-WORKSPACE] emitted"; exit 1; }
# Negative: caller supplied an explicit OUTPUT_ROOT → do not nag them away from it, even if legacy exists.
TMP5=$(mktemp -d)
OVR_LOG=$( cd "$TMP5" && mkdir -p "docs/research/ex-com" && OUTPUT_ROOT="$TMP5/custom" OUTPUT_ROOT_OVERRIDDEN=1 URL="https://ex.com" bash "$DIR/scaffold.sh" 2>&1 )
grep -qF "[LEGACY-WORKSPACE" <<<"$OVR_LOG" && { echo "FAIL: caller-supplied OUTPUT_ROOT must suppress [LEGACY-WORKSPACE]"; exit 1; }

echo "OK"
