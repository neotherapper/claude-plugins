---
name: site-redesign
description: This skill should be used when the user wants to redesign an existing website — e.g. "redesign this site", "create a redesign brief for acme.com", "redesign and modernise this site", "rethink the design of this site". Requires an EXPLICIT redesign intent; a bare URL or an API/endpoint request with no redesign intent belongs to beacon's site-recon, not here. Extracts purpose/content/IA, critiques vs category best-practice, and writes a paste-ready Claude Design brief to docs/redesign/{slug}/.
version: 0.1.0
---

# site-redesign — Coverage-First Redesign Pipeline

Given an existing site URL with explicit redesign intent, runs 9 ordered phases that
produce a strategic brief for Claude Design plus four supporting analysis files.

**Core principle:** Render → verify coverage → infer. Never infer purpose from an empty shell.

## Output structure

```
docs/redesign/{site-slug}/
├── INDEX.md              ← summary, assumptions, coverage manifest, how-to-use
├── brief.md              ← paste-ready Claude Design onboarding brief (headline deliverable)
├── run-sheet.md          ← sequential canvas prompts (validate → key screen → remaining)
├── content-inventory.md  ← evaluative audit (keep/revise/consolidate/remove + ROT flags)
├── ia-map.md             ← nav hierarchy, per-page intent triplets, journeys, conversion path
├── current-critique.md   ← severity-rated findings vs category best-practice + screenshots
└── .crawl/               ← raw per-page markdown + screenshots (git-ignored)
```

Slug: strip `www.`, then `example.com → example-com`.

## Session brief

Maintain a running markdown document in context throughout the run. Append after each phase; never overwrite earlier sections. Sections: Tool Availability (one `[AVAILABLE]`/`[TOOL-UNAVAILABLE:{name}]` line per tool + `[CHROME-NAMESPACE:plugin|project]`), Structure (URL count, cluster count, structural signals), Coverage Manifest (URL/status table), Category Detection (`[PACK-LOADED:{name}]`), Intent (inferred purpose, target purpose, audience, goal), Phase Markers (`[P1✓]` through `[P9✓]`).

## The 9 phases — always in this order

| # | Phase | Writes |
|---|-------|--------|
| 1 | Scaffold + tool check | — |
| 2 | Structure discovery | `ia-map.md` (skeleton) |
| 3 | Render + coverage gate | session brief |
| 4 | Content crawl + screenshots | `.crawl/` |
| 5 | Content audit | `content-inventory.md` |
| 6 | IA / journey map | `ia-map.md` |
| 7 | Intent inference | session brief |
| 8 | Current-design critique | `current-critique.md` |
| 9 | Synthesize | `brief.md`, `run-sheet.md`, `INDEX.md` |

---

## Phase 1 — Scaffold and tool check

**Input:** URL (with explicit redesign intent).

**Actions:**
1. Slugify: strip `https://`, strip `www.`, replace `.` with `-`.
2. Create output folder + empty output files using Write (not touch): `INDEX.md`, `brief.md`, `run-sheet.md`, `content-inventory.md`, `ia-map.md`, `current-critique.md` — all under `docs/redesign/{slug}/`.
3. Write `docs/redesign/{slug}/.gitignore` containing `.crawl/`.
4. Detect tools — log each as `[AVAILABLE]` or `[TOOL-UNAVAILABLE:{name}]`. See `references/tool-availability.md` for exact detection commands (Firecrawl, Jina, WebFetch, Chrome DevTools MCP — test both Chrome namespaces; record active one as `[CHROME-NAMESPACE:plugin|project]`).

**Output:** Session brief initialized with tool availability block. Phase marker `[P1✓]`.

---

## Phase 2 — Structure discovery

**Input:** Site URL, session brief.

**Actions:**
1. Fetch `robots.txt` — parse for `Sitemap:` directives.
2. Fetch `sitemap.xml` (follow sitemap-index children to enumerate leaf URLs).
3. If no sitemap: parse homepage `<nav>` and `<a href>` links.
4. Enumerate ALL discovered URLs.
5. Cluster by path template: `/`, `/blog/*`, `/services/*`, `/products/*`, `/about`, `/contact`, legal paths, and any recurring prefixes found.
6. Write the URL list + cluster map to `ia-map.md` as a skeleton.

