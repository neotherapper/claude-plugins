---
name: site-recon
description: This skill should be used when the user asks to "analyse a site", "research https://...", "map the API surface of", "find endpoints for", "what APIs does X have", "document how to extract data from", or runs /beacon:analyze. Use it even when the user just pastes a URL and says "check this out" or "look into this". Runs a 12-phase systematic investigation of a website and produces a complete persistent docs/research/{site-name}/ folder.
version: 0.6.0
---

# site-recon — Research Mode

Systematically analyse a target website across 12 ordered phases. Each phase writes
findings to an in-memory **session brief** (a running markdown document in context).
Phase 12 flushes everything to disk as structured research files.

## Output structure

```
docs/research/{site-slug}/
├── INDEX.md                 ← Summary, infrastructure table, quick API reference
├── tech-stack.md            ← Framework, version, CDN, auth, hosting evidence
├── site-map.md              ← All discovered URLs by category
├── constants.md             ← Taxonomy IDs, nonces, enums, public config values
├── api-surfaces/
│   └── {surface}.md         ← One file per discovered API surface
├── specs/
│   └── {site}.openapi.yaml  ← Auto-downloaded or scaffolded from discoveries
└── scripts/
    └── test-{site}.sh       ← Runnable smoke tests for key endpoints
```

Derive `{site-slug}` from the domain: `example.com` → `example-com`, `api.example.com` → `api-example-com`.
Strip `www.` before slugifying: `www.jetpens.com` → `jetpens-com`, not `www-jetpens-com`.

## The 12 phases — always in this order

| # | Phase | What happens |
|---|-------|-------------|
| 1 | Scaffold | Create output folder; check tool availability |
| 2 | Passive recon | robots.txt, sitemaps, .well-known, HTTP headers, crt.sh subdomains |
| 3 | Fingerprint | Detect framework + version (Wappalyzer → headers → HTML → JS) |
| 4 | Tech pack | Load framework guide from GitHub, context7, or web search |
| 5 | Known patterns | Apply every item in the tech pack's probe checklist |
| 6 | Feeds & structure | RSS/Atom, JSON-LD, GraphQL introspection, API version enumeration |
| 7 | JS & source maps | Download bundles, grep for endpoints and auth patterns, check .map files |
| 8 | OpenAPI detect | Probe 15 standard paths; download spec if found |
| 9 | OSINT | Wayback CDX, CommonCrawl CDX, GitHub code search, Google dorks |
| 10 | Browse plan | Compile a prioritised URL list + actions from all phase 2–9 findings |
| 11 | Active browse | Execute the browse plan via cmux or Chrome DevTools MCP; HAR → OpenAPI |
| 12 | Document | Write all output files from the completed session brief |

**Why this order:** Phases 2–9 are fully automated (no browser, just curl and APIs). They
maximise the signal available to Phase 10. Phase 10 is a synthesis step — it compiles
a concrete target list *before* any browser opens. Phase 11 executes the plan. The AI
never browses blindly.

**Phase 7 note:** Phase 6 conclusions about API availability are PROVISIONAL. Phase 7 JS
analysis routinely overrides Phase 6 "no API" verdicts — AJAX endpoints are embedded in JS
bundles, not HTML. Never finalise the API surface until Phase 7 is complete.

**Phase 7 browser-fallback:** If curl returns 404 for all JS bundle URLs (URL rewriting may
serve a 404 HTML page instead of the JS file), log `[PHASE-7-CURL-BLOCKED:retrying-via-browser]`
and fetch the same URLs via `cmux browser eval fetch('/path/to/bundle.js').then(r=>r.text())`.
JS bundles on PrestaShop and similar platforms require correct Referer and session cookies that
only the browser context provides. Phase 7 is not complete until at least one JS bundle read
succeeds, or browser fetch also fails.

## Session brief

Maintain a running markdown document in context throughout the run. This is your
working memory — append after each phase, never overwrite earlier sections.

