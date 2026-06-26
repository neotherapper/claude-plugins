# reframe — Roadmap

Planned features and capabilities in priority order. Each version ships as a complete, tested unit.

---

## v0.1.0 — Shipped (2026-06-22)

Initial release. The full 9-phase coverage-first pipeline:

- Scaffold + tool check → Structure discovery → Render + coverage gate → Content crawl + screenshots → Content audit → IA / journey map → Intent inference → Current-design critique → Synthesize
- Coverage-first architecture: render gate escalates JS-rendered SPAs; content-sufficiency gate detects placeholder sites before inferring
- Content-extraction preference: Jina Reader → Firecrawl → Crawl4AI; Chrome DevTools MCP reserved for screenshots and authenticated flows
- Category packs (local): `local-service`, `saas-marketing`, `ecommerce` + `generic` fallback
- Two-stage deliverable: `brief.md` (Claude Design onboarding) + `run-sheet.md` (canvas prompts)
- Evaluative content audit with keep / revise / consolidate / remove verdicts + ROT flags
- IA / journey map with per-page intent triplets and primary conversion path
- Severity-rated current-design critique (0–4), principle-cited, with concrete fixes
- 9 annotated graceful degradation signals
- Beacon interop: reads `docs/sites/{slug}/research/tech-stack.md` first (falls back to legacy `docs/research/{slug}/tech-stack.md`) for the tech-constraint note if present
- Output lives under the shared `docs/sites/{slug}/redesign/` workspace (alongside beacon's `research/`)

---

## v1.1 — Remaining category packs

**Goal:** Complete the ~10-category taxonomy so sites that currently fall back to `generic` get a genuinely opinionated pack.

**Shipped:**
- `portfolio-personal` — designer/developer/freelancer portfolios (v0.3.0, 2026-06-26). Dual co-primary goal (win the next client/role + grow an audience) with an enforced CTA hierarchy; covers creative and developer disciplines with per-type variations noted inline.

**Planned packs (in priority order):**
- `restaurant-hospitality` — restaurants, cafés, hotels
- `nonprofit` — cause-driven organisations, charities
- `editorial-blog` — content-first publications
- `corporate-brochure` — B2B company sites
- `education-course` — online learning, course landing pages
- `events` — conference, festival, ticketed event sites

Until a pack ships, any site in its category detects to `generic`. These packs are planned, not built.

---

## v2 — Deferred features (from design spec §13)

The following were scoped and designed for v1 but deferred as YAGNI. They are planned, not built.

**Competitor and reference-site teardown**
Run the same content/IA/critique pipeline on 2–3 named competitor or reference sites and surface the delta against the target site's brief. Feeds the CHANGE and reference/anti-reference sections with concrete, site-specific evidence rather than category-pack defaults.

**Review mining for local services**
For `local-service` sites, pull Google Business Profile reviews, Trustpilot, or equivalent and extract recurring themes — what patients/clients praise, what they flag. These signals feed audience understanding and the voice/messaging pass without requiring owner access.

**Owner-supplied analytics and Search Console input**
Accept GA4 / Search Console export as optional input; use top landing pages, top queries, and bounce patterns to weight the content audit verdicts and IA priorities.

**Post-Claude-Design feedback and diff loop**
After the user produces a design in Claude Design, re-evaluate it against the brief's goals and generate follow-up prompts ("the pricing page doesn't resolve the trust objection identified in the brief — here is a revised canvas prompt"). Closes the loop between the brief and the actual output.

These are real planned features from the design process, not speculative wish-list items.
