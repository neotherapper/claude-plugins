# beacon — Enforced OKF Output Contract

- **Date:** 2026-07-02
- **Status:** approved (design); ready for implementation plan
- **Branch:** `feat/beacon-okf-output-contract`
- **Scope owner:** beacon plugin / `plugins/beacon/skills/site-recon/`
- **Source of findings:** field evaluation of session "scrum-677" (11 beacon-recon subagent
  transcripts + parent orchestration). Full report:
  `scratchpad/analysis/BEACON-FIELD-REPORT.md` (this session).

## Context

A field review of 11 subagents that used `site-recon` in the wild (JIRA SCRUM-677, maritime
data-source recon) produced one dominant finding: **beacon's investigative posture landed, but its
machinery evaporated.** 10/11 agents correctly invoked the skill and produced excellent,
live-verified recon — but **0/11 maintained a session brief, emitted a phase marker, or ran a single
bundled script**, and **2/14 output folders (`emsa-emcip`, `lloyds-sab`) are empty** because the
agent explored deeply and never wrote output. The 908-line SKILL.md was read once as background and
then ignored.

The root cause is that beacon's output structure is **prose the model must remember to produce**;
nothing deterministic forces the files to exist or to conform. This matches a standing project note:
*"prose-only skill steps get skipped under synthesis pressure — gate what matters deterministically."*

This spec designs **Subsystem A: an enforced OKF output contract** — the root-cause fix. It makes the
output files exist from the start, conform to a validated schema, and gate completion deterministically.
**Subsystem B (fleet orchestration)** is sketched at the end and deferred to its own spec.

## Goals

1. Output files **exist from Phase 1** (scaffold), so "write into these" replaces "remember to create these."
2. Output **conforms to a schema** — the Google Open Knowledge Format (OKF) v0.1 interoperability
   surface plus a beacon producer content-model with typed properties and **enums**.
3. A **deterministic convergence gate**: a recon run cannot be declared complete if required files are
   missing, empty, or invalid (would have caught the `emsa-emcip` no-output case).
