# Model Router — Architectural Decisions

## ADR-001: OpenRouter as primary data source

**Date:** 2026-07-08
**Status:** Superseded by ADR-008

**Context:** We need a primary source for model metadata, pricing, modalities, and free-tier detection. Options: OpenRouter, provider-direct APIs, HuggingFace, aggregated leaderboards.

**Decision:** OpenRouter `/api/v1/models` is the primary source. It covers 343+ models including all NVIDIA free models, requires no API key, returns structured JSON with pricing, context, modalities, reasoning support, and expiration dates.

**Consequences:**
- Free models are detected from pricing (prompt == "0" && completion == "0"), not a separate flag
- Free variants (`:free` suffix) may have different context windows and rate limits — handled via `free_tier` block
- Models not on OpenRouter (e.g., some HuggingFace-only models) are not covered in v1

---

## ADR-002: Derived `is_free`, not stored

**Date:** 2026-07-08
**Status:** Accepted

**Context:** Initial schema stored `is_free: bool` as a separate field. Risk of sync drift if pricing changes but `is_free` isn't updated.

**Decision:** `is_free` is computed at query time from `pricing.input == 0 && pricing.output == 0`. Free-variant specifics (rate limits, context window differences) are captured in a `free_tier` block.

**Consequences:**
- No stale `is_free` values in cache
- Free-variant nuances (lower context, different rate limits) are explicitly modeled
- Query must check pricing to determine free status (trivial cost)

---

## ADR-003: lmarena as category-level only

**Date:** 2026-07-08
**Status:** Superseded by ADR-009

**Context:** Initial schema included `lmarena.text_coding`, `lmarena.text_math`, `lmarena.text_creative_writing` etc. as sub-category Elo scores.

**Decision:** lmarena sub-category breakdowns don't exist in any public API. The leaderboard returns category-level Elo (Agent, Text, WebDev, Vision, Search, etc.) but no sub-breakdown within Text. Schema uses only verified fields.

**Consequences:**
- Text sub-dimensions (coding, math, creative writing) rely on AA and Vellum instead
- lmarena data is supplementary, not primary for any single dimension

---

## ADR-004: Constraint relaxation mandatory

**Date:** 2026-07-08
**Status:** Superseded by ADR-006 (spirit retained: never return empty silently)

**Context:** If no model meets a stage's hard constraints (e.g., min_context: 200000), the recommendation would silently return empty results.

**Decision:** Every stage template must define a `constraint_relaxation` chain. When no candidates match, the system progressively relaxes constraints with user-visible warnings. Final relaxation requires user confirmation.

**Consequences:**
- Users always get recommendations, even if suboptimal
- Warnings make it clear when constraints were relaxed
- Prevents silent failures in automated pipelines

---

## ADR-005: Scoring composites with explicit formulas

**Date:** 2026-07-08
**Status:** Superseded by ADR-010 (auditability retained via source-attributed rationale)

**Context:** Dimensions like "agentic coding" aggregate multiple benchmark sources (SWE-Bench, Terminal-Bench, lmarena-code). Without explicit formulas, scoring is opaque.

**Decision:** Every composite dimension has a documented formula with fixed weights. Formulas are versioned and stored in `scoring-formulas.md`. Changes to formulas require a new ADR.

**Consequences:**
- Scores are reproducible and auditable
- Weight changes are tracked in git
- Users can understand exactly why a model was scored a certain way

---

## ADR-006: Single-task scope — recommend from the user's actual models; pipelines cut

**Date:** 2026-07-27
**Status:** Accepted

**Context:** The original design targeted "all 347+ models" with multi-stage pipeline
templates, capability vectors, and constraint-relaxation chains. Brainstorming established
the real problem: a user with ~9 authenticated providers cannot tell which of *those*
models fits a given task. At that scale, pipeline machinery is complexity without users.

**Decision:** v1 answers exactly one question — "which of my models for this task?" — with
1–3 ranked recommendations. Candidates come from the user's tool config, never a global
catalog. Pipeline templates, capability vectors, and relaxation chains are cut. Multi-step
tasks may get model-per-step suggestions in prose (v2 UX item), with no template machinery.

**Consequences:**
- ADR-004's relaxation chains are gone; its spirit survives as a rule: when nothing meets
  hard requirements, show the closest candidates and what they lack — never empty output
- Persona 5 (pipeline designer) retired
- The design generalizes to other people/tools along one axis only: adapters (ADR-007)

---

## ADR-007: Two adapter families; v1 environment adapters = opencode, claude-code, manual

**Date:** 2026-07-27
**Status:** Accepted