```
## Session Brief — {site-slug}

### Infrastructure
Framework: {name} {version}   Source: {signal}
CDN: {name or unknown}
Auth: {mechanism or unknown}
Bot protection: {name or none detected}

### Tool Availability
[AVAILABLE] or [TOOL-UNAVAILABLE:{name}] for each:
  wappalyzer, firecrawl, chrome-devtools-mcp, cmux-browser, gau

### Tech Pack
[LOADED:{framework}:{version}] or [TECH-PACK-UNAVAILABLE:{framework}:{version}]

### Discovered Endpoints  ← grows throughout the run
| Endpoint | Method | Auth | Phase | Notes |

### Browse Plan  ← written in Phase 10
```

See `references/session-brief-format.md` for the complete schema.

## Phase 1 — Scaffold and tool check

```bash
# Strip www. then slugify
SLUG=$(echo "{url}" | sed -E 's|https?://(www\.)?||;s|/.*||;s|\.|-|g')
mkdir -p docs/research/${SLUG}/{api-surfaces,specs,scripts}
```

**Critical:** Do NOT use `touch` to create output files — the Write tool requires a prior Read.
Use `Write` directly with empty string content for each output file, or they will fail at Phase 12.

```
Write docs/research/${SLUG}/INDEX.md        ← empty string
Write docs/research/${SLUG}/tech-stack.md   ← empty string
Write docs/research/${SLUG}/site-map.md     ← empty string
Write docs/research/${SLUG}/constants.md    ← empty string
```

Then check every tool in the tool availability matrix and log results in the session brief.
See `references/tool-availability.md` for exact detection commands.

**AI crawler check order (log each as AVAILABLE or TOOL-UNAVAILABLE):**
1. Firecrawl MCP — `firecrawl_scrape` in tool list
2. Spider MCP — `spider_scrape` or `spider_crawl` in tool list; or `SPIDER_API_KEY` env var set
3. Scrapfly — `SCRAPFLY_API_KEY` env var set (specialist for DataDome/PerimeterX)
4. Jina Reader — `curl -s -o /dev/null -w "%{http_code}" https://r.jina.ai/https://httpbin.org/get` returns 200
5. Crawl4AI — `python3 -c "import crawl4ai"` exits 0
6. Steel — `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health` returns 200; or `STEEL_API_KEY` env var

Jina Reader is almost always available (no install, free tier). Log `[AVAILABLE:jina-reader]` if the probe returns 200.

**Chrome MCP namespace:** In Phase 1, test BOTH Chrome MCP namespaces and record which works:
- Try `mcp__plugin_chrome-devtools-mcp_chrome-devtools__list_pages` first (plugin-level)
- Fall back to `mcp__chrome-devtools__list_pages` (project-level)
- Log the working namespace as `[CHROME-NAMESPACE:{active}]` in the session brief
- Use ONLY the recorded namespace for all Chrome MCP calls in phases 10–11

**gau alias check:** `which gau` is not sufficient — `gau` may be aliased to `git add --update`.
Run `gau --version 2>&1 | grep -i "getallurls\|gau"` to confirm it is the URL extractor.
If the output contains `git` output, log `[TOOL-UNAVAILABLE:gau:aliased]`.

## Phase 3 — Fingerprinting (first match wins)

1. **Wappalyzer MCP** (if available): `lookup_site(url)` → framework + version

2. **HTTP headers**: `curl -sI {url}` → grep for:
- `Ghost-Version` → Ghost
- `x-nuxt` → Nuxt
- `X-Inertia` → Laravel/Inertia
- `x-shopify-stage: production` → Shopify (Definitive)
- `X-Powered-By: Strapi` or `X-Strapi-Version` → Strapi (Definitive)
- `server: uvicorn` → FastAPI (combined signal)
- `X-Runtime` → Rails (combined signal — confirm with `csrf-token` meta or `_*_session` cookie before concluding Rails; `X-Runtime` alone is not sufficient)
- `X-Powered-By: Express` → Express (Definitive)

