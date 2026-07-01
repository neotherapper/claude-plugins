---
name: site-recon
description: This skill should be used when the user asks to "analyse a site", "research https://...", "map the API surface of", "find endpoints for", "what APIs does X have", "document how to extract data from", or runs /beacon:analyze. Use it even when the user just pastes a URL and says "check this out" or "look into this". Runs a 16-phase systematic investigation of a website and produces a complete persistent docs/sites/{site-slug}/research/ folder.
version: 0.7.0
---

# site-recon — Research Mode

Systematically analyse a target website across 16 ordered phases. Each phase writes
findings to an in-memory **session brief** (a running markdown document in context).
Phase 12 flushes everything to disk as structured research files.

## Output structure

```
docs/sites/{site-slug}/research/
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
The canonical slug rule (including lowercase + `:port` strip) is documented in `docs/SLUG_RULES.md` — use that as the single source of truth for cross-module interop with reframe and other plugins. The examples above remain valid under the canonical rule.

## The 16 phases — always in this order

| # | Phase | What happens |
|---|-------|-------------|
| 1 | Scaffold | Create output folder; check tool availability |
| 1.5 | Multi-source Domain Discovery | Discover related domains from local databases, config files, and cached data |
| 2 | Passive recon | robots.txt, sitemaps, .well-known, HTTP headers, crt.sh subdomains |
| 2.5 | Data Source Inventory | Inventory local databases, migration files, seed scripts, and previous scan results |
| 3 | Fingerprint | Detect framework + version (Wappalyzer → headers → HTML → JS) |
| 4 | Tech pack | Load framework guide from GitHub, context7, or web search |
| 5 | Known patterns | Apply every item in the tech pack's probe checklist |
| 6 | Feeds & structure | RSS/Atom, JSON-LD, GraphQL introspection, API version enumeration |
| 6b | Security Exposure Scan | Check for exposed secrets, config files, payment data, and PII |
| 7 | JS & source maps | Download bundles, grep for endpoints and auth patterns, check .map files |
| 8 | OpenAPI detect | Probe 15 standard paths; download spec if found |
| 8.5 | PII & Payment Data Classification | Classify severity of exposed data (CRITICAL/HIGH/MEDIUM/LOW) |
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
# Canonical slug rule (docs/SLUG_RULES.md) — must match reframe for cross-module interop
SLUG=$(printf '%s' "{url}" | tr 'A-Z' 'a-z' | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g')
mkdir -p docs/sites/${SLUG}/research/{api-surfaces,specs,scripts}
# If a legacy research folder exists for this slug, point the user at the new path.
if [ -d "docs/research/${SLUG}" ]; then
  echo "[LEGACY-WORKSPACE] Found docs/research/${SLUG}/ (pre-0.7.0). New output goes to docs/sites/${SLUG}/research/. Move the old folder to consolidate; legacy is read-only and removed in 0.8.0."
fi
```

**Critical:** Do NOT use `touch` to create output files — the Write tool requires a prior Read.
Use `Write` directly with empty string content for each output file, or they will fail at Phase 12.

