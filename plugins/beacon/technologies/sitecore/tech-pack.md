---
framework: sitecore
version: "10.x+"
last_updated: "2026-05-11"
author: "@opencode"
status: community
---

# Sitecore — Tech Pack

Sitecore is an enterprise CMS and digital experience platform built on ASP.NET.

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `<!-- Sitecore -->` comment | HTML | In page source | Definitive |
| `SC_ANALYTICS` cookie | Cookie | Analytics tracking cookie | High |
| `/sitecore/` path | URL | Sitecore admin/shell | High |
| `sc_site` query param | URL | Sitecore context site identification | High |
| `Sitecore` in HTML | HTML | Various Sitecore markers | High |
| `sc_device` patterns | HTML | Device detection markers | Medium |
| Sitecore.LayoutService | JS | Layout service client | Medium |
| `__RequestVerificationToken` | Form | CSRF token field | Medium |

**Version extraction (bash):**

```bash
# Check for Sitecore version in HTML comments
curl -s https://target.example.com/ | grep -i 'sitecore'

# Check Sitecore login page
curl -sf --max-time 10 "https://target.example.com/sitecore/login" | grep -i 'sitecore\|version'

# Check for Sitecore version in response headers
curl -I --max-time 10 "https://target.example.com/" 2>/dev/null | grep -i 'sitecore'
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/sitecore/api/layout/render/*` | GET | Varies | Layout Service |
| `/sitecore/api/items/*` | GET/POST | Varies | Item Service |
| `/sitecore/api/graph/` | POST | Auth | GraphQL endpoint |
| `/sitecore/shell/api/medialib/*` | GET | Auth | Media Library API |
| `/sitecore/api/managed/*` | Various | Auth | Managed database API |
| `/sitecore/api/analytics/*` | GET | Auth | Analytics APIs |
| `/sitecore/api/jss/*` | GET | Varies | JSS API (if using JSS) |
| `/api/sitecore/*` | Various | Varies | Custom Web API routes |
| `-/api/items/*` | GET | None | Content API (Next.js) |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `/sitecore/` | Browser | Sitecore admin shell |
| `/sitecore/shell/` | Browser | Sitecore desktop |
| `/sitecore/login` | Browser | Login page |
| `/sitecore/admin/` | Browser | Admin tools |
| `web.config` | Server access | Main configuration |
| `App_Config/` | Server access | Configuration includes |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| `__RequestVerificationToken` | Form field | CSRF protection |
| Sitecore Identity Server | External | Modern auth (Sitecore 10+) |
| Extranet匿名用户 | Cookie | Anonymous user cookie |
| `sc_token` | Header | API authentication |
| Basic Auth | Header | For service accounts |

**CSRF token extraction:**

```bash
# Get form token
curl -s https://target.example.com/ | grep -o '__RequestVerificationToken[^"]*value="[^"]*"'

# Get Sitecore token for API
curl -s -X POST "https://target.example.com/sitecore/api/auth/login" -d "username=admin&password=password"
```

## 5. Layout Service API

```bash
# Render layout for item
curl -sf --max-time 10 "https://target.example.com/sitecore/api/layout/render/item?item=/&database=master"
curl -sf --max-time 10 "https://target.example.com/sitecore/api/layout/render/item?item=/&database=web"

# With naming convention
curl -sf --max-time 10 "https://target.example.com/sitecore/api/layout/render/item?item=/path&sc_apikey={key}"
```

## 6. Item Service API

```bash
# Get item by path
curl -sf --max-time 10 "https://target.example.com/sitecore/api/items/-/items?path=/"

# Get item children
curl -sf --max-time 10 "https://target.example.com/sitecore/api/items/-/children?path=/"

# Get item by ID
curl -sf --max-time 10 "https://target.example.com/sitecore/api/items/$(uuid)"
```

## 7. JSS (JavaScript Services) API

```bash
# JSS Layout Service
curl -sf --max-time 10 "https://target.example.com/-/jss/?query=..."

# JSS API for Next.js
curl -sf --max-time 10 "https://target.example.com/-/api/items/[id]"
curl -sf --max-time 10 "https://target.example.com/-/api/items/[id]?format=json"
```

## 8. Probe Checklist

**Phase 5 probes (run after fingerprinting Sitecore):**

```bash
TARGET="target.example.com"

# Sitecore admin paths
curl -sf --max-time 10 "https://${TARGET}/sitecore/"
curl -sf --max-time 10 "https://${TARGET}/sitecore/login"
curl -sf --max-time 10 "https://${TARGET}/sitecore/shell/"

# Layout Service
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/render/item?item=/"
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/render/item?item=/home"

# Item Service
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/items/-/items?path=/"
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/items/-/children?path=/"

# JSS API (if using JavaScript Services)
curl -sf --max-time 10 "https://${TARGET}/-/jss/"
curl -sf --max-time 10 "https://${TARGET}/-/api/items/"

# GraphQL
curl -sf --max-time 10 "https://${TARGET}/sitecore/api/graph/"
curl -sf --max-time 10 "https://${TARGET}/graph/api/endpoint"

# Common content paths
for path in "home" "Products" "Services" "News" "About"; do
  curl -sf --max-time 10 "https://${TARGET}/${path}"
  curl -sf --max-time 10 "https://${TARGET}/sitecore/api/layout/render/item?item=/${path}"
done
```

**What to log:**
- `[SITECORE-DETECTED:{version}]` when Sitecore is confirmed
- `[SITECORE-API:{endpoint}:{status}]` for each API probe
- `[SITECORE-AUTH:{type}]` for authentication patterns found
- `[SITECORE-JSS]` if JSS is detected