**Signals to emit:**
- `[NO-SITEMAP]` — no `sitemap.xml` and no `Sitemap:` in `robots.txt`; nav-crawl used.
- `[SINGLE-PAGE]` — ≤2 enumerated URLs; section-anchor map replaces page table in Phase 6.
- `[MULTI-LOCALE:canonical=x]` — `hreflang` alternates or locale paths (`/en`, `de.`) detected; brief ONLY the canonical locale `x`.

**Output:** `ia-map.md` (skeleton), URL count + cluster table in session brief. Phase marker `[P2✓]`.

---

## Phase 3 — Render gate and coverage gate

**Input:** Site URL, session brief. Load `references/crawl-and-coverage.md` for thresholds and Chrome MCP call sequences.

**Actions:**
1. Fetch homepage (WebFetch; WAF fallback: Firecrawl → Jina → browser-fetch if 403).
2. **Render gate:** `body_text_chars < 200` OR `nav_link_count == 0` → emit `[RENDER-ESCALATED]`, re-fetch via Chrome DevTools MCP.
3. **Content-sufficiency gate:** after render, `unique_headings < 2` AND `non_nav_prose_words < 150` → emit `[GREENFIELD-MODE]`, write `INDEX.md` with finding, halt pipeline.
4. **Coverage manifest:** each URL → Reachable (200) or Gated/Blocked (401/403/challenge). Emit `[COVERAGE-PARTIAL:gated]` if any URL gated.
5. Emit `[WAF-BLOCKED]` only if all three fallback fetchers fail; do not hard-stop.

**Output:** Coverage manifest in session brief. Phase marker `[P3✓]`.

---

## Phase 4 — Content crawl and screenshots

**Input:** URL cluster map from Phase 2, session brief. Load `references/crawl-and-coverage.md`.

**Actions:**
1. Sample **1–2 pages per template cluster**; floor = homepage + primary nav targets.
2. Apply a 60,000-character clean-markdown budget — stop sampling when budget is exhausted.
3. Log `[SAMPLED:n-templates]` where `n` = number of clusters actually sampled.
4. Save per-page markdown to `.crawl/{slug-path}.md`.
5. Take **one screenshot per sampled template** via Chrome MCP `take_screenshot` using the recorded namespace.
   - Homepage: take two screenshots (above-fold and full-page).
   - If Chrome MCP unavailable: log `[TOOL-UNAVAILABLE:chrome-mcp]`; proceed text-only; add explicit visual-gap note in all output files.
6. Save screenshots to `.crawl/screenshots/`.

**Output:** `.crawl/` populated. Phase marker `[P4✓]`.

---

## Phase 5 — Content audit

**Input:** `.crawl/` page markdown files, session brief.

**Actions:**

For each crawled page, record:
- **URL, template cluster, page type** (homepage / service / about / blog-post / contact / legal / …)
- **Purpose** — what the page is trying to accomplish
- **Value props, CTAs, forms, media** present
- **Verdict:** `keep` / `revise` / `consolidate` / `remove` — each verdict tied to the inferred primary goal
- **ROT flags:** redundant (same job as another page), outdated (dated claims/events), trivial (thin/low-value), orphan (no inbound nav link), off-message (content misaligned with purpose)

Write rows to `content-inventory.md` using the template in `templates/content-inventory.md.template`.

**Output:** `content-inventory.md` written. Phase marker `[P5✓]`.

---

## Phase 6 — IA and journey map

**Input:** `content-inventory.md`, session brief.

**Actions:**
1. Build the **navigation hierarchy** — top-nav items, any sub-nav, footer links.
2. Build the **page-purpose table** — one row per page with its **intent triplet** (`concrete subject · target audience · page's single job`). Format as defined in `references/brief-format.md`. For `[SINGLE-PAGE]` sites, use section-anchor map instead.
3. Define **1 primary + 2–3 secondary journeys** keyed to entry intent. Each journey step names the decisive objection it must resolve.
4. Trace the **primary conversion path** — the exact sequence of steps from cold visit to the primary goal, naming each page/step.

