# Model Router — Architectural Decisions

## ADR-001: OpenRouter as primary data source

**Date:** 2026-07-08
**Status:** Accepted

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
**Status:** Accepted

**Context:** Initial schema included `lmarena.text_coding`, `lmarena.text_math`, `lmarena.text_creative_writing` etc. as sub-category Elo scores.

**Decision:** lmarena sub-category breakdowns don't exist in any public API. The leaderboard returns category-level Elo (Agent, Text, WebDev, Vision, Search, etc.) but no sub-breakdown within Text. Schema uses only verified fields.

**Consequences:**
- Text sub-dimensions (coding, math, creative writing) rely on AA and Vellum instead
- lmarena data is supplementary, not primary for any single dimension

---

## ADR-004: Constraint relaxation mandatory

**Date:** 2026-07-08
**Status:** Accepted

**Context:** If no model meets a stage's hard constraints (e.g., min_context: 200000), the recommendation would silently return empty results.

**Decision:** Every stage template must define a `constraint_relaxation` chain. When no candidates match, the system progressively relaxes constraints with user-visible warnings. Final relaxation requires user confirmation.

**Consequences:**
- Users always get recommendations, even if suboptimal
- Warnings make it clear when constraints were relaxed
- Prevents silent failures in automated pipelines

---

## ADR-005: Scoring composites with explicit formulas

**Date:** 2026-07-08
**Status:** Accepted

**Context:** Dimensions like "agentic coding" aggregate multiple benchmark sources (SWE-Bench, Terminal-Bench, lmarena-code). Without explicit formulas, scoring is opaque.

**Decision:** Every composite dimension has a documented formula with fixed weights. Formulas are versioned and stored in `scoring-formulas.md`. Changes to formulas require a new ADR.

**Consequences:**
- Scores are reproducible and auditable
- Weight changes are tracked in git
- Users can understand exactly why a model was scored a certain way
