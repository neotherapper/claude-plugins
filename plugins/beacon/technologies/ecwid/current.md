---
framework: ecwid
version: "current"
last_updated: "2026-04-28"
author: "@neotherapper"
status: official
---

# Ecwid / Lightspeed eCom — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `app.ecwid.com/script.js?{store_id}` in HTML | Script tag | Store-specific widget JS with numeric store ID in URL | Definitive |
| `static.ecwid.com` in HTML | CDN hostname | Static assets CDN present in `<script src>` or `<link href>` | Definitive |
| `window.Ecwid` JS global | JS global | Object present in page source or browser console | Definitive |
| `window.ec` JS global | JS global | Ecwid store config object present in page source | Definitive |
| `Ecwid.init()` call in HTML | JS call | Initialization call with store config object | Definitive |
| `ecwidProductBrowser` or `ecwid-ProductBrowser` element | DOM element | Product browser container div in page HTML | Definitive |
| `store_id` numeric value in script URL | URL parameter | Numeric store ID extracted from `script.js?{store_id}` | Definitive |
| `ecwid-` prefixed CSS classes | HTML source | Ecwid-injected class names present in rendered HTML | High |
| `PSecwid__*PScart` cookie | Cookie | Ecwid cart session cookie | High |
| `PSecwid__customer__sessionPScheck` cookie | Cookie | Ecwid customer session check cookie | High |
| `d3j86k3yi748nz.cloudfront.net` in HTML | CDN hostname | Ecwid assets CloudFront CDN | High |
| `data_platform=code` parameter in script URL | URL parameter | Additional parameter in script src alongside store_id (e.g. `script.js?1003&data_platform=code`) | Medium |
| Wappalyzer detection | Browser extension | Wappalyzer categorizes site as Ecwid/Lightspeed eCom | High |

**Extract store_id and Ecwid config from HTML:**

```bash
# Extract store_id from script tag URL (most reliable):
curl -s https://STORE_DOMAIN/ | grep -oP 'app\.ecwid\.com/script\.js\?\K[0-9]+'

# Extract store_id from window.ec config object:
curl -s https://STORE_DOMAIN/ | grep -oP '"storeId"\s*:\s*\K[0-9]+'

# Extract store_id from Ecwid.init() call:
curl -s https://STORE_DOMAIN/ | grep -oP 'Ecwid\.init\(\{"storeId"\s*:\s*\K[0-9]+'

# Capture full window.ec config block:
curl -s https://STORE_DOMAIN/ | grep -oP 'window\.ec\s*=\s*\{[^<]+' | head -c 500

# Extract public token if embedded in page source (prefix: public_):
curl -s https://STORE_DOMAIN/ | grep -oP 'public_[A-Za-z0-9]+'
```

**Note on Instant Site:** Ecwid Instant Site uses the same `app.ecwid.com/script.js?{store_id}` fingerprint as embedded stores. The JS API method set available on Instant Site is limited (fewer event and management methods), but the REST API surface and fingerprinting signals are identical to a regular embedded store.

## 2. Default API Surfaces

> **Critical:** All Ecwid REST API v3 endpoints require at minimum a **public access token** (`Authorization: Bearer public_...`). There is no truly unauthenticated endpoint — the store_id alone is insufficient for any REST API call. Public tokens grant read-only access and are safe to embed in client-side code.

### Public-Token Endpoints (public `public_...` token — `read_catalog` / `public_storefront` scope)

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://app.ecwid.com/api/v3/{store_id}/profile` | GET | `Bearer public_...` | Returns limited store profile: store ID, website URL, platform, Instant Site settings; full profile (company address, payment methods, social links) requires a private token with `read_store_profile` scope |
| `https://app.ecwid.com/api/v3/{store_id}/products` | GET | `Bearer public_...` | Full enabled product catalog; paginated; requires `public_storefront` scope |
| `https://app.ecwid.com/api/v3/{store_id}/products/{id}` | GET | `Bearer public_...` | Single product with variants (`combinations` array), images, attributes |
| `https://app.ecwid.com/api/v3/{store_id}/products/{id}/combinations` | GET | `Bearer public_...` | Dedicated endpoint for all variations of a product; returns same data as `combinations` array in product response |
| `https://app.ecwid.com/api/v3/{store_id}/categories` | GET | `Bearer public_...` | Full category tree; requires `public_storefront` scope |