```
Write docs/sites/${SLUG}/research/INDEX.md        ← empty string
Write docs/sites/${SLUG}/research/tech-stack.md   ← empty string
Write docs/sites/${SLUG}/research/site-map.md     ← empty string
Write docs/sites/${SLUG}/research/constants.md    ← empty string
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

---

## Phase 1.5 — Multi-source Domain Discovery

**New: Multi-source Domain Discovery**
After creating the output folder, run **Phase 1.5** to discover related domains:
**Load `references/phase-detail.md` (Phase 1.5 commands) before executing this phase.**

Log results in the session brief:
```markdown
### Discovered Domains
| Domain | Source | Notes |
|--------|--------|-------|
| example.com | local database | Active store |
```

**Input**: Base domain or project name.
**Actions**:
1. **Check local SQLite/SQL databases**:
   - glob: `**/*.db`, `**/*.sqlite`
   - Query columns: `url`, `domain`, `shopify_domain`
2. **Check scraper config files**:
   - glob: `**/stores/*.config.mjs`, `**/scrapers/*.config.*`
   - Extract `domain:` field from each
3. **Check cached/enriched data**:
   - glob: `**/*.json`, `**/*.jsonl`, `**/*.ndjson`
   - Search for `domain` or `url` fields
4. **Cross-reference and deduplicate domains**

**Output**: Consolidated domain list saved to `docs/sites/{SLUG}/research/discovered_domains.txt`.

---

## Phase 2 — Passive recon

See `references/phase-detail.md` for detailed probe commands, grep patterns, and API parameters.

**New: Data Source Inventory**
After passive recon, run **Phase 2.5** to inventory local data sources:
**Load `references/phase-detail.md` (Phase 2.5 commands) before executing this phase.**

Log results in the session brief:
```markdown
### Data Sources
| Type | Source Path | Record Count |
|------|-------------|--------------|
| Database | data/stores.db | 9621 |
```

---

## Phase 2.5 — Data Source Inventory

**Input**: Project directory.
**Actions**:
1. **Database schema files**:
   - glob: `**/schema.prisma`, `**/*.drizzle.ts`, `**/*.typeorm.ts`
   - Extract table structures
2. **Migration files**:
   - glob: `**/migrations/*.sql`, `**/*.migration.ts`
   - Extract `CREATE TABLE`/`ALTER TABLE` statements
3. **Seed scripts**:
   - glob: `**/seed*.ts`, `**/seed*.js`
   - Extract `insert`/`create` patterns
4. **Previous scan results**:
   - glob: new `docs/sites/*/research/INDEX.md` (scoped — excludes `redesign/`) and legacy `docs/research/*/INDEX.md`
   - Extract framework/auth/endpoint data

**Output**: Inventory of local data sources in the session brief.

---

## Phase 3 — Fingerprinting (first match wins)

1. **Wappalyzer MCP** (if available): `lookup_site(url)` → framework + version

2. **HTTP headers**: `curl -sI {url}` → grep for:

**Load `references/fingerprints.md` for the full signal tables before fingerprinting.**

4. **JS globals / cookies**: inspect inline scripts and `Set-Cookie` headers:

**See `references/fingerprints.md` for the JS globals & cookies table.**

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

1. **Bundled pack** (primary — offline, always matches the running version):
   ```
   ${CLAUDE_PLUGIN_ROOT}/technologies/{framework}/{major}.x.md
   ```
   If that exact file is absent, list `${CLAUDE_PLUGIN_ROOT}/technologies/{framework}/` and load the best match — a `{N}.x.md` for the nearest major, else `current.md`, `tech-pack.md`, or a dated `{YYYY-MM}.md`. Consult `${CLAUDE_PLUGIN_ROOT}/technologies/REGISTRY.md` to confirm the framework slug and which packs exist. This copy ships with the plugin, so it needs no network and can never 404.

2. **GitHub** (fallback — newer packs published after this install, or no bundled copy) — version-pinned raw URL:
   ```
   https://raw.githubusercontent.com/neotherapper/claude-plugins/v{PLUGIN_VERSION}/plugins/beacon/technologies/{framework}/{major}.x.md
   ```
   Read `{PLUGIN_VERSION}` from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` — never use the `main` branch. (The bundled pack above is the version-matched source; this network path only adds packs published after the install.)

3. **context7 MCP** (if available) — ask for framework's official API documentation

4. **Web search fallback** — search `{framework} {major}.x API routes endpoints file structure`

5. **No pack, no internet** — log `[TECH-PACK-UNAVAILABLE:{framework}:{version}]`, continue with generic probes

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

---

## Phase 6b — Security Exposure Scan

**Input**: Target URL, all discovered paths from Phases 2–6.

**Actions**:
1. **Check for exposed config files**:
   ```bash
   for path in .env .env.local .env.production config.php wp-config.php \
               config.yml config.json config.yaml database.yml \
               settings.py settings.json appsettings.json \
               .git/config .git/HEAD .svn/entries .hgignore \
               Dockerfile docker-compose.yml kubernetes.yaml \
               backup.sql dump.sql db.sql export.sql \
               debug.log error.log access.log install.log; do
     status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${url}/${path}")
     if [ "$status" != "404" ] && [ "$status" != "000" ]; then
       size=$(curl -s --max-time 5 "${url}/${path}" | wc -c)
       echo "${path} → HTTP ${status} (${size} bytes)"
     fi
   done
   ```

