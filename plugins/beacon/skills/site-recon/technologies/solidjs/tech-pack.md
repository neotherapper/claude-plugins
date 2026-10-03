---
framework: solidjs
version: "1.0+"
last_updated: "2026-05-02"
author: "@opencode"
status: community
---

# SolidJS — Tech Pack

SolidJS is a reactive JavaScript framework for building user interfaces with fine-grained reactivity.

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `Solid` JS object | JS global | Object present in page source | Definitive |
| `createSignal`, `createEffect` functions | JS global | Functions present in global scope | High |
| `data-solid` attributes in HTML | HTML attribute | `data-solid="true"` in rendered markup | High (SSR) |
| SolidStart meta tags | HTML meta | `<meta name="framework" content="solid">` | Medium |
| Vite + Solid build patterns | Build output | `/src/**/*.jsx` or `/src/**/*.tsx` references | Medium |
| Solid Router patterns | URL structure | Client-side routing with hash or history API | Medium |

**Version extraction (bash):**

```bash
# Check for Solid version in HTML comments or JS bundles
curl -s https://target.example.com/ | grep -i 'solid\|solidjs'

# Check JS bundles for version strings
curl -s https://target.example.com/assets/index.*.js | grep -o '"solid":"[^"]*"' || true
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/api/` | GET/POST | Varies | API routes (SolidStart or custom backend) |
| `/graphql` | POST | Varies | GraphQL endpoint if used |
| `/auth/*` | GET/POST | None/Credentials | Authentication endpoints |
| `/api/trpc/*` | POST | Varies | tRPC endpoints if used |
| `/api/rpc/*` | POST | Varies | JSON-RPC endpoints |
| `/api/health` | GET | None | Health check endpoint |
| `/api/version` | GET | None | Version information |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.Solid` | Browser console | Solid runtime object |
| `window.__SOLID_DEVTOOLS__` | Browser console | Solid DevTools extension data |
| Vite manifest | `/dist/.vite/manifest.json` | Build asset mapping |
| SolidStart config | View page source | SSR hydration data |
| Environment variables | `.env` files if exposed | API keys, configuration |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| JWT tokens | `Authorization: Bearer` header | Common for API authentication |
| Cookie-based auth | `sessionid` or custom cookies | Server-side sessions |
| OAuth/OIDC | `/auth/callback/*` endpoints | Third-party authentication |
| API keys | `X-API-Key` header | Service-to-service authentication |

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `/dist/assets/index.*.js` | Main application bundle |
| `/dist/assets/vendor.*.js` | Vendor dependencies |
| `/src/**/*.jsx` | Source files (if exposed) |
| `/src/**/*.tsx` | TypeScript source files |

**Bundle analysis:**

```bash
# Search for API endpoints in JS bundles
curl -s https://target.example.com/dist/assets/index.*.js | grep -o '"/api/[^"]*"' | sort -u

# Look for authentication patterns
curl -s https://target.example.com/dist/assets/index.*.js | grep -o 'Authorization\|Bearer\|session\|token' | sort -u
```

## 6. Framework-Specific Endpoints

**SolidStart (meta-framework):**
- `/api/*` - API routes (file-based)
- `/server/*` - Server functions
- `/trpc/*` - tRPC procedures

**Common patterns:**
- `/api/users` - User management
- `/api/products` - Product catalog
- `/api/orders` - Order processing
- `/api/search` - Search functionality

## 7. E-commerce Integration Patterns

When SolidJS is used for e-commerce:

| Endpoint | Purpose | Typical Response |
|----------|---------|------------------|
| `/api/products` | Product listing | JSON array of products |
| `/api/products/:id` | Single product | JSON object |
| `/api/cart` | Shopping cart | JSON cart object |
| `/api/checkout` | Checkout initiation | JSON with checkout URL |
| `/api/search?q=` | Product search | JSON search results |

## 8. Probe Checklist

**Phase 5 probes (run after fingerprinting SolidJS):**

```bash
TARGET="target.example.com"

# API surface discovery
curl -sf "https://${TARGET}/api/"
curl -sf "https://${TARGET}/api/health"
curl -sf "https://${TARGET}/api/version"

# GraphQL endpoint
curl -sf -X POST "https://${TARGET}/graphql" -H "Content-Type: application/json" -d '{"query":"query { __typename }"}'

# Common API patterns
for endpoint in users products cart search orders; do
  curl -sf "https://${TARGET}/api/${endpoint}"
done

# SolidStart specific
curl -sf "https://${TARGET}/api/trpc/health"
curl -sf "https://${TARGET}/server/api/health"
```

**What to log:**
- `[SOLIDJS-DETECTED:{version}]` when SolidJS is confirmed
- `[SOLIDJS-API:{endpoint}:{status}]` for each API probe
- `[SOLIDJS-AUTH:{pattern}]` for authentication patterns found