# Beacon — Roadmap

Planned features and capabilities in priority order. Each version ships as a complete, tested unit.

---

## v0.6.0 — site-intel: Tech Pack Cross-Referencing

**Goal:** When the user asks a *how-do-I* or framework-specific question, site-intel loads the relevant tech pack alongside the research file — so answers draw on both what was discovered *and* framework conventions.

**What changes:**
- New Step 3a in site-intel SKILL.md: detect framework from INDEX.md/tech-stack.md, load `technologies/{framework}/{major}.x.md` when question involves query patterns, endpoint conventions, or framework APIs
- Clear trigger heuristics: "how do I", "query", "pagination", "auth flow", "what's the pattern for" → load tech pack
- Factual questions ("what endpoints exist?", "what CDN?") → research files only, no tech pack needed
- validate-site-intel.sh test (12 checks, TDD)

---

## v0.7.0 — Query Proof Scripts

**Goal:** Give site-intel the ability to optionally generate and run simple data-fetching scripts that prove discovered endpoints return real, useful data — showing the user the actual output, not just the status code.

**What changes:**
- Framework-specific query templates added to each tech pack (5–10 line curl/Python snippets)
- site-intel new Step 5: when user asks "show me what this returns" or "give me a sample", generate a minimal fetch script using the template and run it inline
- New output file type: `scripts/query-{surface}-{site}.sh` — one file per API surface, generated on demand (not auto-generated during Phase 12)
- Templates cover: pagination, listing resources, introspection (GraphQL), schema inspection (OpenAPI, Strapi), authenticated fetch

**Example output:**
```bash
# query-wp-rest-example-com.sh — WordPress REST API proof-of-life
curl -s "https://example.com/wp-json/wp/v2/posts?per_page=3" \
  | python3 -c "import sys,json; [print(p['id'], p['slug']) for p in json.load(sys.stdin)]"
```

---

## v0.8.0 — Research Freshness Signals

**Goal:** surface when research is stale and give the user a clear re-run path.

**What changes:**
- INDEX.md gains an `Analysed:` date field (already templated, but not used by site-intel)
- site-intel Step 2 checks the date; if research is older than 30 days, prepends a freshness warning to every answer
- New signal: `[RESEARCH-STALE:{days}d]` — logged in site-intel responses, not in INDEX.md
- Optional: suggest which phases to re-run for freshness (e.g., Phase 3 for framework version, Phase 8 for OpenAPI)

---

## v0.9.0 — Additional Tech Packs

**Goal:** expand framework coverage beyond the current 12 packs.

**Candidates (in priority order):**

| Framework | Version | Key signals | Notes |
|-----------|---------|-------------|-------|
| SvelteKit | 2.x | `__sveltekit_` globals, `_app/` static dir, `+page.svelte` routes | Compiled output — bundle analysis needed |
| Remix / React Router v7 | 2.x | `__remixContext` global, `window.__remixManifest`, `data-remix-*` | No API routes — loaders/actions only |
| tRPC | 10.x | `@trpc/client` in bundles, `.trpc.` procedure calls | No URL patterns — bundle analysis + DevTools capture |
| Nuxt 2.x | 2.x | `window.__NUXT__` (not `__NUXT_DATA__`), Vuex state | EOL but widely deployed; differs from Nuxt 3 |
| Hono | 4.x | `X-Powered-By: Hono`, `@hono/zod-openapi` → auto OpenAPI | Edge-first; Cloudflare Workers / Deno |
| Hasura | 3.x | `/v1/graphql`, `x-hasura-*` headers, introspection auto-generates full schema | Managed GraphQL on Postgres |
| Express | 4.x / 5.x | No conventions — OSINT-heavy; `X-Powered-By: Express` | Generic probe checklist; route discovery via bundle analysis |
| Spring Boot | 3.x | `/actuator/` endpoints, `springdoc-openapi` auto-generates `/v3/api-docs` | Actuator exposes health, metrics, mappings |
| Payload CMS | 3.x | `/api/{collection}`, `/api/globals/{slug}`, REST + GraphQL dual surface | Version-specific admin paths |
| Directus | 11.x | `/items/{collection}`, `/system/` prefix, `/server/info` | REST + GraphQL; system collections enumerable |

Each new pack triggers a failing check in `validate-fingerprinting.sh` automatically (self-healing coverage loop).

**Domain-specific packs** (no framework fingerprint — grouped by site type):

- **Real estate directory**: GeoJSON search endpoints, Leaflet/Mapbox map APIs, faceted search parameter structures, `RealEstateProperty` JSON-LD schema extraction
- **Government portal**: MantisIMS detection, DataTables jQuery API patterns, WordPress nonce auth, public dataset API discovery

**Research sources used for pack design:**
- tRPC patterns → `knowledge/developer-tools/frontend/trpc.md` (nikai-internal, not available in this repo)
- Nuxt 2 real-world example → `docs/research/spitogatos/tech-stack.md` (nikai-internal, not available in this repo)
- GraphQL vs REST directory API patterns → `research/guides/graphql-vs-rest-directory-apis.md` (nikai-internal, not available in this repo)

