---
framework: optimizely
version: "12.x+"
last_updated: "2026-05-11"
author: "@opencode"
status: community
---

# Optimizely (Episerver) — Tech Pack

Optimizely (formerly Episerver) is an enterprise CMS and digital experience platform.

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `EPiServer` cookie | Cookie | Session/main cookie | Definitive |
| `<!--.episerver-->` comment | HTML | In page source | Definitive |
| `/episerver/` path | URL | Episerver admin | High |
| `/Util/` path | URL | Optimizely admin tools | High |
| `EPiServer` in HTML | HTML | Various markers | High |
| `ContentReference` patterns | Code | Content references | Medium |
| `ContentDeliveryAPI` | API | `/api/episerver/v3/` | Medium |

**Version extraction (bash):**

```bash
# Check for Optimizely version in HTML comments
curl -s https://target.example.com/ | grep -i 'episerver\|optimizely'

# Check Episerver root
curl -sf --max-time 10 "https://target.example.com/episerver/" | grep -i 'version'

# Check util login
curl -sf --max-time 10 "https://target.example.com/Util/Login" | grep -i 'episerver\|version'
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/api/episerver/v3/` | GET | Varies | Content Delivery API |
| `/episerverapi/` | Various | Auth | Content Management API |
| `/api/episerver/search/` | GET | Varies | Optimizely Find search |
| `/api/episerver/commerce/` | Various | Auth | Commerce API |
| `/cms/admin/` | GET | Auth | CMS admin |
| `/episerver/Shell/` | GET | Auth | Shell UI |
| `/Util/` | GET | Auth | Admin tools |
| `/epi-ui/` | GET | Auth | UI resources |
| `/Modules/` | GET | Varies | Installed modules |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `/episerver/` | Browser | Episerver admin |
| `/Util/` | Browser | Admin tools |
| `/cms/admin/` | Browser | CMS admin panel |
| `web.config` | Server access | Main configuration |
| `modules/` | Server access | Module configurations |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| `EPiServer` cookie | Cookie | Forms authentication |
| `.ASPXROLES` cookie | Cookie | Role-based auth |
| OAuth token | Header | API access |
| Basic Auth | Header | Service accounts |
| API key | Header | Content Delivery API |

**API authentication:**

```bash
# Get API token for Content Delivery API
curl -sf --max-time 10 -X POST "https://target.example.com/episerverapi/token" \
  -d "grant_type=client_credentials&client_id=xxx&client_secret=xxx"
```

## 5. Content Delivery API

```bash
# Get content by path
curl -sf --max-time 10 "https://target.example.com/api/episerver/v3/content?contentLink=/"

# Get children
curl -sf --max-time 10 "https://target.example.com/api/episerver/v3/content/children?contentLink=/"

# Get descendants
curl -sf --max-time 10 "https://target.example.com/api/episerver/v3/content/descendants?contentLink=/"
```

## 6. Search API (Find)

```bash
# Search content
curl -sf --max-time 10 "https://target.example.com/api/episerver/search/?q=test"

# Search with filters
curl -sf --max-time 10 "https://target.example.com/api/episerver/search/?q=test&limit=10"
```

## 7. Probe Checklist

**Phase 5 probes (run after fingerprinting Optimizely):**

```bash
TARGET="target.example.com"

# Optimizely admin paths
curl -sf --max-time 10 "https://${TARGET}/episerver/"
curl -sf --max-time 10 "https://${TARGET}/Util/"
curl -sf --max-time 10 "https://${TARGET}/cms/admin/"

# Content Delivery API
curl -sf --max-time 10 "https://${TARGET}/api/episerver/v3/content?contentLink=/"
curl -sf --max-time 10 "https://${TARGET}/api/episerver/v3/content/children?contentLink=/"

# Search API
curl -sf --max-time 10 "https://${TARGET}/api/episerver/search/?q=test"

# GraphQL (if enabled)
curl -sf --max-time 10 -X POST "https://${TARGET}/api/episerver/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { __typename }"}'

# Common content paths
for path in "" "en/" "news/" "products/" "about/" "util/"; do
  curl -sf --max-time 10 "https://${TARGET}/${path}"
  curl -sf --max-time 10 "https://${TARGET}/api/episerver/v3/content?contentLink=/${path}"
done
```

**What to log:**
- `[OPTIMIZELY-DETECTED:{version}]` when Optimizely is confirmed
- `[OPTIMIZELY-API:{endpoint}:{status}]` for each API probe
- `[OPTIMIZELY-DXP]` if DXP hosting detected