---
framework: saleor
version: "3.22.x / 3.23"
last_updated: "2026-04-28"
author: "@neotherapper"
status: official
---

# Saleor — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `POST /graphql/` responds with JSON | HTTP probe | GraphQL JSON response body | Definitive (when confirmed as Saleor) |
| `*.saleor.cloud` domain | Domain pattern | Hostname ends in `.saleor.cloud` | Definitive |
| `GET /.well-known/jwks.json` returns JWKS JSON | HTTP GET | Public key set for JWS webhook signatures | High |
| `__typename: "Shop"` in introspection | GraphQL response | `{ __typename }` returns `"Shop"` type present | High |
| GraphQL Playground or GraphiQL at `/graphql/` | Browser / HTTP | Interactive IDE served at `/graphql/` | High |
| `/dashboard/` returns Saleor login page | HTTP GET | React SPA login screen (conventional default; path is configurable) | High |
| `@saleor/sdk` in JS bundle | JS bundle string | `@saleor/sdk` substring | High |
| Next.js `__NEXT_DATA__` with `apiUrl` pointing to `/graphql/` | JS global | `window.__NEXT_DATA__.runtimeConfig.apiUrl` | High |
| `Saleor-Event` header on webhook receiver POST | HTTP header | Webhook event type header on incoming Saleor webhooks | High (webhook receivers) |
| `X-Saleor-*` response headers | HTTP header | Legacy `X-Saleor-` prefixed headers (deprecated; still common pre-4.0) | Medium |
| `/_next/` paths present | URL pattern | Next.js static assets | Medium (frontend only) |
| Vercel deployment headers (`x-vercel-*`) | HTTP header | Vercel CDN headers | Medium (storefront only) |

**Version / instance extraction:**
```bash
# Confirm GraphQL endpoint and get shop info
curl -s -X POST {site}/graphql/ \
  -H "Content-Type: application/json" \
  -d '{"query":"{ shop { name domain { host } version } }"}' | python3 -m json.tool

# Check for JWKS endpoint — strong Saleor signal
curl -sI {site}/.well-known/jwks.json

# Extract apiUrl from Next.js storefront
curl -s {storefront}/ | grep -oP '"apiUrl":"\K[^"]+'
```

## 2. Default API Surfaces

Saleor is GraphQL-first — **the entire API surface is a single endpoint**.

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/graphql/` | POST | None / Bearer | Main API endpoint; JSON body with `query` key |
| `/graphql/` | GET | None | Serves GraphQL Playground / GraphiQL (browser) |
| `/dashboard/` | GET | None | Admin SPA login page; conventional default path (configurable via `APP_MOUNT_URI`) |
| `/.well-known/jwks.json` | GET | None | Public key set for JWS RS256 webhook signature verification |
| `/openid-connect/` | GET | None | OpenID Connect discovery (if OIDC plugin active) |
| `/.well-known/openid-configuration` | GET | None | OIDC config (if plugin active) |
| `/api/webhooks/` | POST | HMAC / JWS | Saleor App webhook receiver (Next.js storefront) |
| `/plugins/mirumee.payments.adyen/webhook/` | POST | Plugin | Adyen payment plugin webhook |
| `/plugins/mirumee.payments.braintree/webhook/` | POST | Plugin | Braintree payment plugin webhook |

**Key public GraphQL queries:**
```graphql
# Shop metadata
{ shop { name domain { host } defaultCountry { code } version } }

# Schema introspection — full type list
{ __schema { types { name kind } } }

# Confirm GraphQL (works even if introspection is disabled)
{ __typename }

# Products — channel slug required for pricing
{ products(first: 10, channel: "default-channel") {
    edges { node { name slug pricing { priceRange { start { gross { amount currency } } } } } }
  }
}

# Categories with hierarchy
{ categories(first: 20) {
    edges { node { id name slug level children { edges { node { name slug } } } } }
  }
}

