---
name: site-fleet
description: This skill should be used when the user asks to analyse/recon MULTIPLE sites at once — "recon these sites", "map the API surface of A, B and C", "run beacon over this list of URLs", or runs /beacon:fleet. Recons sources one at a time through site-analyst, tracks them in a durable ledger, and gates completion. For a single site, use site-recon instead.
version: 0.8.0
---

# site-fleet — Sequential fleet orchestration

Recon a LIST of sources one at a time, reusing site-recon per source, with a durable
ledger that survives compaction and a deterministic completeness gate.

**Reuses, never replaces:** each source is a full site-recon (Subsystem A). This skill only
adds the ledger, the sequential loop, and the completeness sweep. One source at a time — no
parallelism (that is the deferred B2 subsystem).

## Entry — branch on arguments (REQUIRED)

- **With URLs / a file arg** → start a new fleet:
  ```bash
  python3 "${CLAUDE_PLUGIN_ROOT}/skills/site-recon/scripts/fleet.py" init {url1} {url2} …
  ```
  (A file of URLs, one per line: expand it to the arg list first.) Record the printed
  `[FLEET:{ledger}]`. If it prints `[FLEET-ERROR] … already active`, do NOT retry init —
  go to resume.
- **With no args, OR after `[FLEET-ERROR] already active`** → resume; never call `init`:
  ```bash
  python3 "${CLAUDE_PLUGIN_ROOT}/skills/site-recon/scripts/fleet.py" pending
  ```

## The loop (sequential)

Repeat until `fleet.py pending` prints nothing:

1. Take the next slug from `fleet.py pending` (it also re-arms a paused fleet).
2. **Reconcile:** if that source's `docs/sites/{slug}/research/INDEX.md` is already complete
   (`python3 …/okf_validate.py --is-complete <INDEX>`), mark it and skip:
   `fleet.py update {slug} --status complete --verdict complete`.
3. Otherwise mark it in flight: `fleet.py update {slug} --status reconning`.
4. **Recon the whole source (Phases 1–12) in ONE context.** Dispatch the `site-analyst`
   subagent for `{url}` and await its completion — a foreground `site-analyst` agent can run
   the entire recon, including the browser phases, end to end. This is the primary path.
   (Fallback only: if a future environment denies subagents Bash/browser access, run the
   `site-recon` skill for `{url}` yourself in the main session instead.) Do NOT split
   Phases 1–9 from 10–11 across contexts — that re-opens the content seam (prohibited in B1).
5. Record the outcome:
   - completed (INDEX flipped `status: complete`) → `fleet.py update {slug} --status complete --verdict complete`
   - blocked for a concrete reason (e.g. auth wall) → `fleet.py update {slug} --status blocked --verdict blocked:{reason}`
   - errored / produced nothing → `fleet.py update {slug} --status inconclusive --verdict inconclusive`, then **retry once**; if still not complete, `waive` it so it reaches a terminal status (`inconclusive` is NOT terminal — leaving it inconclusive would make `fleet.py pending` re-list it forever): `fleet.py waive {slug} --reason inconclusive-after-retry`. Each `--status inconclusive` update bumps the row's durable `retries` count in the ledger (survives compaction) — the retry policy is bounded to **one** retry, so once `retries` reaches 2 for a slug, waive it rather than retrying again; do not rely on in-context memory of how many times you've retried, check `retries` in the ledger.

## Close

- `python3 …/fleet.py sweep` → prints `[FLEET-COMPLETE]` or `[FLEET-INCOMPLETE:{slug}:{reason}]`.
- Report a slug → status table and the incomplete list.
- **Pausing across sessions:** before an intentional mid-fleet stop, run `fleet.py pause`
  (preserves the resume handle; the Stop gate will not block). Resume next session with
  `/beacon:fleet` (no args) or `fleet.py pending`.
- **A source that genuinely cannot complete:** `fleet.py waive {slug} --reason {why}`.
- **Abandon the fleet:** `fleet.py close`.

If you stop with unresolved sources and have not paused, the `fleet-sweep.sh` Stop hook blocks
with `[FLEET-SWEEP-PENDING:…]` — finish, waive, pause, or close.
