# Beacon E-Commerce Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship 15 fixes to the beacon site-recon skill derived from real session failures on Pen-Chalet and JetPens, plus two new e-commerce tech packs (WooCommerce, Magento 2), one new ASP.NET tech pack, updated reference files, and a full skill-creator eval loop that validates the improvements and optimizes the skill's triggering description.

**Architecture:** Changes split across three layers: (1) tech packs — static markdown knowledge files per framework, (2) the site-recon SKILL.md — the agent's runtime instruction set, and (3) reference files — deep detail loaded on demand. The skill-creator eval loop runs as a separate phase after all content changes land, using parallel subagents to compare old vs. new skill behaviour on four representative test sites.

**Tech Stack:** Markdown, bash, Python 3 (skill-creator scripts), Claude API via `claude -p` CLI (skill-creator run_loop.py)

**Branch:** `feat/beacon-ecommerce-improvements`

**Session analysis source:** `docs/research/beacon-session-analysis/session-analysis.md`

---

## File Map

### Already done (commit in Task 0)
| File | Change |
|------|--------|
| `plugins/beacon/technologies/woocommerce/9.x.md` | Created — WooCommerce 9.x tech pack |
| `plugins/beacon/technologies/magento/2.x.md` | Created — Magento 2.x tech pack |
| `plugins/beacon/skills/site-recon/SKILL.md` | Updated — 11 fixes, version 0.5.0 → 0.6.0 |
| `plugins/beacon/hooks/session-start.sh` | Updated — WooCommerce + Magento in tech pack list |
| `plugins/beacon/CHANGELOG.md` | Added [0.6.2] entry |
| `docs/research/beacon-session-analysis/session-analysis.md` | Created — retrospective |

### Tasks 1–3 (content work)
| File | Change |
|------|--------|
| `plugins/beacon/technologies/aspnet/webforms-mvc.md` | Create — ASP.NET WebForms & MVC tech pack |
| `plugins/beacon/skills/site-recon/references/tool-availability.md` | Update — gau alias check, Chrome MCP dual namespace |
| `plugins/beacon/skills/site-recon/references/browser-recon.md` | Update — Cloudflare bypass section, Turnstile limitation |

### Tasks 4–8 (skill-creator eval loop)
| File | Change |
|------|--------|
| `plugins/beacon/skills/site-recon-workspace/evals/evals.json` | Create — 4 eval test prompts |
| `plugins/beacon/skills/site-recon-workspace/iteration-1/` | Create — eval run outputs |
| `plugins/beacon/skills/site-recon-workspace/old-skill-snapshot/SKILL.md` | Snapshot from git before changes |

---

## Task 0: Commit all work done in previous session

**Files:**
- Modify (stage): all files listed in "Already done" above

- [ ] **Step 1: Verify the diff is clean**

```bash
git diff --stat
git status
```

Expected: see `plugins/beacon/technologies/woocommerce/9.x.md`, `magento/2.x.md`, `SKILL.md`, `session-start.sh`, `CHANGELOG.md`, and the session analysis file. No other files.

- [ ] **Step 2: Stage beacon files only**

```bash
git add plugins/beacon/technologies/woocommerce/9.x.md
git add plugins/beacon/technologies/magento/2.x.md
git add plugins/beacon/skills/site-recon/SKILL.md
git add plugins/beacon/hooks/session-start.sh
git add plugins/beacon/CHANGELOG.md
git add docs/research/beacon-session-analysis/session-analysis.md
```

- [ ] **Step 3: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat(beacon): add WooCommerce + Magento 2 tech packs, apply 11 site-recon fixes

- technologies/woocommerce/9.x.md: 227-line pack covering Store API v1, REST v3,
  Consumer Key auth, wc-ajax endpoints, JS globals fingerprinting, 10 gotchas
- technologies/magento/2.x.md: 216-line pack covering REST V1, GraphQL, X-Magento-*
  header fingerprinting, RequireJS bundles, multi-store scoping, 11 gotchas
- SKILL.md v0.6.0: fix Write-before-Read scaffold bug, www. slug stripping, Chrome MCP
  namespace detection, gau alias check, Phase 4 late discovery rule, Phase 12 completion
  gate, Cloudflare bypass section, e-commerce probe list, cmux usage guide
- session-start hook: advertises WooCommerce and Magento 2 in tech pack list
- docs/research/beacon-session-analysis: 353-line retrospective on Pen-Chalet/JetPens

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Verify commit succeeded**

```bash
git log --oneline -3
```

Expected: first line shows the feat(beacon) commit.

---

## Task 1: Create ASP.NET WebForms & MVC tech pack

Priority 1 from session analysis — `[TECH-PACK-UNAVAILABLE:aspnet]` caused Phase 4/5 to be entirely skipped on penchalet.com (an ASP.NET WebForms site).

**Files:**
- Create: `plugins/beacon/technologies/aspnet/webforms-mvc.md`

- [ ] **Step 1: Create directory and write the file**

Create `plugins/beacon/technologies/aspnet/webforms-mvc.md` with this exact content:

```markdown
---
framework: aspnet
version: "webforms-mvc"
last_updated: "2026-04-27"
author: "@neotherapper"
status: official
---

# ASP.NET WebForms & MVC — Tech Pack

Covers both ASP.NET WebForms (`.aspx` pages, ViewState) and ASP.NET MVC (`/Controller/Action`
routes). These are server-rendered .NET frameworks typically running on IIS. Neither exposes
a REST API by default — all data access is through page requests and AJAX handlers.

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `__VIEWSTATE` hidden input | HTML field | `<input type="hidden" name="__VIEWSTATE"` | Definitive (WebForms) |
| `__EVENTVALIDATION` hidden input | HTML field | `<input type="hidden" name="__EVENTVALIDATION"` | Definitive (WebForms) |
| `.aspx` in URL paths | URL pattern | `*.aspx` | High |
| `ASP.NET_SessionId` cookie | Cookie | exact name | Definitive |
| `X-Powered-By: ASP.NET` response header | HTTP header | starts with `ASP.NET` | Definitive |
| `X-AspNet-Version` response header | HTTP header | version string e.g. `4.0.30319` | Definitive + version |
| `X-AspNetMvc-Version` response header | HTTP header | MVC version e.g. `5.2` | Definitive (MVC) |
| `web.config` returning 403 | HTTP status | IIS blocks `web.config` by default | High |
| `ScriptResource.axd` script tag | HTML `<script src>` | path contains `ScriptResource.axd` | Definitive (WebForms) |
| `WebResource.axd` in HTML | HTML source | path contains `WebResource.axd` | Definitive (WebForms) |
| Wappalyzer result | MCP | `"ASP.NET"` or `"IIS"` | Definitive |
| `__RequestVerificationToken` | HTML hidden field or cookie | Anti-forgery token (MVC) | High (MVC) |
| Error page `Server Error in '/' Application` | HTML body | Stack trace shows `System.Web` | Definitive |

**Version extraction:**
```bash
# From response headers
curl -sI {site} | grep -i "x-aspnet-version\|x-aspnetmvc-version\|x-powered-by"

# ASP.NET version from ScriptResource.axd query string
curl -s {site} | grep -oP 'ScriptResource\.axd\?d=[^&"]+' | head -3

# Try common version leak endpoints
curl -s {site}/trace.axd -o /dev/null -w "%{http_code}"   # 403 = IIS, 200 = leaking
curl -s {site}/elmah.axd -o /dev/null -w "%{http_code}"   # 200 = ELMAH error log exposed
```

## 2. Default API Surfaces

ASP.NET WebForms and MVC do not expose REST APIs by default. All endpoints are HTML pages
or AJAX handlers called from page JavaScript.

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/search.aspx?keyword={q}` | GET | None | Search results page (WebForms) |
| `/category.aspx?keyword={q}` | GET | None | Category page (WebForms) |
| `/autocomplete.aspx?keyword={q}` | GET | None | JSON autocomplete (common custom endpoint) |
| `/product.aspx?id={N}` | GET | None | Product detail page (WebForms) |
| `/cart.aspx` | GET/POST | Session | Shopping cart page |
| `/{Controller}/{Action}` | GET/POST | Varies | MVC route pattern |
| `/api/{controller}/{id}` | GET | Varies | ASP.NET Web API (if added) |
| `/__MVC_AJAX__` pattern | POST | Session | MVC AJAX actions |
| `/WebResource.axd` | GET | None | Embedded web resources |
| `/ScriptResource.axd` | GET | None | Script resources (CSS/JS bundles) |
| `/trace.axd` | GET | App config | Trace log — 403 if protected, leak if not |
| `/elmah.axd` | GET | App config | Error log — 403 if protected, leak if not |

**ASP.NET Web API** (if present — separate from MVC):
| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/api/products` | GET | Varies | REST API (if Web API installed) |
| `/api/products/{id}` | GET | Varies | Single product |
| `/Help` | GET | None | Web API help page (dev environments) |

## 3. Config / Constants Locations

| Location | What's there | How to access |
|----------|-------------|---------------|
| `web.config` | DB strings, app settings, handler map | IIS blocks: always 403; source only |
| `App_Data/` | Database files, XML config | IIS blocks: always 403 |
| `__VIEWSTATE` field | Encrypted form state (base64) | HTML scrape — not meaningful without key |
| `__RequestVerificationToken` | MVC anti-forgery token | HTML hidden field or cookie |
| `ASP.NET_SessionId` cookie | Session identifier | Cookie in response headers |
| Inline JS `var config = {…}` | Custom AJAX URLs, API keys | HTML source grep |
| Response headers | Framework version, server | `curl -sI {site}` |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| ASP.NET Forms Authentication | `ASPXAUTH` cookie | Set-Cookie on `/login.aspx` POST |
| Session cookie | `ASP.NET_SessionId` | Present for all visitors |
| Anti-forgery token (MVC) | `__RequestVerificationToken` hidden field + cookie | Required for all MVC POST actions |
| Windows Authentication | `WWW-Authenticate: Negotiate` | Intranet apps; not applicable for public sites |
| Basic Auth over IIS | `WWW-Authenticate: Basic` | Rare in production |

**Acquiring anti-forgery token (MVC POST):**
```bash
# 1. GET the page containing the form — extract token
TOKEN=$(curl -sc /tmp/cookies.txt -s {site}/checkout | grep -oP '__RequestVerificationToken" value="\K[^"]+')
# 2. POST with token in form body and Cookie header
curl -sb /tmp/cookies.txt -s -X POST {site}/checkout \
  -d "__RequestVerificationToken=${TOKEN}&field=value"
```

**Acquiring ViewState for WebForms POST:**
```bash
VS=$(curl -sc /tmp/cookies.txt -s {site}/cart.aspx | grep -oP '__VIEWSTATE" value="\K[^"]+')
EV=$(curl -sc /tmp/cookies.txt -s {site}/cart.aspx | grep -oP '__EVENTVALIDATION" value="\K[^"]+')
curl -sb /tmp/cookies.txt -s -X POST {site}/cart.aspx \
  -d "__VIEWSTATE=${VS}&__EVENTVALIDATION=${EV}&field=value"