4. Research bundles become **agent-portable + graph-linked** (OKF), readable by humans and any agent.
5. **Caller-supplied output root** is a first-class input (kills the `docs/research` vs `docs/sites`
   landmine that put scrum-677's output on a path beacon 0.8.0 makes read-only).

## Non-goals (this spec)

- The open-data / document-source **recon mode** itself (report P2). The OKF profile below is
  mode-aware and reserves the data-source `type`s, but designing that mode is separate.
- **Fleet orchestration** (report P3 / Subsystem B) — sketched, deferred.
- Migrating scrum-677's existing `docs/research/` output (separate operational task).

## Background — Google OKF v0.1 (the standard we conform to)

Google Cloud published **Open Knowledge Format v0.1** on 2026-06-12 (Apache 2.0). Salient rules:

- A **bundle** is a directory of markdown files; **no manifest required**. Each file is a **concept**;
  its **path is its identity**.
- **Only `type` is required** in frontmatter. Reserved optional fields: `title`, `description`,
  `resource` (URL), `tags`, `timestamp` (ISO 8601). **Producers may add custom fields.**
- **Relationships are plain markdown links** — that is what makes the directory a graph.
- Two reserved filenames: `index.md` (progressive disclosure entrypoint) and `log.md` (change history).

Beacon becomes an **OKF producer**: it conforms to this interoperability surface and defines its own
content model (beacon `type` enum + typed producer fields). Beacon ships its **own** validator
(modelled on ai-sdlc's `okf_validate.py`) rather than hard-depending on ai-sdlc, which lives in a
separate marketplace.

## Design

### Component 1 — Beacon OKF producer profile (schema)

New reference: `plugins/beacon/skills/site-recon/references/okf-profile.md`. The authoritative,
human/agent-readable schema. It defines:

**Closed beacon `type` enum** (unknown value = validation failure, by design):

| `type` | File | Notes |
|--------|------|-------|
| `site-index` | `INDEX.md` | the OKF `index.md` entrypoint; links to every other concept |
| `tech-stack` | `tech-stack.md` | framework/version/CDN/auth/hosting |
| `site-map` | `site-map.md` | discovered URLs by category |
| `api-surface` | `api-surfaces/{surface}.md` | one per surface |
| `constants` | `constants.md` | nonces/enums/public config |
| `openapi-spec` | `specs/{slug}.openapi.yaml` | referenced, not frontmattered (YAML file) |
| `session-brief` | `.beacon/session-brief.md` | running working memory |
| `data-source-index` | `INDEX.md` (data mode) | reserved for the open-data mode |
| `dataset` | `datasets/{name}.md` (data mode) | reserved |
| `access-profile` | `access.md` (data mode) | reserved |

**Reserved OKF fields used:** `type` (required), `title`, `description`, `resource`, `tags`,
`timestamp`.

**Beacon producer fields with enums** (the "specific properties + enum values"):

| Field | Enum / form | Applies to |
|-------|-------------|-----------|
| `access_mode` | `open-api \| bulk-download \| scrape \| gated \| mixed` | api-surface, index |
| `auth` | `none \| api-key \| oauth \| session \| cac-pki \| account` | api-surface |
| `bot_protection` | `none \| cloudflare \| akamai \| datadome \| perimeterx \| f5 \| recaptcha \| turnstile` | tech-stack, api-surface |
| `verification` | `live-verified \| wayback-verified \| asserted-unverified` | api-surface |
| `status` | `draft \| in-progress \| complete` | all (drives the gate) |
| `licensing` | free string (SPDX-ish) | data-source mode |

**Edges** are markdown links (OKF graph): `INDEX.md` links to each surface; an `api-surface` links to
its `openapi-spec`. Optional explicit `depends_on`/`feeds_to` frontmatter lists (ai-sdlc-style) may
back the same edges for machine traversal — decided at plan time; markdown links are the minimum.

Example (`api-surfaces/nav-warnings.md`):

```yaml
---
type: api-surface
title: NGA MSI — Broadcast Navigational Warnings
description: Public JSON REST surface for NAV warnings + ASAM.
resource: https://msi.nga.mil/api/publications/broadcast-warn
tags: [maritime, distress, open-data]
timestamp: 2026-07-02T16:55:00Z
access_mode: open-api
auth: none
bot_protection: f5
verification: live-verified
status: complete
openapi: ./specs/nga-msi.openapi.yaml
---
```

### Component 2 — Scaffold script (Phase 1)

New: `plugins/beacon/skills/site-recon/scripts/scaffold.sh` (bash; a `.py` variant is a plan-time
call). Invoked as the **first action** of Phase 1. Behaviour:

1. Resolve `OUTPUT_ROOT` — **caller override** honored (skill `args` / env), default
   `docs/sites/{slug}/research/`. Log `[OUTPUT-OVERRIDE:{path}]` when overridden.
2. `mkdir -p` the tree (`api-surfaces/`, `specs/`, `.beacon/`).
3. Copy OKF-frontmatter **stub templates** (new `plugins/beacon/templates/okf/*.md`, evolved from the
   existing `templates/`) into place — every stub carries valid frontmatter with `status: draft` and
   placeholder body sections. Mirrors ai-sdlc okf-author **Bundle mode** (copy template, fill
   frontmatter, leave section placeholders for the owning phase).
4. Write real `.beacon/session-brief.md` and `.beacon/phase-checklist.md` files (not in-context markdown).

Phases 2–12 then **edit into** these files (`Edit`/`Write` on an existing path), so an abandoned run
still leaves partial, schema-valid artifacts instead of nothing.

### Component 3 — Validator (fail-closed)

New: `plugins/beacon/skills/site-recon/scripts/okf_validate.py`. Modelled on ai-sdlc's
`okf_validate.py`. Given an output root, it fails (non-zero exit) on any of:

- a file whose `type` is absent or not in the beacon enum;
- a required producer field missing, or an enum field with an illegal value;
- a dangling markdown-link edge (target file does not exist);
- `INDEX.md` not present / not reachable as the entrypoint;
- a stub left unfilled (placeholder token present) when `status: complete` is claimed.

Ships with a test (`test_okf_validate.py`) like ai-sdlc's `test_okf_validate.py`.

### Component 4 — Deterministic gate (hook)

New beacon plugin hook (`plugins/beacon/hooks/`), `SubagentStop` + `Stop`. **Option A semantics:**
the hook is a silent no-op until the recon *claims completion* — signalled by `INDEX.md`
frontmatter being `status: complete` (Phase 12 flips it as its last step). Only then does it run
`okf_validate.py` against the output root and block/flag on failure. This catches the
"claimed-done-but-invalid" case deterministically without false-triggering on normal mid-run
Stop/SubagentStop events (a fresh scaffold is all `status: draft`, which is valid but unfinished —
gating on that would block/delete-the-marker on every routine subagent handoff). The
abandoned/no-output case (`emsa-emcip`/`lloyds-sab`-style: recon started, nothing ever written) is
caught upstream instead — by the Phase-12 self-gate (Component 5) and, longer-term, the deferred
Subsystem-B orchestrator sweep — not by this hook.

A hook cannot know the output root without a hint; the scaffold writes a `.beacon/recon-active.json`
marker (`output_root` + `retries`) that the hook reads and deletes on success/give-up. Mechanism
finalised at plan time.

### Component 5 — SKILL.md wiring

- A **Quickstart** block at the very top (surfaced immediately on skill launch): *"Before anything
  else: run `scaffold.sh`, then tick `.beacon/phase-checklist.md` as you go."* — action before taxonomy.
- **Phase 12 gate** greps `.beacon/phase-checklist.md` for a mode-appropriate floor and runs
  `okf_validate.py` before declaring done.
- `site-analyst` agent gains OKF-author awareness (it writes conformant files) — its description is
  also broadened so an orchestrator reaches for it (relevant to Subsystem B).

## Enforcement stance (why hook + validator, not an "enforcer agent")

The user's phrase was "an OKF agent that enforces." An agent that enforces is non-deterministic and
skippable — the exact failure mode this spec exists to kill. So enforcement is the **deterministic**
`okf_validate.py` + hook (Components 3–4). An **optional semantic-QA subagent** (does the api-surface
actually document the fields it claims?) may layer on top later, but it is never the gate.

## Data flow

```
Phase 1   scaffold.sh → OKF stub files + .beacon/{session-brief,phase-checklist,output-root}
Phase 2-11 append to session-brief; each phase Edits the relevant OKF file (fills enums + body);
           tick phase-checklist
Phase 12  fill INDEX.md (entrypoint) + log.md → run okf_validate.py
Stop      hook re-runs okf_validate.py → blocks on any violation
```

## Isolation / interfaces

- **scaffold.sh**: input `OUTPUT_ROOT` + `slug` + `mode`; output = a valid empty bundle. No network.
- **okf_validate.py**: input = output root; output = exit code + violation list. Pure/deterministic.
- **okf-profile.md**: the single source of truth both scripts and the skill read from.
- **hook**: input = stop event; calls the validator. Swappable.

Each unit is independently testable; the profile doc is the contract between them.

## Risks / open questions (resolve at plan time)

1. **Hook ↔ output-root discovery** — marker file vs directory scan (Component 4).
2. **`depends_on`/`feeds_to` frontmatter vs markdown-links-only** for edges — start links-only (OKF
   minimum), add explicit edges only if the validator needs them.
3. **Existing `templates/` reuse** — evolve in place vs new `templates/okf/`. Prefer evolving to avoid
   two template sets.
4. **`.beacon/` placement under a caller override** — keep `.beacon/` beside the output root.

## Subsystem B — Fleet orchestration (deferred; sketch only)

A follow-on spec. A `/beacon:fleet` command (or companion skill) that:
- dispatches sources through the real **`site-analyst`** agent (+ rewrites its description so an
  orchestrator actually reaches for it — today it reads as a sub-task helper, not a full-recon runner);
- writes a **fleet ledger** (`slug → agent-id → status`) to `.beacon/fleet.md` so a compacted batch is
  never lost (scrum-677 lost a 6-agent wave to context compaction);
- **caps concurrency ~3** (6 tripped API rate limits);
- **fans out passive Phases 1–9 in parallel but serializes browser Phases 10–11 behind a single-holder
  "browser lease,"** so no two agents drive one Chrome at once (fixes the observed Chrome DevTools MCP
  session collisions). Consistent with beacon's existing "keep Phases 10–11 in the main session" note.

## Traceability to field-report findings

| Finding | Fixed by |
|---------|----------|
| Phase discipline 0/11; session brief never maintained | Components 2, 4, 5 |
| `emsa-emcip`/`lloyds-sab` produced no output | Components 2 (scaffold), 5 (Phase-12 self-gate); stop gate (Component 4) only enforces on claimed-complete bundles |
| Output-path landmine (`docs/research` vs `docs/sites`) | Component 2 (`OUTPUT_ROOT`) |
| No typed/enum output schema; no licensing capture | Component 1 (profile) |
| Bundled scripts never run / deterministic gate absent | Components 3–4 |
| Generic agents, lost batch, rate limits, Chrome collision | Subsystem B (deferred) |
