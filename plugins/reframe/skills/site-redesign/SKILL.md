---
name: site-redesign
description: This skill should be used when the user wants to redesign an existing website — e.g. "redesign this site", "create a redesign brief for acme.com", "redesign and modernise this site", "rethink the design of this site". Requires an EXPLICIT redesign intent; a bare URL or an API/endpoint request with no redesign intent belongs to beacon's site-recon, not here. Extracts purpose/content/IA, critiques vs category best-practice, and writes a paste-ready Claude Design brief to docs/sites/{slug}/redesign/.
version: 0.2.0
---

# site-redesign — Coverage-First Redesign Pipeline

Given an existing site URL with explicit redesign intent, runs 9 ordered phases that
produce a strategic brief for Claude Design plus four supporting analysis files.

**Core principle:** Render → verify coverage → infer. Never infer purpose from an empty shell.

## Output structure

```
docs/sites/{site-slug}/redesign/
├── INDEX.md              ← summary, assumptions, coverage manifest, how-to-use
├── brief.md              ← paste-ready Claude Design onboarding brief (headline deliverable)
├── run-sheet.md          ← sequential canvas prompts (validate → key screen → remaining)
├── content-inventory.md  ← evaluative audit (keep/revise/consolidate/remove + ROT flags)
├── ia-map.md             ← nav hierarchy, per-page intent triplets, journeys, conversion path
├── current-critique.md   ← severity-rated findings vs category best-practice + screenshots
└── .crawl/               ← raw per-page markdown + screenshots (git-ignored)
```

Slug: canonical rule — see `docs/SLUG_RULES.md`.

## Session brief

Running markdown doc in context. Append after each phase; never overwrite. Sections: Tool Availability (`[AVAILABLE]`/`[TOOL-UNAVAILABLE:{name}]` per tool + `[CHROME-NAMESPACE:plugin|project]`), Structure (URL/cluster count, signals), Coverage Manifest, Category Detection (`[PACK-LOADED:{name}]`), Intent, Phase Markers (`[P1✓]`–`[P9✓]`).

## The 9 phases — always in this order

| # | Phase | Writes |
|---|-------|--------|
| 1 | Scaffold + tool check | — |
| 2 | Structure discovery | `ia-map.md` (skeleton) |
| 3 | Render + coverage gate | session brief |
| 4 | Content crawl + screenshots | `.crawl/` |
| 5 | Content audit | `content-inventory.md` |
| 6 | IA / journey map | `ia-map.md` |
| 7 | Intent inference + category detect (+ strategic question) | session brief |
| 8 | Current-design critique | `current-critique.md` |
| 9 | Synthesize | `brief.md`, `run-sheet.md`, `INDEX.md` |

> **Ordering note (the one allowed flex):** the *strategic question* (P7 step 4) may be asked any time after Phase 4 (crawl) and **must** be asked before writing the deliverable files (P5/P6/P8) — its answer reframes them. **Category detection (P7 step 2) is never skipped or deferred**: it must run and emit `[PACK-LOADED:<cat>]` before Phase 8's pack-cited critique. Asking the question early does NOT license skipping detection.

---

## Phase 1 — Scaffold and tool check

**Input:** URL (with explicit redesign intent).

**Actions:**
1. Derive slug (mirrors the canonical rule in `docs/SLUG_RULES.md` — that doc is authoritative; keep this one-liner in sync with it): `SLUG=$(printf '%s' "$URL" | tr 'A-Z' 'a-z' | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g')`. Examples: `www.example.com/`→`example-com`, `Example.COM`→`example-com`.
2. Create output folder + empty output files (Write, not touch — create each file with the **Write tool**, never `touch`/Bash heredoc/`>`-redirect. Bash-created files are untracked by the harness and force a redundant Read before every later Write (observed cost: 6 wasted Reads in a prior run)): `INDEX.md`, `brief.md`, `run-sheet.md`, `content-inventory.md`, `ia-map.md`, `current-critique.md` — all under `docs/sites/{slug}/redesign/`.
3. Write `docs/sites/{slug}/redesign/.gitignore` containing `.crawl/`.
4. Detect tools — log each as `[AVAILABLE]` or `[TOOL-UNAVAILABLE:{name}]`. See `references/tool-availability.md` (Jina Reader, Firecrawl, Crawl4AI, WebFetch, Chrome DevTools MCP — test both namespaces; record active one as `[CHROME-NAMESPACE:plugin|project]`).
5. **Check for prior beacon recon:** if `docs/sites/{slug}/research/` (or legacy `docs/research/{slug}/`) exists, log `[RECON-REUSE]` and read **every** file in it (not just `site-map.md`/`tech-stack.md` — include `osint.md`, `INDEX.md`, any `claude-design-inputs`/competitive/performance files). The recon corpus becomes a content source for Phases 3–5; still **live-re-verify the homepage** (render gate) and spot-check 1–2 key routes. Never treat recon as a substitute for the render gate.