3. **HTML signals**: `curl -s {url}` → grep for:
- `wp-content/` → WordPress
- `/_next/` → Next.js
- `/_nuxt/` → Nuxt
- `laravel_session` → Laravel
- `/_astro/` or `astro-island` → Astro
- `content="Astro v` → Astro + version (Definitive)
- `csrfmiddlewaretoken` → Django (Definitive)
- `<meta name="csrf-token"` → Rails (Definitive)
- `cdn.shopify.com` or `window.Shopify` → Shopify (Definitive)
- `Zend_Controller_Exception` or `Zend_Exception` in error body → Zend Framework 1 (Definitive)
- `/library/Zend/` or `/application/controllers/` in stack trace → Zend Framework 1 (Definitive)
- `X-Powered-By: Express` → Express (Definitive)
- "Cannot GET /" → Express (High)

4. **JS globals / cookies**: inspect inline scripts and `Set-Cookie` headers:
   - `__NEXT_DATA__` → Next.js
   - `window.__nuxt` → Nuxt
   - `_shopify_y` or `_shopify_s` cookies → Shopify
   - `_[a-z0-9_]+_session` cookie pattern → Rails
   - `X-Magento-Tags` or `X-Magento-Cache-Id` response headers → Magento 2 (Definitive)
   - `mage-cache-sessid` cookie → Magento 2 (High)
   - `data-mage-init` attribute in HTML → Magento 2 (High)
   - `window.woocommerce_params` or `wc-cart-hash` cookie → WooCommerce (Definitive)
   - `window.wc` JS global present → WooCommerce (High)
   - `__VIEWSTATE` hidden input field → ASP.NET WebForms (Definitive)
   - `.aspx` in URL paths → ASP.NET (High)
   - `ASP.NET_SessionId` cookie → ASP.NET (High)
   - `X-Powered-By: ASP.NET` header → ASP.NET (Definitive)
   - Atom/RSS feed `<generator>` tag → check for framework signal:
     `Zend_Feed_Writer` → Zend Framework 1, `Ghost` → Ghost, etc.

5. **Endpoint probes** (for API-only and CMS sites):
   ```bash
   # Strapi — check /admin/init for hasAdmin field (Definitive)
   curl -s {url}/admin/init | python3 -c "import sys,json; d=json.load(sys.stdin); print('strapi' if 'hasAdmin' in d.get('data',{}) else '')" 2>/dev/null || true
   # FastAPI — Swagger UI at /docs (High; may be disabled)
   curl -s {url}/docs | grep -i 'swagger-ui'
   # FastAPI — OpenAPI JSON (High; may be disabled)
   curl -s {url}/openapi.json | python3 -c "import sys,json; d=json.load(sys.stdin); print('fastapi' if 'openapi' in d else '')" 2>/dev/null
   # Django admin (Definitive)
   curl -s {url}/admin/ | grep -i 'django site administration'
   # Django REST Framework browsable API (Definitive)
   curl -s {url}/api/?format=api | grep -i 'django rest framework'
   ```

6. **No match**: log `[FRAMEWORK-UNKNOWN]`, continue with generic probes

Log the result: `Framework: WordPress 6.5 (source: wp-content/ in HTML + generator meta, confidence: high)`

