# Beacon Fleet Orchestration (Subsystem B) — Design

- **Date:** 2026-07-10
- **Status:** Approved for planning (post adversarial review; NEEDS-REWORK findings folded in)
- **Depends on:** Subsystem A — enforced OKF output contract (beacon v0.7.1, PR #37, merged `c66db77`)
- **Supersedes:** the "Subsystem B — Fleet orchestration (sketch)" section in
  `docs/superpowers/specs/2026-07-02-beacon-okf-output-contract-design.md`

## 1. Motivation

Session "scrum-677" ran 11 beacon-recon subagents in parallel and exposed four orchestration
failures that Subsystem A (per-source output contract) does **not** address:

1. **Generic agents** — the orchestrator dispatched generic subagents, never the purpose-built
   `site-analyst`.
2. **Lost batch** — a 6-agent wave was lost to context compaction; there was no durable record of
   what had been dispatched or completed.
3. **Rate limits** — 6 concurrent recons tripped API rate limits.
4. **Chrome collision** — parallel subagents drove one shared Chrome/cmux browser simultaneously,
   corrupting each other's browse sessions.

Plus the **Option-A residual gap** carried over from Subsystem A: the `Stop`/`SubagentStop` gate
enforces only on a bundle that *claims* completion (`INDEX.md` `status: complete`); an
abandoned/zero-output recon (the `emsa-emcip` / `lloyds-sab` case) stays `draft` and is a silent
no-op. Subsystem A left that catch to the Phase-12 self-gate (prose — the weak link).

Subsystem B is fleet orchestration: run N site-recons safely in parallel, never lose the batch,
never collide on the browser, and **deterministically** catch a source that never completed.

Governing principle (repo memory, `project_plugin-prose-vs-enforcement`): *prose-only skill steps
get skipped under synthesis pressure — gate what matters deterministically.* This design was
reworked specifically because an adversarial review found its first draft defended its core
guarantees with prose.

## 2. Goals / Non-goals

**Goals**
- One command to recon a list of sources, reusing Subsystem A per source.
- Parallelism on the passive phases with a hard concurrency cap.
- Collision-freedom on the browser that is *structural*, not instructional.
- A durable ledger that survives context compaction and supports resume.
- A deterministic end-of-fleet completeness gate that closes the Option-A residual gap.

**Non-goals**
- Changing `/beacon:analyze` (single-site path stays exactly as it is).
- A rolling-window scheduler (barrier waves are sufficient — YAGNI).
- Cross-run analytics, a fleet dashboard, or scheduling.
- Recon logic itself — Subsystem B orchestrates existing site-recon phases; it does not change them.

## 3. Architecture — split-phase, capability-restricted

Only **Phase 11** (active browse) drives the browser; Phases 1–10 — including Phase 10's
browse-plan *compilation* (a passive synthesis step that opens no browser) — are passive
(curl / WebFetch / OSINT APIs). The fleet splits on that seam:

- **Passive phase (parallel).** Dispatch a **restricted-capability** agent, `beacon:site-scout`,
  one per source, in barrier waves of ≤3. Each scout runs Phases 1–10 (through browse-plan
  compilation), writes hand-off artifacts, and stops with its bundle still `status: draft`.
- **Browser phase (serial, main session).** After *all* scout waves (including retries) finish,
  the main session runs browser Phase 11 and the Phase-12 completion/validate for each source,
  one at a time.

**Collision-freedom is by capability removal, not instruction.** `site-scout`'s `tools:`
frontmatter grants the passive tool set (Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch,
TodoWrite) and **omits every browser tool** — both Chrome MCP namespaces
(`mcp__chrome-devtools__*`, `mcp__plugin_chrome-devtools-mcp_*`, `mcp__claude-in-chrome__*`) and
cmux. A scout therefore *cannot* open the browser even if its prompt is ignored under pressure.
Only the main session (full tools) ever drives Chrome, and it does so serially. This is the review's
C2 fix and it is the linchpin of the whole subsystem — see §11 (Review traceability).

`site-analyst` is left unchanged: it remains the full-capability agent for a single-site end-to-end
recon. `site-scout` is a new, narrower sibling for the fleet's passive worker role. Using a
purpose-built agent (not a generic one) also answers scrum-677 finding #1.

## 4. Components

| Component | Path | Responsibility |
|---|---|---|
| Command | `plugins/beacon/commands/beacon-fleet.md` | `/beacon:fleet {url… \| path/to/urls.txt}`; thin; invokes the fleet skill. |
| Skill | `plugins/beacon/skills/site-fleet/SKILL.md` | The orchestration procedure (§6). |
| Scout agent | `plugins/beacon/agents/site-scout.md` | Restricted-tools passive worker (§3). |
| Ledger + sweep | `plugins/beacon/skills/site-recon/scripts/fleet.py` (+ `test_fleet.py`) | Durable ledger and completeness sweep (§5, §7). |
| Canonical slug | `plugins/beacon/skills/site-recon/scripts/slugify.py` | Single source of truth for URL→slug; called by both `scaffold.sh` and `fleet.py` (§8, review I4). |
| Sweep gate | `plugins/beacon/hooks/fleet-sweep.sh` (+ `test_fleet_sweep.sh`) | `Stop`-only hook that deterministically closes the Option-A gap (§9, review C4). |

Fleet coordination artifacts live **outside** any per-source bundle root, under `docs/sites/.fleet/`:

- `docs/sites/.fleet/fleet-<ts>.json` — machine ledger (source of truth).
- `docs/sites/.fleet/fleet-<ts>.md` — human-readable view, regenerated from the JSON.
- `docs/sites/.fleet/active.json` — **stable handle** → `{"ledger": "<path to current fleet-*.json>"}` (review I1).
- `docs/sites/.fleet/plans/<slug>.md` — the browse plan a scout hands to the main session.
- `docs/sites/.fleet/plans/<slug>.verdict` — one verdict token the scout writes for the main session.

Keeping these out of `docs/sites/<slug>/research/` is mandatory: `okf_validate.py` rglobs `*.md`
across the bundle **including `.beacon/`** and fails closed on any file without valid OKF
frontmatter. A prose `browse-plan.md` inside the bundle would fail every completed source's gate
(review C1). `.fleet/` has no `research/INDEX.md`, so it is invisible to the site-intel glob.

## 5. Ledger schema

`fleet-<ts>.json`:

```json
{
  "created": "<ISO-8601 UTC>",
  "sources": {
    "<slug>": {
      "url": "<original url>",
      "agent_id": "<subagent id | null>",
      "status": "pending | scouting | handoff-ready | browsing | complete | blocked | inconclusive | rate-limited",
      "verdict": "handoff-ready | blocked:<reason> | inconclusive | rate-limited | null",
      "browse_plan_path": "docs/sites/.fleet/plans/<slug>.md | null",
      "retries": 0
    }
  }
}
```

- `status` is the orchestrator's view of where the source is in the pipeline.
- `verdict` is the scout's self-reported terminal outcome, read from the `.verdict` sidecar.
- **Terminal states** for the completeness gate: `complete` and `blocked` (a `blocked:<reason>`
  source is a decision, not a failure — see §7). Everything else is *unresolved*.
- `<ts>` uses second precision **plus a PID/monotonic suffix** so two inits in the same second
  cannot collide on a filename (review nit).

**Single-writer invariant (review I3):** the main session is the *only* writer of the ledger.
Scouts never touch it — they write only their own `plans/<slug>.{md,verdict}` sidecars. `fleet.py
update` additionally takes an `flock` on the JSON (matching `okf_marker_retry.py`) so the invariant
is defended even against accidental concurrent calls.

## 6. `fleet.py` interface

- `init <url…>` → resolve each URL to a slug via `slugify.py`, **dedup by slug** (§8), write
  `fleet-<ts>.json` + `.md` + `active.json`, print `[FLEET:<ledger-path>]`.
- `update <slug> --status … [--verdict …] [--agent-id …] [--browse-plan …]` → mutate one source
  row under `flock`, regenerate the `.md`. Resolves the ledger via `active.json` when no explicit
  path is given.
- `pending` → with no argument, resolve `active.json` and list sources not in a terminal state
  (this is the **compaction-resume** entry point: the orchestrator re-reads it and continues).
- `sweep` → resolve `active.json`; for each source read `INDEX.md` `status` (via
  `okf_validate.py --is-complete`) **and** the ledger verdict; classify and print
  `[FLEET-COMPLETE]` or one `[FLEET-INCOMPLETE:<slug>:<reason>]` per unresolved source. Sweep fails
  *toward flagging*: a missing/unreadable `INDEX.md` counts as incomplete.
- `waive <slug> [--reason …]` / `close` → escape hatch to mark a source resolved or deactivate the
  fleet (removes `active.json`) so the §9 gate stops firing (§9).

`sweep` reads completion `status` from `INDEX.md` and `verdict` from the ledger — they live in
different places; there is no `verdict` field in OKF frontmatter (review I2 note).

## 7. Verdict + sweep semantics

Each scout writes exactly one token to `plans/<slug>.verdict`:

- `handoff-ready` — passive phases done, browse plan written; ready for the browser phase.
- `blocked:<reason>` — cannot proceed for a concrete reason discovered while probing
  (e.g. `blocked:auth-gated` for EMSA's CAC-PKI). **Terminal — never retried** (hammering a gated
  source wastes budget and never succeeds).
- `inconclusive` — the scout errored, produced nothing, or returned null. **Eligible for one retry.**
- `rate-limited` — a distinct outcome from `inconclusive`: the scout hit a 429/limit. Eligible for
  one retry, but **with exponential backoff** before re-dispatch (review I6).

Retry policy: an `inconclusive`/`rate-limited` source is re-dispatched **at most once**, during the
passive phase (see ordering in §10), then flagged if still not `handoff-ready`. `blocked` is never
retried.

## 8. Slug handling (review I4)

`fleet.py` must produce byte-identical slugs to `scaffold.sh`, or `sweep` reads the wrong
`INDEX.md` path and false-flags. The URL→slug rule (lowercase → strip scheme → strip `www.` → strip
path → strip `:port` → dots→dashes) is extracted to a canonical `slugify.py`. `scaffold.sh` calls
it (replacing its inline `sed` at line 6) and `fleet.py` calls it. A `test_fleet.py` case asserts
`fleet.py`'s slugs match `slugify.py` for a fixture set (drift guard). `docs/SLUG_RULES.md` is
updated to point at `slugify.py` as the implementation.

**Dedup at init:** two input URLs on one domain (`example.com/a`, `example.com/b`) slugify to one
OUTPUT_ROOT. Letting both through would put two scouts on the same bundle — the on-disk version of
the collision this subsystem exists to prevent. `fleet.py init` **rejects** duplicate slugs with a
clear error naming the colliding URLs (merge is a possible future refinement; reject is safer for v1).

## 9. Deterministic gap closure — the fleet `Stop` hook (C4 = option a)

`fleet-sweep.sh` is registered on **`Stop` only** (never `SubagentStop`, so it cannot block scout
subagents mid-fleet):

1. If `docs/sites/.fleet/active.json` is absent → exit 0 (no fleet in flight; no-op).
2. Otherwise resolve the ledger and run `fleet.py sweep`.
3. If **every** source is terminal (`complete` or `blocked:<reason>` or waived) → remove
   `active.json` (deactivate) → exit 0.
4. If any source is unresolved → block (exit 2) with
   `[FLEET-SWEEP-PENDING:<slug,slug,…>]` and re-emit the sweep's per-source reasons on stderr.

This makes "did every source actually finish?" a deterministic check that runs at the orchestrator's
`Stop` regardless of whether the skill prose remembered to sweep — the actual closure of the
Option-A residual gap. The `waive`/`close` escape hatch (§6) lets the user dismiss a source the
fleet genuinely can't complete, so the gate informs rather than traps. Deactivation on full
resolution stops it firing on later, unrelated stops.

This hook is independent of Subsystem A's `okf-gate.sh` (per-source, `Stop`+`SubagentStop`); both
may fire on the same `Stop` and do not interact — one validates each bundle, the other checks fleet
completeness.

## 10. Data flow (ordering pinned — review I5)

```
/beacon:fleet urls
  └─ fleet.py init urls               → fleet-<ts>.json + .md + active.json   [FLEET:…]
  ── PASSIVE PHASE (parallel, barrier waves of ≤3) ───────────────────────────
  for wave in chunks(sources, 3):
     dispatch site-scout(url)  ×wave  → each writes plans/<slug>.md + .verdict, bundle stays draft
     (await ALL in wave)               main session reads sidecars, fleet.py update per source
  retry inconclusive/rate-limited sources ONCE here (backoff for rate-limited)
  ── BARRIER: every scout + retry done; all bundles still draft (okf-gate no-ops on draft) ──
  ── BROWSER PHASE (serial, main session, one source at a time) ──────────────
  for slug in sources where verdict == handoff-ready:
     run Phase 11 (browser) using plans/<slug>.md
     run Phase 12: flip INDEX status→complete + okf_validate     [Subsystem A Stop-gate applies]
     fleet.py update <slug> --status complete
  ── CLOSE ───────────────────────────────────────────────────────────────────
  fleet.py sweep                       → [FLEET-COMPLETE] | [FLEET-INCOMPLETE:…]
  (main session Stop → fleet-sweep.sh verifies + deactivates, or blocks if unresolved)
  final report: slug → status table + FLEET-INCOMPLETE list
```

The critical ordering property: **no `Phase-12` flip happens until every scout wave (including
retries) has finished.** While scouts run, all bundles are `draft`, so a scout's `SubagentStop`
never overlaps a `status: complete` bundle — eliminating the cross-source false-block that
`okf-gate.sh` (which scans every marker on each stop) would otherwise cause.

## 11. Review traceability

Adversarial review (2026-07-10) verdict was NEEDS-REWORK. Each finding and where it is resolved:

| Finding | Resolution |
|---|---|
| **C1** browse-plan.md inside bundle fails the validator | Hand-off artifacts under `docs/sites/.fleet/plans/`, never a non-OKF `.md` in a bundle (§4). |
| **C2** collision by instruction, not construction | `site-scout` with browser tools removed from `tools:` frontmatter (§3). |
| **C3** background-subagent Bash unvalidated | Build-gate spike is **Task 0** of the plan; nothing else is built until it passes (§13). |
| **C4** residual gap not deterministically closed | `fleet-sweep.sh` `Stop` hook (§9). |
| **I1** no stable ledger handle for resume | `active.json` pointer; `pending`/`sweep`/`update` resolve it (§4, §6). |
| **I2** verdict via free-text parse | Scout writes a `.verdict` sidecar; main session reads the file (§4, §7). |
| **I3** concurrent ledger writes | Single-writer invariant + `flock` on `update` (§5). |
| **I4** slug drift + duplicate-slug collision | Canonical `slugify.py`; `init` dedups by slug (§8). |
| **I5** retry/Phase-12 ordering race | Ordering pinned: all scout waves + retries before any Phase-12 flip (§10). |
| **I6** no rate-limit backoff | Distinct `rate-limited` verdict + exponential backoff on retry (§7). |
| nits | `handoff-ready` naming (scout runs through Phase 10); `<ts>`+PID suffix; stale-marker cruft noted (§12). |

## 12. Known limitations (owned honestly)

- **Scaling ceiling.** The browser phase runs serially in the *one* main session. For a
  scrum-677-sized fleet (11 sources) that is 11 sequential browser recons accumulating in a single
  context — re-creating the orchestrator compaction that motivated the ledger. The ledger + `pending`
  resume (§6) is the mitigation, not a cure. Callers reconning very large fleets should expect to
  resume across sessions. This is acceptable for the target use (handfuls of sources) and called out
  rather than hidden.
- **Stale draft markers.** An incomplete/blocked source keeps its `.beacon/recon-active.json`
  (okf-gate only deletes on complete+valid or give-up). Harmless cruft; `fleet.py close` may sweep
  these in a future refinement.
- **Skill orchestration is not unit-testable.** The dispatch loop needs real subagents. It is
  covered by the `fleet.py`/hook unit tests plus the doc; there is no automated end-to-end fleet test.

## 13. Build gate (Task 0) and testing

**Task 0 — background-Bash spike (blocking).** Before any other code: dispatch one background
subagent and confirm it can run `scaffold.sh` and a `curl` probe. The codebase asserts this works
(`site-analyst.md:47`, `SKILL.md:700` scope the no-Bash limit to cmux/browser), but it is
load-bearing enough that it must be proven, not assumed. If background pre-approved Bash does **not**
work, the parallelism premise fails and the design must change (fall back to a different dispatch
model) — so we learn it first.

**Automated tests**
- `test_fleet.py` (pure, no network): `init` creates ledger + `active.json`; `init` rejects
  duplicate slugs; `update` mutates one row; `pending` lists non-terminal sources and resolves
  `active.json`; `sweep` classifies complete / blocked / inconclusive / draft / missing-INDEX
  correctly; partial-then-resume; malformed ledger fails safely; slug-conformance vs `slugify.py`.
- `test_fleet_sweep.sh`: no `active.json` → no-op; all-terminal → deactivates + exit 0; an
  unresolved source → exit 2 with `[FLEET-SWEEP-PENDING]`; `Stop`-only registration (not
  `SubagentStop`).
- Regression: `scaffold.sh` still passes `test_scaffold.sh` after switching to `slugify.py`.

## 14. Scope / YAGNI

No rolling-window scheduler (barrier waves). Retry bound = 1. `blocked` never auto-retried. No
change to `/beacon:analyze`. No fleet dashboard/analytics. `merge` of duplicate-slug URLs deferred
(reject for now). A version bump (`0.8.0`, minor — new capability) and CHANGELOG entry ship with the
implementation.