**Output:** Session brief initialized with tool availability block. Phase marker `[P1✓]`.

---

## Phase 2 — Structure discovery

**Input:** Site URL, session brief.

**Actions:**
1. Fetch `robots.txt` — parse for `Sitemap:` directives.
2. Fetch `sitemap.xml` (follow sitemap-index children to enumerate leaf URLs).
3. If no sitemap: parse homepage `<nav>` and `<a href>` links.
4. Enumerate ALL discovered URLs.
5. Cluster by path template (e.g. `/`, `/blog/*`, `/services/*`, `/about`, `/contact`, legal) and any recurring prefixes.
6. Write the URL list + cluster map to `ia-map.md` as a skeleton.

**Signals to emit:**
- `[NO-SITEMAP]` — no `sitemap.xml` and no `Sitemap:` in `robots.txt`; nav-crawl used.
- `[SINGLE-PAGE]` — ≤2 enumerated URLs; section-anchor map replaces page table in Phase 6.
- `[MULTI-LOCALE:canonical=x]` — `hreflang` alternates or locale paths (`/en`, `de.`) detected; brief ONLY the canonical locale `x`.

**Output:** `ia-map.md` (skeleton), URL count + cluster table in session brief. Phase marker `[P2✓]`.

---

## Phase 3 — Render gate and coverage gate

**Input:** Site URL, session brief. Load `skills/site-redesign/references/crawl-and-coverage.md`.

**Actions:**
1. Fetch homepage (WebFetch; WAF fallback: Firecrawl → Jina → browser-fetch if 403).
2. **Render gate + content-sufficiency gate:** Run `python3 ${CLAUDE_PLUGIN_ROOT}/skills/site-redesign/scripts/coverage-metrics.py <fetched-markdown-file>` (or `--stdin`). Read `body_text_chars`, `nav_link_count`, `unique_headings`, `non_nav_prose_words`, and `signals` from the JSON output. Fallback if python3 or the script is unavailable: estimate the four metrics by inspection against the same thresholds below.
   - `[RENDER-ESCALATED]` — `body_text_chars < 200` OR `nav_link_count == 0` → re-fetch via Jina → Firecrawl → Crawl4AI (Chrome MCP: auth/interactive walls only).
   - `[GREENFIELD-MODE]` — after render: `unique_headings < 2` AND `non_nav_prose_words < 150` → write `INDEX.md`, delete the five unfilled output files (every Phase-1 file except `INDEX.md`), halt pipeline.
3. **Coverage manifest:** each URL → Reachable (200) or Gated/Blocked (401/403/challenge). Emit `[COVERAGE-PARTIAL:gated]` if any URL gated.
   - **Per-route render check:** for each sampled route, record whether it renders real content or only an app shell (a client-side 404 returns a 200 shell). Flag shell-only routes as findings. See `references/crawl-and-coverage.md` → "Per-route render check".
4. Emit `[WAF-BLOCKED]` only if all three fallback fetchers fail; do not hard-stop.

**Output:** Coverage manifest in session brief. Phase marker `[P3✓]`.

---

## Phase 4 — Content crawl and screenshots

**Input:** URL cluster map from Phase 2, session brief. Load `skills/site-redesign/references/crawl-and-coverage.md`.

**Actions:**
1. Sample **1–2 pages per template cluster**; floor = homepage + primary nav targets.
2. Apply a 60,000-character clean-markdown budget — stop when exhausted.
3. Log `[SAMPLED:n-templates]` where `n` = clusters actually sampled.
4. Save per-page markdown to `.crawl/{slug-path}.md`.
5. Take **one screenshot per sampled template** (Jina pageshot → Firecrawl → Crawl4AI → Chrome MCP fallback; sequences in references/crawl-and-coverage.md).
   - Homepage: two screenshots (above-fold and full-page).
   - No screenshot source available: log `[TOOL-UNAVAILABLE:chrome-mcp]`; text-only; visual-gap note in all output files.
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

Write to `ia-map.md` using `templates/ia-map.md.template` (replacing the skeleton from Phase 2).

**Output:** `ia-map.md` completed. Phase marker `[P6✓]`.

---

## Phase 7 — Intent inference and category detection

**Input:** All crawled content, `ia-map.md`, `content-inventory.md`, session brief.

