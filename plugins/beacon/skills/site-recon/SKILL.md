---
name: site-recon
description: This skill should be used when the user asks to "analyse a site", "research https://...", "map the API surface of", "find endpoints for", "what APIs does X have", "document how to extract data from", or runs /beacon:analyze. Use it even when the user just pastes a URL and says "check this out" or "look into this". Runs a 12-phase systematic investigation of a website and produces a complete persistent docs/research/{site-name}/ folder.
version: 0.5.0
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
SLUG=$(echo "{url}" | sed -E 's|https?://||;s|/.*||;s|\.|-|g')
mkdir -p docs/research/${SLUG}/{api-surfaces,specs,scripts}
touch docs/research/${SLUG}/{INDEX,tech-stack,site-map,constants}.md
```

Then check every tool in the tool availability matrix and log results in the session brief.
See `references/tool-availability.md` for exact detection commands.

## Phase 3 — Fingerprinting (first match wins)

1. **Wappalyzer MCP** (if available): `lookup_site(url)` → framework + version

2. **HTTP headers**: `curl -sI {url}` → grep for:
   - `Ghost-Version` → Ghost
   - `x-nuxt` → Nuxt
   - `X-Inertia` → Laravel/Inertia
   - `x-shopify-stage: production` → Shopify (Definitive)
   - `X-Powered-By: Strapi` or `X-Strapi-Version` → Strapi (Definitive)
   - `server: uvicorn` → FastAPI (combined signal)
   - `X-Runtime` → Rails (combined signal)

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

4. **JS globals / cookies**: inspect inline scripts and `Set-Cookie` headers:
   - `__NEXT_DATA__` → Next.js
   - `window.__nuxt` → Nuxt
   - `_shopify_y` or `_shopify_s` cookies → Shopify
   - `_[a-z0-9_]+_session` cookie pattern → Rails

5. **Endpoint probes** (for API-only and CMS sites):
   ```bash
   # Strapi — check /admin/init for hasAdmin field (Definitive)
   curl -s {url}/admin/init | python3 -c "import sys,json; d=json.load(sys.stdin); print('strapi' if 'hasAdmin' in d.get('data',{}) else '')"
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

## Phase 8 — OpenAPI auto-detection

Probe these paths in order; stop at the first 200 response that returns JSON or YAML:

```
/openapi.json    /openapi.yaml    /swagger.json    /swagger.yaml
/api/openapi.json   /api/swagger.json   /api/docs   /api/docs.json
/docs/openapi.json  /v1/api-docs  /api-docs  /api-docs.json  /spec.json  /redoc
```

If found: save to `specs/{slug}.openapi.yaml`, mark `source: auto-downloaded`.  
If not found: continue — Phase 12 will scaffold a spec from all discovered endpoints.

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

## Phase 12 — Output synthesis

**Load `references/output-synthesis.md` before executing this phase** — it contains
the full instructions for reading the session brief and writing all output files.

Summary:
- Read the completed session brief once
- Write `tech-stack.md`, `site-map.md`, `constants.md`, `scripts/test-{slug}.sh`
- Resolve all tokens in `templates/INDEX.md.template` → write `INDEX.md`
- Resolve `{{OPENAPI_STATUS}}` based on Phase 11 signals in the session brief

## Reference files

Load these when you need detailed guidance — they are not always necessary:

- **`references/phase-detail.md`** — Every probe URL, bash command, grep pattern, and CDX API parameter for phases 2, 5, 6, 7, and 9
- **`references/session-brief-format.md`** — Complete session brief schema with all fields
- **`references/tool-availability.md`** — Tool detection commands, full fallback matrix, browser command reference