```

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `/Scripts/jquery.min.js` | jQuery (common in WebForms/MVC projects) |
| `/Scripts/bootstrap.min.js` | Bootstrap JS |
| `/bundles/jquery` | MVC bundling route → actual JS |
| `/bundles/modernizr` | MVC bundling route |
| `/Content/site.css` | Main stylesheet |
| `/ScriptResource.axd?d={hash}` | Embedded WebForms script resource |
| Custom: `/Scripts/site.js` | Site-specific JS — grep for AJAX URLs |

Check `/Scripts/site.js`, `/Scripts/main.js`, `/js/app.js` for `$.ajax`, `$.getJSON`, `fetch(` calls — these are the custom API endpoints.

## 6. Source Map Patterns

ASP.NET WebForms and MVC projects do not emit source maps by default. Bundled JS via
`System.Web.Optimization` is minified but not source-mapped in production.

Custom webpack/vite builds layered on top may produce `.map` files. Check:
```bash
curl -s {site}/Scripts/site.min.js -o /dev/null -I | grep -i "sourcemappingurl"
curl -s {site}/Scripts/site.min.js.map -o /dev/null -w "%{http_code}"
```
A 200 on the `.map` file means source recovery is possible.

## 7. Common Modules & Extensions

| Module | API it adds | Detection signal |
|--------|------------|-----------------|
| ASP.NET Web API 2 | `/api/{controller}/{id}` REST | `ApiController` in stack traces; `/Help` page |
| SignalR | `/signalr/hubs` + WebSocket | `signalr.js` script loaded; hub endpoint responds |
| ELMAH (error logging) | `/elmah.axd` | Returns error log if not password-protected |
| Glimpse (profiler) | `/__glimpse__` | Dev environments only; 404 in production |
| DotNetNuke / DNN | `/desktopmodules/` paths | CMS built on ASP.NET WebForms |
| Umbraco | `/umbraco/` admin path | Umbraco CMS on ASP.NET |
| Telerik / Kendo UI | `/Telerik.Web.UI.WebResource.axd` | Telerik component library |
| Bundling (`System.Web.Optimization`) | `/bundles/{name}` | MVC bundling — GETable in production |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `/autocomplete.aspx?keyword={q}` | JSON product suggestions | Often returns `[{"id":N,"label":"..."}]` |
| `/sitemap.aspx` | XML sitemap | Alternative to `/sitemap.xml` |
| `/newsletter.aspx` | Newsletter subscribe form | POST target for email collection |
| `X-AspNet-Version` header | .NET runtime version | `curl -sI {site} \| grep X-Asp` |
| `X-Powered-By` header | Framework version | Same curl |
| `/Scripts/site.js` | All custom AJAX endpoint URLs | Grep for `$.ajax`, `url:`, `fetch(` |
| Page `<form action>` attribute | POST target URLs | Parse from HTML form elements |

## 9. Probe Checklist

Run these in order. Record result (✓ 200 / ✗ 403 / – 404) for each.

- [ ] `HEAD {site}` — capture `X-Powered-By`, `X-AspNet-Version`, `X-AspNetMvc-Version` headers
- [ ] `GET {site}` — grep for `__VIEWSTATE`, `.aspx`, `ScriptResource.axd`, `__RequestVerificationToken`
- [ ] `GET {site}/web.config` — expect 403 (IIS default block — confirms IIS/ASP.NET)
- [ ] `GET {site}/trace.axd` — 403 = protected, 200 = trace log exposed
- [ ] `GET {site}/elmah.axd` — 403 = protected, 200 = error log exposed (read all entries)
- [ ] `GET {site}/ScriptResource.axd` — expect 302 or 400 (confirms ASP.NET script handler)
- [ ] `GET {site}/WebResource.axd` — same as above
- [ ] `GET {site}/autocomplete.aspx?keyword=test` — JSON autocomplete (common custom endpoint)
- [ ] `GET {site}/search.aspx?keyword=test` — search results page
- [ ] `GET {site}/sitemap.aspx` — alternative sitemap location
- [ ] `GET {site}/Scripts/site.js` — main JS: grep for `$.ajax`, `fetch(`, `url:`
- [ ] `GET {site}/Scripts/main.js` — alternate JS file name
- [ ] `GET {site}/bundles/jquery` — confirms MVC bundling active
- [ ] `GET {site}/api/` — check for ASP.NET Web API root (404 = not present)
- [ ] `GET {site}/Help` — ASP.NET Web API help page (dev environments)
- [ ] Check page HTML for `<form action>` attributes — all POST targets

## 10. Gotchas

- **ViewState is not data.** The `__VIEWSTATE` field is base64-encoded, encrypted form state. It cannot be decoded without the server's `machineKey`. Don't try to parse it.
- **WebForms POST requires ViewState + EventValidation.** Any form POST without these fields returns a validation error. Always extract both from the GET response before posting.
- **IIS 403 on `.config` files is a feature, not a bug.** A 403 on `/web.config` is definitive IIS evidence — it means IIS is blocking it correctly. Do not interpret 403 as "this path doesn't exist."
- **Trace.axd and ELMAH are critical if accessible.** A 200 response means real data: trace.axd shows server-side execution traces, ELMAH shows all application errors with stack traces and request context. Always check both.
- **AJAX endpoints are never documented.** WebForms and MVC projects have no built-in API discovery. All custom AJAX URLs must be found in JS source (grep for `$.ajax`, `fetch(`, `$.getJSON`, `url:`) or by watching network traffic in the browser.
- **ASP.NET Web API is a separate layer.** Some ASP.NET apps add Web API controllers on top of WebForms/MVC. The presence of a `/api/` prefix route is the only indicator — check for it explicitly.
- **Cloudflare blocks all curl probes for this stack.** ASP.NET sites are often on shared hosting or Azure with Cloudflare in front. All `.aspx` probes should be run via browser fetch() from an already-loaded page if curl returns 403.
- **`__RequestVerificationToken` must match the session.** The anti-forgery token is tied to the `ASP.NET_SessionId` cookie. If you use a fresh curl session, you must GET the form page, save cookies, extract the token, then POST — all with the same cookie jar.
- **SignalR endpoints are WebSocket.** `/signalr/negotiate` returns JSON; the actual connection upgrades to WebSocket. Probe `/signalr/hubs` for the auto-generated hub proxy JS.
- **DNN/Umbraco/Telerik detection.** Many ASP.NET sites use CMS or component libraries that add their own endpoints. Check for `/desktopmodules/` (DNN), `/umbraco/` (Umbraco), and `Telerik.Web.UI.WebResource.axd` (Telerik) — each adds significant API surface.
```

- [ ] **Step 2: Add directory reference to session-start hook**

Edit `plugins/beacon/hooks/session-start.sh` line 17:

```
Tech packs available for: WordPress, WooCommerce, Magento 2, ASP.NET, Next.js, Nuxt, Django, Rails, Astro, Laravel, Shopify, Ghost, Zend Framework 1
```

- [ ] **Step 3: Add CHANGELOG entry**

Prepend to `plugins/beacon/CHANGELOG.md` after the `## [0.6.2]` block a new `## [0.6.3]` section:

```markdown
## [0.6.3] — 2026-04-27

### Added

- Tech pack: `technologies/aspnet/webforms-mvc.md` — ASP.NET WebForms & MVC
  - 10-section pack: `__VIEWSTATE`/`__EVENTVALIDATION` WebForms fingerprints, `.axd` endpoint
    probes, anti-forgery token acquisition, ViewState POST pattern, ELMAH/trace.axd exposure
    check, ASP.NET Web API detection, SignalR detection, 10 gotchas
  - Session-start hook updated to advertise ASP.NET in tech pack list
```

- [ ] **Step 4: Commit**

```bash
git add plugins/beacon/technologies/aspnet/webforms-mvc.md
git add plugins/beacon/hooks/session-start.sh
git add plugins/beacon/CHANGELOG.md
git commit -m "$(cat <<'EOF'
feat(beacon): add ASP.NET WebForms & MVC tech pack

Covers VIEWSTATE fingerprinting, .axd endpoint probes (trace.axd, elmah.axd),
anti-forgery token acquisition pattern, ViewState POST recipe, Web API detection,
SignalR detection, and 10 gotchas including Cloudflare/curl interaction.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Update tool-availability.md — gau alias and Chrome MCP namespace

The existing `references/tool-availability.md` has two incorrect entries that caused real failures in both sessions.

**Files:**
- Modify: `plugins/beacon/skills/site-recon/references/tool-availability.md`

- [ ] **Step 1: Replace the GAU detection block**

Find and replace the GAU section (lines 42–45 in the current file):

Old content:
```markdown
### GAU (GetAllURLs)
```bash
which gau && echo "gau available"
# Fallback: Wayback CDX API (no install, always works)
```
```

New content:
```markdown
### GAU (GetAllURLs)
```bash
# 'which gau' is NOT sufficient — gau may be aliased to 'git add --update'
# Confirm the binary is the URL extractor before marking available:
GAU_CHECK=$(gau --version 2>&1 || gau --help 2>&1 || true)
if echo "$GAU_CHECK" | grep -qi "getallurls\|gau.*version"; then
  echo "[AVAILABLE] gau"
else
  echo "[TOOL-UNAVAILABLE:gau:aliased-or-not-found]"
fi
# Fallback: Wayback CDX API (no install, always works — see phase-detail.md Phase 9)
```
```

- [ ] **Step 2: Replace the Chrome DevTools MCP detection block**

Find and replace the Chrome DevTools MCP section:

Old content:
```markdown
### Chrome DevTools MCP
```
Available if: 'mcp__chrome-devtools__new_page' in MCP tool list
Fallback: check for cmux; if neither, skip Phase 11
```
```

New content:
```markdown
### Chrome DevTools MCP

Two namespaces exist depending on how the MCP server is registered. Test BOTH in Phase 1
and record which one responds. Use ONLY the recorded namespace for all of Phase 11.

```
# Plugin-level (preferred — registered via plugin system):
Test: attempt mcp__plugin_chrome-devtools-mcp_chrome-devtools__list_pages
  → If it returns a list (even empty): log [CHROME-NAMESPACE:plugin]

# Project-level (fallback — registered in project .mcp.json):
Test: attempt mcp__chrome-devtools__list_pages
  → If it returns a list: log [CHROME-NAMESPACE:project]

# Neither responds:
  → Check cmux; if neither: log [TOOL-UNAVAILABLE:chrome-devtools-mcp]
```

**Important:** If list_pages returns a timeout or "Network.enable timed out", the Chrome
process may have a stale CDP connection. Ask the user to: restart Chrome, run
`pkill -f chrome-devtools-mcp`, then retry before giving up on Chrome MCP entirely.
```

- [ ] **Step 3: Commit**

```bash
git add plugins/beacon/skills/site-recon/references/tool-availability.md
git commit -m "$(cat <<'EOF'
fix(beacon): fix tool-availability gau alias detection and Chrome MCP namespace

- gau: 'which gau' replaced with output-checking validation to detect git alias
- chrome-devtools-mcp: document both plugin-level and project-level namespaces,
  add stale CDP connection recovery instructions

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Update browser-recon.md — Cloudflare and cmux corrections

Two active failure modes from both sessions: (1) no documented Cloudflare pivot strategy, (2) wrong cmux command signatures causing 3 failed attempts.

**Files:**
- Modify: `plugins/beacon/skills/site-recon/references/browser-recon.md`

- [ ] **Step 1: Add Cloudflare bypass section before Phase 11a**

Insert after the opening paragraph (before `## Phase 11a`):

```markdown
## Cloudflare and Bot Protection

When the target site is behind Cloudflare (detected by 403 on Phase 2 curl probes):

### Identification
A Cloudflare block is confirmed when:
- `GET /robots.txt` via curl returns HTTP 403 (not 401 — that is auth)
- Response body contains `cloudflare` or `cf-ray` header is present
- Log immediately: `[CF-BLOCKED:curl]`

### Pivot strategy
All Phase 2, 5, 6, 8 probes must be run via browser `fetch()` from inside a page
already loaded on the target domain (which holds a CF clearance cookie):

```javascript
// Run inside evaluate_script() from a page on the target domain
const result = await fetch('/robots.txt').then(async r => ({
  status: r.status,
  type: r.type,
  body: r.ok ? await r.text() : null
}));
JSON.stringify(result)
```

Log: `[CF-PIVOT:browser-fetch]`

**CORS-blocked probes:** Same-origin `fetch()` from page context works for all paths on the
same domain. Cross-origin requests (e.g., to crt.sh from within the target page) return
`{status: 0, type: "opaqueredirect"}` — this means the route exists but CORS blocks the body.
Log as `[CORS-OPAQUE:{path}]` and note the route exists.

### Cloudflare Turnstile
If a page triggers a Turnstile challenge (visible as a spinner/checkbox in the page), the CDP
`click()` on the verify checkbox will time out with: `The element did not become interactive
within the configured timeout`. This is a fundamental limitation — Turnstile is designed to
prevent CDP interaction.

**Resolution:** switch to a cmux surface that holds an existing CF clearance from a real browser
session. Do NOT retry the CDP click — it will always fail. Log: `[CF-TURNSTILE-BLOCKED:{url}]`

---
```

- [ ] **Step 2: Fix the cmux command syntax reference**

Find the cmux section and replace it with corrected signatures derived from actual session usage:

```markdown
## cmux Browser Commands (Phase 11) — CORRECTED SIGNATURES

The cmux commands in this file reflect v1.x syntax observed in production sessions.
`cmux browser wait --load-state complete` is NOT a valid command in this version.

```bash
# Open a new browser tab and get its surface ID
cmux browser open https://example.com
# Returns output like: "surface:83" or a UUID string

# All subsequent commands require --surface {id}
SURF="surface:83"   # replace with actual ID from open

# Navigate to URL
cmux browser --surface $SURF goto https://example.com/products

# Get current URL (useful to confirm navigation succeeded)
cmux browser --surface $SURF get url

# Evaluate JavaScript — ALWAYS wrap return value in JSON.stringify
cmux browser --surface $SURF eval "JSON.stringify(window.__NEXT_DATA__)"
cmux browser --surface $SURF eval "JSON.stringify(Object.keys(window).filter(k=>k.startsWith('wc')))"

# Get HTML of element — CSS selector is REQUIRED (bare 'get html' fails)
cmux browser --surface $SURF get html "body"
cmux browser --surface $SURF get html "#product-list"

# Take screenshot
cmux browser --surface $SURF screenshot --out docs/research/example-com/screenshot.png

# List network requests captured since page load
cmux browser --surface $SURF list network

# Common failure modes:
#   'Error: Unsupported browser subcommand: --load-state'  → remove --load-state
#   'Error: browser requires a subcommand'                 → add a subcommand
#   'Error: Invalid surface handle: get'                   → add --surface flag
#   '(eval):1: bad math expression: illegal character: \'  → JSON.stringify the return value
```

**Backslash escaping in eval:** When the JS string contains backslashes or single quotes,
pass it as a heredoc or use double-outer/single-inner quoting:
```bash
cmux browser --surface $SURF eval "JSON.stringify(fetch('/api/products').then(r=>r.json()))"
# Not safe with single quotes inside — use JSON.stringify to wrap
```
```

- [ ] **Step 3: Commit**

```bash
git add plugins/beacon/skills/site-recon/references/browser-recon.md
git commit -m "$(cat <<'EOF'
fix(beacon): add Cloudflare bypass strategy and fix cmux command signatures

- browser-recon.md: new Cloudflare/bot protection section before Phase 11a covering
  cf-ray detection, same-origin browser fetch() pivot, Turnstile limitation
- cmux commands: corrected signatures from real session failures (--load-state removed,
  --surface flag added, get html selector requirement documented, eval escaping guide)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Set up skill-creator eval workspace

Before running evals, snapshot the old skill (so the baseline subagent uses pre-fix instructions)
and write the test cases.

**Files:**
- Create: `plugins/beacon/skills/site-recon-workspace/evals/evals.json`
- Create: `plugins/beacon/skills/site-recon-workspace/old-skill-snapshot/SKILL.md`

- [ ] **Step 1: Snapshot the old skill from git**

```bash
mkdir -p plugins/beacon/skills/site-recon-workspace/old-skill-snapshot
git show main:plugins/beacon/skills/site-recon/SKILL.md \
  > plugins/beacon/skills/site-recon-workspace/old-skill-snapshot/SKILL.md
```

Verify the snapshot contains `version: 0.5.0` (the pre-fix version):
```bash
head -5 plugins/beacon/skills/site-recon-workspace/old-skill-snapshot/SKILL.md
```
Expected: `version: 0.5.0`

- [ ] **Step 2: Create evals.json**

Create `plugins/beacon/skills/site-recon-workspace/evals/evals.json`:

```json
{
  "skill_name": "site-recon",
  "skill_path": "plugins/beacon/skills/site-recon/SKILL.md",
  "evals": [
    {
      "id": 1,
      "eval_name": "scaffold-no-touch",
      "prompt": "Analyse https://httpbin.org and produce a docs/research/ folder documenting its API surface. Run all 12 phases. Focus especially on the scaffold step — I want to see how you create the output directory and files.",
      "expected_output": "Phase 1 creates output files using Write tool (not touch). docs/research/httpbin-org/ directory exists with INDEX.md, tech-stack.md, site-map.md, constants.md all created via Write.",
      "files": []
    },
    {
      "id": 2,
      "eval_name": "ecommerce-probe-list",
      "prompt": "Research https://woocommerce.com/woocommerce-demo — it's a WooCommerce demo store. Map all available product APIs and cart endpoints. Run all 12 phases and document what you find.",
      "expected_output": "WooCommerce tech pack loaded (LOADED:woocommerce:9.x in session brief). E-commerce probe list applied: /wp-json/wc/store/v1/products, /wp-json/wc/v3/products, and wc-ajax endpoints probed. INDEX.md and api-surfaces/ created.",
      "files": []
    },
    {
      "id": 3,
      "eval_name": "phase-completion-gate",
      "prompt": "Analyse https://jsonplaceholder.typicode.com — a fake REST API for testing. Run a full beacon site analysis across all 12 phases. I want to see the complete phase sequence in your session brief.",
      "expected_output": "All 12 phases executed. Session brief shows phase completion markers [P1✓] through [P11✓] or SKIPPED before Phase 12 runs. No phases silently skipped. INDEX.md and api-surfaces/rest-api.md created.",
      "files": []
    },
    {
      "id": 4,
      "eval_name": "late-tech-pack-trigger",
      "prompt": "Map the API surface of https://wordpress.org/news/feed/ — this is a WordPress Atom feed endpoint. Start with Phase 1 and work through all 12 phases. I want to see how you handle tech pack lookup when you discover the framework from a feed.",
      "expected_output": "WordPress tech pack loaded after feed discovery. If ZF1 or other framework detected from generator tag, Phase 4 is re-triggered (TECH-PACK-LATE-LOAD logged). Session brief documents framework source as the feed generator tag.",
      "files": []
    }
  ]
}
```

- [ ] **Step 3: Verify the workspace structure**

```bash
find plugins/beacon/skills/site-recon-workspace -type f
```

Expected output:
```
plugins/beacon/skills/site-recon-workspace/evals/evals.json
plugins/beacon/skills/site-recon-workspace/old-skill-snapshot/SKILL.md
```

---

## Task 5: Run iteration-1 evals (with-skill vs baseline)

Spawn 8 subagents in parallel (4 with-skill, 4 baseline), all in the same turn. The skill-creator
says: **do not spawn with-skill runs first and come back for baselines later — launch everything at once.**

**Files:**
- Create: `plugins/beacon/skills/site-recon-workspace/iteration-1/eval-{1..4}-{with_skill,old_skill}/`

- [ ] **Step 1: Create iteration-1 directory**

```bash
mkdir -p plugins/beacon/skills/site-recon-workspace/iteration-1
```

- [ ] **Step 2: Spawn all 8 subagents in a single message**

For each of the 4 evals, dispatch two subagents in the SAME tool-use turn:

**With-skill runs** (use updated SKILL.md at `plugins/beacon/skills/site-recon/SKILL.md`):
```
Skill path: plugins/beacon/skills/site-recon/SKILL.md
Task: [eval prompt from evals.json]
Save outputs to: plugins/beacon/skills/site-recon-workspace/iteration-1/eval-{N}-scaffold-no-touch/with_skill/outputs/
Outputs to save: the session brief (markdown in context), any created docs/research/ files
```

**Baseline runs** (use old skill snapshot at `plugins/beacon/skills/site-recon-workspace/old-skill-snapshot/SKILL.md`):
```
Skill path: plugins/beacon/skills/site-recon-workspace/old-skill-snapshot/SKILL.md
Task: [same eval prompt]
Save outputs to: plugins/beacon/skills/site-recon-workspace/iteration-1/eval-{N}-scaffold-no-touch/old_skill/outputs/
```

Also create `eval_metadata.json` in each eval directory:
```json
{
  "eval_id": 1,
  "eval_name": "scaffold-no-touch",
  "prompt": "Analyse https://httpbin.org...",
  "assertions": [
    {
      "text": "Phase 1 creates files with Write tool, not touch command",
      "check": "grep -r 'touch' outputs/ | grep -v '# ' | wc -l == 0"
    },
    {
      "text": "docs/research directory created with correct slug",
      "check": "ls outputs/docs/research/ | head -1 matches httpbin-org"
    },
    {
      "text": "INDEX.md created and non-empty",
      "check": "wc -c outputs/docs/research/httpbin-org/INDEX.md > 100"
    }
  ]
}
```

- [ ] **Step 3: Save timing data as each subagent completes**

When each subagent notification arrives, immediately save to its run directory:
```json
{
  "total_tokens": 0,
  "duration_ms": 0,
  "total_duration_seconds": 0.0
}
```
Replace zeroes with actual values from the notification.

---

## Task 6: Draft assertions, grade, and launch eval viewer

While runs are in progress (Task 5), draft assertions for all 4 evals. Once runs complete,
grade and launch the viewer.

- [ ] **Step 1: Draft assertions for all 4 evals while runs are in progress**

Update each `eval_metadata.json` with assertions (see Task 5 Step 2 for eval-1 example).

**Eval 2 — ecommerce-probe-list assertions:**
```json
[
  {"text": "WooCommerce tech pack loaded (LOADED:woocommerce in session brief)"},
  {"text": "At least one of /wp-json/wc/store/v1/products or /wp-json/wc/v3/products probed"},
  {"text": "api-surfaces/ directory contains at least one file"}
]
```

**Eval 3 — phase-completion-gate assertions:**
```json
[
  {"text": "Session brief contains phase markers for all 12 phases"},
  {"text": "Phase 12 runs only after P1-P11 markers are present"},
  {"text": "INDEX.md created"}
]
```

**Eval 4 — late-tech-pack-trigger assertions:**
```json
[
  {"text": "WordPress tech pack loaded (LOADED:wordpress in session brief)"},
  {"text": "Framework detected from feed or HTTP signals, not just HTML"},
  {"text": "tech-stack.md documents the discovery source"}
]
```

- [ ] **Step 2: Aggregate benchmark**

```bash
SKILL_CREATOR=/Users/georgiospilitsoglou/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator
python -m scripts.aggregate_benchmark \
  plugins/beacon/skills/site-recon-workspace/iteration-1 \
  --skill-name site-recon
```

Run from the skill-creator directory:
```bash
cd $SKILL_CREATOR && python -m scripts.aggregate_benchmark \
  /Users/georgiospilitsoglou/Developer/projects/claude-plugins/plugins/beacon/skills/site-recon-workspace/iteration-1 \
  --skill-name site-recon
```

- [ ] **Step 3: Launch eval viewer**

```bash
SKILL_CREATOR=/Users/georgiospilitsoglou/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator
WORKSPACE=/Users/georgiospilitsoglou/Developer/projects/claude-plugins/plugins/beacon/skills/site-recon-workspace

nohup python $SKILL_CREATOR/eval-viewer/generate_review.py \
  $WORKSPACE/iteration-1 \
  --skill-name "beacon-site-recon" \
  --benchmark $WORKSPACE/iteration-1/benchmark.json \
  > /dev/null 2>&1 &

echo "Viewer launched. Visit the URL shown above."
echo "Review the Outputs tab (qualitative) and Benchmark tab (quantitative)."
echo "Click Submit All Reviews when done, then return here."
```

---

## Task 7: Iterate skill based on eval feedback

After the user reviews outputs in the viewer and submits feedback:

- [ ] **Step 1: Read feedback.json**

```bash
cat plugins/beacon/skills/site-recon-workspace/iteration-1/feedback.json
```

Focus on non-empty feedback entries — those are the test cases that need fixing.

- [ ] **Step 2: Apply targeted fixes to SKILL.md**

For each piece of feedback, edit `plugins/beacon/skills/site-recon/SKILL.md` with a specific fix.
Do not make broad rewrites — one fix per feedback item.

Common expected issues based on the session analysis:
- If eval-1 still shows `touch` in outputs: the Phase 1 Write instruction is not strong enough — add a `NEVER use touch` rule
- If eval-3 skips phases: the phase completion gate instruction needs to be more explicit — add a numbered pre-flight check
- If eval-2 doesn't load WooCommerce pack: Phase 4 lookup URL pattern needs `woocommerce` listed explicitly
- If eval-4 misses late ZF1 signal: Phase 6 feed check needs an explicit generator tag → Phase 4 re-trigger instruction

- [ ] **Step 3: Run iteration-2 (with same baselines)**

```bash
mkdir -p plugins/beacon/skills/site-recon-workspace/iteration-2
```

Spawn 4 with-skill subagents (same prompts, updated skill) in one turn. The baseline
(old-skill) results carry over from iteration-1 — no need to rerun them.

Launch viewer with `--previous-workspace`:
```bash
nohup python $SKILL_CREATOR/eval-viewer/generate_review.py \
  $WORKSPACE/iteration-2 \
  --skill-name "beacon-site-recon" \
  --benchmark $WORKSPACE/iteration-2/benchmark.json \
  --previous-workspace $WORKSPACE/iteration-1 \
  > /dev/null 2>&1 &
```

- [ ] **Step 4: Repeat until feedback is clear or progress plateaus**

Stop when: all feedback entries are empty, OR two consecutive iterations show no measurable
improvement in assertion pass rate.

- [ ] **Step 5: Commit final SKILL.md**

```bash
git add plugins/beacon/skills/site-recon/SKILL.md
git commit -m "$(cat <<'EOF'
fix(beacon): skill-creator iteration — improve site-recon based on eval results

[describe specific fixes applied from eval feedback]

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Description optimization

Use the skill-creator's `run_loop.py` to optimize the site-recon skill description for
better triggering accuracy (the description is the only thing the model sees before deciding
to invoke the skill).

- [ ] **Step 1: Generate trigger eval queries**

Read the HTML template and create the trigger eval review page:

```bash
SKILL_CREATOR=/Users/georgiospilitsoglou/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator

# Read the template
cat $SKILL_CREATOR/assets/eval_review.html
```

Create a JSON file at `plugins/beacon/skills/site-recon-workspace/trigger-evals.json`:

```json
[
  {"query": "analyse https://www.jetpens.com — i want to find all the product APIs they have", "should_trigger": true},
  {"query": "map the api surface of https://penchalet.com — it sells fountain pens", "should_trigger": true},
  {"query": "research https://woocommerce-demo.com and document how to pull product data from it", "should_trigger": true},
  {"query": "what endpoints does https://demo.opencart.com expose for products and cart?", "should_trigger": true},
  {"query": "use beacon to check out https://httpbin.org", "should_trigger": true},
  {"query": "find all the APIs on https://shop.example.com — i need to know if it has a product JSON endpoint", "should_trigger": true},
  {"query": "check this site for me https://somestore.com, what can i extract programmatically?", "should_trigger": true},
  {"query": "/beacon:analyze https://example.com", "should_trigger": true},
  {"query": "how do i authenticate with the jetpens API we found last week", "should_trigger": false},
  {"query": "write me a python script to fetch products from /wp-json/wc/v3/products", "should_trigger": false},
  {"query": "explain how woocommerce auth works with consumer keys", "should_trigger": false},
  {"query": "tell me about the penchalet research we did before", "should_trigger": false},
  {"query": "fix the bug in my site scraper where the requests are getting 403", "should_trigger": false},
  {"query": "what is the difference between REST API v2 and v3 in woocommerce", "should_trigger": false},
  {"query": "add error handling to this fetch call", "should_trigger": false},
  {"query": "i want to load the existing research for jetpens.com", "should_trigger": false},
  {"query": "site-intel: what APIs does the jetpens site have", "should_trigger": false},
  {"query": "can you debug why my magento graphql query is returning null", "should_trigger": false}
]
```

Note: the last two should NOT trigger site-recon — they should trigger site-intel (load existing
research). This tests that beacon's two skills do not cross-trigger.

- [ ] **Step 2: Open eval review page**

Replace `__EVAL_DATA_PLACEHOLDER__` and `__SKILL_NAME_PLACEHOLDER__` in the template and open:
```bash
TRIGGER_EVALS=$(cat plugins/beacon/skills/site-recon-workspace/trigger-evals.json)
sed "s/__EVAL_DATA_PLACEHOLDER__/${TRIGGER_EVALS}/g;s/__SKILL_NAME_PLACEHOLDER__/beacon:site-recon/g" \
  $SKILL_CREATOR/assets/eval_review.html > /tmp/eval_review_site-recon.html
open /tmp/eval_review_site-recon.html
```

Wait for user to review and click "Export Eval Set". Check Downloads for `eval_set.json`.

- [ ] **Step 3: Run description optimization loop**

```bash
python -m scripts.run_loop \
  --eval-set plugins/beacon/skills/site-recon-workspace/eval_set.json \
  --skill-path plugins/beacon/skills/site-recon/SKILL.md \
  --model claude-sonnet-4-6 \
  --max-iterations 5 \
  --verbose
```

Run from the skill-creator directory. This takes ~10–15 minutes. The script runs in the
background and prints iteration progress.

- [ ] **Step 4: Apply best description**

When the loop completes, it prints `best_description`. Update the SKILL.md frontmatter:

```bash
# The result looks like:
# best_description: "This skill should be used when..."
# Update line 3 of SKILL.md with the new description
```

Show the user before/after and the score improvement.

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-recon/SKILL.md
git commit -m "$(cat <<'EOF'
feat(beacon): optimize site-recon skill description for triggering accuracy

run_loop.py iterated 5x on 18 trigger/no-trigger evals. New description achieves
[N]% trigger accuracy vs [M]% baseline. Key change: [describe main change].

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Plugin version bump and final CHANGELOG

- [ ] **Step 1: Update plugin.json version**

Edit `plugins/beacon/.claude-plugin/plugin.json`:

```json
{
  "name": "beacon",
  "version": "0.6.3",
  ...
}
```

- [ ] **Step 2: Verify CHANGELOG is complete**

```bash
head -60 plugins/beacon/CHANGELOG.md
```

Confirm entries exist for 0.6.2 (WooCommerce/Magento + SKILL.md fixes) and 0.6.3 (ASP.NET).

- [ ] **Step 3: Commit version bump**

```bash
git add plugins/beacon/.claude-plugin/plugin.json
git add plugins/beacon/CHANGELOG.md
git commit -m "$(cat <<'EOF'
chore(beacon): bump version to 0.6.3

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Create PR

- [ ] **Step 1: Push branch**

```bash
git push -u origin feat/beacon-ecommerce-improvements
```

- [ ] **Step 2: Create PR**

```bash
gh pr create \
  --title "feat(beacon): e-commerce tech packs + 15 site-recon fixes from session analysis" \
  --body "$(cat <<'EOF'
## Summary

- **3 new tech packs:** WooCommerce 9.x, Magento 2.x, ASP.NET WebForms & MVC — all follow the 10-section standard format
- **11 site-recon SKILL.md fixes** derived from real failure analysis of Pen-Chalet and JetPens sessions (353-line retrospective in \`docs/research/beacon-session-analysis/\`)
- **2 reference file updates:** \`tool-availability.md\` (gau alias, Chrome MCP dual namespace), \`browser-recon.md\` (Cloudflare bypass strategy, corrected cmux signatures)
- **Skill-creator eval loop:** 4 test cases with assertions, iteration results, and optimized triggering description

## Key fixes

| Fix | Root cause |
|-----|-----------|
| Phase 1 scaffold uses `Write` not `touch` | Write tool requires prior Read; touch caused 12 failed writes per session |
| Chrome MCP namespace detection | Two valid namespaces; wrong one caused repeated timeouts |
| Phase 4 late discovery rule | ZF1/ASP.NET found in Phase 6 feeds was never triggering tech pack lookup |
| Phase 12 completion gate | Phases 4/5/7 silently skipped; gate forces re-run |
| Cloudflare bypass strategy | All curl probes 403'd; no documented pivot path |
| gau alias detection | `gau` aliased to `git add --update`; `which gau` couldn't detect this |
| `www.` slug stripping | `www.jetpens.com` → `www-jetpens-com` instead of `jetpens-com` |
| E-commerce probe list | "no API" verdict issued before WooCommerce Store API was probed |
| cmux command signatures | 3 failed attempts from wrong syntax |

## Test plan

- [ ] Run `/beacon:analyze https://httpbin.org` — verify Phase 1 uses Write, all 12 phases complete
- [ ] Run `/beacon:analyze https://woocommerce-demo.com` — verify WooCommerce tech pack loads
- [ ] Verify `eval-viewer` benchmark shows improvement over baseline
- [ ] Run description optimization and confirm trigger accuracy ≥ 85%

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review

**Spec coverage check:**
- ✅ WooCommerce tech pack (Rec #3 from analysis)
- ✅ Magento 2 tech pack (Rec #2 from analysis)
- ✅ ASP.NET tech pack (Rec #1 from analysis, highest priority)
- ✅ Write-before-Read fix (Fix #6 from analysis)
- ✅ Phase completion gate (Fix #7)
- ✅ Late discovery rule (Fix #8)
- ✅ gau alias detection (Fix #9)
- ✅ E-commerce probe list (Fix #10)
- ✅ Cloudflare bypass (Fix #11)
- ✅ Chrome MCP namespace (Fix #12)
- ✅ Cloudflare Turnstile limitation (Fix #13)
- ✅ cmux usage guide (Fix #14)
- ✅ Site slug normalization (Fix #15)
- ✅ Skill-creator eval loop with 4 test cases
- ✅ Description optimization via run_loop.py
- ✅ Plugin version bump

**Task 0 prerequisite:** Task 0 must complete before Tasks 1–3 can commit cleanly (baseline is pre-T0 state). All other tasks are independent of each other except Task 7 (depends on Task 5/6) and Task 8 (depends on Task 7).