**Actions:**
1. **Infer:** purpose, audience, primary goal — with per-field confidence (high / medium / low).
2. **Detect category:** Run `python3 ${CLAUDE_PLUGIN_ROOT}/skills/site-redesign/scripts/detect-category.py --categories ${CLAUDE_PLUGIN_ROOT}/categories --corpus <.crawl-dir-or-file>`. Read `winner` from JSON; load `categories/{winner}.md`. Fallback if the script is unavailable: score each pack's `detect_signals` against the corpus by inspection and pick the dominant; ties and zero-match → `generic`.
   - If the top-scoring category's confidence is low, load `categories/generic.md` and note the assumption explicitly in the brief.
   - If a site scores across multiple categories, pick the **single dominant pack**, note secondaries inline (e.g. "primarily ecommerce; secondary: local-service"). **Never merge packs.**
3. Emit `[PACK-LOADED:{winner}]` once the pack is selected.
4. **Ask the one question** (may be asked any time after Phase 4; MUST precede writing `content-inventory.md`/`ia-map.md`/`current-critique.md`): "Redesigning for the same purpose or a new one?" — record as `current purpose (inferred)` vs `target purpose (declared)`. Only human question in the pipeline. **Asking this early does not permit skipping steps 1–3 above** — category detection and `[PACK-LOADED:<cat>]` are mandatory and gate-enforced (see Phase 9).
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
   - **`[INFER-GUARD]`:** do NOT record a "section empty / content missing / link broken" finding unless it is verified against a JS render or raw HTML — not markdown alone (markdown crawlers drop JS-revealed content). See `references/crawl-and-coverage.md` → "Render fidelity".
3. **Voice/messaging pass** — flag vague adjectives ("innovative", "world-class"); identify three vaguest claims, propose replacements.
4. **SEO/a11y pass** — heading structure, metadata completeness, schema/NAP presence, alt-text coverage.
5. Write `current-critique.md` using `templates/current-critique.md.template`.

If `[TOOL-UNAVAILABLE:chrome-mcp]`: no screenshots — add `[VISUAL-GAP: visual-hierarchy critique not possible without screenshots]` to `current-critique.md`.

**Output:** `current-critique.md` written. Phase marker `[P8✓]`.

---

## Phase 9 — Synthesize

**Input:** All prior phase outputs and the session brief. Load `references/brief-format.md`.

**Actions:**
1. Resolve all **38** `{{TOKEN}}`s (listed below) from the session brief and phase outputs.
2. Write `brief.md` via `templates/brief.md.template`. Section order is a contract — do not reorder; see `references/brief-format.md` for the full contract including the per-page intent triplet format and design-system seed block format.
   - §9 web-capture instruction must include verbatim: _"Capture the live URL for content, structure, and brand assets to KEEP (logo, brand color, product photography) only. The design direction above OVERRIDES all captured visual styling."_
3. Write `run-sheet.md` via `templates/run-sheet.md.template`. Order: validate → key screen → remaining screens (severity order, not nav order) → components.
4. Finalize `content-inventory.md`, `ia-map.md`, `current-critique.md` (written in phases 5/6/8; resolve any remaining tokens).
   - **If `[RECON-REUSE]` fired:** `{{SAMPLING_NOTE}}` must state plainly that the audit reused a prior beacon recon and live-re-verified only the homepage + key routes (e.g. "re-verified recon synthesis, not a fresh crawl of all N URLs"); `{{AUDITED_COUNT}}` counts only pages actually (re-)read this run. Do not imply a full fresh crawl.
5. Write `INDEX.md` via `templates/INDEX.md.template`. Populate `{{PHASE_MARKERS}}` with the emitted `[P1✓]`…`[P9✓]` (or `[GREENFIELD-MODE]`) and `{{SIGNALS_FIRED}}` with every degradation signal that fired this run, including the `[PACK-LOADED:<cat>]` from Phase 7.
6. Resolve `{{TECH_EXPORT_HANDOFF}}`: read `docs/sites/{slug}/research/tech-stack.md`; if absent, read `docs/research/{slug}/tech-stack.md` (legacy); if neither exists, log `[TECH-STACK-ABSENT]` and add to `brief.md` §10: "No beacon tech-stack found — specify the target stack manually, or run beacon first".

7. **Completeness check:** Run `bash ${CLAUDE_PLUGIN_ROOT}/skills/site-redesign/scripts/check-output-complete.sh docs/sites/{slug}/redesign`. A non-zero exit means the run is not complete — resolve the named files/tokens and re-run. Fallback if unavailable: grep each output file for `{{` manually; no `{{` remaining = complete run. The gate now also fails if `INDEX.md` is missing any phase marker or the `[PACK-LOADED:<cat>]` token; resolve by recording the genuine run log (do not fabricate markers for phases you skipped — run them).