**Version extraction after identification:**
- WordPress: `grep -oP 'content="WordPress \K[\d.]+'` from generator meta
- Next.js: `grep -oP '"next":"\K[^"]+'` from `__NEXT_DATA__` inline JSON
- Ghost: read `Ghost-Version` header directly
- Astro: `grep -o 'content="Astro v[^"]*"'` from HTML — version in meta tag
- Strapi v5+: `X-Strapi-Version` header
- Rails: `grep -oP '@hotwired/turbo@\K[^"]*'` from importmap block
- Shopify: `window.Shopify.theme.name` via JS eval in Phase 11
- Django / FastAPI: version not exposed in production headers
- Zend Framework 1: check error page stack traces for `/library/Zend/Version.php` path; probe `{site}/library/Zend/Version.php` for `VERSION` constant; otherwise version unknown
- Magento 2: `GET /magento_version` (returns version string directly); fallback: grep `/pub/static/version{N}/` path — `N` is a deploy timestamp, not the Magento version
- WooCommerce: generator meta tag `<meta name="generator" content="WooCommerce {version}">` or `/wp-json/wc/v3/system_status` (requires auth)
- ASP.NET: version rarely exposed; `X-Powered-By: ASP.NET` may include version; check `ScriptResource.axd` query string for hash hints

## Phase 4 — Tech pack lookup

Once framework and major version are known, try in order:

1. **GitHub** (primary) — version-pinned URL:
   ```
   https://raw.githubusercontent.com/neotherapper/claude-plugins/v{PLUGIN_VERSION}/plugins/beacon/technologies/{framework}/{major}.x.md
   ```
   Read plugin version from `.claude-plugin/plugin.json` — never use `main` branch.

2. **context7 MCP** (if available) — ask for framework's official API documentation

3. **Web search fallback** — search `{framework} {major}.x API routes endpoints file structure`

4. **No pack, no internet** — log `[TECH-PACK-UNAVAILABLE:{framework}:{version}]`, continue with generic probes

If web search fallback used, offer a PR at the end of Phase 12:
> "I built a temporary tech pack for {framework} {version} from web search.
> Would you like me to open a PR to add it permanently to the community library?"

Version mismatch: if `15.x` requested but only `14.x` exists, use `14.x` and log
`[TECH-PACK-VERSION-MISMATCH:nextjs:15.x→14.x]`.

**Late discovery rule:** If a new framework signal is found in Phase 5, 6, 7, or 9 (e.g., ZF1 from
an Atom feed generator tag, ASP.NET from a response header), immediately pause and re-run Phase 4
for that framework before continuing. Do not defer the tech pack lookup to Phase 12. Log:
`[TECH-PACK-LATE-LOAD:{framework}:{version}:phase={N}]`

**Tech pack checklist comparison (run immediately after loading any tech pack):**
After loading a tech pack (at Phase 4 time, or after a late discovery), compare the pack's
probe checklist section against the Discovered Endpoints table in the session brief. Count how
many checklist items have NOT yet been probed. Log:
`[TECH-PACK-SUPPLEMENTAL-PROBE:{n} items from checklist not yet run]`
Run all outstanding checklist items before proceeding. Do not start Phase 12 until the tech
pack's checklist is exhausted — reading the pack but skipping its probes is the most common
cause of incomplete output files.

**External tech pack update rule:** If the user says a tech pack was added or updated externally
after Phase 5 already ran, re-read the new pack, run its checklist comparison, and execute any
outstanding probes before Phase 12. Log: `[TECH-PACK-RELOAD:{framework}]`

## Phase 8 — OpenAPI auto-detection

Probe these paths in order; stop at the first 200 response that returns JSON or YAML:

```
/openapi.json    /openapi.yaml    /swagger.json    /swagger.yaml
/api/openapi.json   /api/swagger.json   /api/docs   /api/docs.json
/docs/openapi.json  /v1/api-docs  /api-docs  /api-docs.json  /spec.json  /redoc
```

If found: save to `specs/{slug}.openapi.yaml`, mark `source: auto-downloaded`.  
If not found: continue — Phase 12 will scaffold a spec from all discovered endpoints.

## Bot protection handling

When curl probes return 403 from Cloudflare (or similar), escalate through this chain:

