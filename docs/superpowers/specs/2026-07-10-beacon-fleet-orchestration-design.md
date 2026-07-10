# Beacon Fleet Orchestration — B1: Sequential Core — Design

- **Date:** 2026-07-10
- **Status:** Approved for planning (decomposed from the parallel design after two adversarial review rounds)
- **Depends on:** Subsystem A — enforced OKF output contract (beacon v0.7.1, PR #37, merged `c66db77`)
- **Supersedes:** the "Subsystem B — Fleet orchestration (sketch)" section in
  `docs/superpowers/specs/2026-07-02-beacon-okf-output-contract-design.md`
- **Defers to a later spec:** **B2 — parallel scouts** (concurrency, capability-sandboxed
  `site-scout`, browser serialization, cross-context content hand-off). See §13.

## 1. Motivation and decomposition

Session "scrum-677" ran 11 beacon-recon subagents in parallel and exposed four failures Subsystem A
(per-source output contract) does not address, plus the Option-A residual gap:

1. **Generic agents** — the orchestrator used generic subagents, never the purpose-built `site-analyst`.
2. **Lost batch** — a 6-agent wave was lost to context compaction; no durable record of dispatch/progress.
3. **Rate limits** — 6 concurrent recons tripped API rate limits.
4. **Chrome collision** — parallel subagents drove one shared browser simultaneously.
5. **Option-A residual gap** — an abandoned/zero-output recon (`emsa-emcip`, `lloyds-sab`) stays
   `draft`, and Subsystem A's Stop-gate is a silent no-op on `draft`; the catch was left to the
   Phase-12 self-gate (prose — the weak link).

**Key insight from design review:** failures 1, 2, 5 are *correctness* problems; failures 3 and 4
are consequences purely of *parallelism*. Two adversarial review rounds of a parallel-first design
both cratered on parallelism-induced complexity (a capability sandbox that leaks via cmux; a
cross-context content-hand-off seam that reproduces the "no session brief" failure). None of the
correctness wins require parallelism. So this subsystem is **decomposed**:

- **B1 (this spec) — sequential core.** Recon sources one at a time through the real `site-analyst`,
  wrapped by a durable ledger and a deterministic completeness sweep. Fixes 1, 2, 5, and *dissolves*
  3 and 4 (one source at a time = one API stream, one browser user).
- **B2 (deferred) — parallelism.** Waves, a capability-sandboxed passive agent, browser
  serialization, and a content hand-off contract. Its own spec, built on B1 once B1 is proven.

Governing principle (repo memory, `project_plugin-prose-vs-enforcement`): *prose-only skill steps
get skipped under synthesis pressure — gate what matters deterministically.*

## 2. Goals / Non-goals

**Goals**
- One command to recon a list of sources, reusing Subsystem A per source, through `site-analyst`.
- A durable ledger that survives context compaction and supports resume across sessions.
- A deterministic end-of-fleet completeness gate that closes the Option-A residual gap.

**Non-goals (all deferred to B2)**
- Parallel/concurrent recon, concurrency caps, rate-limit backoff.
- Browser-collision avoidance machinery (dissolved here by running one source at a time).
- A capability-restricted agent or any cross-context content hand-off.
- Changing `/beacon:analyze` (single-site path is untouched) or the site-recon phases themselves.

## 3. Architecture — sequential, whole-recon-per-source

The fleet reconnoiters sources **one at a time**. Each source is handled **end-to-end (Phases 1–12)
by a single actor**, so the Subsystem-A content model (findings accumulate in one context's session
brief → Phase 12 synthesizes the bundle → flips `status: complete`) is preserved exactly. There is
**no split, no seam, no hollow-bundle risk** — the defect that sank the parallel design cannot occur
because no recon is ever divided across two contexts.

Running one source at a time also means exactly one API stream (no rate-limit bursts) and exactly
one browser user (no collision) — failures 3 and 4 are dissolved by construction rather than
managed.

**Dispatch actor (resolved by the Task-0 spike, §14).** Preferred: dispatch `site-analyst` as a
**foreground** subagent per source (main session awaits it before the next), which uses the
purpose-built agent (fixes failure 1) and keeps each recon's context isolated from the main
session (good context hygiene, better than accumulating N recons in one context). This requires a
foreground subagent to be able to run the full recon including the Bash/browser phases (10–11) —
which the existing beacon caveat only guarantees for the *main session* (`site-analyst.md:47`,
`SKILL.md:700` scope the "background subagents lack Bash" limit to background dispatch). **Task 0
proves this before anything else is built.** Fallback if it does not hold: the main session runs
each source's `site-recon` skill itself, sequentially, still wrapped by the identical ledger +
sweep + hook. The deterministic core (ledger, sweep, hook) is unchanged either way — only the actor
differs.

## 4. Components

| Component | Path | Responsibility |
|---|---|---|
| Command | `plugins/beacon/commands/beacon-fleet.md` | `/beacon:fleet {url… \| path/to/urls.txt}`; thin; invokes the fleet skill. |
| Skill | `plugins/beacon/skills/site-fleet/SKILL.md` | The sequential orchestration procedure (§6, §10). |
| Ledger + sweep | `plugins/beacon/skills/site-recon/scripts/fleet.py` (+ `test_fleet.py`) | Durable ledger and completeness sweep. |
| Canonical slug | `plugins/beacon/skills/site-recon/scripts/slugify.py` | Single source of truth for URL→slug; called by `scaffold.sh` and `fleet.py` (§12). |
| Sweep gate | `plugins/beacon/hooks/fleet-sweep.sh` (+ `test_fleet_sweep.sh`) | `Stop`-only hook that deterministically closes the Option-A gap (§11). |

No new agent. Fleet coordination artifacts live **outside** any per-source bundle root, under
`docs/sites/.fleet/`:

- `docs/sites/.fleet/fleet-<ts>.json` — machine ledger (source of truth).
- `docs/sites/.fleet/fleet-<ts>.md` — human-readable view, regenerated from the JSON.
- `docs/sites/.fleet/active.json` — **stable handle** → `{"ledger": "<path to current fleet-*.json>"}`
  (a pure pointer; the fleet's `state` lives in the ledger — one source of truth).

Keeping these out of `docs/sites/<slug>/research/` is mandatory: `okf_validate.py` rglobs `*.md`
across the bundle **including `.beacon/`** (line 101, `.beacon/` explicitly not excluded) and fails
closed on any file without valid OKF frontmatter. `.fleet/` has no `research/INDEX.md`, so it is
invisible to `okf_validate.py`, to `okf-gate.sh`'s `find … .beacon/recon-active.json`, and to the
site-intel glob (`find docs/sites -path '*/research/INDEX.md'`) — verified in review. (This is the
C1 fix, carried over; in B1 there is no browse-plan hand-off artifact at all, so the surface is
smaller.)

## 5. Ledger schema

`fleet-<ts>.json`:

```json
{
  "created": "<ISO-8601 UTC>",
  "state": "active | paused",
  "sources": {
    "<slug>": {
      "url": "<original url>",
      "agent_id": "<subagent id | null>",
      "status": "pending | reconning | complete | blocked | inconclusive",
      "verdict": "complete | blocked:<reason> | inconclusive | null",
      "retries": 0
    }
  }
}
```

- `status` is the orchestrator's view; `verdict` is the recon's terminal outcome.
- **Terminal states** for the completeness gate: `complete` and `blocked` (a `blocked:<reason>`
  source is a decision, not a failure — §9). Everything else is *unresolved*.
- The completeness signal of record is the source's **`INDEX.md` `status`** read via
  `okf_validate.py --is-complete` (deterministic); `verdict` is advisory metadata that refines the
  *reason* an incomplete source is incomplete. A bad verdict can never produce a false `complete`.
- `<ts>` uses second precision **plus a PID/monotonic suffix** so two inits in the same second
  cannot collide on a filename.

**Single-writer invariant:** the main session is the only writer of the ledger. `fleet.py update`
takes an `flock` on the JSON (matching `okf_marker_retry.py`) to defend the invariant even against
accidental concurrent calls.

## 6. `fleet.py` interface

- `init <url…>` → resolve each URL to a slug via `slugify.py`, **dedup by slug** (§12), write
  `fleet-<ts>.json` + `.md`, and set `active.json`. **Anti-clobber (N-I1 fix):** if `active.json`
  already points at an *unresolved* fleet (state `active`/`paused` with non-terminal sources),
  `init` **refuses** with an error naming the existing ledger and telling the user to `close` or
  `pause`+resume it first. Prints `[FLEET:<ledger-path>]`.
- `update <slug> --status … [--verdict …] [--agent-id …]` → mutate one source row under `flock`,
  regenerate the `.md`. Resolves the ledger via `active.json`.
- `pending` → no argument: resolve `active.json` and list sources not in a terminal state. This is
  the **compaction-resume** entry point.
- `sweep` → resolve `active.json`; for each source read `INDEX.md` status (via
  `okf_validate.py --is-complete`) and the ledger verdict; print `[FLEET-COMPLETE]` or one
  `[FLEET-INCOMPLETE:<slug>:<reason>]` per unresolved source. Fails *toward flagging*: a
  missing/unreadable `INDEX.md` counts as incomplete.
- `pause` → set ledger `state: paused` (N-I2 fix): the Stop gate skips a paused fleet **without
  dropping `active.json`**, so `pending` can still resume it next session.
- `resume` → set `state: active` (re-arms the gate; convenience for the orchestrator).
- `waive <slug> [--reason …]` → mark one source terminal (`blocked:waived`) so the gate stops
  flagging a source that genuinely cannot complete.
- `close` → deactivate the fleet (remove `active.json`); the gate no-ops afterwards.

## 7. Verdict + sweep semantics

Each recon ends in one verdict:

- `complete` — the recon finished; its own Subsystem-A Stop-gate validated the bundle and
  `INDEX.md` is `status: complete`.
- `blocked:<reason>` — cannot proceed for a concrete reason (e.g. `blocked:auth-gated` for EMSA's
  CAC-PKI). **Terminal — never retried.**
- `inconclusive` — the recon errored, produced nothing, or the subagent returned null. **Eligible
  for one retry.**

Retry policy: an `inconclusive` source is re-dispatched **at most once**, then flagged if still not
`complete`. `blocked` is never retried. (No rate-limit backoff: sequential execution makes 429
bursts a non-issue; a lone 429 falls into `inconclusive`'s single retry. Backoff is a B2 concern.)

## 8. Input resolution

`/beacon:fleet` accepts either space-separated URLs or a path to a file with one URL per line
(a `.txt`/`.md` list). `fleet.py init` resolves each to a slug (§12), dedups by slug, and **skips a
malformed URL with a logged warning rather than aborting the fleet** — one bad line never sinks a
batch. The resolved, deduped set becomes the ledger's `sources`.

## 9. Data flow

```
/beacon:fleet urls
  └─ fleet.py init urls               → fleet-<ts>.json + .md + active.json (state:active)   [FLEET:…]
  ── SEQUENTIAL LOOP (one source at a time) ──────────────────────────────────
  for slug in fleet.py pending:       # resumable: pending re-reads the ledger every iteration
     fleet.py update <slug> --status reconning
     run site-analyst end-to-end for <url>     # Phases 1–12; its own Stop-gate validates the bundle
     determine verdict (INDEX --is-complete + the recon's terminal report)
     if inconclusive and retries < 1: retry once
     fleet.py update <slug> --status <complete|blocked|inconclusive> --verdict … --agent-id …
  ── CLOSE ────────────────────────────────────────────────────────────────────
  fleet.py sweep                      → [FLEET-COMPLETE] | [FLEET-INCOMPLETE:<slug>:<reason>]…
  (main session Stop → fleet-sweep.sh verifies + deactivates, or blocks if unresolved)
  final report: slug → status table + FLEET-INCOMPLETE list
```

Because each source is reconned whole by one actor and the loop is strictly sequential, no recon's
`Stop`/`SubagentStop` ever overlaps another source mid-completion; the cross-source false-block that
haunted the parallel design cannot occur. Resume after a compaction: re-run `/beacon:fleet` with no
args or call `fleet.py pending` — the ledger names every not-yet-terminal source.

## 10. Orchestration skill responsibilities

`skills/site-fleet/SKILL.md` drives the loop above. It: resolves input (space-separated URLs or a
file, one per line); calls `fleet.py init`; iterates `fleet.py pending`, dispatching `site-analyst`
per source and recording the outcome; retries `inconclusive` once; runs `fleet.py sweep`; and prints
the final report. It instructs the orchestrator to `fleet.py pause` before an intentional stop
mid-fleet (so the gate does not nag) and to `fleet.py close`/`waive` for sources that cannot
complete. The load-bearing guarantees (never lose a source, catch every incomplete one) are the
deterministic `fleet.py`/hook mechanisms, not this prose.

## 11. Deterministic gap closure — the fleet `Stop` hook (C4)

`fleet-sweep.sh` is registered on **`Stop` only** (never `SubagentStop`):

1. `docs/sites/.fleet/active.json` absent → exit 0 (no fleet in flight; no-op).
2. Ledger `state: paused` → exit 0 (intentional multi-session pause; handle preserved — N-I2 fix).
3. Otherwise run `fleet.py sweep`. If **every** source is terminal (`complete` or `blocked`/waived)
   → remove `active.json` → exit 0. If any source is unresolved → block (exit 2) with
   `[FLEET-SWEEP-PENDING:<slugs>]` and re-emit the sweep's per-source reasons on stderr.

This makes "did every source finish?" a deterministic check at the orchestrator's `Stop`,
regardless of whether the skill prose remembered to sweep — the actual closure of the Option-A
residual gap. `pause` preserves the resume handle for a deliberate multi-session run; `waive`/`close`
dismiss sources that cannot complete; deactivation on full resolution stops later, unrelated stops
from firing.

Independent of Subsystem A's `okf-gate.sh` (per-source, `Stop`+`SubagentStop`). Both may fire on the
same `Stop`; they do not interact (one validates each bundle, the other checks fleet completeness);
a block is the union of their exit-2s and both reasons surface on stderr (confirmed in review).

## 12. Slug handling

`fleet.py` must produce byte-identical slugs to `scaffold.sh`, or `sweep` reads the wrong
`INDEX.md`. The URL→slug rule is extracted to a canonical `slugify.py`; `scaffold.sh` calls it
(replacing its inline `sed`), `fleet.py` calls it, and `docs/SLUG_RULES.md` points at it.

**Drift guard (N-I3 fix):** `tests/validate-slug-rule.sh` currently greps for the `sed` one-liner
and tests its own inline bash `slugify()`. It is extended to run `slugify.py` against the same case
table, and a canonical `sed` copy is kept present so its existing "found a slug-rule copy" check
still passes — otherwise the Python implementation (beacon) and the bash rule (reframe, per
`docs/SLUG_RULES.md`) could silently diverge. `test_fleet.py` additionally asserts `fleet.py`'s
slugs equal `slugify.py`'s.

**Dedup at init (§6):** two input URLs on one domain slugify to one bundle root; `fleet.py init`
**rejects** duplicates with an error naming the colliding URLs (merge deferred to B2).

## 13. Review traceability (two rounds) and B2 boundary

| Finding (round) | Status in B1 |
|---|---|
| **C1** hand-off `.md` breaks validator (R1) | N/A — B1 has no hand-off artifact; `.fleet/` is outside every bundle anyway (§4). |
| **C2** collision by instruction / cmux escape (R1, R2) | **Dissolved** — one browser user at a time; no capability sandbox needed. (The cmux-sandbox problem is a B2 concern.) |
| **C3** background-Bash unvalidated (R1) | Re-scoped as the B1 Task-0 spike: can a *foreground* subagent run the full recon? (§14) |
| **C4** Option-A gap not deterministically closed (R1) | Fixed — `fleet-sweep.sh` Stop hook (§11). |
| **N-C1** cross-context content seam / hollow bundle (R2) | **Dissolved** — each source reconned whole by one actor; the Subsystem-A content model is untouched (§3). |
| **I1** stable ledger handle (R1) | Fixed — `active.json`; `pending`/`sweep`/`update` resolve it (§4, §6). |
| **N-I1** `active.json` clobber under concurrent/abandoned fleets (R2) | Fixed — `init` refuses an unresolved active fleet (§6). |
| **N-I2** Stop gate vs resume-across-sessions nag (R2) | Fixed — `pause` state suspends the gate without dropping the handle (§6, §11). |
| **I3** ledger write races (R1) | Fixed — single-writer invariant + `flock` (§5). |
| **I4 / N-I3** slug drift + duplicate-slug collision + drift-guard gap (R1, R2) | Fixed — shared `slugify.py`, `init` dedup, extended `validate-slug-rule.sh` (§12). |
| **I2** verdict via free-text (R1) | Reduced — completeness is read deterministically from `INDEX.md`; verdict is advisory only, and B1's foreground return is reliable (§5, §7). |
| **I5** retry/Phase-12 ordering race (R1) | Dissolved — sequential loop, no overlap (§9). |
| **I6** rate-limit backoff (R1) | Deferred to B2 — sequential execution removes the burst (§7). |

**B2 (deferred, own spec)** will add: waves with a concurrency cap, a capability-sandboxed passive
agent **plus a `PreToolUse` Bash hook to block cmux** (the R2 cmux finding), a content hand-off
contract (persist the session brief + passive synthesis across the seam, substance-gated), and
rate-limit backoff. B2 builds on B1's ledger, sweep, hook, and slug helper unchanged.

## 14. Build gate (Task 0) and testing

**Task 0 — foreground-subagent full-recon spike (blocking).** Before other code: dispatch one
`site-analyst` as a foreground subagent and confirm it runs the full recon end-to-end — `scaffold.sh`
+ curl phases **and** a browser Phase-11 step — returning a completed bundle. If foreground
subagents cannot drive the browser/Bash, fall back to the main-session-loop actor (§3); the ledger/
sweep/hook are unaffected. We learn this before committing to the dispatch model.

**Automated tests**
- `test_fleet.py` (pure, no network): `init` creates ledger + `active.json`; `init` **refuses** a
  second unresolved fleet; `update` mutates one row under `flock`; `pending` lists non-terminal
  sources and resolves `active.json`; `sweep` classifies complete / blocked / inconclusive /
  missing-INDEX; `pause` makes the sweep-gate skip while preserving the handle; partial-then-resume;
  duplicate-slug `init` rejects; slug-conformance vs `slugify.py`; malformed ledger fails safely.
- `test_fleet_sweep.sh`: no `active.json` → no-op; `state: paused` → no-op; all-terminal →
  deactivates + exit 0; an unresolved source → exit 2 `[FLEET-SWEEP-PENDING]`; `Stop`-only
  registration.
- Regression: `scaffold.sh` still passes `test_scaffold.sh`; `tests/validate-slug-rule.sh` passes
  with `slugify.py` covered.

## 15. Known limitations (owned honestly)

- **Sequential is slower.** A large fleet reconnoiters serially. Acceptable for the target use
  (handfuls of sources); the durable ledger makes multi-session resume clean. Throughput is exactly
  what B2 exists to improve — and B1 is the correct, proven base to add it onto.
- **Skill orchestration is not unit-testable** (needs real dispatch). Covered by the `fleet.py`/hook
  unit tests plus the doc; the deterministic guarantees live in the tested scripts, not the prose.
- **Stale draft markers.** An incomplete/blocked source keeps its `.beacon/recon-active.json`
  (harmless; `okf-gate` acts only on complete+valid).

## 16. Scope / YAGNI

No parallelism, concurrency cap, browser serialization, capability-restricted agent, content
hand-off, or rate-limit backoff — all B2. Retry bound = 1; `blocked` never retried. Duplicate-slug
`init` rejects (no merge). No change to `/beacon:analyze`. A minor version bump (`0.8.0`) and
CHANGELOG entry ship with the implementation.
