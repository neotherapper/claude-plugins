---
framework: sitecore
version: "10.x+, XM Cloud, Headless Services 22.x, SitecoreAI"
last_updated: "2026-07-29"
author: "@opencode"
status: community
---

# Sitecore — Tech Pack

Sitecore is an enterprise CMS and digital experience platform built on ASP.NET. Current product lines:
- **Sitecore XP 10.4** — On-prem/PaaS Experience Platform (latest: 10.4.1)
- **XM Cloud** — Fully managed cloud-hosted headless CMS (launched July 2022)
- **SitecoreAI** — AI platform integrating content management, CDP, and personalisation (2025+)
- **Experience Edge for XM** — Globally replicated GraphQL delivery via CDN
- **Sitecore Content Hub** — DAM, CMP, MRM
- **Sitecore Commerce (XC)** — B2B/B2C e-commerce
- **Sitecore Experience Accelerator (SXA)** — Templated UX components
- **Sitecore Publishing Service** — High-performance publishing module (optional)
- **Sitecore xConnect/xDB** — Analytics and experience database OData service
- **Sitecore Horizon** — Next-generation content editor (replaces Experience Editor on modern stacks)
- **Sitecore SPEAK** — Legacy UI framework for Sitecore applications

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `<!-- Sitecore -->` comment | HTML | In page source | Definitive |
| `SC_ANALYTICS` cookie | Cookie | Analytics tracking cookie | High |
| `/sitecore/` path | URL | Sitecore admin/shell | High |
| `sc_site` query param | URL | Sitecore context site identification | High |
| `sc_mode=edit\|preview\|normal` | URL | Experience Editor mode | High |
| `sc_lang` query param | URL | Language version | Medium |
| `sc_apikey` query param/header | URL/Header | SSC API key | High |
| `__RequestVerificationToken` | Form | CSRF token | Medium |
| `data-sc-*` attributes | HTML | Item/rendering IDs | Medium |
| `/-/jss/` or `/-/api/items/` | URL | JSS headless endpoints | High |
| `Sitecore.LayoutService` | JS | Layout service client | Medium |
| `edge.sitecorecloud.io` | Domain | Experience Edge cloud | Definitive (if seen) |
| `X-Sitecore-*` response headers | Header | Custom Sitecore headers | Medium |
| `sc_device` patterns | HTML | Device detection markers | Low |

**Version extraction (bash):**