**Context:** The plugin should serve other people on other CLI tools (Codex, Cursor, Kiro,
Kilo) without redesign, and must find each user's real candidate set.

**Decision:** Two adapter families. *Environment adapters* (`discover.py`) implement
`detect() -> bool` / `candidates() -> [{provider, model_id}]` per tool. *Data adapters*
(`enrich.py`, `refresh_benchmarks.py`) each own the data type they are the best source for.
v1 ships environment adapters only for the two tools the maintainer can verify end-to-end
(opencode via `auth.json`, claude-code via `~/.claude`) plus an always-available `manual`
fallback where the user names providers inline. Codex/Cursor/Kiro/Kilo are v2,
ideally contributed by users of those tools.

**Consequences:**
- The plugin works everywhere immediately (manual fallback), and works *well* on verified tools
- Adding a tool is a contribution-sized task: one adapter class + fixtures
- No adapter ships that cannot be tested against a real setup

---

## ADR-008: models.dev as candidate-resolution source of truth

**Date:** 2026-07-27
**Status:** Accepted (supersedes ADR-001)

**Context:** ADR-001 made OpenRouter primary when the candidate set was "all models."
With candidates now defined as "models behind the user's providers," the right registry is
the one the user's tool itself uses: OpenCode resolves models from models.dev (154
providers, public JSON, no key — verified live 2026-07-10).

**Decision:** models.dev is the source of truth for provider→model mapping, context,
pricing, and modalities. OpenRouter remains as a data adapter for what it is uniquely good
at: capability flags (tools, structured output, reasoning) and `:free` variant limits.

**Consequences:**
- The candidate set matches what the user's tool can actually invoke
- Entity resolution shrinks: models.dev and OpenRouter IDs mostly align; `aliases.json`
  holds only the exceptions
- Both sources are keyless JSON fetched live with a 24h cache and stale-cache fallback

---

## ADR-009: Freshness split by volatility; Artificial Analysis API for benchmarks; no scraping

**Date:** 2026-07-27
**Status:** Accepted (supersedes ADR-003)

**Context:** "Keep our own data vs extract on the spot" was the core open question. Facts
(pricing, availability, free tiers) decay in hours-days; benchmark judgment decays on model
release cadence (weeks). One TTL policy forces one class to be wastefully re-fetched or
dangerously stale. Meanwhile Artificial Analysis now has an official API (free key —
verified live 2026-07-27), removing the need to scrape; Vellum and lmarena still have no APIs.

**Decision:** Facts are fetched live from keyless APIs at query time (24h cache). Judgment
is a committed `data/benchmarks.json` refreshed deterministically from the AA official API
via `/model-router:refresh`, gated by fail-closed schema validation. Vellum/lmarena are
dropped from the deterministic core (optional LLM-refresh overlay in v2, never on the
query path). Snapshot older than 30 days triggers a warning in every recommendation; models
without benchmark coverage are recommended with `confidence: low`, never hidden.

**Consequences:**
- No scraper code to maintain; nothing fragile sits on the query path
- New models appear within a cache window of the registries knowing them
- Benchmark refresh requires a free AA key (`ARTIFICIALANALYSIS_API_KEY`) — documented in
  the refresh skill; the recommend flow never needs it

---

## ADR-010: Scripts + skill, no MCP server; deterministic extraction, in-context judgment

**Date:** 2026-07-27
**Status:** Accepted (supersedes ADR-005's scoring-engine framing)

**Context:** The original architecture described an MCP server with SQLite and a
14-dimension weighted scoring engine. An MCP server needs per-platform wiring on every tool
the marketplace serves; skills already sync everywhere via the symlink farm. And with
candidate sets of dozens (not hundreds), weighted composite formulas are less accurate and
less explainable than direct judgment over clean numbers. Repo-wide lesson (beacon,
reframe): prose-only steps get skipped under synthesis pressure — but the inverse also
holds: judgment forced into rigid formulas produces formula-shaped rationales.

**Decision:** No MCP server, no SQLite, no scoring engine. Everything that must be
*correct* — config parsing, API fetching, ID joining, caching, snapshot validation — lives
in scripts with fixture tests. Everything that must be *wise* — task matching, trade-off
weighing, rationale — is the model reasoning in-context over merged `candidates.json`.
ADR-005's auditability goal is preserved by requiring source attribution in every
rationale line.

**Consequences:**
- Works on all marketplace tools with zero per-tool wiring
- The deterministic layer is fully fixture-testable; the judgment layer is inspectable
  through its cited sources
- If reproducible numeric scoring is ever needed (e.g., CI regression tests on
  recommendations), it would be a new ADR
