# Model Router — Design Spec

**Date:** 2026-07-27
**Status:** Approved for planning
**Supersedes:** the phantom `2026-07-08-model-router-design.md` reference and the pipeline-centric
design previously described in `docs/plugins/model-router/architecture.md`.

---

## 1. Purpose

A user working in a CLI coding tool (OpenCode, Claude Code, and later Codex, Cursor, Kiro,
Kilo) asks:

> "Which of **my** models should I use for this task?"

and gets **1–3 ranked recommendations with a one-line rationale each**, drawn only from the
models the user actually has access to (their authenticated providers), scored against
current facts (pricing, context, capabilities) and current judgment (benchmarks).

### Origin

The original design targeted "all 347+ models" with a 14-dimension weighted scoring engine,
multi-stage pipeline templates, an MCP server, and SQLite caching. Brainstorming (2026-07-10)
established the real problem is much smaller: the user has ~9 authenticated providers in
OpenCode and cannot tell which of *those* models fits a given task. The design was cut down,
then re-generalized along exactly one axis: **other people, other tools, same question** —
via an adapter architecture rather than a larger feature set.

## 2. Goals

1. **Answer from the user's real candidate set** — discovered from their tool config, not a
   global catalog. Manual fallback when discovery isn't possible.
2. **Stay current without maintenance** — new models appear in recommendations as soon as
   the registries know them; no hand-curated catalog to maintain.
3. **Deterministic extraction, in-context judgment** — everything that must be *correct*
   (config parsing, API fetching, ID joining, snapshot validation) is a script; everything
   that must be *wise* (matching task to data, weighing trade-offs, writing rationale) is
   the model reasoning over merged JSON. (Lesson from beacon/reframe: prose-only steps get
   skipped under synthesis pressure — gate what matters in code.)
4. **Shareable** — works out of the box for other people on supported tools, degrades
   gracefully everywhere else, and adding a tool adapter is a contribution-sized task.
