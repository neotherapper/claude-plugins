# reframe — Architectural Decisions

> Why things are the way they are. Read before proposing changes.

---

## D-01 — Strategic/semantic extraction only — no visual/design-system token extraction

**Decision:** reframe extracts purpose, audience, content, IA, and category-specific critique — not visual tokens, design systems, or CSS values.

**Why:** Claude Design and `design-extract` already extract design tokens natively from a live URL or a codebase. Duplicating this would produce a lower-quality version of something Claude Design already does well. reframe's value is strictly upstream of the visual layer: strategic and semantic extraction that neither Claude Design nor Beacon produces.

**Trade-off rejected:** Extract brand colours and type scale as a "nice to have". Would blur reframe's positioning, add extraction complexity, and compete with Claude Design's own token extraction rather than complementing it. The only visual artefact reframe extracts is the KEEP list (logo, brand colour, product photography) — as a *constraint for Claude Design*, not a design-system deliverable.

---

## D-02 — Coverage-first pipeline (render → verify → infer), not inference-first

**Decision:** The 9-phase pipeline runs in strict dependency order: render and verify content sufficiency before drawing any inference about purpose or audience.

**Why:** The flagship test site (`trustyourphysio.com`) is a React SPA that returns near-zero rendered body text to a plain HTTP fetch. Inferring purpose from an empty HTML shell produces a confident, useless brief. Two mechanical gates enforce coverage: the **render gate** (escalate to a markdown crawler when `body_text_chars < 200` or `nav_link_count == 0`) and the **content-sufficiency gate** (enter `[GREENFIELD-MODE]` and halt when `unique_headings < 2` AND `non_nav_prose_words < 150`). These gates guarantee coverage *before* inference — inference-first philosophy is preserved because they are not questions, they are thresholds.

**Trade-off rejected:** Infer first and annotate low-confidence results. Faster, but produces plausible-sounding briefs from empty shells that would mislead a designer. The greenfield gate is the more honest outcome: "this is not a redesign target" is more useful than a brief invented from nothing.

---

## D-03 — Inference-first with exactly one unavoidable human question

**Decision:** reframe infers purpose, audience, goals, and category without asking the user. Exactly one question is asked — "redesign for the same purpose, or a new one?" — before Phase 9 finalises the brief.

**Why:** The purpose-vs-pivot question is logically uninferable: no amount of content analysis can determine whether the client wants to keep the current purpose or pivot to something new. Everything else — category, audience, goals — can be inferred with noted confidence and corrected via the **assumptions header** that opens every output file. An interview is not inference-first; one binary question is the minimum unavoidable input.

**Trade-off rejected:** Infer the purpose direction too (assume same purpose). Would produce wrong briefs for pivoting clients without any signal. The question adds one interaction and prevents a category of fundamental errors.

---

## D-04 — Category packs bundled locally, not version-pinned remote files

**Decision:** Category packs live at `plugins/reframe/categories/{category}.md` and are loaded by file read, not fetched from a version-pinned GitHub raw URL.

**Why:** Category best-practice is evergreen — "local-service clinic sites should show booking above the fold" does not have a version number. Beacon's remote version-pinned scheme is appropriate for framework tech packs (Next.js 15 has genuinely different API conventions from Next.js 13), but it introduces network dependency, checksum complexity, and a PR-offer flow that adds no value for category packs. Bundled local files load instantly, work offline, and never drift between plugin version and remote file.

**Trade-off rejected:** Remote version-pinned packs matching Beacon's scheme. Correct for tech-stack facts; unnecessary overhead for design best-practice. N=4 packs in v1 (generic, local-service, saas-marketing, ecommerce) — the taxonomy is small enough to bundle without bloat. A `generic.md` fallback means low-confidence detection never hard-fails. Multi-category sites use the **dominant pack only** (secondaries noted inline) — packs are never merged because merged guidance contradicts itself.

---

## D-05 — Content-extraction preference: Jina → Firecrawl → Crawl4AI; Chrome DevTools MCP reserved for screenshots and authenticated flows

**Decision:** Default content extraction uses Jina Reader → Firecrawl → Crawl4AI (gated by install). Chrome DevTools MCP is reserved for authenticated/interactive flows and screenshots — it is not the default content fetcher.

**Why:** An early prototype routed SPA render through Chrome DevTools MCP for all content extraction. This caused a 35-minute → ~5-second regression: Chrome MCP is a browser automation tool with significant per-page overhead. Jina Reader and Firecrawl return clean markdown from JS-rendered pages orders of magnitude faster. Chrome MCP earns its overhead for two specific jobs: element screenshots (used in Phase 4 and referenced in Phase 8 critique) and pages that are both SPA-rendered *and* authentication-gated, where a markdown crawler cannot log in.

