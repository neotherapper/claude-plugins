---
framework: sveltekit
version: "2.0+"
last_updated: "2026-05-02"
author: "@opencode"
status: community
---

# SvelteKit — Tech Pack

SvelteKit is a full-stack meta-framework for building applications with Svelte, featuring file-based routing, server-side rendering, and API endpoints.

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `data-sveltekit-*` attributes | HTML attribute | `data-sveltekit-[key]="value"` in rendered markup | Definitive |
| `__SVELTEKIT__` global | JS global | Object present in page source | High |
| `/_app/immutable/` paths | Static files | Hashed asset paths in SvelteKit build | High |
| `+page.svelte` references | Source code | References in JS bundles or source maps | Medium |
| Svelte store patterns | JS bundle | `$:` reactive statements, `writable/readable` stores | Medium |
| Vite + SvelteKit patterns | Build output | Vite manifest with Svelte components | Medium |

**Version extraction (bash):**

```bash
# Check data-sveltekit attributes for version hints
curl -s https://target.example.com/ | grep -o 'data-sveltekit-[^=]*="[^"]*"' | head -5

# Check package.json if exposed
curl -sf https://target.example.com/package.json | grep -o '"@sveltejs/kit":"[^"]*"'

# Look for SvelteKit version in SSR payload
curl -s https://target.example.com/ | grep -o 'svelte-kit[^>]*' | head -3
```

## 2. Default API Surfaces

SvelteKit uses file-based API routes (`+server.js` files):

| Endpoint Pattern | Method | Auth | Notes |
|------------------|--------|------|-------|
| `/api/*` | Various | Varies | Traditional API routes (if used) |
| `/+server.js` routes | Various | Varies | File-based API endpoints |
| `/api/health` | GET | None | Health check endpoint |
| `/api/version` | GET | None | Version information |
| Form actions (`+page.server.js`) | POST | Session | Form submissions with CSRF protection |
| Load functions | GET | Varies | Data loading for pages/layouts |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.__SVELTEKIT__` | Browser console | SvelteKit runtime data |
| `data-sveltekit-*` attributes | HTML inspection | SSR hydration data, page ID, etc. |
| Vite manifest | `/_app/manifest.json` | Build asset mapping |
| SvelteKit hooks | Source if exposed | `src/hooks.server.js`, `src/hooks.client.js` |
| Environment variables | `.env` files if exposed | API keys, configuration |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| Cookie-based sessions | `session` cookie | SvelteKit's built-in session management |
| JWT tokens | `Authorization: Bearer` header | Common for API authentication |
| Form actions with CSRF | `+page.server.js` | Protected form submissions |
| OAuth/OIDC | `/auth/callback/*` | Third-party authentication flows |
| Lucia Auth patterns | If Lucia library used | Modern auth library for SvelteKit |

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `/_app/immutable/assets/*.js` | Hashed JavaScript bundles |
| `/_app/immutable/chunks/*.js` | Code-split chunks |
| `/_app/immutable/entry/*.js` | Entry point bundles |
| Source maps | `/_app/immutable/*.js.map` | Debug source maps |

**Bundle analysis:**

```bash
# Search for API endpoints in SvelteKit bundles
curl -s https://target.example.com/_app/immutable/assets/*.js 2>/dev/null | head -2000 | grep -o '"/api/[^"]*"' | sort -u

# Look for fetch patterns and endpoints
curl -s https://target.example.com/_app/immutable/entry/*.js 2>/dev/null | grep -o 'fetch("[^"]*"' | cut -d'"' -f2 | sort -u
```

## 6. Framework-Specific Endpoints

**SvelteKit file-based routing:**
- `GET /api/users` → `src/routes/api/users/+server.js`
- `POST /api/login` → `src/routes/api/login/+server.js`
- `GET /products/[slug]` → `src/routes/products/[slug]/+page.svelte`

**Common patterns:**
- `/api/auth/*` - Authentication endpoints
- `/api/users/*` - User management
- `/api/products/*` - Product catalog
- `/api/orders/*` - Order processing

## 7. Form Actions and Endpoints

SvelteKit form actions are special POST endpoints:

```bash
# Test for form action endpoints
curl -X POST https://target.example.com/?/actionName
curl -X POST https://target.example.com/some-page?/actionName

# Common form action patterns
for action in login register checkout contact; do
  curl -X POST "https://target.example.com/?/${action}"
done
```

## 8. Load Function Data Endpoints

SvelteKit load functions can expose data endpoints:

```bash
# Load function data endpoints (if enabled)
curl -H "Accept: application/json" https://target.example.com/some-page/__data.json
curl -H "Accept: application/json" https://target.example.com/api/__data.json
```

## 9. Probe Checklist

**Phase 5 probes (run after fingerprinting SvelteKit):**

```bash
TARGET="target.example.com"

# SvelteKit static assets
curl -sf "https://${TARGET}/_app/immutable/manifest.json"
curl -sf "https://${TARGET}/_app/version.json"

# API surface discovery
curl -sf "https://${TARGET}/api/"
curl -sf "https://${TARGET}/api/health"
curl -sf "https://${TARGET}/api/version"

# Form actions
curl -X POST -sf "https://${TARGET}/?/health"
curl -X POST -sf "https://${TARGET}/api?/test"

# Load function data
curl -H "Accept: application/json" -sf "https://${TARGET}/__data.json"
curl -H "Accept: application/json" -sf "https://${TARGET}/api/__data.json"

# Common API patterns
for endpoint in users products cart search orders auth; do
  curl -sf "https://${TARGET}/api/${endpoint}"
  curl -sf "https://${TARGET}/api/${endpoint}/"
done
```

**What to log:**
- `[SVELTEKIT-DETECTED:{version}]` when SvelteKit is confirmed
- `[SVELTEKIT-API:{endpoint}:{status}]` for each API probe
- `[SVELTEKIT-FORM-ACTION:{action}:{status}]` for form action tests
- `[SVELTEKIT-DATA-ENDPOINT:{endpoint}:{status}]` for load function data