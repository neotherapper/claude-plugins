# Fleet dispatch-actor decision (B1 Task 0/1)

**Decision: `ACTOR = subagent`** — the fleet dispatches `site-analyst` as a foreground
subagent per source, running the whole recon (Phases 1–12) in that one subagent context.

## Why (spike result, 2026-07-10)
A foreground capability-probe subagent was dispatched and confirmed both prerequisites the
browser phases need:
- **Bash available:** `curl -sI https://example.com | head -1` → `HTTP/2 200` (not permission-denied).
- **Browser tools available:** `mcp__chrome-devtools__*` loaded and callable to the subagent.

So a foreground `site-analyst` subagent can run the passive phases (Bash/curl) *and* the browser
Phase 11 (Chrome MCP) end-to-end — the whole recon in one context, satisfying B1's no-seam
guardrail. This is the preferred actor (uses the purpose-built agent per the scrum-677 finding, and
isolates each recon's context from the main session).

## Fallback (not needed)
If a future environment denies subagents Bash/browser, fall back to `ACTOR = main-session-loop`
(main session runs `site-recon` per source). The ledger/sweep/hook are unchanged either way.

## Guardrail
Whichever actor: recon each source as a **whole 1–12 in one context**. The background 1–9 / main
10–11 split is prohibited in B1 (re-opens the N-C1 content seam).
