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
## 11. GitHub Code Search Patterns

Use these queries on GitHub to find custom endpoints, plugin code, and configuration examples for this framework.

### Framework-Specific Queries

| Search Query | What it finds |
|--------------|---------------|
| `"<pattern>" language:<lang> path:<path>` | <description> |

### Example Queries

```bash
# Search for custom endpoints
site:github.com "<framework>" "api" filetype:<ext>

# Search for auth patterns  
site:github.com "<framework>" "auth" "middleware"

# Search for config files
site:github.com "<framework>" "config" "endpoint"
```

## 12. Framework-Specific Google Dorks

### Discovery Queries

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:<path>` | <description> |

### Complete Dork List

```
# API endpoints
site:{domain} inurl:/api/
site:{domain} inurl:/v1/

# Framework paths
site:{domain} inurl:<specific-path>
```


## 13. Cross-Cutting OSINT Patterns

These patterns apply across frameworks and should be checked for any detected technology.

### Favicon Hashing

Identify technology stack by hashing favicon and searching Shodan/Censys for same stack:

```bash
# Get favicon hash (mmh3 hash of favicon content)
curl -s "https://{domain}/favicon.ico" | python3 -c "
import sys, hashlib
data = sys.stdin.buffer.read()
# Simple mmh3 hash simulation using Python
try:
    import mmh3
    print('Favicon hash:', mmh3.hash(data))
except ImportError:
    print('Install mmh3: pip install mmh3')
"

# Search Shodan for same favicon (indicates shadow IT subdomains)
# site:shodan.io search: icon_hash:{hash}
```

**What it reveals:** Hidden subdomains running same framework stack as main site.

### Source Map Discovery

Check for source maps across all JS bundles:

```bash
# Extract all JS bundle URLs from HTML
curl -s "https://{domain}/" | grep -oP 'src="[^"]+\.js[^"]*"' | grep -oP '"[^"]+"' | tr -d '"' > js_urls.txt

# Check each for .map file
while read url; do
  map_url="${url}.map"
  status=$(curl -s -o /dev/null -w "%{http_code}" "${map_url}")
  [ "$status" = "200" ] && echo "SOURCE MAP: ${map_url}"
done < js_urls.txt
```

**Build tool patterns:**
| Build Tool | Source Map Pattern | Detection |
|------------|-------------------|------------|
| Webpack | `{bundle}.js.map` or `//# sourceMappingURL=` | Check response header `X-SourceMap` |
| Vite | `{name}-[hash].js.map` | Vite manifest `manifest.json` |
| Rollup | `{bundle}.js.map` | Check `sourceMappingURL` comment |
| esbuild | `{bundle}.js.map` | Check `sourceMappingURL` comment |
| Next.js | `/_next/static/chunks/*.js.map` | Only if `productionBrowserSourceMaps: true` |

### Tech Stack → API Pattern Mapping

Auto-map detected frameworks to likely endpoint patterns:

| Framework | Common API Patterns |
|-----------|---------------------|
| Next.js | `/api/*`, `/_next/data/*`, `/api/auth/*`, `/api/trpc/*` |
| WordPress | `/wp-json/*`, `/wp-json/wp/v2/*`, `/wp-admin/admin-ajax.php` |
| Shopify | `/api/2024-10/graphql.json`, `/products.json`, `/collections.json` |
| Rails | `/api/v1/*`, `/assets/*`, `/users/sign_in` |
| Laravel | `/api/*`, `/livewire/message/*`, `/sanctum/csrf-cookie` |
| Strapi | `/api/*`, `/admin/*`, `/api/upload*` |
| Magento | `/rest/V1/*`, `/pub/static/*` |
| Django | `/api/*`, `/admin/*`, `/accounts/*` |
| Express | `/api/*`, `/v1/*`, `/health` |
| Astro | `/_astro/*`, `/api/*` |
| Ghost | `/ghost/api/*`, `/members/api/*` |

When Phase 3 detects a framework, use this table to prioritize Phase 5/6/7 probes.

### Email Naming Convention Analysis

Extract emails from theHarvester/GitHub results to predict internal subdomains:

```bash
# Sample emails found: john.doe@example.com, jane.smith@example.com
# Predicted subdomains: mail.example.com, smtp.example.com, exchange.example.com

# Common patterns:
# first.last@ → internal.example.com, mail.example.com
# firstinitial+last@ → owa.example.com, outlook.example.com
```

**Add to Phase 9 session brief:** Note email patterns and predicted subdomains.
