# Model Router — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

Model Router answers one question: **"Which of MY models should I use for this task?"**
It discovers the models the user actually has access to (from their CLI tool's config),
enriches them with live facts (pricing, context, capabilities) and committed benchmark
judgment, and recommends 1–3 models with a one-line rationale each.

**Commands:** `/model-router:recommend` · `/model-router:refresh`
(comparison is a phrasing of `recommend`: "compare A vs B")

**Version:** 0.1.0 — see `features.md` for v1 scope and v2 roadmap.

---

## File map

```
plugins/model-router/
├── .claude-plugin/
│   └── plugin.json               manifest
├── skills/
│   ├── recommend/SKILL.md        main entry: task → ranked models with rationale
│   └── refresh/SKILL.md          refresh benchmarks.json from the AA API, validate, report diff
├── scripts/
│   ├── discover.py               environment adapters: which tool am I in → candidate models
│   ├── enrich.py                 data adapters: merge live facts + snapshot → candidates.json
│   └── refresh_benchmarks.py     deterministic AA fetch → data/benchmarks.json
├── data/
│   ├── benchmarks.json           committed Artificial Analysis snapshot (fetched_at inside)
│   ├── aliases.json              cross-source ID map (entries only where IDs differ)
│   └── user-notes.md             optional personal ranking overrides
└── tests/
    └── fixtures/                 fake configs + fake registry payloads
```

---

## The two adapter families

**Environment adapters** (in `discover.py`) find the user's real candidate set.
Contract: `detect() -> bool`, `candidates() -> [{provider, model_id}]`.
v1: `opencode` (auth.json + models.dev), `claude-code` (static Claude set),
`manual` (always-available fallback — user names providers inline).
v2: `codex`, `cursor`, `kiro`, `kilo`.

**Data adapters** (in `enrich.py` / `refresh_benchmarks.py`) know things about models:

| Source | THE source for | Access | Mode |
|--------|---------------|--------|------|
| models.dev | provider→model mapping, context, pricing, modalities | public JSON, no key | live, 24h cache |
| OpenRouter | capability flags (tools/structured/reasoning), `:free` variant limits | public JSON, no key | live, 24h cache |
| Artificial Analysis | Intelligence/coding index, TPS, TTFT, cost-per-task | official API, free key (`ARTIFICIALANALYSIS_API_KEY`) | offline refresh → committed snapshot |
| HuggingFace | open-weight metadata | public API | v2 |
| Vellum / lmarena | SWE-Bench, Elo | no API | **not in deterministic core** (v2 LLM-refresh overlay at most) |

---

## Key rules

- **Deterministic extraction, in-context judgment.** Config parsing, API fetching, ID
  joining, and snapshot validation live in scripts. Task matching, trade-off weighing, and
  rationale live in the skill. Never move math-that-must-be-correct into prose.
- **Candidates come from the user, not a catalog.** Never recommend a model the user's
  providers don't serve (manual adapter aside).
- **`is_free` is never stored.** Derived from `pricing.input == 0 && pricing.output == 0`
  (ADR-002). Free variants keep their own limits block.
- **Freshness splits by volatility.** Facts live (24h cache, stale-cache fallback);
  judgment committed (staleness warning after 30 days). New models without benchmark
  coverage are recommended with `confidence: low`, never hidden.
- **Never silently return empty.** If nothing satisfies hard requirements, say so and show
  the closest candidates with what they're missing.
- **Every recommendation cites sources.** "AA Intelligence 62, 210 t/s (AA), free on your
  NVIDIA key (models.dev)."

---

## Validation

All in `tests/`. Run before any PR: fixture tests for `discover.py` and `enrich.py`
(exact-output), schema check for `benchmarks.json` (refresh fails closed on violation).

---

## Related docs

| Doc | Location |
|-----|----------|
| Design spec | `docs/superpowers/specs/2026-07-27-model-router-design.md` |
| Personas | `docs/plugins/model-router/personas.md` |
| Features & roadmap | `docs/plugins/model-router/features.md` |
| Architecture detail | `docs/plugins/model-router/architecture.md` |
| Decisions (ADRs) | `docs/plugins/model-router/DECISIONS.md` |
