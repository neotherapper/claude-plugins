#!/usr/bin/env bash
# Beacon OKF gate: on Stop/SubagentStop, validate the active recon output root.
#
# Contract:
#   - No active marker found          -> exit 0 (not a beacon recon; let the stop through)
#   - Marker found, bundle valid      -> delete the marker, exit 0
#   - Marker found, bundle invalid,
#     retries < 2                     -> bump retries, print [OKF-GATE-BLOCK:<root>], exit 2 (block)
#   - Marker found, bundle invalid,
#     retries >= 2                    -> print [OKF-GATE-FAILED:<root>], delete the marker, exit 0
#
# This hook ONLY validates. It never calls scaffold.sh and never creates/overwrites
# any output file — re-scaffolding here would destroy in-progress phase work.
set -uo pipefail
HOOKS=$(cd "$(dirname "$0")" && pwd)
VALIDATE="$HOOKS/../skills/site-recon/scripts/okf_validate.py"

MARK=$(find . -path '*/.beacon/recon-active.json' -not -path '*/node_modules/*' 2>/dev/null | head -1)
[ -z "$MARK" ] && exit 0   # no active beacon recon → not our concern

ROOT=$(python3 -c "import json; print(json.load(open('$MARK'))['output_root'])" 2>/dev/null)
[ -z "$ROOT" ] && exit 0   # marker unreadable/malformed → don't block on our own bug

if python3 "$VALIDATE" "$ROOT"; then
  rm -f "$MARK"
  exit 0
fi

RETRIES=$(python3 -c "import json; print(json.load(open('$MARK')).get('retries', 0))" 2>/dev/null)
[ -z "$RETRIES" ] && RETRIES=0

if [ "$RETRIES" -ge 2 ]; then
  echo "[OKF-GATE-FAILED:$ROOT] validation still failing after retries — allowing stop" >&2
  rm -f "$MARK"
  exit 0
fi

python3 -c "
import json
p = '$MARK'
d = json.load(open(p))
d['retries'] = $RETRIES + 1
json.dump(d, open(p, 'w'))
"
echo "[OKF-GATE-BLOCK:$ROOT] output files missing/invalid — fix before finishing (see errors above)" >&2
exit 2
