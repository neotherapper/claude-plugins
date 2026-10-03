---
framework: adobe-experience-manager
version: "6.5+"
last_updated: "2026-05-11"
author: "@opencode"
status: community
---

# Adobe Experience Manager (AEM) — Tech Pack

Adobe Experience Manager is an enterprise CMS and digital asset management system built on Apache Sling and Jackrabbit/Oak.

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `<!-- CQ -->` comment | HTML | In page source or response | Definitive |
| `<!-- DAM -->` comment | HTML | DAM-specific pages | Definitive |
| `/crx/de/index.jsp` | Path | CRXDE Lite access | High |
| `/libs/granite/core/content/login.html` | Path | AEM login page | High |
| `Sling` in response headers | HTTP Header | `Sling` header or server signature | High |
| AEM selectors | URL | `.html`, `.json`, `.model.json`, `.infinity` | High |
| `/content/dam/` path | Path | DAM asset storage | High |
| `/apps/` path exposure | Path | Application path (if misconfigured) | Medium |
| AEM version comment | HTML | `<!-- Adobe Experience Manager -->` | Medium |

**Version extraction (bash):**

```bash
# Check for AEM version in HTML comments
curl -s https://target.example.com/ | grep -i 'CQ\|AEM\|Adobe\|sling'

# Check system console (requires auth in newer versions)
curl -sf --max-time 10 "https://target.example.com/system/console/about" | grep -i 'adobe\|aem\|version'

# Check package manager version
curl -sf --max-time 10 "https://target.example.com/packagemanager" | grep -i 'version'
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/api/assets/` | GET/POST | AEM User | DAM asset API |
| `/api/assets/*.json` | GET | None | JSON representation of assets |
| `/api/resources/` | GET | Varies | Sling resource API |
| `/content/dam/*.json` | GET | None | DAM asset metadata |
| `/bin/querybuilder.json` | GET | Session | AEM QueryBuilder API |
| `/libs/foundation/components/primary/*` | GET | Varies | Foundation components |
| `/apps/*/servlet/*` | Various | Varies | Custom servlets |
| `/api/workflow/*` | Various | Session | Workflow APIs |
| `/aem/start.html` | GET | None | AEM start screen |
| `/libs/granite/security/usermanager.*` | Various | Admin | User management |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `/crx/de/index.jsp` | Browser | CRXDE Lite (dev only) |
| `/system/console/bundles` | Browser | OSGi bundle status |
| `/system/console/configMgr` | Browser | OSGi configurations |
| `/content/geometrixx/*` | Browser | Demo content |
| `webapps` path | Server access | AEM webapp files |
| `crx-quickstart` | Server access | Repository and config |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| AEM cookie (`login-token`) | Cookie | Session-based authentication |
| Adobe IMS (OIDC) | External | Modern AEM Cloud |
| Basic Auth | Header | For service accounts |
| CSRF token (`granite.csrf.token`) | HTML/Header | POST request protection |
| Sling `sling:auth` | Content | Authentication requirements |

**CSRF token extraction:**

```bash
# Get CSRF token for subsequent requests
curl -s https://target.example.com/ | grep -o 'csrf.token[^"]*value="[^"]*"'
curl -s -c cookies.txt https://target.example.com/libs/granite/csrf/token.json
```

## 5. DAM Asset Patterns

| Path | Content |
|------|---------|
| `/content/dam/` | DAM root |
| `/content/dam/*.md` | Asset metadata |
| `/content/dam/*/jcr:content/renditions/*` | Asset renditions |
| `/api/assets/` | Asset API root |
| `/api/assets/*.json` | Asset JSON representation |

**Asset discovery:**

```bash
# List DAM root contents
curl -sf --max-time 10 "https://target.example.com/api/assets.json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for entity in d.get('entities', [])[:20]:
        print(entity.get('properties', {}).get('dc:title', entity.get('href', 'unknown')))
except: pass
"

# Get folder contents
curl -sf --max-time 10 "https://target.example.com/api/assets/[folder-path].json"
```

## 6. Content Fragment API

```bash
# List content fragments
curl -sf --max-time 10 "https://target.example.com/api/assets//content-fragments.json"

# Get specific fragment
curl -sf --max-time 10 "https://target.example.com/api/assets/[fragment-path].json"
```

## 7. QueryBuilder API

```bash
# Basic query
curl -sf --max-time 10 "https://target.example.com/bin/querybuilder.json?path=/content&type=cq:Page"

# Search for assets
curl -sf --max-time 10 "https://target.example.com/bin/querybuilder.json?type=dam:Asset&limit=20"

# Full-text search
curl -sf --max-time 10 "https://target.example.com/bin/querybuilder.json?fulltext=test&type=cq:Page"
```

## 8. Probe Checklist

**Phase 5 probes (run after fingerprinting AEM):**

```bash
TARGET="target.example.com"

# AEM specific endpoints
curl -sf --max-time 10 "https://${TARGET}/api/assets.json"
curl -sf --max-time 10 "https://${TARGET}/api/resources.json"
curl -sf --max-time 10 "https://${TARGET}/content/dam/"
curl -sf --max-time 10 "https://${TARGET}/bin/querybuilder.json"

# Login and auth endpoints
curl -sf --max-time 10 "https://${TARGET}/libs/granite/core/content/login.html"
curl -sf --max-time 10 "https://${TARGET}/crx/de/index.jsp"
curl -sf --max-time 10 "https://${TARGET}/libs/granite/csrf/token.json"

# DAM asset endpoints
curl -sf --max-time 10 "https://${TARGET}/content/dam/.assets.json"
curl -sf --max-time 10 "https://${TARGET}/api/assets/[folder-path].json"

# Common content paths
for path in geometrixx geometrixx-outdoors we-retail; do
  curl -sf --max-time 10 "https://${TARGET}/content/${path}.json"
  curl -sf --max-time 10 "https://${TARGET}/content/${path}/"
done
```

**What to log:**
- `[AEM-DETECTED:{version}]` when AEM is confirmed
- `[AEM-API:{endpoint}:{status}]` for each API probe
- `[AEM-AUTH:{type}]` for authentication patterns found
- `[AEM-DAM]` when DAM paths are discovered