Write to `ia-map.md` (replacing the skeleton from Phase 2).

**Output:** `ia-map.md` completed. Phase marker `[P6✓]`.

---

## Phase 7 — Intent inference and category detection

**Input:** All crawled content, `ia-map.md`, `content-inventory.md`, session brief.

**Actions:**
1. **Infer:** purpose, audience, primary goal — with per-field confidence (high / medium / low).
2. **Detect category** by scoring `detect_signals` from each category pack's YAML frontmatter against homepage + nav + crawled content. Use the matching pack at `categories/{detected}.md`.
   - Score by counting signal matches; prefer **longer/more-specific signals** over short generic ones — do NOT use first-match.
   - If the top-scoring category's confidence is low, load `categories/generic.md` and note the assumption explicitly in the brief.
   - If a site scores across multiple categories, pick the **single dominant pack** and note secondaries inline (e.g. "primarily ecommerce; secondary: local-service"). **Never merge packs** — merging produces contradictory guidance.
3. Emit `[PACK-LOADED:{category}]` once the pack is selected.
4. **Ask the one question:** "Are you redesigning for the same purpose as the current site, or a new one?" — record the answer as `current purpose (inferred)` vs `target purpose (declared)`. This is the only human question in the pipeline.
5. Record all inferences (purpose, audience, goal, category, confidence) in the session brief.

**Output:** Session brief updated with intent block. Phase marker `[P7✓]`.

---

## Phase 8 — Current-design critique

**Input:** Category pack loaded in Phase 7, `.crawl/screenshots/`, `ia-map.md`, `content-inventory.md`, session brief.

**Actions:**
1. Load `categories/{detected}.md` (already loaded in Phase 7; re-read if needed).
2. For each finding (visual, IA, content, voice, SEO/a11y), record:
   - **Finding** — specific observation, referenced to a page or screenshot
   - **Severity** — 0 (note) / 1 (minor) / 2 (moderate) / 3 (major) / 4 (critical)
   - **Best-practice violated** — cite the named principle from the category pack
   - **Concrete fix** — one actionable sentence; no design theory
   - **Evidence** — screenshot filename or quoted text excerpt
3. Run a **voice/messaging pass** — flag vague adjectives ("innovative", "world-class"); identify the three vaguest claims and propose concrete replacements.
4. Run a **content-side SEO/a11y pass** — heading structure, metadata completeness, schema/NAP presence, alt-text coverage.
5. Write `current-critique.md` using `templates/current-critique.md.template`.

If `[TOOL-UNAVAILABLE:chrome-mcp]`: no screenshots — add `[VISUAL-GAP: visual-hierarchy critique not possible without screenshots]` to `current-critique.md`.

**Output:** `current-critique.md` written. Phase marker `[P8✓]`.

---

## Phase 9 — Synthesize

**Input:** All prior phase outputs and the session brief. Load `references/brief-format.md`.

**Actions:**
1. Resolve all 36 `{{TOKEN}}`s (listed below) from the session brief and phase outputs.
2. Write `brief.md` via `templates/brief.md.template`. Section order is a contract — do not reorder; see `references/brief-format.md` for the full contract including the per-page intent triplet format and design-system seed block format.
   - §9 web-capture instruction must include verbatim: _"Capture the live URL for content, structure, and brand assets to KEEP (logo, brand color, product photography) only. The design direction above OVERRIDES all captured visual styling."_
3. Write `run-sheet.md` via `templates/run-sheet.md.template`. Order: validate → key screen → remaining screens (severity order, not nav order) → components.
4. Finalize `content-inventory.md`, `ia-map.md`, `current-critique.md` (written in phases 5/6/8; resolve any remaining tokens).
5. Write `INDEX.md` via `templates/INDEX.md.template`.

**Output:** All six output files written. Phase marker `[P9✓]`.

### Phase-9 token contract

