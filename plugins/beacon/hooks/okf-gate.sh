#!/usr/bin/env bash
# Beacon OKF gate (Option A): on Stop/SubagentStop, enforce ONLY once an
# active recon claims completion — signalled by INDEX.md frontmatter being
# `status: complete` (Phase 12 flips it as its last step).
#
# Contract (evaluated independently for EVERY marker found — see below):
#   - Marker's output_root unreadable      -> skip (don't block on our own bug)
#   - INDEX.md missing OR not status:complete
#                                          -> skip, do NOTHING (mid-run / abandoned case;
#                                             marker is left untouched, no delete, no block)
#   - INDEX.md status:complete, bundle valid
#                                          -> delete the marker
#   - INDEX.md status:complete, bundle invalid,
#     retries < 2                         -> bump retries, print [OKF-GATE-BLOCK:<root>], block
#   - INDEX.md status:complete, bundle invalid,
#     retries >= 2                        -> print [OKF-GATE-FAILED:<root>], delete the marker
# The hook's own exit code blocks the stop (2) if ANY marker ended up blocked;
# otherwise it exits 0.
#
# Every marker under the tree is evaluated — not just the first one found.
# Multiple site-recons can be in flight at once (the field incident that
# motivated this contract was an 11-subagent parallel run, each scaffolding
# its own docs/sites/{slug}/research/.beacon/recon-active.json): picking a
# single arbitrary marker via `head -1` would validate/clean up the wrong
# bundle on a Stop event and leave the actually-finishing recon's marker
# orphaned forever (never validated, never cleaned up).
#
# This hook ONLY validates. It never calls scaffold.sh and never creates/overwrites
# any output file — re-scaffolding here would destroy in-progress phase work.
#
# The abandoned/no-output case (recon started, nothing ever written) is NOT this
# hook's job — that's the Phase-12 self-gate plus the deferred Subsystem-B
# orchestrator sweep. This hook only ever looks at claimed-complete bundles.
set -uo pipefail
HOOKS=$(cd "$(dirname "$0")" && pwd)
SCRIPTS="$HOOKS/../skills/site-recon/scripts"
VALIDATE="$SCRIPTS/okf_validate.py"
MARKER_RETRY="$SCRIPTS/okf_marker_retry.py"

MARKS=$(find . -path '*/.beacon/recon-active.json' -not -path '*/node_modules/*' 2>/dev/null)
[ -z "$MARKS" ] && exit 0   # no active beacon recon anywhere → not our concern

STATUS=0
while IFS= read -r MARK; do
  [ -z "$MARK" ] && continue

  ROOT=$(python3 -c "import json, sys; print(json.load(open(sys.argv[1]))['output_root'])" "$MARK" 2>/dev/null)
  [ -z "$ROOT" ] && continue   # marker unreadable/malformed → don't block on our own bug

  INDEX="$ROOT/INDEX.md"
  [ -f "$INDEX" ] || continue   # no INDEX yet → mid-run, silent no-op for this recon

  # Completion check reuses the validator's own frontmatter parser (quote-normalizing,
  # frontmatter-anchored) instead of a standalone grep, so status: "complete" (quoted)
  # is recognised identically to status: complete, and a body line can never false-arm this.
  python3 "$VALIDATE" --is-complete "$INDEX" >/dev/null 2>&1 || continue   # not claimed complete

  if python3 "$VALIDATE" "$ROOT"; then
    rm -f "$MARK"
    continue
  fi

  ACTION=$(python3 "$MARKER_RETRY" "$MARK" 2>/dev/null)
  if [ "$ACTION" = "failed" ]; then
    echo "[OKF-GATE-FAILED:$ROOT] validation still failing after retries — allowing stop" >&2
    rm -f "$MARK"
  else
    echo "[OKF-GATE-BLOCK:$ROOT] claimed complete but invalid — fix before finishing (see errors above)" >&2
    STATUS=2
  fi
done <<< "$MARKS"

exit "$STATUS"
