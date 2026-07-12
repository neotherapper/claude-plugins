#!/usr/bin/env bash
# Beacon fleet completeness gate (Subsystem B1). Registered on `Stop` ONLY
# (never SubagentStop — it must not fire on per-source subagent completion).
# Closes the Option-A residual gap: an abandoned/zero-output source stays
# non-terminal, so this blocks the orchestrator's stop until every source is
# complete/blocked/waived — regardless of whether the skill prose ran `sweep`.
set -uo pipefail
HOOKS=$(cd "$(dirname "$0")" && pwd)
FLEET="$HOOKS/../skills/site-recon/scripts/fleet.py"
ACTIVE="docs/sites/.fleet/active.json"

[ -f "$ACTIVE" ] || exit 0   # no fleet in flight

LEDGER=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['ledger'])" "$ACTIVE" 2>/dev/null)
[ -n "$LEDGER" ] && [ -f "$LEDGER" ] || exit 0   # unreadable handle -> don't block on our own bug

STATE=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('state',''))" "$LEDGER" 2>/dev/null)
[ "$STATE" = "paused" ] && exit 0   # intentional multi-session pause; handle preserved

SWEEP=$(python3 "$FLEET" sweep 2>/dev/null)
if grep -q '\[FLEET-INCOMPLETE:' <<<"$SWEEP"; then
  SLUGS=$(grep -oE '\[FLEET-INCOMPLETE:[^:]+' <<<"$SWEEP" | sed 's/\[FLEET-INCOMPLETE://' | paste -sd, -)
  echo "[FLEET-SWEEP-PENDING:$SLUGS] fleet has unresolved sources — finish, waive, or 'fleet.py pause'/'close'" >&2
  echo "$SWEEP" >&2
  exit 2
elif grep -q '\[FLEET-COMPLETE\]' <<<"$SWEEP"; then
  # only a confirmed all-terminal sweep deactivates; a crashed/empty sweep leaves state intact
  rm -f "$ACTIVE"
fi
exit 0