**Finding the public token:** Some stores embed the public token in page source via `Ecwid.getAppPublicToken('app-client-id')` or `window.instantsite.getAppPublicToken('client_id')` (Instant Site). Search page source for `public_` to locate it. The token is intentionally safe to expose client-side.

### Private Endpoints (OAuth secret token — app install required)

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://app.ecwid.com/api/v3/{store_id}/profile` (full) | GET | `Authorization: Bearer {secret_token}` | Full profile with company address, payment methods enabled, social links, currency — requires `read_store_profile` scope |
| `https://app.ecwid.com/api/v3/{store_id}/orders` | GET | `Authorization: Bearer {secret_token}` | Requires app installation in store control panel |
| `https://app.ecwid.com/api/v3/{store_id}/customers` | GET | `Authorization: Bearer {secret_token}` | Requires app installation in store control panel |
| `https://app.ecwid.com/api/v3/{store_id}/discount_coupons` | GET | `Authorization: Bearer {secret_token}` | Requires app installation in store control panel |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.ec.config` | View page source or browser console | `storeId`, `apiHost`, `chameleon` (font/color theme), `storefrontUrls` (hreflang, internationalPages), `store_main_page_url` |
| `window.ec.storefront` | View page source or browser console | Design configuration settings; changes require `Ecwid.refreshConfig()` to apply |
| `window.Ecwid` | Browser console | Full Ecwid widget object; methods, event handlers, `Ecwid.getOwnerId()` returns store ID |
| `app.ecwid.com/script.js?{store_id}` URL | View page source | Store ID embedded directly in script src attribute; may include `&data_platform=code` suffix |
| `Ecwid.init({...})` call | View page source | Store ID and initial widget configuration |
| `/api/v3/{store_id}/profile` response | API call (public token) | Limited: store ID, website URL, platform; full data requires private token |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| Public token (`public_...`) | `Authorization: Bearer public_...` HTTP header | Read-only access to enabled products, categories, and limited store profile. Safe to use client-side. Obtained when an installed app requests `public_storefront` scope. |
| Secret/private token | `Authorization: Bearer {secret_token}` HTTP header | Full read/write access; requires OAuth app install by merchant; never safe to expose publicly |
| Public token in page source | View page source; search for `public_` | Some stores expose the public token in embedded app JS; use `Ecwid.getAppPublicToken()` call or grep for `public_[A-Za-z0-9]+` |
| `store_id` in script URL | View page source | Required as URL path parameter for all API calls, but NOT sufficient on its own — a token is always needed |

**OAuth flow for private endpoints:**
Private API access requires installing an OAuth app through the Ecwid (Lightspeed eCom) app marketplace or control panel. This is not feasible for passive reconnaissance — the merchant must authorize the app. There is no credential to extract from the page source that grants private endpoint access.

**Public token reconnaissance path:**
1. Extract `store_id` from script tag
2. Search page source for `public_[A-Za-z0-9]+` pattern
3. If found, use it as `Bearer public_...` to call products, categories, and limited profile endpoints

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `https://app.ecwid.com/script.js?{store_id}` | Main Ecwid widget JS; store-specific; loaded per store ID; may include `&data_platform=code` |
| `https://static.ecwid.com/` | Ecwid static assets CDN |
| `https://d3j86k3yi748nz.cloudfront.net/` | Ecwid assets via AWS CloudFront CDN |

The store ID in the `script.js` URL is unique per store and is the primary key for all API calls. There are no webpack build artifacts to enumerate — Ecwid is a hosted widget loaded from `app.ecwid.com`. The `Ecwid.getOwnerId()` JS method also returns the store ID at runtime.

## 6. Source Map Patterns

Ecwid is a hosted, closed-source widget. The `app.ecwid.com/script.js` bundle is minified and obfuscated. Source maps are not exposed publicly.

```bash
# Probe for source maps on the widget bundle (expected: 404):
curl -I "https://app.ecwid.com/script.js?{store_id}.map"
```