5. **Explainable** — every recommendation cites its sources ("AA Intelligence 62, 210 t/s,
   free on your NVIDIA key").

## 3. Non-goals (v1)

- Multi-stage pipeline templates, capability vectors, constraint-relaxation chains — **cut**.
  If a user describes a multi-step job, the skill may naturally suggest a model per step in
  prose; there is no pipeline machinery.
- A numeric scoring engine with weighted composite formulas — **cut**. Candidate sets are
  dozens, not hundreds; in-context judgment over clean benchmark numbers is both better and
  more explainable at that scale.
- An MCP server, SQLite cache, or any long-running runtime — **cut**. Scripts + skill only.
- Scraping. Sources without APIs (Vellum, lmarena) are out of the deterministic core.
- Codex/Cursor/Kiro/Kilo config adapters (v2 — they start on the manual fallback).

## 4. Users

| Persona | Need | v1 answer |
|---------|------|-----------|
| Multi-provider OpenCode user (primary — Georgios) | "Which of my 9 providers' models for this task?" | auto-discovery + ranked recommendation |
| Speed-critical builder | "Fastest model that can do X" | AA TPS/TTFT in the merged record + rationale |
| Quality maximizer | "Compare A vs B vs C" | same data path, comparison phrasing |
| Free-tier starter | "Best completely free model right now" | `is_free` derived live from pricing; free-variant limits |

## 5. Architecture

Two adapter families feed one merge; one skill reasons over the result.

```
plugins/model-router/
├── .claude-plugin/plugin.json
├── skills/
│   ├── recommend/SKILL.md        "which model for X" + "compare A vs B"
│   └── refresh/SKILL.md          runs refresh_benchmarks.py, validates, reports diff
├── scripts/
│   ├── discover.py               ENVIRONMENT adapters → candidate model IDs
│   ├── enrich.py                 DATA adapters → merged candidates.json
│   └── refresh_benchmarks.py     Artificial Analysis API → data/benchmarks.json
├── data/
│   ├── benchmarks.json           committed AA snapshot (with fetched_at)
│   ├── aliases.json              cross-source ID map (only where IDs differ)
│   └── user-notes.md             optional personal ranking overrides
└── tests/
    └── fixtures/                 fake configs + fake registry payloads → exact outputs
```

### 5.1 Environment adapters (`discover.py`)

Contract per adapter: `detect() -> bool` (is this tool present/active?) and
`candidates() -> [{provider, model_id}]`.

| Adapter | Detection | Candidate source | v1 |
|---------|-----------|-----------------|----|
| `opencode` | `~/.local/share/opencode/auth.json` exists | providers from `auth.json` (+ project/global `opencode.json` overrides) → models resolved via models.dev | ✅ |
| `claude-code` | `~/.claude/` exists | static Claude model set (subscription models) | ✅ |
| `manual` | always | user names providers/models inline; skill passes them through | ✅ (fallback) |
| `codex` | `~/.codex/config.toml` | parse config | v2 |
| `cursor` / `kiro` / `kilo` | TBD (configs poorly documented) | TBD | v2 |

Selection: run all `detect()`s; if exactly one real adapter matches, use it; if several
match (user has both tools), prefer the tool the session is running in when identifiable,
else ask. If none match, use `manual`.

### 5.2 Data adapters (`enrich.py` + `refresh_benchmarks.py`)

Each source is included because it is the **best** source for a data type, not for overlap:

| Source | THE source for | Access | Fetch mode |
|--------|---------------|--------|-----------|
| **models.dev** (`/api.json`) | candidate resolution: provider→model mapping, context, base pricing, modalities (154 providers; the registry OpenCode itself uses) | public JSON, no key | live at query time, 24h cache |
| **OpenRouter** (`/api/v1/models`) | capability flags: tools, structured output, reasoning; `:free` variant limits | public JSON, no key | live at query time, 24h cache |
| **Artificial Analysis** (official API) | judgment: Intelligence Index, coding index, output TPS, TTFT, cost-per-task | API key (free registration), `ARTIFICIALANALYSIS_API_KEY` env var | offline refresh → committed `benchmarks.json` |
| HuggingFace | open-weight metadata (license, downloads) | public API | v2 |
| Vellum / lmarena | SWE-Bench, Elo | **no API** | dropped from core; optional LLM-refresh overlay in v2, never on the query path |

**Freshness model — split by volatility, not by source:**
- *Facts* (what exists, prices, capabilities, free tiers) are perishable → fetched live from
  keyless APIs on every run, 24h cache in `~/.cache/model-router/`.
- *Judgment* (benchmark scores) is shelf-stable → committed snapshot, refreshed
  deterministically via `/model-router:refresh`. Snapshot older than 30 days ⇒ warning in
  every recommendation. Models present live but absent from the snapshot are still
  recommended, marked `confidence: low` — new releases surface immediately, honestly.

**Entity resolution:** `aliases.json` maps IDs across models.dev / OpenRouter / AA, with
entries only where IDs differ (they mostly align). `enrich.py` warns on benchmark entries
that match no live model and fails on alias collisions.

### 5.3 Merged candidate record (output of `enrich.py`)

```yaml
model_id: string                # models.dev id
provider: string                # which of the USER'S providers serves it
display_name: string
context_length: int
max_output_tokens: int | null
pricing_usd_per_mtok: {input: float, output: float}
# is_free is DERIVED (input == 0 && output == 0), never stored (ADR-002)
free_variant: {id, context_length, rate_limits} | null
modalities: {input: [..], output: [..]}
capabilities: {tools: bool, structured_output: bool, reasoning: bool}
benchmarks:                     # null when model not in snapshot → confidence: low
  aa_intelligence_index: float | null
  aa_coding_index: float | null
  aa_output_tps: float | null
  aa_ttft_seconds: float | null
  aa_cost_per_task_usd: float | null
  fetched_at: string
sources: [string]               # which adapters contributed, for rationale attribution
```

### 5.4 Recommend flow

1. Skill parses the task (needs vision? long context? tools? free-only? speed-critical?).
2. Runs `discover.py` → candidate IDs; `enrich.py` → merged `candidates.json`.
3. Applies `user-notes.md` overrides if present.
4. Reasons over the merged records: hard requirements first (context, modality, tools),
   then trade-offs (quality vs speed vs cost) per the task.
5. Emits 1–3 ranked models, each with: one-line rationale citing sources, is_free,
   confidence (high = benchmarks + capability data agree; low = no benchmark coverage),
   and any staleness warnings.

Compare ("A vs B") is the same path with a fixed candidate list and side-by-side output.

## 6. Error handling

| Failure | Behavior |
|---------|----------|
| models.dev / OpenRouter unreachable | use last cache + staleness note; if no cache has ever existed, recommend from benchmarks snapshot only, with a clear warning |
| no tool config found | fall back to `manual` adapter — ask the user to name providers |
| AA key missing on refresh | refresh skill explains registration (free) and the env var; recommend flow is unaffected |
| snapshot > 30 days old | warning appended to every recommendation, pointing to `/model-router:refresh` |
| no candidate satisfies hard requirements | say so explicitly and show the closest candidates with what they're missing — never silently return empty (spirit of old ADR-004, without the relaxation-chain machinery) |

## 7. Testing

- Fixture tests for `discover.py`: fake `auth.json` / `opencode.json` / `~/.claude` layouts
  → exact candidate lists.
- Fixture tests for `enrich.py`: fake registry payloads + fake snapshot → exact merged
  records, including alias joins, free-variant derivation, and missing-benchmark handling.
- Schema check for `benchmarks.json` (run by the refresh skill before accepting a new
  snapshot — fail closed).
- CI-optional canary: one real request to each live endpoint.

## 8. Roadmap

**v1:** everything above.

**v2:** codex/cursor/kiro/kilo adapters (ideally contributed/tested by users of those
tools) · HuggingFace adapter · Vellum/lmarena LLM-refresh overlay · scheduled auto-refresh
of the snapshot · lightweight multi-step task structuring (prose-level, still no templates).

## 9. Decisions

Recorded as ADR-006…010 in `docs/plugins/model-router/DECISIONS.md`:

- **ADR-006** — scope: single-task recommendation from the user's actual models; pipelines cut.
- **ADR-007** — two adapter families; v1 environment adapters = opencode, claude-code, manual.
- **ADR-008** — models.dev is the candidate-resolution source of truth; OpenRouter provides
  capability flags (supersedes ADR-001's "OpenRouter primary").
- **ADR-009** — freshness split by volatility: live keyless facts vs committed AA snapshot;
  Vellum/lmarena dropped from the deterministic core (supersedes ADR-003).
- **ADR-010** — scripts + skill, no MCP server; deterministic extraction in code,
  judgment in-context (supersedes ADR-005's scoring-engine framing; auditability is
  preserved through source-attributed rationale).

ADR-002 (derived `is_free`) survives unchanged.