**First, identify the WAF** — check response headers before choosing bypass:
- `cf-ray` header → Cloudflare
- `x-datadome-*` or `{"type":"DataDome"}` body → DataDome
- `_px*` cookies → PerimeterX
- `AkamaiGHost` in `Server` header → Akamai

Then escalate through the appropriate chain:

**Step 1 — Firecrawl** (if MCP available): `firecrawl_scrape(url, formats=["markdown"])` — bypasses most Cloudflare configs. Log `[CF-PIVOT:firecrawl]`.

**Step 2 — Spider** (if API key available): rotates fingerprints per request — effective against Cloudflare and Akamai. Log `[CF-PIVOT:spider]`.

**Step 3 — Scrapfly** (if API key available, `asp=true`): **specialist for DataDome/PerimeterX** — 98% bypass rate on those WAFs. `curl "https://api.scrapfly.io/scrape?key={KEY}&url={url}&asp=true"`. Log `[CF-PIVOT:scrapfly]`.

**Step 4 — Jina Reader** (always available, no install):
```bash
curl -s "https://r.jina.ai/{target_url}"
```
Returns clean markdown when curl 403s. Works for content pages; less effective on API endpoints. Log `[CF-PIVOT:jina]`.

**Step 5 — Browser fetch**: use `evaluate_script` with `fetch()` from within a same-domain page. Log `[CF-PIVOT:browser-fetch]`.

**Step 6 — Give up on that probe**: log `[CF-BLOCKED:all]` and move on. Do not loop.

**Identification:** if Phase 2 `GET /robots.txt` returns 403, the site is curl-blocked — start Firecrawl/Jina immediately for all Phase 2–9 probes.

**CORS-blocked probes:** browser fetch from same-origin page context works for same-domain paths. Cross-origin fetch returns `{status:0, type:"opaqueredirect"}` — log `[CORS-OPAQUE:{path}]`.

**Cloudflare Turnstile:** CDP `click` on the verify checkbox always times out. Use cmux with existing CF-cleared session. Log `[CF-TURNSTILE-BLOCKED:{url}]`.

## E-commerce probe list (Phase 5 supplement)

When an e-commerce platform is detected (WooCommerce, Magento, Shopify, ZF1, ASP.NET, or `[FRAMEWORK-UNKNOWN]` on a store-like site), run these additional probes in Phase 5:

**Product discovery:**
- `GET /wp-json/wc/store/v1/products?per_page=20` — WooCommerce Store API (no auth)
- `GET /wp-json/wc/v3/products?per_page=5` — WooCommerce REST API (may need consumer key)
- `POST /graphql {"query":"{ products { items { name sku price { regularPrice { amount { value } } } } } }"}` — Magento 2
- `GET /products.json?limit=5` — Shopify
- `GET /Compare/loadAjax` — ZF1 comparison AJAX
- `GET /Compare/getPopularComparisonsAjax` — ZF1 curated product groups
- `GET /Compare/addProductAjax?products_id=1` — ZF1 single product JSON

**Search and autocomplete:**
- `GET /search/suggestions?q=test` — generic autocomplete
- `GET /autocomplete?q=test` — variant
- `GET /search/autocomplete?q=test` — variant
- `GET /autocomplete.aspx?keyword=test` — ASP.NET variant
- `GET /Search/index/q/test/format/json` — ZF1 style

**Cart AJAX:**
- `GET /cart/addAjax?products_id=1` — ZF1 cart add (returns JSON)
- `GET /cart/getAddListAjax?products_ids=1,2` — ZF1 batch product cards
- `POST /wp-json/wc/store/v1/cart/add-item` — WooCommerce Store API
- `GET /?wc-ajax=get_refreshed_fragments` — WooCommerce legacy cart

**Feeds and structured data:**
- `GET /feeds/products` — product XML/JSON feed
- `GET /feeds/google` — Google Shopping feed
- `GET /feed` and `GET /blog/feed` — Atom/RSS (check `<generator>` tag for framework signal)
- `GET /sitemap_products_1.xml` — Shopify product sitemap

