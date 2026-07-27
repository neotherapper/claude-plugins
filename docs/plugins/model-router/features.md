# Model Router — Features

## v1.0

### Discovery (environment adapters)
- [ ] `opencode` adapter: providers from `~/.local/share/opencode/auth.json` (+ global/project
      `opencode.json` overrides) → models resolved via models.dev
- [ ] `claude-code` adapter: detect `~/.claude/`, static Claude model set
- [ ] `manual` fallback adapter: user names providers/models inline — guarantees the plugin
      works on any tool
- [ ] Adapter selection: auto-detect; prefer the running tool when several match; ask on tie

### Enrichment (data adapters)
- [ ] models.dev adapter: provider→model mapping, context, pricing, modalities (live, 24h cache)
- [ ] OpenRouter adapter: capability flags (tools, structured output, reasoning),
      `:free` variant limits (live, 24h cache)
- [ ] Benchmark snapshot join: committed `data/benchmarks.json` (AA scores) via `aliases.json`
- [ ] Derived `is_free` from pricing (never stored — ADR-002)
- [ ] Stale-cache fallback when registries are unreachable

### Benchmarks snapshot
- [ ] `refresh_benchmarks.py`: deterministic fetch from the Artificial Analysis official API
      (`ARTIFICIALANALYSIS_API_KEY`, free registration)
- [ ] Fail-closed schema validation before a new snapshot is accepted
- [ ] `/model-router:refresh` skill: run, validate, report diff (models added/removed/changed)
- [ ] Staleness warning in every recommendation when snapshot > 30 days old

### Recommendation
- [ ] `/model-router:recommend {task}`: 1–3 ranked models from the user's candidate set
- [ ] One-line rationale per model with source attribution
- [ ] Confidence: high (benchmarks + capability data agree) / low (no benchmark coverage —
      typical for brand-new models, which still appear)
- [ ] Hard requirements honored first: context, modality, tools, structured output, free-only
- [ ] Comparison phrasing: "compare A vs B" → side-by-side over the same merged data
- [ ] `data/user-notes.md` personal overrides ("rank Kimi down for tool use")
- [ ] Never-empty output: if nothing qualifies, show closest candidates + what they lack

### Tests
- [ ] Fixture tests for `discover.py` and `enrich.py` (exact expected outputs)
- [ ] Snapshot schema check
- [ ] CI-optional live-endpoint canary

---

## v2.0

### More environment adapters
- [ ] `codex` (`~/.codex/config.toml`)
- [ ] `cursor`, `kiro`, `kilo` — ideally contributed/tested by users of those tools

### More data
- [ ] HuggingFace adapter: open-weight license, downloads (matters for self-hosters)
- [ ] Vellum / lmarena overlay via LLM-driven refresh (no APIs exist; never on the query path)
- [ ] Scheduled auto-refresh of the benchmark snapshot (CI cron or scheduled agent)

### UX
- [ ] Lightweight multi-step task structuring: model-per-step in prose (no templates/schemas)
- [ ] Model sunset alerts when registries expose expiration dates

---

## Explicitly cut (see spec §3 and ADR-006/010)

Pipeline templates, capability vectors, constraint-relaxation chains, the 14-dimension
weighted scoring engine, MCP server, SQLite cache, scraper adapters.
