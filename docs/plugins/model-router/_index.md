# Model Router — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

Model Router connects to live AI model registries and benchmarking APIs to recommend the optimal model(s) for a given task. It breaks complex multi-step workflows into stages, each scored against capability vectors (agentic coding, search, knowledge work, speed, cost), and returns a ranked pipeline with per-stage rationale.

**Commands:** `/model-router:recommend` · `/model-router:compare` · `/model-router:cache`

**Version:** 0.1.0 — see `features.md` for v1 scope and v2+ roadmap.

---

## File map

```
plugins/model-router/
├── _index.md              ← you are here
├── personas.md            ← who uses this plugin and how
├── features.md            ← v1 shipped features + v2+ roadmap
├── architecture.md        ← adapters, scoring, pipeline design
│
├── .claude-plugin/
│   └── plugin.json        ← manifest: name, version, author, hooks, skills[]
│
├── skills/
│   ├── recommend/
│   │   ├── SKILL.md                    ← /model-router:recommend — main routing
│   │   └── references/
│   │       ├── stage-templates.md      ← curated pipeline templates
│   │       ├── scoring-formulas.md     ← how composites are computed
│   │       └── output-spec.md          ← recommendation output schema
│   ├── compare/
│   │   ├── SKILL.md                    ← /model-router:compare — side-by-side
│   │   └── references/
│   │       └── comparison-spec.md
│   └── cache/
│       └── SKILL.md                    ← /model-router:cache — manage cache
│
├── agents/
│   └── router-agent.md     ← orchestrates adapter calls, scoring, pipeline design
│
├── schemas/
│   ├── model.schema.json          ← unified model record
│   ├── stage-template.schema.json ← pipeline template structure
│   └── recommendation.schema.json ← output schema
│
├── scripts/
│   ├── fetch-openrouter.sh   ← curl wrapper for /api/v1/models
│   ├── fetch-aa.py           ← Artificial Analysis page scraper
│   └── merge-models.py       ← deduplicate + normalize across sources
│
└── hooks/
    └── hooks.json            ← SessionStart: detect platform, hint commands
```

---

## Data sources

| Source | What it provides | Access | Reliability |
|--------|-----------------|--------|-------------|
| **OpenRouter** `/api/v1/models` | Pricing, context, modalities, reasoning, free-tier, supported parameters, expiration | Public REST, no key required | High — versioned, stable |
| **Artificial Analysis** | Intelligence Index, speed (TPS), TTFT, cost per task, verbosity, openness, sub-benchmarks | Public per-model pages (scrape) | Medium — no API, page structure may change |
| **Vellum** leaderboard | HLE, SWE-Bench, Terminal-Bench, OSWorld, BrowseComp, AutoBench, GPQA Diamond | Public leaderboard pages (scrape) | Low — no API, fragile |
| **lmarena** | Agent Elo, Text/WebDev/Vision/Search Elo rankings | Public leaderboard pages (scrape) | Low — no API, sub-category breakdowns unavailable |
| **HuggingFace** | Open-weight metadata, license, downloads, model cards | Public REST API | High — versioned |

---

## Validation

All in `tests/`. Run before any PR:

| Script | What it checks |
|--------|---------------|
| `validate-schema.sh` | JSON Schema conformance for model, stage-template, recommendation |
| `validate-scoring.sh` | Weight sums, composite score formulas, edge cases |
| `validate-adapters.sh` | Adapter response parsing, normalization, deduplication |

---

## Key rules

- **OpenRouter is primary.** It covers 343+ models including all NVIDIA free models. Other sources are supplementary scoring layers.
- **Task types are derived, not tagged.** The 12 task types (Text Generation, Image-to-Text, ASR, etc.) come from `architecture.modality` + `input_modalities`. A model can have multiple task types (e.g., `Text Generation` + `Image-to-Text`).
- **Capabilities are orthogonal to task types.** A `Text Generation` model can have `Reasoning + Function calling + Vision`. A `Image-to-Text` model can have `Vision`. Tags come from OpenRouter fields + Cloudflare taxonomy.
- **`is_free` is never stored.** Derived from `pricing.input == 0 && pricing.output == 0`. Free variants (`:free` suffix) get a separate `free_tier` block with variant-specific limits.
- **Scoring composites are explicit formulas.** `agentic_coding` = weighted(SWE-Bench, Terminal-Bench, lmarena-code). No magic. All formulas in `scoring-formulas.md`.
- **Constraint relaxation is mandatory.** Every stage template must define a relaxation chain — never silently return empty.
- **Stale data is flagged.** Every source block has `fetched_at`. Cache TTL is 6h for OpenRouter, 24h for scraped sources. Stale data surfaces a warning, never a silent recommendation.
- **Same model, multiple providers.** OpenRouter may serve the same model from different providers with different pricing/speed. The `offerings` array captures this; scoring picks the best offering per model.

---

## Related docs

| Doc | Location |
|-----|----------|
| Design spec | `docs/superpowers/specs/2026-07-08-model-router-design.md` |
| Feature specs (.feature) | `docs/plugins/model-router/specs/` |
| Personas | `docs/plugins/model-router/personas.md` |
| Features & roadmap | `docs/plugins/model-router/features.md` |
| Architecture detail | `docs/plugins/model-router/architecture.md` |
| User-facing README | `plugins/model-router/README.md` |