**Note:** A "no programmable API" conclusion requires ALL of the above to be probed and return non-useful responses. A 404 on `/wp-json/wc/v3/` does not mean the site has no API.

**Critical:** Do NOT write "no JSON API" or "no programmable endpoints" in any output file until
Phase 7 (JS bundle analysis) is fully complete. JS bundles routinely reveal AJAX endpoints that
are invisible to Phase 5/6 probing — e.g., a search endpoint that returns HTML by default but
JSON when `ajaxSearch=1` is appended, or a GTM data endpoint embedded only in theme JS. Phase 6
conclusions about API availability are always provisional until Phase 7 is done.

**Pagination with hidden form fields (server-rendered sites):**
When category/product listing uses server-side pagination with hidden form fields (common on
ASP.NET, OpenCart, PrestaShop), use the navigate→extract→POST sequence:
```
1. goto /category-page  (via cmux or Chrome MCP)
2. eval: document.querySelector('input[name="s"]').value  → extract current state
3. eval: fetch('/category.aspx', {method:'POST', body:'p=loadmore&pp=24&cid=2&s=25'})
         .then(r=>r.text()).then(h => count product links)
4. Repeat, incrementing 's' by page size until response returns 0 products
```
Stop condition is in the response, not in a URL counter. Extract the next state value from
each response rather than guessing the increment.

## Phase 10 — Browse plan

Before opening any browser, compile a prioritised list from all phase 2–9 findings:

```markdown
## Browse Plan

Priority 1 — Auth flow
- [ ] GET /login — capture POST target from form action
- [ ] POST /api/auth/login — test with dummy creds, observe response shape

Priority 2 — Authenticated API surface
- [ ] GET /dashboard — capture XHR from DevTools after login

Priority 3 — Admin / discovery pages
- [ ] GET {admin-subdomain-from-crt.sh}/api — explore admin API
```

The browse plan is the synthesis of everything gathered so far — it tells Phase 11
exactly where to go and what to capture.

## Phase 11 — Active browse

**Load `references/browser-recon.md` before executing this phase** — it contains
corrected tool signatures, auth setup logic, per-URL loop instructions, HAR reconstruction,
and OpenAPI generation commands.

Summary of sub-phases:
- **11a** — Detect Chrome MCP mode (`auto-connect` vs `new-instance`) or cmux; handle auth
- **11b** — Execute browse plan: JS globals + network capture per URL (up to 10)
- **11c** — Save raw captures to `.beacon/`; run `har-reconstruct.py` → `.beacon/capture.har`
- **11d** — Run `npx har-to-openapi`; merge with passive spec if Phase 8 found one

If neither Chrome DevTools MCP nor cmux is available: log `[PHASE-11-SKIPPED]`, proceed to Phase 12.

**Chrome MCP fail-fast rule:** If two consecutive Chrome MCP calls (to the recorded namespace)
both fail with timeout or connection errors, immediately declare `[CHROME-MCP-UNAVAILABLE]` and
switch to cmux. Do not spend more than 2 attempts diagnosing the Chrome debug port — that's
user-side configuration. If the plugin-namespaced Chrome MCP returns "browser already running"
on every call, the profile lock at `~/.cache/chrome-devtools-mcp/chrome-profile` needs clearing:
```bash
pkill -f chrome-devtools-mcp
rm -rf ~/.cache/chrome-devtools-mcp/chrome-profile
```
Then retry once before switching to cmux.

**Subagent dispatch rule for Phase 11:** Background subagents do not inherit Bash permissions
from the main session. If cmux is the browse tool, Phase 11 must run in the main session — not
dispatched as a background subagent. Use subagents only for Phases 1–9 (curl-based and passive);
keep Phases 10–11 in the main session where Bash works.