No source maps are available for Ecwid's widget JS. If the host site uses its own build tooling (e.g., WordPress, Wix, or a custom site embedding Ecwid), source maps for the host site's own JS may be present — probe those separately based on the host CMS fingerprint.

## 7. Common Plugins & Integrations

| App/Integration | API it adds | Detection signal |
|-----------------|-------------|------------------|
| Mailchimp | Email marketing sync | `mailchimp.com` script in HTML |
| Kliken | Google Shopping / ads | `kliken.com` script in HTML |
| ShipStation | Order fulfillment | No front-end signal; back-end integration only |
| PayPal | Payment widget | `paypalobjects.com` or `paypal.com` script in HTML |
| Stripe | Payment widget | `js.stripe.com` script in HTML |
| Facebook Pixel | Conversion tracking | `connect.facebook.net` script in HTML |
| Google Analytics | Analytics | `googletagmanager.com` or `analytics.js` in HTML |
| TaxJar | Tax calculation | No front-end signal; back-end integration only |
| WordPress (WP e-Commerce plugin) | Host CMS embeds Ecwid | `wp-content/` paths in HTML alongside Ecwid signals |
| Wix | Host site platform | Wix fingerprints (`static.wixstatic.com`) alongside Ecwid signals |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `/api/v3/{store_id}/profile` | Store ID, website URL, platform, Instant Site settings | Requires public token; limited data — company address, social links, payment methods only accessible with private token |
| `/api/v3/{store_id}/products?limit=100&offset=0` | Full enabled product catalog: names, prices, SKUs, images, descriptions, inventory | Paginated with `offset`; increment by `limit` value; requires public token |
| `/api/v3/{store_id}/products?enabled=true&limit=100&sortBy=ADDED_TIME_DESC` | Recently added active products | Sorted by addition time descending; requires public token |
| `/api/v3/{store_id}/products?category={N}&limit=100` | Products filtered by category ID | Use category IDs from the categories endpoint; requires public token |
| `/api/v3/{store_id}/products/{id}` | Single product detail including `combinations` array (variants by size/color) | Product variants in `combinations` field; requires public token |
| `/api/v3/{store_id}/products/{id}/combinations` | All product variations for a product: id, combinationNumber, options[], sku, price, inStock, sku, weight, dimensions | Dedicated variations endpoint; same auth as products; `combinations` terminology retained in API path for backward compat |
| `/api/v3/{store_id}/categories` | Full category tree with IDs, names, parent IDs, URLs | Use category IDs to filter product queries; requires public token |

**Products endpoint as search:** The `/products` endpoint serves as the search/filter endpoint. Key filter params: `keyword` (text search), `category` (category ID), `enabled` (true/false), `sortBy` (ADDED_TIME_DESC, PRICE_ASC, etc.), `limit` (max 100), `offset` (pagination).

## 9. Probe Checklist

- [ ] `GET {site}` — grep HTML for `app.ecwid.com/script.js` to confirm Ecwid fingerprint; extract store_id from URL
- [ ] Verify store_id via secondary signals — `window.ec.config.storeId`, `Ecwid.init({storeId:...})`, or `"storeId":` in page source
- [ ] Search page source for `public_[A-Za-z0-9]+` — extract public token if present (required for REST API calls)
- [ ] `GET https://app.ecwid.com/api/v3/{store_id}/profile` with `Authorization: Bearer {public_token}` — store ID, website URL, platform; note that full company/payment data needs private token
- [ ] `GET https://app.ecwid.com/api/v3/{store_id}/categories` with public token — full category tree; note category IDs for product filtering
- [ ] `GET https://app.ecwid.com/api/v3/{store_id}/products?limit=100&offset=0` with public token — first page of product catalog
- [ ] Paginate products — increment `offset` by 100 until response `items` array is shorter than `limit`
- [ ] `GET https://app.ecwid.com/api/v3/{store_id}/products?enabled=true&limit=100&sortBy=ADDED_TIME_DESC` — most recently added active products
- [ ] For each category ID: `GET /api/v3/{store_id}/products?category={N}&limit=100` — products by category
- [ ] Inspect product responses for `combinations` array — variant data (options[], sku, price, stock, weight)
- [ ] Optionally hit `/api/v3/{store_id}/products/{id}/combinations` directly for a product's full variation list
- [ ] Check for `PSecwid__*PScart` and `PSecwid__customer__sessionPScheck` cookies — confirm active Ecwid session
- [ ] Fingerprint host CMS separately — Ecwid is embedded; the host may be WordPress, Wix, Squarespace, or a plain HTML site

