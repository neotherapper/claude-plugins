#!/usr/bin/env bash
# Beacon OKF gate (Option A): on Stop/SubagentStop, enforce ONLY once the
# active recon claims completion — signalled by INDEX.md frontmatter being
# `status: complete` (Phase 12 flips it as its last step).
#
# Contract:
#   - No active marker found              -> exit 0 (not a beacon recon; let the stop through)
#   - Marker found, output_root unreadable -> exit 0 (don't block on our own bug)
#   - INDEX.md missing OR not status:complete
#                                          -> exit 0, do NOTHING (mid-run / abandoned case;
#                                             marker is left untouched, no delete, no block)
#   - INDEX.md status:complete, bundle valid
#                                          -> delete the marker, exit 0
#   - INDEX.md status:complete, bundle invalid,
#     retries < 2                         -> bump retries, print [OKF-GATE-BLOCK:<root>], exit 2 (block)
#   - INDEX.md status:complete, bundle invalid,
#     retries >= 2                        -> print [OKF-GATE-FAILED:<root>], delete the marker, exit 0
#
# This hook ONLY validates. It never calls scaffold.sh and never creates/overwrites
# any output file — re-scaffolding here would destroy in-progress phase work.
#
# The abandoned/no-output case (recon started, nothing ever written) is NOT this
# hook's job — that's the Phase-12 self-gate plus the deferred Subsystem-B
# orchestrator sweep. This hook only ever looks at claimed-complete bundles.
set -uo pipefail
HOOKS=$(cd "$(dirname "$0")" && pwd)
VALIDATE="$HOOKS/../skills/site-recon/scripts/okf_validate.py"

MARK=$(find . -path '*/.beacon/recon-active.json' -not -path '*/node_modules/*' 2>/dev/null | head -1)
[ -z "$MARK" ] && exit 0   # no active beacon recon → not our concern

ROOT=$(python3 -c "import json; print(json.load(open('$MARK'))['output_root'])" 2>/dev/null)
[ -z "$ROOT" ] && exit 0   # marker unreadable/malformed → don't block on our own bug

INDEX="$ROOT/INDEX.md"
[ -f "$INDEX" ] || exit 0   # no INDEX yet → mid-run, silent no-op
grep -Eq '^status:[[:space:]]*complete[[:space:]]*$' "$INDEX" || exit 0   # not claimed complete → silent no-op

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
echo "[OKF-GATE-BLOCK:$ROOT] claimed complete but invalid — fix before finishing (see errors above)" >&2
exit 2