**Verification pass after subagent dispatch:** After subagents complete Phases 1–9 for multiple
sites, the main session should read the relevant tech packs and run a verification pass: compare
each pack's probe checklist against the subagent's session brief, then run outstanding probes
inline in the main session. This catches misses caused by subagent permission constraints.
Log: `[VERIFICATION-PASS:{site-slug}:{n} missing probes run]`

After Phase 11 completes, set `OPENAPI_STATUS` to the full Markdown table row for INDEX.md:
- Phase 11 ran + spec generated:
  `| [specs/{site-slug}.openapi.yaml](specs/{site-slug}.openapi.yaml) | OpenAPI spec (observed traffic) |`
- Phase 11 ran + har-to-openapi missing:
  `| .beacon/capture.har | Raw HAR (har-to-openapi unavailable) |`
- Phase 11 skipped: `""` (empty string — row omitted from INDEX.md)

## Graceful degradation signals

Log these in the session brief and repeat in the generated INDEX.md:

| Signal | Meaning |
|--------|---------|
| `[TOOL-UNAVAILABLE:wappalyzer]` | Used header/HTML grep instead |
| `[TOOL-UNAVAILABLE:firecrawl]` | Used curl fallbacks |
| `[TOOL-UNAVAILABLE:chrome-devtools-mcp]` | Phase 11 used cmux or was skipped |
| `[PHASE-11-SKIPPED]` | No browser tool available; static analysis only |
| `[TECH-PACK-UNAVAILABLE:name:ver]` | No pack found; used web search |
| `[TECH-PACK-VERSION-MISMATCH:name:found→used]` | Nearest major version used |
| `[GENERATED-INLINE:path]` | Script generated inline, not downloaded |
| `[CHROME-MODE:auto-connect]` | Chrome MCP connected to user's Chrome — sessions inherited |
| `[CHROME-MODE:new-instance]` | Chrome MCP launched fresh headless instance — no sessions |
| `[PHASE-11-AUTH:manual]` | User logged in manually; auth state saved to `.beacon/auth-state.json` |
| `[PHASE-11-UNAUTH]` | Phase 11 ran without authentication |
| `[OPENAPI-SKIPPED:har-to-openapi-unavailable]` | har-to-openapi not found; HAR preserved at `.beacon/capture.har` |
| `[CF-BLOCKED:curl]` | Cloudflare returned 403 on curl probes; pivoted to browser fetch |
| `[CF-PIVOT:browser-fetch]` | All HTTP probes run via browser `fetch()` from page context |
| `[CF-TURNSTILE-BLOCKED:{url}]` | Cloudflare Turnstile challenge blocked CDP interaction; used cmux existing session |
| `[CORS-OPAQUE:{path}]` | Probe returned opaque redirect — route exists but CORS-blocked |
| `[CHROME-NAMESPACE:{active}]` | Active Chrome MCP namespace recorded in Phase 1 |
| `[TECH-PACK-LATE-LOAD:{framework}:{version}:phase={N}]` | Tech pack loaded after late framework discovery |
| `[PHASE-GATE:P{N} missing — running now]` | Phase completion gate triggered a missed phase |
| `[TOOL-UNAVAILABLE:gau:aliased]` | `gau` is aliased to another command; URL extractor unavailable |
| `[AVAILABLE:jina-reader]` | Jina Reader reachable; used as curl fallback |
| `[CF-PIVOT:firecrawl]` | Cloudflare blocked curl; Firecrawl used instead |
| `[CF-PIVOT:spider]` | WAF blocked curl; Spider used (fingerprint rotation) |
| `[CF-PIVOT:scrapfly]` | DataDome/PerimeterX blocked; Scrapfly asp=true used |
| `[CF-PIVOT:jina]` | WAF blocked curl; Jina Reader used instead |
| `[CF-BLOCKED:all]` | All probe methods (curl, Firecrawl, Spider, Scrapfly, Jina) blocked |
| `[PHASE-7-CURL-BLOCKED:retrying-via-browser]` | JS bundle fetch returned 404; retrying via browser eval |
| `[CHROME-MCP-UNAVAILABLE]` | 2 consecutive Chrome MCP failures; switched to cmux |
| `[CHROME-MCP-PROFILE-LOCK]` | Plugin Chrome MCP stuck; profile lock cleared |
| `[VERIFICATION-PASS:{slug}:{n} missing probes run]` | Post-subagent tech pack verification completed |
| `[TECH-PACK-SUPPLEMENTAL-PROBE:{n} items from checklist not yet run]` | Pack loaded; checklist comparison found outstanding probes |
| `[TECH-PACK-RELOAD:{framework}]` | Tech pack updated externally; re-run Phase 5 probes |
| `[CF-BYPASS:brand-subpage]` | Category page blocked; brand/manufacturer sub-page used as alternate |
| `[PRODUCT-SITEMAP-SEED:{count} URLs]` | Product sitemap used as enumeration fallback |

