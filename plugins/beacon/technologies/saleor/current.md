---
framework: saleor
version: "current"
last_updated: "2026-04-28"
author: "@neotherapper"
status: official
---

# Saleor — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `POST /graphql/` responds with JSON | HTTP probe | GraphQL JSON response body | Definitive (when confirmed as Saleor) |
| `X-Saleor-*` response headers | HTTP header | Any `X-Saleor-` prefixed header | Definitive |
| `*.saleor.cloud` domain | Domain pattern | Hostname ends in `.saleor.cloud` | Definitive |
| `__typename: "Shop"` in introspection | GraphQL response | `{ __typename }` returns `"Shop"` type present | High |
| GraphQL Playground or GraphiQL at `/graphql/` | Browser / HTTP | Interactive IDE served at `/graphql/` | High |
| `/dashboard/` returns Saleor login page | HTTP GET | React SPA login screen | High |
| `@saleor/sdk` in JS bundle | JS bundle string | `@saleor/sdk` substring | High |
| Next.js `__NEXT_DATA__` with `apiUrl` pointing to `/graphql/` | JS global | `window.__NEXT_DATA__.runtimeConfig.apiUrl` | High |
| `/_next/` paths present | URL pattern | Next.js static assets | Medium (frontend only) |
| Vercel deployment headers (`x-vercel-*`) | HTTP header | Vercel CDN headers | Medium (storefront only) |

**Version / instance extraction:**
```bash
# Confirm GraphQL endpoint and get shop info
curl -s -X POST {site}/graphql/ \
  -H "Content-Type: application/json" \
  -d '{"query":"{ shop { name domain { host } version } }"}' | python3 -m json.tool

# Check for Saleor Cloud domain pattern
curl -sI {site}/graphql/ | grep -i "x-saleor"

# Extract apiUrl from Next.js storefront
curl -s {storefront}/ | grep -oP '"apiUrl":"\K[^"]+'
```

## 2. Default API Surfaces

Saleor is GraphQL-first — **the entire API surface is a single endpoint**.

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/graphql/` | POST | None / Bearer | Main API endpoint; JSON body with `query` key |
| `/graphql/` | GET | None | Serves GraphQL Playground / GraphiQL (browser) |
| `/dashboard/` | GET | None | Admin SPA login page; always at this path |
| `/openid-connect/` | GET | None | OpenID Connect discovery (if OIDC plugin active) |
| `/.well-known/openid-configuration` | GET | None | OIDC config (if plugin active) |
| `/api/webhooks/` | POST | HMAC | Saleor App webhook receiver (Next.js storefront) |
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
| App token | `Authorization: Bearer {app_token}` | Per-app; granular permissions set in dashboard |
| Webhook HMAC (`X-Saleor-Signature`) | Request header on incoming webhooks | Verify Saleor event webhooks with app secret |

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
| `{ products(first:100, channel:"default-channel") { edges { node { name slug } } } }` | Product catalog | Channel required; empty result = wrong channel slug |
| `{ __schema { types { name kind fields { name } } } }` | Full GraphQL schema | May be disabled in production |
| `/dashboard/` | Saleor admin login SPA | Confirms Saleor; no credentials needed |

## 9. Probe Checklist

Run these in order. Record result (✓ 200 / ✗ 403 / -- 404) for each.

- [ ] `POST {site}/graphql/` with `{"query":"{ __typename }"}` — confirm GraphQL responds (Definitive)
- [ ] `POST {site}/graphql/` with `{"query":"{ shop { name domain { host } version } }"}` — shop identity
- [ ] `POST {site}/graphql/` with `{"query":"{ __schema { types { name kind } } }"}` — full schema introspection
- [ ] `POST {site}/graphql/` with categories query (`first:100`) — category tree with IDs
- [ ] `POST {site}/graphql/` with collections query (`channel:"default-channel"`) — collections list
- [ ] `POST {site}/graphql/` with attributes query (`first:100`) — attribute schema
- [ ] `POST {site}/graphql/` with products query (`channel:"default-channel"`) — product catalog
- [ ] `POST {site}/graphql/` with `{"query":"{ channels { id name slug currencyCode } }"}` — enumerate channels (may require staff auth; 200 with empty = auth needed)
- [ ] `GET {site}/dashboard/` — Saleor admin login page (confirms Saleor; note response)
- [ ] `GET {site}/.well-known/openid-configuration` — OIDC config (200 = OIDC plugin active)
- [ ] `GET {storefront}/` — check for `__NEXT_DATA__` and `apiUrl` in HTML source
- [ ] `GET {storefront}/_next/static/chunks/pages/_app*.js` — extract `apiUrl` and `@saleor/sdk` presence
- [ ] `GET {site}/graphql/` in browser — check for GraphQL Playground / GraphiQL UI
- [ ] `HEAD {site}/graphql/` — check response headers for `X-Saleor-*`
- [ ] `GET {storefront}/api/webhooks/` — Saleor App webhook receiver endpoint

## 10. Gotchas

- **Separate domains for API and storefront.** Saleor's Django API and the Next.js storefront commonly run on different domains (e.g., `api.example.com` for GraphQL and `www.example.com` for the storefront). Always probe both independently. Saleor Cloud uses `*.saleor.cloud` for the API.
- **Channel slug is required for most storefront data.** Products, collections, and pricing all require a `channel` argument. `"default-channel"` is the convention but is not guaranteed. If product queries return an empty edges array, try enumerating channels or guessing common slugs (`default`, `usd`, `eur`, `en`).
- **Introspection may be disabled in production.** A `{ __typename }` probe confirms the GraphQL endpoint is live even when introspection is turned off. An introspection error does not mean the endpoint is blocked.
- **Staff-only queries return empty data, not 403.** Saleor silently returns `null` or an empty edges array for queries requiring staff permissions rather than a 403 error. Absence of data is not proof the endpoint is inaccessible.
- **Relay-style pagination.** Saleor uses cursor-based pagination (`first`, `last`, `before`, `after`) — not page numbers. To page through results, use `pageInfo { hasNextPage endCursor }` and pass `after: "{endCursor}"` in the next request.
- **The dashboard path is fixed.** `/dashboard/` is always the Saleor admin path — it is not randomized. Login credentials are not default values; do not attempt brute-force or stuffing.
- **Saleor Cloud domain is a Definitive signal.** Any `*.saleor.cloud` hostname is a Saleor Cloud API instance. The custom storefront domain may be on a CDN (Vercel, Cloudflare) with no Saleor-specific headers.
- **App tokens are per-application with granular permissions.** Unlike a global API key, each Saleor App has its own token and permission scope. Token enumeration from the dashboard is required to understand the full access surface.
- **`product.pricing` is null without channel context.** A product node without a price in a given channel returns `pricing: null`. This is expected — the product exists but is not listed in that channel.
- **Webhook signatures use HMAC-SHA256.** Saleor signs outbound webhook events with `X-Saleor-Signature`. Verify using the app's signing secret from the dashboard.