```bash
# Check for Sitecore version in HTML comments
curl -s https://target.example.com/ | grep -i 'sitecore\|Sitecore [0-9]'

# Check Sitecore login page for version
curl -sf --max-time 10 "https://target.example.com/sitecore/login" | grep -oE 'version [0-9]+\.[0-9]+'

# Check for Sitecore version in response headers
curl -I --max-time 10 "https://target.example.com/" 2>/dev/null | grep -i 'sitecore\|x-sitecore'

# Detect XM Cloud via edge domain
curl -sI "https://target.example.com/" | grep -i 'edge.sitecorecloud.io'

# Detect JSS/headless mode via __NEXT_DATA__ or layout service
curl -s "https://target.example.com/" | grep -oE '"sitecore"[^}]+'
curl -s "https://target.example.com/" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print('nextjs-sitecore' if 'sitecore' in str(d.get('props',{})) else '')" 2>/dev/null || true
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Product | Notes |
|----------|--------|------|---------|-------|
| `/sitecore/api/layout/render/{config}?item=` | GET | sc_apikey | XP/Headless | Layout Service (full page) |
| `/sitecore/api/layout/placeholder/{config}?placeholderName=` | GET | sc_apikey | XP/Headless | Layout Service (single placeholder) |
| `/sitecore/api/items/-/items?path=` | GET/POST | Varies | XP | Item Service |
| `/sitecore/api/items/-/children?path=` | GET | Varies | XP | Item Service children |
| `/sitecore/api/graph/` | POST | Auth | XP/Headless | On-prem GraphQL endpoint |
| `/sitecore/api/jss/*` | GET | Varies | JSS | JavaScript Services |
| `/sitecore/shell/api/medialib/*` | GET | Auth | XP | Media Library API |
| `/sitecore/api/managed/*` | Various | Auth | XP | Managed database API |
| `/sitecore/api/analytics/*` | GET | Auth | XP | Analytics APIs |
| `/-/jss/` | GET | Varies | JSS | JSS entry point |
| `/-/api/items/{id}` | GET | Varies | JSS | JSS item API |
| `/api/sitecore/*` | Various | Varies | Custom | Custom Web API routes |
| `POST https://edge.sitecorecloud.io/api/graphql/v1` | POST | sc_apikey (Bearer) | Edge | Experience Edge Delivery API |
| `GET https://edge.sitecorecloud.io/api/graphql/ide` | GET | None | Edge | GraphQL IDE playground |
| `https://edge.sitecorecloud.io/api/apikey/v1` | Various | JWT Bearer | Edge | Token management API |
| `https://edge.sitecorecloud.io/api/admin/v1` | Various | JWT Bearer | Edge | Admin API (cache, webhooks, settings) |
| `/sitecore/api/auth/login` | POST | None | XP | Login endpoint |
| `/sitecore/login` | GET | None | XP | Login page |
| `/sitecore/shell/` | GET | Auth | XP | Sitecore desktop shell |
| `/sitecore/admin/` | GET | Auth | XP | Admin tools |
| `/sitecore/config/` | GET | Auth | XP | Config viewer |
| `/xconnect/` | Various | Auth | XP | xConnect OData service |
| `/xconnect/xcontrib/` | Various | Auth | XP | xConnect custom endpoints |
| `/xconnect/odata/` | GET | Auth | XP | xConnect OData API |
| `/sitecore/api/publishing/` | POST | Auth | XP/PubSvc | Publishing Service API |
| `/sitecore/api/speakeasy/` | Various | Auth | XP | SPEAK (legacy) |

## 2b. Headless Services API Surface (on-prem, version 22.x)

| Service | Endpoint | Method | Notes |
|---------|----------|--------|-------|
| Layout Service | `/sitecore/api/layout/render/{config}?item=` | GET | Full layout JSON |
| Layout Service (placeholder) | `/sitecore/api/layout/placeholder/{config}?placeholderName=` | GET | Single placeholder |
| Dictionary Service | `/sitecore/api/jss/dictionary/{app}` | GET | Translation keys |
| Media Handler | `/-/media/{path}` | GET | Media resizing/proxying |
| GraphQL | `/sitecore/api/graph/` | POST | Custom GraphQL endpoints |
| Tracking Service | `/sitecore/api/jss/track/` | POST | Event/page tracking |
| Forms Service | `/sitecore/api/forms/` | Various | Form submissions |
| Import Service | `/sitecore/api/import/` | POST | JSS app import |
| App Configuration API | (config-based) | N/A | XML config patches |

## 2c. Experience Edge API Surface (cloud, version 22.x)

| API | Base URL | Endpoints | Auth |
|-----|----------|-----------|------|
| Delivery (GraphQL) | `https://edge.sitecorecloud.io/api/graphql/v1` | `POST /` | `sc_apikey` header |
| Token (REST) | `https://edge.sitecorecloud.io/api/apikey/v1` | `GET /`, `POST /`, `PUT /renamebyhash/`, `PUT /renamebytoken/`, `PUT /revokebyhash/`, `PUT /revokebytoken/` | JWT Bearer |
| Admin (REST) | `https://edge.sitecorecloud.io/api/admin/v1` | `GET/PUT/PATCH /settings`, `DELETE /cache`, `DELETE /content`, `CRUD /webhooks` | JWT Bearer |
| GraphQL IDE | `https://edge.sitecorecloud.io/api/graphql/ide` | `GET /` | None (public) |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `/sitecore/` | Browser | Sitecore admin shell |
| `/sitecore/shell/` | Browser | Sitecore desktop |
| `/sitecore/login` | Browser | Login page |
| `/sitecore/admin/` | Browser | Admin tools |
| `web.config` | Server access | Main .NET configuration |
| `App_Config/` | Server access | Configuration includes (Patches) |
| `App_Config/Sitecore/JavaScriptServices/` | Server access | JSS app definitions |
| `Sitecore.Kernel.dll` | Server access | Assembly version info |
| `scjssconfig.json` | JSS app source | JSS import credentials |
| `App_Data/` | Server access | Data files, logs, packages |
| Sitecore Cloud Portal | `https://portal.sitecorecloud.io/` | XM Cloud management |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| `__RequestVerificationToken` | Form field | CSRF protection (all versions) |
| Sitecore Identity Server | `https://{id-server}/` | Modern auth (Sitecore 10+) |
| `sc_apikey` | Query param or HTTP header | SSC/Edge API authentication |
| JWT (OAuth client credentials) | Authorization header | Experience Edge admin auth |
| `sc_token` | Header | Legacy API authentication |
| Basic Auth | Header | For service accounts |
| `sitecore\JssImport` user | App config | Default import service account |
| Extranet匿名用户 | Cookie | Anonymous user cookie |

**Auth endpoint detection:**
```bash
# Detect Sitecore Identity Server
curl -sf --max-time 10 "https://target.example.com/sitecore/login" | grep -oE 'https?://[^"]*identity[^"]*'

# Check for OAuth/JWT endpoints
curl -sf --max-time 10 "https://target.example.com/.well-known/openid-configuration" | grep -i 'sitecore\|identity'

# Get CSRF token from form
curl -s "https://target.example.com/" | grep -o '__RequestVerificationToken[^"]*value="[^"]*"'
```

## 5. Layout Service API

```bash
TARGET="target.example.com"

# Render full layout (default config)
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/render/default?item=/"
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/render/default?item=/home"

# Render with JSS config
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/render/jss?item=/"

# Render with tracking disabled
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/render/jss?item=/&tracking=false"

# Render single placeholder
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/placeholder/jss?placeholderName=/main&item=/home&tracking=false"

# With API key
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/render/jss?item=/&sc_apikey={key}"
curl -sf --max-time 10 -H "sc_apikey: {key}" "https://${TARGET}/sitecore/api/layout/render/jss?item=/"

# Language-specific
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/render/default?item=/&sc_lang=en"
```

## 6. Item Service API

```bash
# Get item by path
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/items/-/items?path=/"

# Get item children
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/items/-/children?path=/"
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/items/-/children?path=/sitecore/content/Home"

# Get item by ID
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/items/$(uuid)"

# OData-style queries
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/items/-/items?\$filter=TemplateName eq 'Article'&\$top=10"
```

## 7. JSS (JavaScript Services) API

```bash
# JSS Layout Service entry
curl -sf --max-time 10 "https://${TARGET}/-/jss/"

# JSS item API
curl -sf --max-time 10 "https://${TARGET}/-/api/items/"
curl -sf --max-time 10 "https://${TARGET}/-/api/items/{id}?format=json"

# JSS dictionary
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/jss/dictionary/{appname}"

# JSS tracking
curl -sf --max-time 10 -X POST "https://${TARGET}/sitecore/api/jss/track/event" \
  -H "Content-Type: application/json" \
  -d '{"event":"pageview","url":"/home"}'

# Detect JSS + Next.js
curl -s "https://${TARGET}/" | python3 -c "
import sys, json, re
html = sys.stdin.read()
# Check for __NEXT_DATA__ with Sitecore
m = re.search(r'__NEXT_DATA__\s*=\s*({.*?});', html, re.DOTALL)
if m:
    data = json.loads(m.group(1))
    if 'sitecore' in str(data.get('props', {})):
        print('[JSS-NEXTJS-DETECTED]')
    else:
        print('[NEXTJS-DETECTED] (not Sitecore JSS)')
elif 'sitecore' in html.lower():
    print('[JSS-POSSIBLE]')
else:
    print('[NO-JSS-SIGNAL]')
"
```

## 7b. Experience Edge (Cloud) API

```bash
# Delivery API (GraphQL) — requires sc_apikey
curl -sf --max-time 10 -X POST "https://edge.sitecorecloud.io/api/graphql/v1" \
  -H "Content-Type: application/json" \
  -H "sc_apikey: {api_key}" \
  -d '{"query":"{ site { siteInfo { name } } }"}'

# GraphQL IDE (public, no auth)
curl -sf --max-time 10 "https://edge.sitecorecloud.io/api/graphql/ide"

# Token API — requires JWT Bearer
curl -sf --max-time 10 "https://edge.sitecorecloud.io/api/apikey/v1" \
  -H "Authorization: Bearer {jwt}"

# Admin API — requires JWT Bearer
curl -sf --max-time 10 "https://edge.sitecorecloud.io/api/admin/v1/settings" \
  -H "Authorization: Bearer {jwt}"
```

## 8. Probe Checklist

**Phase 5 probes (run after fingerprinting Sitecore):**

```bash
TARGET="target.example.com"

echo "=== Sitecore Admin Paths ==="
for path in "/sitecore/" "/sitecore/login" "/sitecore/shell/" "/sitecore/admin/" \
            "/sitecore/config/" "/sitecore/api/" "/sitecore/debug/" \
            "/xconnect/" "/xconnect/odata/" "/xconnect/xcontrib/"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}${path}")
  echo "${path} → ${status}"
done

echo "=== Layout Service ==="
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/render/default?item=/"
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/render/jss?item=/home"

echo "=== Item Service ==="
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/items/-/items?path=/"
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/items/-/children?path=/"

echo "=== JSS API ==="
curl -sf --max-time 10 "https://${TARGET}/-/jss/"
curl -sf --max-time 10 "https://${TARGET}/-/api/items/"
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/jss/dictionary/default"

echo "=== GraphQL ==="
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/graph/"
curl -sf -X POST --max-time 10 "https://${TARGET}/sitecore/api/graph/" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __typename }"}'

echo "=== Experience Edge (cloud) ==="
curl -sf --max-time 10 "https://edge.sitecorecloud.io/api/graphql/ide"

echo "=== XM Cloud Check ==="
curl -sf --max-time 10 "https://${TARGET}/api/editing/config"

echo "=== Media Library ==="
curl -sf --max-time 10 "https://${TARGET}/-/media/"

echo "=== Common Content Paths ==="
for path in "home" "Products" "Services" "News" "About" "Contact"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}/${path}")
  echo "${path} → ${status}"
done
```

**Phase 9 OSINT probes:**

```bash
echo "=== Wayback Machine paths ==="
curl -s "http://web.archive.org/cdx/search/cdx?url=${TARGET}/*&output=text&filter=statuscode:200" \
  | grep -iE '/sitecore/|/-/jss|/-/media|-/api/items' | sort -u | head -20

echo "=== Google dorks ==="
# inurl:/sitecore/login
# inurl:sc_mode=edit
# intitle:"Sitecore Login" or "Sitecore Experience Platform"
# inurl:/sitecore/shell

echo "=== Common subdomains ==="
for sub in "cm" "cd" "xmcloud" "edge" "identity" "portal" "admin" "api"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${sub}.${TARGET}/")
  echo "${sub}.${TARGET} → ${status}"
done

echo "=== Known CVE paths (passive check) ==="
# Check for known vulnerable paths
for path in "/sitecore/shell/WebService/GetStoredFile.asmx" \
            "/sitecore/shell/WebService/Performance.asmx" \
            "/sitecore/shell/sitecore.version.xml" \
            "/sitecore/shell/Controls/Rich Text Editor/InsertImage.aspx" \
            "/App_Config/Security/Domains.config" \
            "/sitecore/shell/~/xaml/Sitecore.Shell.Applications.Security.SetSecurity.aspx"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://${TARGET}${path}")
  if [ "$status" != "404" ] && [ "$status" != "000" ]; then
    echo "${path} → HTTP ${status}"
  fi
done
```

**What to log:**
- `[SITECORE-DETECTED:{version}]` when Sitecore is confirmed
- `[SITECORE-XM-CLOUD]` if XM Cloud detected (edge.sitecorecloud.io or cloud portal)
- `[SITECORE-JSS]` if JSS is detected (/-/jss, __NEXT_DATA__ with sitecore)
- `[SITECORE-HEADLESS]` if Headless Services detected
- `[SITECORE-EDGE]` if Experience Edge detected
- `[SITECORE-API:{endpoint}:{status}]` for each API probe
- `[SITECORE-AUTH:{type}]` for authentication patterns found
- `[SITECORE-SXA]` if SXA detected
- `[SITECORE-IDENTITY-SERVER:{url}]` if Identity Server found
- `[SITECORE-VERSION:{ver}]` extracted version string

## Known Quirks

- **`sc_mode=edit` redirect**: In Sitecore 10.4.1+, requests with `sc_mode=edit` may NOT redirect to login page (changed behaviour). Check both with and without sc_mode.
- **Layout Service paths** are relative to the site's Home item — use `sc_site` or hostname-based site resolution.
- **Item Service vs Layout Service**: Item Service returns raw field data; Layout Service returns structured layout JSON with rendered components.
- **JSS + Next.js**: `__NEXT_DATA__` JSON will contain a `sitecore` key with `route`, `context`, `language` fields when JSS is used. Check `document.getElementById('__NEXT_DATA__')`.
- **SXA dynamic placeholders**: The Layout Service assumes all non-root placeholders are dynamic. Placeholder format includes dynamic key.
- **Cloud vs On-prem URLs**: On-prem paths use `/sitecore/api/` prefix; XM Cloud/Edge uses `edge.sitecorecloud.io` domain with no `/sitecore/` prefix.
- **Dictionary items** in Sitecore AI/XM Cloud: May publish to Experience Edge but use a different cache mechanism. Preview works, but published may not update until cache clears.
- **Content SDK (App Router)**: Newer JSS uses Content SDK with different API patterns (not the classic JSS server.js). The `/api/editing/config` endpoint is used for editing configuration.
- **Import service**: Uses the JSS Import user (`sitecore\JssImport`) — shared secret for app import endpoint.
- **SitecoreAI** (2025+): AI-powered content creation and personalisation — look for SitecoreAI-specific cookies and API patterns.
- **xConnect OData**: Exposes `/xconnect/odata/` with standard OData query syntax (`$filter`, `$top`, `$skip`). Often exposed on a separate port or subdomain (e.g. `xconnect.target.com`). Common endpoints: `/xconnect/odata/contacts`, `/xconnect/odata/interactions`, `/xconnect/odata/campaigns`.
- **Publishing Service**: Sitecore Publishing Service uses its own API at `/sitecore/api/publishing/`. It's a separate module — not all Sitecore instances have it. Check for `PSA-*` cookies.
- **Horizon**: Newer editing interface replacing Experience Editor. Look for `/sitecore/horizon/` paths and `data-hz-*` HTML attributes. Horizon uses WebSocket connections for real-time editing.
- **SPEAK** (legacy): Older Sitecore UI framework. Look for `/sitecore/shell/~/xaml/` paths and SPEAK-specific JavaScript bundles. In use on older installations (pre-10.x) but still present in 10.x.
- **Packaging/xDB**: The Sitecore xDB (Experience Database) can leak via error pages exposing `xDB.ConnectionString` or `xConnect.SearchIndexer` in stack traces. Check for these on error pages.