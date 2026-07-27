# Model Router — Architecture

## Overview

Two adapter families feed one merge; one skill reasons over the result. No MCP server, no
SQLite, no scoring engine — scripts produce data, the model produces judgment.

```
User: "which model for <task>?"            (in OpenCode, Claude Code, …)
  │
  ▼
/model-router:recommend  (skill — orchestration + judgment)
  │
  ├─ 1. discover.py ──────────────► candidate model IDs
  │       environment adapters:
  │         opencode     auth.json → providers → models.dev models   (v1)
  │         claude-code  ~/.claude → static Claude set               (v1)
  │         manual       user names providers inline                 (v1 fallback)
  │         codex/cursor/kiro/kilo                                   (v2)
  │
  ├─ 2. enrich.py ────────────────► candidates.json (merged records)
  │       data adapters:
  │         models.dev   context, pricing, modalities     live, 24h cache
  │         OpenRouter   capability flags, :free limits   live, 24h cache
  │         benchmarks.json  AA snapshot (committed)      joined via aliases.json
  │
  ├─ 3. apply data/user-notes.md overrides (if present)
  │
  └─ 4. reason over merged records:
         hard requirements (context, modality, tools, free-only)
         → trade-offs (quality vs speed vs cost) per the task
         → 1–3 ranked models, one-line rationale each, confidence, warnings

/model-router:refresh  (skill)
  └─ refresh_benchmarks.py ──► Artificial Analysis official API
       → validate against schema (fail closed) → write data/benchmarks.json → report diff
```

## Division of labor

| Concern | Where | Why |
|---------|-------|-----|
| Config parsing, API fetching, ID joins, caching, snapshot validation | scripts | must be *correct* — deterministic, fixture-testable |
| Task interpretation, trade-off weighing, rationale writing | skill (in-context) | must be *wise* — candidate sets are dozens, not hundreds; judgment over clean numbers beats formula composites and stays explainable |

This split is the beacon/reframe lesson applied: prose-only steps get skipped under
synthesis pressure, so anything that must not be skipped or approximated is code.

## Environment adapter contract

```python
class Adapter:
    name: str
    def detect(self) -> bool: ...          # is this tool present/active?
    def candidates(self) -> list[Candidate]: ...   # [{provider, model_id}]
```

Selection: run all `detect()`s. Exactly one match → use it. Several (user has multiple
tools) → prefer the tool the session runs in when identifiable, else ask. None → `manual`.

Adding a tool = one adapter class + fixtures. This is the intended contribution surface.

## Merged candidate record

```yaml
model_id: string                # models.dev id
provider: string                # which of the USER'S providers serves it
display_name: string
context_length: int
max_output_tokens: int | null
pricing_usd_per_mtok: {input: float, output: float}
# is_free DERIVED from pricing at read time, never stored (ADR-002)
free_variant: {id, context_length, rate_limits} | null
modalities: {input: [..], output: [..]}
capabilities: {tools: bool, structured_output: bool, reasoning: bool}
benchmarks:                     # null → confidence: low, model still recommended
  aa_intelligence_index: float | null
  aa_coding_index: float | null
  aa_output_tps: float | null
  aa_ttft_seconds: float | null
  aa_cost_per_task_usd: float | null
  fetched_at: string            # ISO 8601
sources: [string]               # attribution for rationale
```

## Freshness model

Split by **volatility**, not by source:

| Class | Examples | Mechanism |
|-------|----------|-----------|
| Perishable facts | what exists, pricing, free tiers, capability flags | live keyless fetch every run; 24h cache in `~/.cache/model-router/`; stale-cache fallback on network failure |
| Shelf-stable judgment | AA benchmark scores | committed `data/benchmarks.json`; deterministic refresh via `/model-router:refresh`; >30-day age ⇒ warning in every output |

New model in the registries but not in the snapshot ⇒ recommended with `confidence: low`
and a note — never hidden, never silently trusted.

## Entity resolution

`data/aliases.json` maps IDs across models.dev / OpenRouter / AA — entries only where IDs
actually differ (they mostly align). `enrich.py` **warns** on snapshot entries matching no
live model (may be pre-listing) and **fails** on alias collisions.

## Error handling

| Failure | Behavior |
|---------|----------|
| registry unreachable | last cache + staleness note; never-cached ⇒ snapshot-only mode with warning |
| no tool config found | `manual` adapter — ask user for providers |
| AA key missing | refresh explains free registration + `ARTIFICIALANALYSIS_API_KEY`; recommend unaffected |
| nothing meets hard requirements | say so; show closest candidates and what they lack — never empty output |

## Testing

- `discover.py` fixtures: fake `auth.json` / `opencode.json` / `~/.claude` → exact candidate lists
- `enrich.py` fixtures: fake registry payloads + fake snapshot → exact merged records
  (alias joins, free-variant derivation, missing-benchmark handling)
- `benchmarks.json` schema check — refresh fails closed
- CI-optional canary against real endpoints