---

## v0.10.0 — Multi-Site Comparison

**Goal:** answer questions that span two research folders — "how does X differ from Y?", "which site has a public GraphQL API?", "compare the auth flows".

**What changes:**
- site-intel gains a multi-site mode: when the user references two sites, finds both research folders and loads INDEX.md for each before routing
- New routing table entries for comparative questions
- No new output files; operates on existing research

---

## v0.11.0 — Export Formats

**Goal:** convert the OpenAPI spec discovered during analysis into formats that are immediately usable in other tools.

**What changes:**
- New command `/beacon:export {site} {format}` — runs post-processing on `specs/{site}.openapi.yaml`
- Formats: Postman collection (via `openapi-to-postman`), Bruno collection, Insomnia workspace
- Falls back to manual scaffolding if spec is partial
- Output: `docs/research/{site}/exports/{format}/`

---

## Phase Enhancement Backlog

Improvements to existing phases that don't require a version bump — suitable for patch releases.

### Phase 2 — Passive Recon

**Structured data extraction (JSON-LD)**
Add `<script type="application/ld+json">` extraction to Phase 2. Key schema types:
- `SearchAction` → reveals search endpoint URL and query parameter name directly
- `Organization.sameAs` → social profiles and associated domains
- `Product` / `LocalBusiness` → data shape hints for API responses

See `references/osint-sources.md` — JSON-LD section.

**Robots.txt structural analysis**
Parse Disallow paths as infrastructure signals:
- `/api/*` → confirms API surface and root path
- `/admin/*` → admin panel location (often different auth surface)
- `/internal/*` → internal/external endpoint split
- `/partner/*` / `/enterprise/*` → tiered access surfaces

### Phase 3 — Fingerprinting

**Bot protection detection**
Add to infrastructure table:
- `CF-Ray` / `cf-cache-status` → Cloudflare (with CDN)
- `X-AWS-WAF-Action` → AWS WAF
- `X-Sucuri-ID` → Sucuri WAF
- `_abck` cookie → Akamai Bot Manager
- reCAPTCHA / hCaptcha `<script>` tags → CAPTCHA provider

Log as: `Bot protection: Cloudflare (source: CF-Ray header)`

### Phase 7 — JS & Source Maps

**Webhook URL discovery**
Bundle grep patterns to add:
- Path patterns: `/webhook`, `/webhooks`, `/hook`, `/callback`, `/notify`
- Standard probe paths: `/api/webhooks`, `/{version}/webhooks`, `/hooks`
- Tech pack sections should document known webhook paths (Stripe, GitHub, Shopify)

### Phase 9 — OSINT

**Expand Google dorking patterns** (add to phase-detail.md):
```
site:github.com "{domain}" "endpoint" "api"
site:{domain} inurl:"/api/v" OR inurl:"/graphql"
inurl:"github.com" "{domain}" "NEXT_PUBLIC_API_URL" OR "API_BASE_URL"
site:{domain} "swagger" OR "openapi" OR "/api/docs"
```

**Add optional Shodan + SecurityTrails integration**
Both require API keys — detect via env var, log `[TOOL-UNAVAILABLE:shodan]` if absent.
See `references/osint-sources.md` for query patterns.

### Phase 11 + api-surfaces — Rate Limit Discovery

Capture rate limit headers from Phase 11 XHR responses:
- `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- `Retry-After`
- Populate `{{RATE_LIMIT_NOTES}}` token in api-surface.md.template

### All Phases — ReAct Prompt Pattern

Consider adding explicit Think/Act/Observe structure to phase instructions:
- **Think:** What signals am I looking for and why?
- **Act:** What commands/probes to run
- **Observe:** How to interpret results and log them in the session brief

Reference: `knowledge/prompt-techniques/_index.md` (nikai-internal, not available in this repo) for examples.

---

## Research Sources

Knowledge from the nikai project (internal, not available in this repo) used in planning this roadmap. Useful references
for contributors designing new phases or packs:

| Topic | nikai location (internal) |
|-------|--------------------------|
| OSINT tool guides (Shodan, crt.sh, theHarvester, SpiderFoot) | `knowledge/security/osint/` |
| Web scraping tools comparison (Firecrawl, Crawl4AI, ScrapeGraphAI) | `research/guides/web-scraping-for-ai-agents.md` |
| HTTP header tech detection patterns | `knowledge/methodologies/http-header-tech-detection.md` |
| robots.txt and sitemap analysis techniques | `knowledge/methodologies/robots-txt-analysis.md` |
| JSON-LD / Schema.org extraction | `knowledge/methodologies/schema-org-json-ld-extraction.md` |
| Real-world Nuxt 2 + real estate tech stack | `docs/research/spitogatos/tech-stack.md` |
| tRPC patterns and bundle signatures | `knowledge/developer-tools/frontend/trpc.md` |
| GraphQL vs REST for directory/aggregator APIs | `research/guides/graphql-vs-rest-directory-apis.md` |
| Prompt engineering techniques (ReAct, CoT, etc.) | `knowledge/prompt-techniques/_index.md` |