## 10. Gotchas

- **All REST API endpoints require at least a public token — store_id alone is not enough:** Unlike the widget JS (which loads with just the store_id), every REST API call requires `Authorization: Bearer {token}`. The minimum is a public token (`public_...`). Search page source for `public_[A-Za-z0-9]+` to find it. Without a token, all API calls return 401.

- **Public token vs private token:** A public token (`public_...`) grants read-only access to enabled products, categories, and a limited store profile (ID, URL, platform). It is safe to embed in client-side JS. A private/secret token grants full access including orders, customers, coupons, and the full profile. Private tokens require merchant OAuth authorization and cannot be obtained passively.

- **store_id is always in the page source — it is public:** The `store_id` appears in `<script src="https://app.ecwid.com/script.js?{store_id}">`. It is intentionally public and required for the widget to load. It is the path key for all API calls but is NOT an auth credential.

- **Script URL may include `&data_platform=code`:** The script src sometimes appears as `https://app.ecwid.com/script.js?1003&data_platform=code`. The store_id is always the first numeric parameter immediately after `?`. Adjust extraction regex accordingly.

- **`combinations` is the API name; docs call them "product variations":** Ecwid renamed "product combinations" to "product variations" in their UI and docs, but all API endpoints and response fields still use `combinations` for backward compatibility. The path is `/products/{id}/combinations` and the field in the product response is `combinations`.

- **There is a dedicated variations endpoint:** Besides the `combinations` array in a product response, you can call `GET /api/v3/{store_id}/products/{id}/combinations` directly for a full list of all variations for a product.

- **Ecwid is embedded — fingerprint it separately from the host CMS:** Ecwid can live inside WordPress, Wix, Squarespace, Webflow, or a plain HTML page. The presence of Ecwid signals does not indicate a standalone Ecwid storefront. Always fingerprint the host platform independently and record both.

- **The API lives at `app.ecwid.com`, not the store domain:** All API calls go to `https://app.ecwid.com/api/v3/{store_id}/...` regardless of the store's custom domain. The rebranding to Lightspeed eCom (2022) did not change any API URLs, script URLs, or CDN hostnames — everything still uses `ecwid.com`.

- **Instant Site has a limited JS API but identical REST API surface:** Instant Site restricts the set of Storefront JS API methods available (fewer event triggers and management methods). The REST API endpoints, auth patterns, and fingerprinting signals are identical to an embedded store. Use `window.instantsite.getAppPublicToken()` instead of `Ecwid.getAppPublicToken()` on Instant Site pages.

- **Cookie names use `PSecwid__` prefix, not `xProduct`:** The documented Ecwid session and cart cookies are `PSecwid__*PScart` (cart session) and `PSecwid__customer__sessionPScheck` (customer session check). The `xProduct` cookie name cited in older documentation could not be verified and should not be relied on as a fingerprinting signal.

- **Pagination uses `offset` and `limit`:** Products are paginated with `?limit=100&offset=0`. Increment `offset` by `limit` on each request until the returned `items` count is less than `limit`. There is no cursor-based pagination. Maximum `limit` is 100.

- **Rate limit is 600 req/min — with hard failure on bad tokens:** The public API allows 600 requests per minute. Exceeding this returns HTTP 429 with a `Retry-After` header. Additionally, if more than 20 req/min or 600 total requests arrive with a non-working token, the IP is blocked for an extended period. Use valid tokens and respect the limit.

- **`profile` endpoint returns limited data with public token:** With a public token, `/profile` returns only store ID, website URL, platform type, and Instant Site settings. Company address, social links, enabled payment methods, and currency are only available with a private token that has `read_store_profile` scope. Do not assume the public-token profile response is the complete picture.
