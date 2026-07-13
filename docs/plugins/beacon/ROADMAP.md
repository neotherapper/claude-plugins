# Beacon — Roadmap

Planned features and capabilities in priority order. Each version ships as a complete, tested unit.

> **Status legend:** ✅ shipped · 🔜 next · 📋 planned. The version numbers below were reconciled
> against what actually shipped, most recently on 2026-07-12 — read **Shipped** first. The
> sequence has slipped three times now (v0.7.0, v0.8.0, v0.9.0 each went to something other than
> the item originally planned for that number), so the two items immediately below **Shipped**
> intentionally carry no pre-assigned version number — it gets assigned at actual release, not
> before. Numbers further down the backlog (v0.10.0+) are still indicative placeholders.

---

## Shipped

| Version | What actually shipped | Notes |
|---------|----------------------|-------|
| ✅ v0.6.0 | site-intel tech-pack cross-referencing (Step 3a) | Matches the v0.6.0 plan below |
| ✅ v0.7.0 | **Workspace restructure** → `docs/sites/{slug}/research/` with dual-path fallback (PR #27) | ⚠️ This consumed the v0.7.0 number; the planned "Query Proof Scripts" shipped one version later, as v0.8.0 (see below) |
| ✅ #31 | site-recon `SKILL.md` de-dup + phase reorder (Phase 1–2.5 reconcile, Phase 8.5 restored after Phase 8) | Landed on `main` before this work; the OSINT wiring below builds on it |
| ✅ site-recon OSINT wiring (2026-06-30) | On top of #31: Phase 9 OSINT sweep wired via `osint.py run_all` (fixed its `TARGET` env-var bug so the 9 `.sh` helpers actually run); CSP/CORS `connect-src` API-domain extraction (Phase 2) and third-party-key harvest (Phase 9) promoted from `references/`; bundled-scripts table added to `SKILL.md` | Closes the "catalogued-but-unwired" gap for the OSINT helpers |
| ✅ v0.8.0 | site-intel Step 5 (Query Proof Scripts) + tech-pack `## Query Templates` | Data-driven snippet selection by `auth:`; see plan |
| ✅ v0.9.0 | **Fleet orchestration B1 (sequential core)** — `/beacon:fleet`, durable `.fleet/` ledger, `Stop`-only sweep gate (PR #40) | Closes the Option-A residual gap (abandoned/zero-output recons); parallelism deferred to B2 |

---

## v0.6.0 — site-intel: Tech Pack Cross-Referencing ✅ SHIPPED

**Goal:** When the user asks a *how-do-I* or framework-specific question, site-intel loads the relevant tech pack alongside the research file — so answers draw on both what was discovered *and* framework conventions.

**What changes:**
- New Step 3a in site-intel SKILL.md: detect framework from INDEX.md/tech-stack.md, load `technologies/{framework}/{major}.x.md` when question involves query patterns, endpoint conventions, or framework APIs
- Clear trigger heuristics: "how do I", "query", "pagination", "auth flow", "what's the pattern for" → load tech pack
- Factual questions ("what endpoints exist?", "what CDN?") → research files only, no tech pack needed
- validate-site-intel.sh test (12 checks, TDD)

---

## Query Proof Scripts — ✅ SHIPPED (v0.8.0)

> **Reconciled 2026-07-08:** v0.7.0 actually shipped as the `docs/sites/{slug}/research/` workspace
> restructure (see **Shipped**), so this feature slipped one version and shipped as v0.8.0 instead
> (site-intel Step 5 + tech-pack `## Query Templates` — see **Shipped** above).

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

## Research Freshness Signals — 🔜 next

> **Reconciled 2026-07-12:** previously labeled v0.9.0, but that number was consumed by Fleet
> orchestration B1 (see **Shipped**) — the third consecutive slip. Rather than bump to v0.10.0
> (already "Multi-Site Comparison" further down) and create a fourth collision, this item and
> "Additional Tech Packs" below now carry no pre-assigned number; per this doc's own legend,
> the actual version gets assigned at release. Not re-cascading the rest of the backlog's
> numbers here — out of scope for this reconciliation.

**Goal:** surface when research is stale and give the user a clear re-run path.

**What changes:**
- INDEX.md gains an `Analysed:` date field (already templated, but not used by site-intel)
- site-intel Step 2 checks the date; if research is older than 30 days, prepends a freshness warning to every answer
- New signal: `[RESEARCH-STALE:{days}d]` — logged in site-intel responses, not in INDEX.md
- Optional: suggest which phases to re-run for freshness (e.g., Phase 3 for framework version, Phase 8 for OpenAPI)

---

## Additional Tech Packs — 📋 planned

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

`validate-fingerprinting.sh` scans each new pack automatically, but coverage gaps are reported as informational WARNs, not CI failures — only the 6 named regression checks (Astro, Django, FastAPI, Rails, Shopify, Strapi) hard-fail. Adding a new pack does not self-enforce a Phase 3 signal; treat the WARN count as a backlog, not a gate.

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
- Output: `docs/sites/{site}/research/exports/{format}/`

---

## Fleet Orchestration B2 — Parallelism 📋 (deferred — not a priority)

> **Deferred by design.** B1 (v0.9.0, shipped) already delivers every *correctness* win — the real
> `site-analyst` agent, a durable ledger, no lost batch, and a deterministic zero-output catch. B2
> buys only *throughput* (a large fleet finishes faster), and it is the genuinely hard part: the
> parallel-first design failed adversarial review twice before B1 was decomposed out of it. Pick it
> up only if reconning many sources (10+) sequentially becomes a real speed pain point. It gets its
> own spec/plan — the requirements are sketched in the B1 design's "B2 boundary"
> (`docs/superpowers/specs/2026-07-10-beacon-fleet-orchestration-design.md`, §13).

**Goal:** run `/beacon:fleet` sources concurrently (waves of ≤3) instead of one at a time.

**What changes:**
- **Capability-sandboxed passive agent** (`site-scout` with a restricted `tools:` frontmatter that
  omits the browser MCP namespaces) **plus a `PreToolUse` Bash hook to block `cmux`** — cmux is a
  Bash CLI, so a tools-allowlist alone does not stop a scout from driving the browser.
- **Content hand-off contract** — splitting a source across scout (passive) + main (browser)
  contexts kills beacon's in-context session brief at scout termination, yielding a hollow bundle.
  Persist the brief + passive synthesis across the seam, substance-gated so an empty bundle cannot
  ship.
- **Browser serialization** — parallel scouts must still serialize the browser phase; no two agents
  drive one Chrome at once.
- **Rate-limit backoff** — concurrency re-introduces the 6-concurrent API rate-limit problem B1
  dissolved by going sequential.
- Builds on B1's `.fleet/` ledger, sweep, `Stop`-hook, and `slugify.py` unchanged.

**Related B1 fast-follow (smaller, can land independently):** atomic ledger write in `fleet.py`
`_mutate` (`os.replace` instead of truncate-in-place) — the `fleet-sweep.sh` hook already fails safe
on a corrupt ledger, so this is hardening, not a blocker.

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

> ✅ **Done (2026-06-30 hardening pass):** the bundled OSINT scripts — `passive_dns.sh`,
> `sublist3r.sh`, `tls_fingerprint.sh`, `cloud-enum.sh`, `container-scan.sh`, `cicd-scan.sh` — are
> now executed in Phase 9 via `osint.py run_all`, and CSP `connect-src` API-domain extraction
> (Phase 2) plus third-party-key harvest (Phase 9) were promoted from `references/osint-sources.md`
> into the executable phases. Still open below: Shodan/SecurityTrails (API-key-gated) and the
> expanded dork patterns.

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