## Phase 11 — cmux usage guide

When cmux is available (logged `[AVAILABLE:cmux]` in Phase 1), use these exact commands:

```bash
# Open a URL and get surface ID
cmux browser open https://example.com          # returns surface UUID like "surface:83"

# Navigate an existing surface
cmux browser --surface surface:83 goto https://example.com/products

# Get current URL
cmux browser --surface surface:83 get url

# Evaluate JavaScript (returns JSON or string)
cmux browser --surface surface:83 eval "JSON.stringify(window.location.href)"

# Get HTML of a specific element (selector is REQUIRED)
cmux browser --surface surface:83 get html "body"

# Take screenshot
cmux browser --surface surface:83 screenshot --out /tmp/page.png
```

Surface IDs: `cmux browser open` returns a UUID. Use `cmux browser --surface {id}` for all subsequent calls on that surface. Surface IDs look like `surface:83` or a UUID string — always quote them.

## Phase 12 — Output synthesis

**Phase completion gate — verify before writing:**

Before executing Phase 12, check the session brief for completion markers:
```
[P1✓] Scaffold and tool check
[P2✓] Passive recon
[P3✓] Fingerprint
[P4✓] Tech pack (or UNAVAILABLE logged)
[P5✓] Known patterns
[P6✓] Feeds & structure
[P7✓] JS & source maps
[P8✓] OpenAPI detect
[P9✓] OSINT
[P10✓] Browse plan compiled
[P11✓] Active browse (or SKIPPED logged)
```

If any phase marker is absent from the session brief, run that phase now before writing output.
Log: `[PHASE-GATE: P{N} missing — running now]`. Do not skip phases to save time.

**Load `references/output-synthesis.md` before executing this phase** — it contains
the full instructions for reading the session brief and writing all output files.

Summary:
- Read the completed session brief once
- Write `tech-stack.md`, `site-map.md`, `constants.md`, `scripts/test-{slug}.sh`
- Write one `api-surfaces/{surface}.md` per discovered API surface (see output-synthesis.md)
- Write `specs/{slug}.openapi.yaml` if Phase 8 or Phase 11 produced a spec
- Resolve all tokens in `templates/INDEX.md.template` → write `INDEX.md`
- Resolve `{{OPENAPI_STATUS}}` based on Phase 11 signals in the session brief

## Reference files

Load these when you need detailed guidance — they are not always necessary:

- **`references/phase-detail.md`** — Every probe URL, bash command, grep pattern, and CDX API parameter for phases 2, 5, 6, 7, and 9
- **`references/osint-sources.md`** — Phase 9 data sources: CDX APIs, crt.sh, GitHub search, Google dorking, robots.txt/sitemap mining, JSON-LD extraction
- **`references/session-brief-format.md`** — Complete session brief schema with all fields
- **`references/tool-availability.md`** — Tool detection commands, full fallback matrix, browser command reference
