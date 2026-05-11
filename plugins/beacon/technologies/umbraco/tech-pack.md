---
framework: umbraco
version: "10.x+"
last_updated: "2026-05-11"
author: "@opencode"
status: community
---

# Umbraco — Tech Pack

Umbraco is an open-source CMS built on ASP.NET.

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `<!--Umbraco-->` comment | HTML | In page source | Definitive |
| `UMB_UPDCHK` cookie | Cookie | Update check cookie | High |
| `UMB_SESSION` cookie | Cookie | Session cookie | High |
| `/umbraco/` path | URL | Umbraco backoffice | High |
| `umb` or `Umbraco` JS global | JS | JavaScript global | High |
| `data-umb-` attributes | HTML | Umbraco-specific attributes | Medium |
| `__CallBack` parameter | Form | Callback parameter | Medium |

**Version extraction (bash):**

```bash
# Check for Umbraco version in HTML comments
curl -s https://target.example.com/ | grep -i 'umbraco'

# Check Umbraco backoffice
curl -sf --max-time 10 "https://target.example.com/umbraco/" | grep -i 'version\|umbraco'

# Check login page
curl -sf --max-time 10 "https://target.example.com/umbraco/login" | grep -i 'version'
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/umbraco/api/` | Various | Auth/Varies | Backoffice API |
| `/umbraco/surface/` | Various | Varies | Surface controllers |
| `/api/members/` | GET/POST | Varies | Member API |
| `/api/content/` | GET/POST | Auth | Content API |
| `/api/media/` | GET/POST | Auth | Media API |
| `/Umbraco/Api/` | Various | Auth/Varies | Legacy API paths |
| `/api/forms/` | Various | Varies | Umbraco Forms API |
| `/backoffice/` | GET | Auth | Backoffice UI |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `/umbraco/` | Browser | Umbraco backoffice |
| `/Umbraco/` | Browser | Legacy backoffice |
| `web.config` | Server access | Main configuration |
| `appsettings.json` | Server access | .NET Core config |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| `__CallBack` parameter | Form | Callback authentication |
| `__RequestVerificationToken` | Form | CSRF token |
| `umb_auth` cookie | Cookie | Backoffice auth |
| `ASP.NET_SessionId` | Cookie | Session cookie |
| Bearer token | Header | API authentication |
| Member auth | Forms | Frontend members |

**API authentication:**

```bash
# Get backoffice token
curl -sf --max-time 10 -X POST "https://target.example.com/umbraco/backoffice/UmbracoApi/Authentication/GetCurrentUser" \
  -H "Content-Type: application/json"
```

## 5. Content API (Delivery API)

```bash
# Get content by path
curl -sf --max-time 10 "https://target.example.com/umbraco/delivery/api/v1/content/item/"

# Get specific item
curl -sf --max-time 10 "https://target.example.com/umbraco/delivery/api/v1/content/item/[path]"

# Get children
curl -sf --max-time 10 "https://target.example.com/umbraco/delivery/api/v1/content/children/[parent-path]"
```

## 6. Member API

```bash
# Get members
curl -sf --max-time 10 "https://target.example.com/api/members?pageSize=20"

# Get member by ID
curl -sf --max-time 10 "https://target.example.com/api/members/[id]"

# Get member groups
curl -sf --max-time 10 "https://target.example.com/api/member-groups"
```

## 7. Probe Checklist

**Phase 5 probes (run after fingerprinting Umbraco):**

```bash
TARGET="target.example.com"

# Umbraco backoffice paths
curl -sf --max-time 10 "https://${TARGET}/umbraco/"
curl -sf --max-time 10 "https://${TARGET}/Umbraco/"
curl -sf --max-time 10 "https://${TARGET}/umbraco/login"

# Delivery API
curl -sf --max-time 10 "https://${TARGET}/umbraco/delivery/api/v1/content/item/"
curl -sf --max-time 10 "https://${TARGET}/api/members"

# Surface controllers
curl -sf --max-time 10 "https://${TARGET}/umbraco/surface/"

# Common content paths
curl -sf --max-time 10 "https://${TARGET}/api/content"
curl -sf --max-time 10 "https://${TARGET}/api/media"

# Forms API
curl -sf --max-time 10 "https://${TARGET}/api/forms/"

# GraphQL (if enabled)
curl -sf --max-time 10 -X POST "https://${TARGET}/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { __typename }"}'

# Common Umbraco paths
for path in "home" "contact" "about" "news" "blog" "products"; do
  curl -sf --max-time 10 "https://${TARGET}/${path}"
  curl -sf --max-time 10 "https://${TARGET}/umbraco/delivery/api/v1/content/item/${path}"
done
```

**What to log:**
- `[UMBRACO-DETECTED:{version}]` when Umbraco is confirmed
- `[UMBRACO-API:{endpoint}:{status}]` for each API probe
- `[UMBRACO-DELIVERY-API]` if Delivery API is available
- `[UMBRACO-CLOUD]` if Umbraco Cloud hosting detected