# Collections
{ collections(first: 20, channel: "default-channel") {
    edges { node { id name slug } }
  }
}

# Attributes
{ attributes(first: 20) {
    edges { node { id name slug type } }
  }
}

# Channels (requires staff auth; default-channel is a safe guess for public queries)
{ channels { id name slug currencyCode } }
```

## 3. Config / Constants Locations

| Location | What's there | How to access |
|----------|-------------|---------------|
| `{ shop { ... } }` GraphQL query | Shop name, domain, default country, version, languages | Public GraphQL POST |
| `window.__NEXT_DATA__.runtimeConfig.apiUrl` | GraphQL API endpoint URL | JS eval in storefront browser |
| `window.__NEXT_DATA__.props` | Storefront runtime props including channel config | JS eval in storefront browser |
| `/graphql/` introspection | Full schema — all types, queries, mutations, subscriptions | Public GraphQL POST (unless disabled) |
| `/.well-known/openid-configuration` | OIDC issuer, token endpoint, JWKS URI | Public GET (if OIDC plugin active) |
| Dashboard `/dashboard/apps/` | Installed apps with webhook URLs and permissions | Staff auth required |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| Customer JWT (`tokenCreate` mutation) | `Authorization: Bearer {token}` | Short-lived; refresh with `tokenRefresh` |
| Staff JWT (same mutation, higher perms) | `Authorization: Bearer {token}` | Same endpoint; permissions determined by account role |
| App token | `Authorization: Bearer {app_token}` | Per-app; granular permissions set in dashboard; created via `appTokenCreate` or at app install |
| Webhook HMAC-SHA256 (`Saleor-Signature`) | Request header on incoming webhooks | Used when webhook `secretKey` is set; `X-Saleor-Signature` is the legacy alias (deprecated, removed in 4.0) |
| Webhook JWS RS256 (`Saleor-Signature`) | Request header on incoming webhooks | Used when no `secretKey` is set; detached-payload JWS; verify public key from `/.well-known/jwks.json` |

**Customer / staff JWT acquisition:**
```graphql
mutation {
  tokenCreate(email: "user@example.com", password: "secret") {
    token
    refreshToken
    errors { field message }
    user { id email }
  }
}
```

**Token refresh:**
```graphql
mutation {
  tokenRefresh(refreshToken: "{refreshToken}") {
    token
    errors { field message }
  }
}
```

**Token verify:**
```graphql
mutation {
  tokenVerify(token: "{token}") {
    isValid
    payload
    user { id email }
    errors { field message }
  }
}
```

**App tokens** are created in the dashboard under `Apps > {App} > App tokens`. Pass as a Bearer token in the `Authorization` header. Permissions are scoped per app.

## 5. JS Bundle Patterns

Saleor is headless — the storefront is a separate frontend application (official Saleor Storefront uses Next.js; community frontends may use Remix or other frameworks).

| Path | Content |
|------|---------|
| `/_next/static/chunks/*.js` | Next.js compiled app chunks |
| `/_next/static/chunks/pages/_app*.js` | Next.js app-level bootstrap (contains `apiUrl`) |
| `/_next/static/chunks/framework*.js` | React / Next.js framework bundle |
| `/_next/data/{buildId}/index.json` | Next.js SSR data for home page |
| `/_next/static/{buildId}/_buildManifest.js` | Full list of Next.js routes |

Check each bundle for `@saleor/sdk` string to confirm official storefront.
Check `window.__NEXT_DATA__.runtimeConfig.apiUrl` for the GraphQL endpoint URL.

## 6. Source Map Patterns

Saleor's official storefront may ship source maps in staging/development builds.

Check: `{bundle}.js.map` — if 200, recover original TypeScript source paths.
Look for: `//# sourceMappingURL=` comment at the end of each JS bundle chunk.
In Next.js: source maps appear at `/_next/static/chunks/{chunk}.js.map`.

## 7. Common Extensions & Apps

| Extension | API / Webhook it adds | Detection signal |
|-----------|----------------------|-----------------|
| Adyen payment plugin | `/plugins/mirumee.payments.adyen/webhook/` | Plugin webhook path in network traffic |
| Braintree payment plugin | `/plugins/mirumee.payments.braintree/webhook/` | Plugin webhook path |
| OpenID Connect plugin | `/openid-connect/` and `/.well-known/openid-configuration` | OIDC discovery endpoint returns 200 |
| Saleor Apps (marketplace apps) | `/api/webhooks/` on the storefront | Webhook receiver in Next.js API routes |
| Custom Saleor Apps | Varies — check dashboard under Apps | App tokens listed per-app in dashboard |

## 8. Known Public Data

| Query / Endpoint | Data | Notes |
|----------|------|-------|
| `{ shop { name domain { host } defaultCountry { code } version } }` | Instance identity and version | Always public |
| `{ categories(first:100) { edges { node { id name slug level } } } }` | Full category tree with IDs | Public; use IDs for product filtering |
| `{ collections(first:100, channel:"default-channel") { edges { node { id name slug } } } }` | All collections | Requires channel |
| `{ attributes(first:100) { edges { node { id name slug type inputType } } } }` | Product attribute schema | Public; reveals product data model |
| `{ products(first:100, channel:"default-channel") { edges { node { name slug } } } }` | Product catalog | Channel required; empty result means wrong slug or no products — Saleor does not distinguish these by design |
| `{ __schema { types { name kind fields { name } } } }` | Full GraphQL schema | May be disabled in production |
| `/dashboard/` | Saleor admin login SPA | Confirms Saleor; no credentials needed |

## 9. Probe Checklist

Run these in order. Record result (✓ 200 / ✗ 403 / -- 404) for each.

- [ ] `POST {site}/graphql/` with `{"query":"{ __typename }"}` — confirm GraphQL responds (Definitive)
- [ ] `POST {site}/graphql/` with `{"query":"{ shop { name domain { host } version } }"}` — shop identity
- [ ] `GET {site}/.well-known/jwks.json` — JWKS public key set; 200 with JSON is a strong Saleor signal
- [ ] `POST {site}/graphql/` with `{"query":"{ __schema { types { name kind } } }"}` — full schema introspection
- [ ] `POST {site}/graphql/` with categories query (`first:100`) — category tree with IDs
- [ ] `POST {site}/graphql/` with collections query (`channel:"default-channel"`) — collections list
- [ ] `POST {site}/graphql/` with attributes query (`first:100`) — attribute schema
- [ ] `POST {site}/graphql/` with products query (`channel:"default-channel"`) — product catalog; empty result does not confirm wrong slug (Saleor silences wrong-slug errors by design)
- [ ] `POST {site}/graphql/` with `{"query":"{ channels { id name slug currencyCode } }"}` — enumerate channels (may require staff auth; 200 with empty = auth needed)
- [ ] `GET {site}/dashboard/` — Saleor admin login page (conventional default; if 404 also try `{site}/`); note response
- [ ] `GET {site}/.well-known/openid-configuration` — OIDC config (200 = OIDC plugin active)
- [ ] `GET {storefront}/` — check for `__NEXT_DATA__` and `apiUrl` in HTML source
- [ ] `GET {storefront}/_next/static/chunks/pages/_app*.js` — extract `apiUrl` and `@saleor/sdk` presence
- [ ] `GET {site}/graphql/` in browser — check for GraphQL Playground / GraphiQL UI
- [ ] `HEAD {site}/graphql/` — check response headers for `Saleor-Signature` or legacy `X-Saleor-*`
- [ ] `GET {storefront}/api/webhooks/` — Saleor App webhook receiver endpoint

## 10. Gotchas

- **Separate domains for API and storefront.** Saleor's Django API and the Next.js storefront commonly run on different domains (e.g., `api.example.com` for GraphQL and `www.example.com` for the storefront). Always probe both independently. Saleor Cloud uses `*.saleor.cloud` for the API.
- **Channel slug is required for most storefront data.** Products, collections, and pricing all require a `channel` argument. `"default-channel"` is the conventional slug but is not guaranteed. An empty `edges` array does not distinguish "wrong channel slug" from "no products in this channel" — Saleor returns empty silently on a wrong slug by design to prevent channel enumeration. The reliable ways to discover the actual slug are: reading `window.__NEXT_DATA__` or `NEXT_PUBLIC_SALEOR_API_URL` config on the storefront, querying `{ channels { slug } }` with staff auth, or finding the slug in the dashboard.
- **Introspection may be disabled in production.** A `{ __typename }` probe confirms the GraphQL endpoint is live even when introspection is turned off. An introspection error does not mean the endpoint is blocked.
- **Staff-only queries return empty data, not 403.** Saleor silently returns `null` or an empty edges array for queries requiring staff permissions rather than a 403 error. Absence of data is not proof the endpoint is inaccessible.
- **Relay-style pagination.** Saleor uses cursor-based pagination (`first`, `last`, `before`, `after`) — not page numbers. To page through results, use `pageInfo { hasNextPage endCursor }` and pass `after: "{endCursor}"` in the next request.
- **The dashboard path is configurable, not fixed.** `/dashboard/` is the conventional default set by `APP_MOUNT_URI` in the dashboard build, but operators can mount the dashboard at any path (e.g., `/admin/`, `/`). If `GET {site}/dashboard/` returns 404, check the JS bundle for `APP_MOUNT_URI` or try the root `/`. Login credentials are not default values; do not attempt brute-force or stuffing.
- **Saleor Cloud domain is a Definitive signal.** Any `*.saleor.cloud` hostname is a Saleor Cloud API instance. The custom storefront domain may be on a CDN (Vercel, Cloudflare) with no Saleor-specific headers.
- **App tokens are per-application with granular permissions.** Unlike a global API key, each Saleor App has its own token and permission scope. Token enumeration from the dashboard is required to understand the full access surface.
- **`product.pricing` is null without channel context.** A product node without a price in a given channel returns `pricing: null`. This is expected — the product exists but is not listed in that channel.
- **Webhook signatures have two modes and a header rename.** When a webhook `secretKey` is set, Saleor signs with HMAC-SHA256. When no `secretKey` is set, Saleor uses JWS RS256 with a detached payload; the verifier must fetch the public key from `GET {api}/.well-known/jwks.json`. The header in current 3.x is `Saleor-Signature` (no `X-` prefix). The legacy `X-Saleor-Signature` is deprecated and will be removed in Saleor 4.0; both headers are sent during the transition period.
- **Auto-checkout completion (3.23+).** If the `automaticCompletion` flag is enabled on a channel's `CheckoutSettings`, Saleor can complete a checkout without an explicit `checkoutComplete` mutation call. Once auto-completed, the `Checkout` object is deleted and any subsequent queries or mutations on that checkout ID return errors or the previously created `Order`. Be aware when probing checkout flows on 3.23+ instances.

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
import sys, hashlib, base64
data = sys.stdin.buffer.read()
# Simple mmh3 hash simulation using Python
import mmh3 2>/dev/null || pip install mmh3
# Or use: python3 -c "import mmh3; print(mmh3.hash(data))"
print('Favicon hash needed for Shodan search: icon_hash')
"

# Search Shodan for same favicon (indicates shadow IT subdomains)
# site:shodan.io search: icon_hash:{hash}
```

**What it reveals:** Hidden subdomains running same framework stack as main site.

### Source Map Discovery

Check for source maps across all JS bundles:

```bash
# Extract all JS bundle URLs from HTML
curl -s "https://{domain}/" | grep -oP 'src="[^"]+\.js[^"]*"' | grep -oP '"[^"]+' | tr -d '"' > js_urls.txt

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