**Trade-off rejected:** Chrome DevTools MCP as primary content fetcher. Higher fidelity for authenticated pages, but unacceptable latency for standard crawls. The WAF fallback chain is trimmed from Beacon's: Firecrawl → Jina → browser-fetch only. Beacon's Scrapfly/Spider/DataDome specialists serve API probing; reframe does not need them.

---

## D-06 — Two-stage deliverable: brief.md (onboarding) and run-sheet.md (canvas prompts)

**Decision:** Phase 9 writes two files: `brief.md` — the paste-ready Claude Design onboarding block — and `run-sheet.md` — a sequenced set of canvas follow-up prompts.

**Why:** Pasting the entire strategic analysis plus per-screen instructions into a single Claude Design prompt exceeds practical context limits and mixes onboarding concerns with screen-by-screen generation. Separating them mirrors the actual Claude Design workflow: onboarding (what the project is) runs once; canvas prompts run per screen. The run-sheet ordering (validate → key screen → remaining screens, ordered by critique severity) ensures early screens catch taste mismatches before the full canvas is built out.

**Trade-off rejected:** Single output file combining onboarding and run-sheet. Simpler for the plugin, worse for the user — they would need to manually split the output before using it in Claude Design.

---

## D-07 — Web-capture-override instruction in brief.md

**Decision:** The penultimate section of every `brief.md` contains a verbatim instruction: *"Capture the live URL for content, structure, and brand assets to KEEP (logo, brand color, product photography) only. The design direction above OVERRIDES all captured visual styling."*

**Why:** Claude Design's web-capture feature imports a site's current visual patterns into the design system. Without an explicit override, the model uses the captured styling as a baseline, producing a reskin rather than a redesign. The override instruction exploits Claude Design's instruction-following to suppress the captured visual layer while keeping the content and brand asset import that the brief's KEEP list depends on.

**Trade-off rejected:** Omit the override and let the user manage it. The override is the single sentence that separates a redesign from a clone; it must be in the brief unconditionally.

---

## D-08 — Token-based output templates with a 36-token Phase-9 contract

**Decision:** All six output files are generated in Phase 9 by resolving `{{TOKEN}}` placeholders in `templates/*.template` files. The full token set (36 tokens) is documented as a contract in SKILL.md.

**Why:** Freeform generation produces inconsistent structure across runs — section names drift, tables grow unexpected columns, checklist formatting varies. Token-based templates lock in the schema so the output is predictable and validatable (no `{{` remaining = complete run). The token contract in SKILL.md also makes it explicit what information each phase must collect — it is both the output format and the data collection spec.

**Trade-off rejected:** Freeform generation with a post-pass structural check. More flexible, but harder to validate and more likely to produce briefs with different shapes across runs. Consistent structure matters here because the brief is meant to be pasted into Claude Design, where structural expectations are set by the user's workflow.

---

## D-09 — Standalone sibling plugin reusing Beacon patterns, not Beacon's code

**Decision:** reframe is a fully independent plugin that reuses Beacon's *patterns* (session-brief→flush, tool-availability matrix) but shares no code, API scope, or output paths with Beacon.

**Why:** Beacon's scope is technical reconnaissance — API surfaces, framework fingerprinting, security exposure. reframe's scope is strategic/semantic extraction for redesign. They serve different user intents and produce different output formats. Sharing code would couple them unnecessarily and risk Beacon's security-conscious patterns leaking into reframe (e.g., OSINT, subdomain enumeration, probe scripts — none of which belong in a design brief). The session-brief→flush pattern is copied and trimmed (not imported); the tool-availability matrix is copied and trimmed to the three crawlers reframe needs (Jina, Firecrawl, WebFetch) plus Chrome DevTools MCP.

**Categories and templates resolve from bare paths** (`categories/`, `templates/`) at the plugin root — this mirrors how Beacon's tech packs resolve, and avoids `${CLAUDE_PLUGIN_ROOT}` indirection for model-read files. `references/` lives under `skills/site-redesign/references/` (matching Beacon's actual layout, not the spec diagram which had it at the plugin root).

**Trade-off rejected:** Build reframe as a Beacon sub-skill or extension. Saves scaffolding but couples two plugins with incompatible scopes and would route redesign requests through Beacon's site-analyst agent, which is optimised for API probing rather than content analysis.