Phase 9 MUST resolve every one of these 36 tokens — the deduplicated union across all six templates. Do not add or rename tokens.

`{{SITE_NAME}}` `{{DATE}}` `{{URL}}` `{{CATEGORY}}` `{{CATEGORY_CONFIDENCE}}` `{{INFERRED_PURPOSE}}` `{{TARGET_PURPOSE}}` `{{AUDIENCE}}` `{{PRIMARY_GOAL}}` `{{COVERAGE_MANIFEST}}` `{{ASSUMPTIONS}}` `{{WHAT_IT_IS}}` `{{GOALS_SUCCESS}}` `{{KEEP_CHANGE_ADD}}` `{{IA_PROPOSED}}` `{{DESIGN_DIRECTION_SEED}}` `{{REFERENCES_ANTI}}` `{{WEB_CAPTURE_OVERRIDE}}` `{{TECH_EXPORT_HANDOFF}}` `{{VALIDATE_PROMPT}}` `{{KEY_SCREEN_PROMPT}}` `{{REMAINING_SCREEN_PROMPTS}}` `{{COMPONENT_PROMPTS}}` `{{URL_COUNT}}` `{{AUDITED_COUNT}}` `{{SAMPLING_NOTE}}` `{{INVENTORY_ROWS}}` `{{UNAUDITED_LIST}}` `{{NAV_HIERARCHY}}` `{{PAGE_PURPOSE_TABLE}}` `{{JOURNEYS}}` `{{PRIMARY_CONVERSION_PATH}}` `{{VISUAL_TRACK_NOTE}}` `{{CRITIQUE_ROWS}}` `{{VOICE_FINDINGS}}` `{{SEO_A11Y_FINDINGS}}`

---

## Graceful degradation signals

Log these in the session brief. Surface any that fired in `INDEX.md`.

| Signal | Meaning |
|--------|---------|
| `[RENDER-ESCALATED]` | Homepage body text < 200 chars or 0 nav links; Chrome MCP headless render invoked |
| `[GREENFIELD-MODE]` | After render: < 2 unique headings and < 150 non-nav words; pipeline halted — not a redesign target |
| `[NO-SITEMAP]` | No `sitemap.xml` and no `Sitemap:` in `robots.txt`; fell back to homepage-nav crawl |
| `[COVERAGE-PARTIAL:gated]` | One or more URLs returned 401/403/challenge; only public pages briefed |
| `[WAF-BLOCKED]` | Homepage blocked by Firecrawl, Jina, AND browser-fetch; proceeded with partial content |
| `[SAMPLED:n-templates]` | Crawl budget exhausted; `n` template clusters sampled, not all |
| `[SINGLE-PAGE]` | ≤2 URLs discovered; section-anchor map used instead of page table |
| `[MULTI-LOCALE:canonical=x]` | Locale branching detected; briefed canonical locale `x` only |
| `[TOOL-UNAVAILABLE:chrome-mcp]` | Chrome DevTools MCP unavailable; text-only critique; visual gap noted |
| `[PACK-LOADED:x]` | Category pack `x` loaded for Phase 8 critique and design-system seed |

---

## Reference files

Load on demand — not always necessary:

- **`references/tool-availability.md`** — exact detection commands for Firecrawl, Jina, WebFetch, Chrome DevTools MCP; WAF escalation chain (Firecrawl → Jina → browser-fetch)
- **`references/crawl-and-coverage.md`** — Phase 2/3/4 detail: render-gate thresholds, content-sufficiency thresholds, Chrome MCP call sequences, coverage manifest format, crawl budget, signal-emission conditions
- **`references/brief-format.md`** — `brief.md` section order (a contract), per-page intent triplet format, design-system seed block format, canonical web-capture-override sentence, run-sheet ordering
- **`categories/{detected}.md`** — matched category pack (priorities, IA conventions, design-system seed, trust signals, references/anti-references); `categories/generic.md` is the low-confidence fallback
- **`templates/`** — the six `*.template` files resolved in Phase 9

> `categories/`, `templates/`, and `references/` paths resolve relative to this plugin's root, not the user's project (same convention as beacon).