2. **Check for exposed payment data**:
   ```bash
   for path in orders.json transactions.csv payments.log \
               stripe_config.js paypal_config.js billing.sql \
               receipts/ invoices/ orders/ payments/; do
     status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${url}/${path}")
     if [ "$status" != "404" ] && [ "$status" != "000" ]; then
       size=$(curl -s --max-time 5 "${url}/${path}" | wc -c)
       echo "${path} → HTTP ${status} (${size} bytes)"
     fi
   done
   ```

3. **Check for PII exposure**:
   ```bash
   for path in customers.json users.csv employees.sql \
               personnel/ staff/ users/ members/ clients/; do
     status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${url}/${path}")
     if [ "$status" != "404" ] && [ "$status" != "000" ]; then
       echo "${path} → HTTP ${status}"
     fi
   done
   ```

4. **Check for exposed admin/API docs**:
   ```bash
   for path in phpinfo.php info.php test.php admin/phpinfo.php \
               swagger/ api/docs/ graphql/playground graphiql \
               _debug/ debug/ dev/ api/debug/; do
     status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${url}/${path}")
     if [ "$status" != "404" ] && [ "$status" != "000" ]; then
       echo "${path} → HTTP ${status}"
     fi
   done
   ```

**False positive handling**: Cloudflare challenge pages can be misidentified as config file content.
If an exposed file check returns content containing "cf-browser-verification" or "Just a moment...",
log `[PHASE-6B-FALSE-POSITIVE:{path}]` and mark as `MITIGATED`.

**Output**: Append findings to the session brief with severity assessment. High-severity findings
should be reported to the user immediately rather than waiting for Phase 12 output.

---

## Phase 8 — OpenAPI auto-detection

Probe these paths in order; stop at the first 200 response that returns JSON or YAML:

```
/openapi.json    /openapi.yaml    /swagger.json    /swagger.yaml
/api/openapi.json   /api/swagger.json   /api/docs   /api/docs.json
/docs/openapi.json  /v1/api-docs  /api-docs  /api-docs.json  /spec.json  /redoc
```

If found: save to `specs/{slug}.openapi.yaml`, mark `source: auto-downloaded`.  
If not found: continue — Phase 12 will scaffold a spec from all discovered endpoints.

---

## Phase 8.5 — PII and Payment Data Classification

**Input**: All discovered endpoints, `constants.md` values, JS bundle leaks, exposed files (Phase 6b).

**Actions**:
1. **Flag Payment Endpoints**:
   - Paths containing `/payment`, `/checkout`, `/order`, `/cart`, `/transaction`.
   - Endpoints returning `payment_method`, `transaction_id`, `cardBin`, `lastFour`, `expiryDate`.

2. **Grep for Payment Integrations**:
   - JS bundles: `stripe|paypal|braintree|adyen|authorize\.net`.
   - Config files: `STRIPE_KEY|PAYPAL_CLIENT_ID`.

3. **Classify Leaks**:
```bash
# CRITICAL (PCI DSS violation)
grep -E "\b(4[0-9]{12}|5[1-5][0-9]{14}|6(?:011|5[0-9]{2})[0-9]{12})\b" exposed_files/*
grep -E "cardBin.*lastFour.*expiry" js_bundles/*

# PII
grep -E "[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}" exposed_files/*
grep -E "\bname.*address.*phone\b" exposed_files/*

# Secrets
grep -E "API_KEY|SECRET|PASSWORD|DB_PASSWORD" exposed_files/*
```

4. **Severity Matrix**:
| Severity   | Criteria                                                                 | Action Required                     |
|------------|-------------------------------------------------------------------------|--------------------------------------|
| CRITICAL   | Card BIN + last4 + expiry, CVC/CVV                                       | Immediate disclosure                 |
| HIGH       | Database credentials, 100+ MB logs, live payment processor keys, HMAC webhook signatures | Review within 24 hours                |
| MEDIUM     | Server paths, plugin versions, email lists                              | Review within 7 days                  |
| LOW        | Trivial errors, no PII                                                  | Note in findings                     |
| MITIGATED  | File exists but returns 301/302/403/404, or empty                       | None                                 |