**Output:** All six output files written. Phase marker `[P9✓]`.

### Phase-9 token contract

Phase 9 MUST resolve every one of these **38** tokens — the deduplicated union across all six templates. Do not add or rename tokens.

`{{SITE_NAME}}` `{{DATE}}` `{{URL}}` `{{CATEGORY}}` `{{CATEGORY_CONFIDENCE}}` `{{INFERRED_PURPOSE}}` `{{TARGET_PURPOSE}}` `{{AUDIENCE}}` `{{PRIMARY_GOAL}}` `{{COVERAGE_MANIFEST}}` `{{ASSUMPTIONS}}` `{{WHAT_IT_IS}}` `{{GOALS_SUCCESS}}` `{{KEEP_CHANGE_ADD}}` `{{IA_PROPOSED}}` `{{DESIGN_DIRECTION_SEED}}` `{{REFERENCES_ANTI}}` `{{WEB_CAPTURE_OVERRIDE}}` `{{TECH_EXPORT_HANDOFF}}` `{{VALIDATE_PROMPT}}` `{{KEY_SCREEN_PROMPT}}` `{{REMAINING_SCREEN_PROMPTS}}` `{{COMPONENT_PROMPTS}}` `{{URL_COUNT}}` `{{AUDITED_COUNT}}` `{{SAMPLING_NOTE}}` `{{INVENTORY_ROWS}}` `{{UNAUDITED_LIST}}` `{{NAV_HIERARCHY}}` `{{PAGE_PURPOSE_TABLE}}` `{{JOURNEYS}}` `{{PRIMARY_CONVERSION_PATH}}` `{{VISUAL_TRACK_NOTE}}` `{{CRITIQUE_ROWS}}` `{{VOICE_FINDINGS}}` `{{SEO_A11Y_FINDINGS}}` `{{PHASE_MARKERS}}` `{{SIGNALS_FIRED}}`

---

## Graceful degradation signals

Log these in the session brief. Surface any that fired in `INDEX.md`.

| Signal | Meaning |
|--------|---------|
| `[RENDER-ESCALATED]` | Homepage < 200 chars or 0 nav links; re-fetched via Jina → Firecrawl → Crawl4AI; Chrome MCP only if all crawlers unavailable or auth-gated |
| `[GREENFIELD-MODE]` | After render: < 2 unique headings and < 150 non-nav words; pipeline halted — not a redesign target |
| `[NO-SITEMAP]` | No `sitemap.xml` and no `Sitemap:` in `robots.txt`; fell back to homepage-nav crawl |
| `[COVERAGE-PARTIAL:gated]` | One or more URLs returned 401/403/challenge; only public pages briefed |
| `[WAF-BLOCKED]` | Homepage blocked by Firecrawl, Jina, AND browser-fetch; proceeded with partial content |
| `[SAMPLED:n-templates]` | Crawl budget exhausted; `n` template clusters sampled, not all |
| `[SINGLE-PAGE]` | ≤2 URLs discovered; section-anchor map used instead of page table |
| `[MULTI-LOCALE:canonical=x]` | Locale branching detected; briefed canonical locale `x` only |
| `[TOOL-UNAVAILABLE:chrome-mcp]` | No screenshot source available (Jina/Firecrawl/Crawl4AI/Chrome MCP all unavailable); text-only output; visual gap noted |
| `[PACK-LOADED:x]` | Category pack `x` loaded for Phase 8 critique and design-system seed |
| `[TECH-STACK-ABSENT]` | No beacon tech-stack found at new or legacy path; §10 note added — specify stack manually or run beacon first |
| `[RECON-REUSE]` | A prior beacon recon exists at `docs/sites|research/{slug}/research/`; its files were read as a content source and the homepage live-re-verified. Provenance recorded in `{{SAMPLING_NOTE}}`. |

---

## Reference files

Load on demand:

- **`references/tool-availability.md`** — detection commands; crawl preference order; WAF escalation chain
- **`references/crawl-and-coverage.md`** — render-gate thresholds; screenshot sequences; coverage manifest; crawl budget
- **`references/brief-format.md`** — `brief.md` section order; intent triplet format; seed block format; run-sheet ordering
- **`categories/{detected}.md`** — matched category pack; `categories/generic.md` is the low-confidence fallback
- **`templates/`** — the six `*.template` files resolved in Phase 9

> **Path note:** `categories/` and `templates/` are at the plugin root (`plugins/reframe/`). `references/` is in `plugins/reframe/skills/site-redesign/references/`.