**Output**: Append to `INDEX.md`:

```markdown
## Security Exposure

| Path                     | Severity   | PII Found | Payment Data | Evidence                                  |
|--------------------------|------------|-----------|--------------|--------------------------------------------|
| /wp-content/debug.log    | CRITICAL   | 125 emails| Yes          | Stripe keys + card BINs in log             |
| /api/checkout/process    | HIGH       | No        | Yes          | LastFour + expiry in response              |
| /.env                    | HIGH       | No        | No           | DB_PASSWORD=example                        |
```

**PCI DSS Awareness**:
- **CRITICAL**: Card BIN + last4 + expiry = **PCI DSS violation** (immediate breach reporting required).
- **CRITICAL**: CVC/CVV match results = **PCI DSS violation** (stored in logs).
- **HIGH**: HMAC webhook signatures = **replay attacks** (API abuse risk).

---

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
- **11c** — Save raw captures to `.beacon/`; run `${CLAUDE_PLUGIN_ROOT}/scripts/core/har-reconstruct.py` → `.beacon/capture.har`
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
| `[PHASE-6B-FALSE-POSITIVE:{path}]` | Cloudflare challenge page misidentified as `.env`/`.git/config` |
| `[PHASE-7-CURL-BLOCKED:retrying-via-browser]` | JS bundle fetch returned 404; retrying via browser eval |
| `[CHROME-MCP-UNAVAILABLE]` | 2 consecutive Chrome MCP failures; switched to cmux |
| `[CHROME-MCP-PROFILE-LOCK]` | Plugin Chrome MCP stuck; profile lock cleared |
| `[VERIFICATION-PASS:{slug}:{n} missing probes run]` | Post-subagent tech pack verification completed |
| `[TECH-PACK-SUPPLEMENTAL-PROBE:{n} items from checklist not yet run]` | Pack loaded; checklist comparison found outstanding probes |
| `[TECH-PACK-RELOAD:{framework}]` | Tech pack updated externally; re-run Phase 5 probes |
| `[CF-BYPASS:brand-subpage]` | Category page blocked; brand/manufacturer sub-page used as alternate |
| `[PRODUCT-SITEMAP-SEED:{count} URLs]` | Product sitemap used as enumeration fallback |
| `[PHASE-6B-FALSE-POSITIVE:{path}]` | Cloudflare challenge page misidentified as `.env`/`.git/config` |
| `[PCI-DSS-VIOLATION:CRITICAL]` | Card BIN + last4 + expiry or CVC/CVV found; immediate disclosure required |

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

---

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
[P6b✓] Security Exposure Scan
[P7✓] JS & source maps
[P8✓] OpenAPI detect
[P8.5✓] PII & Payment Data Classification
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
- Resolve all tokens in `${CLAUDE_PLUGIN_ROOT}/templates/INDEX.md.template` → write `INDEX.md`
- Resolve `{{OPENAPI_STATUS}}` based on Phase 11 signals in the session brief

## Reference files

Load these when you need detailed guidance — they are not always necessary:

- **`references/phase-detail.md`** — Every probe URL, bash command, grep pattern, and CDX API parameter for phases 1.5, 2, 2.5, 5, 6, 7, and 9
- **`references/osint-sources.md`** — Phase 9 data sources: CDX APIs, crt.sh, DNSDumpster, VirusTotal, urlscan.io, ASN, Censys, GitHub search, Google dorking, robots.txt/sitemap mining, JSON-LD extraction, S3 buckets, Paste sites, NPM/PyPI, bug bounty scopes
- **`references/session-brief-format.md`** — Complete session brief schema with all fields
- **`references/tool-availability.md`** — Tool detection commands, full fallback matrix, browser command reference
- **`references/fingerprints.md`** — Phase 3 signal tables: HTTP header/path patterns and JS globals/cookies signals
- **`scripts/README.md`** — inventory of the 12 bundled helper scripts (currently reference-only, not invoked by the phase flow)
