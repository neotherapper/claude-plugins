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
| `xProduct` cookie | Cookie | Ecwid session cookie set on product interaction | High |
| `d3j86k3yi748nz.cloudfront.net` in HTML | CDN hostname | Ecwid assets CloudFront CDN | High |
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
```

## 2. Default API Surfaces

### Public Endpoints (no auth — store_id required)

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://app.ecwid.com/api/v3/{store_id}/profile` | GET | None | Store name, URL, company info, social links, payment settings |
| `https://app.ecwid.com/api/v3/{store_id}/products` | GET | None | Full product catalog; paginated; always public |
| `https://app.ecwid.com/api/v3/{store_id}/products/{id}` | GET | None | Single product with variants, images, attributes |
| `https://app.ecwid.com/api/v3/{store_id}/categories` | GET | None | Full category tree; always public |

### Private Endpoints (OAuth token required)

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://app.ecwid.com/api/v3/{store_id}/orders` | GET | `Authorization: Bearer {token}` | Requires app installation in store control panel |
| `https://app.ecwid.com/api/v3/{store_id}/customers` | GET | `Authorization: Bearer {token}` | Requires app installation in store control panel |
| `https://app.ecwid.com/api/v3/{store_id}/discount_coupons` | GET | `Authorization: Bearer {token}` | Requires app installation in store control panel |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.ec` | View page source or browser console | `storeId`, `apiHost`, `productBrowserUrl`, store config |
| `window.Ecwid` | Browser console | Full Ecwid widget object; methods, event handlers |
| `app.ecwid.com/script.js?{store_id}` URL | View page source | Store ID embedded directly in script src attribute |
| `Ecwid.init({...})` call | View page source | Store ID and initial widget configuration |
| `/api/v3/{store_id}/profile` response | API call (no auth) | Store name, URL, company info, currency, social links, payment methods |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| No auth (store_id only) | URL path parameter | Products, categories, and profile endpoints are fully public — store_id is the only credential needed |
| `Authorization: Bearer {token}` | HTTP request header | Private endpoints (orders, customers, coupons); requires OAuth app installed in merchant's control panel |
| Public token in page source | View page source | Some stores expose a partial read-only public token in HTML; search page source for `publicToken` |

**OAuth flow for private endpoints:**
Private API access requires installing an OAuth app through the Ecwid (Lightspeed eCom) app marketplace or control panel. This is not feasible for passive reconnaissance — the merchant must authorize the app. There is no credential to extract from the page source that grants private endpoint access.

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `https://app.ecwid.com/script.js?{store_id}` | Main Ecwid widget JS; store-specific; loaded per store ID |
| `https://static.ecwid.com/` | Ecwid static assets CDN |
| `https://d3j86k3yi748nz.cloudfront.net/` | Ecwid assets via AWS CloudFront CDN |

The store ID in the `script.js` URL is unique per store and is the primary key for all API calls. There are no webpack build artifacts to enumerate — Ecwid is a hosted widget loaded from `app.ecwid.com`.

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
| `/api/v3/{store_id}/profile` | Store name, URL, company info, currency, language, social links, payment methods enabled | High-value recon — no auth required |
| `/api/v3/{store_id}/products?limit=100&offset=0` | Full product catalog: names, prices, SKUs, images, descriptions, inventory | Paginated with `offset`; increment by `limit` value |
| `/api/v3/{store_id}/products?enabled=true&limit=100&sortBy=ADDED_TIME_DESC` | Recently added active products | Sorted by addition time descending |
| `/api/v3/{store_id}/products?category={N}&limit=100` | Products filtered by category ID | Use category IDs from the categories endpoint |
| `/api/v3/{store_id}/products/{id}` | Single product detail including `combinations` array (variants by size/color) | Product variants are in the `combinations` field |
| `/api/v3/{store_id}/categories` | Full category tree with IDs, names, parent IDs, URLs | Use category IDs to filter product queries |

## 9. Probe Checklist

- [ ] `GET {site}` — grep HTML for `app.ecwid.com/script.js` to confirm Ecwid fingerprint; extract store_id from URL
- [ ] Verify store_id via secondary signals — `window.ec.storeId`, `Ecwid.init({storeId:...})`, or `"storeId":` in page source
- [ ] `GET https://app.ecwid.com/api/v3/{store_id}/profile` — store name, URL, company info, payment settings (always public; start here)
- [ ] `GET https://app.ecwid.com/api/v3/{store_id}/categories` — full category tree; note category IDs for product filtering
- [ ] `GET https://app.ecwid.com/api/v3/{store_id}/products?limit=100&offset=0` — first page of product catalog
- [ ] Paginate products — increment `offset` by 100 until response `items` array is shorter than `limit`
- [ ] `GET https://app.ecwid.com/api/v3/{store_id}/products?enabled=true&limit=100&sortBy=ADDED_TIME_DESC` — most recently added active products
- [ ] For each category ID from step 3: `GET /api/v3/{store_id}/products?category={N}&limit=100` — products by category
- [ ] Inspect product responses for `combinations` array — variant data (size, color, SKU, price, stock)
- [ ] Search page source for `publicToken` — some stores expose a partial read-only API token in HTML
- [ ] Check `xProduct` cookie for active session state
- [ ] Fingerprint host CMS separately — Ecwid is embedded; the host may be WordPress, Wix, Squarespace, or a plain HTML site

## 10. Gotchas

- **store_id is always in the page source:** The `store_id` appears in the `<script src="https://app.ecwid.com/script.js?{store_id}">` tag. It is intentionally public — it must be visible for the widget to load. It is the only key needed to access all public API endpoints.

- **Products and categories are fully public:** Unlike most e-commerce platforms, Ecwid exposes its full product catalog and category tree with zero authentication. Any store's entire inventory can be enumerated with just the store_id. This is by design — Ecwid's architecture relies on client-side rendering with public API calls.

- **Ecwid is embedded — fingerprint it separately from the host CMS:** Ecwid can live inside WordPress, Wix, Squarespace, Webflow, or a plain HTML page. The presence of Ecwid signals does not indicate a standalone Ecwid storefront. Always fingerprint the host platform independently and record both.

- **The API lives at `app.ecwid.com`, not the store domain:** All API calls go to `https://app.ecwid.com/api/v3/{store_id}/...` regardless of the store's custom domain. Never try to hit the store domain for API endpoints.

- **Ecwid rebranded to Lightspeed eCom in 2022:** The API URL, script URLs, and CDN hostnames all still use `ecwid.com`. Documentation may use either brand name. The technical fingerprints and API surfaces are unchanged.

- **Pagination uses `offset` and `limit`:** Products are paginated with `?limit=100&offset=0`. Increment `offset` by `limit` on each request until the returned `items` count is less than `limit`. There is no cursor-based pagination.

- **Product variants are in `combinations`:** Each product response includes a `combinations` array listing all variant combinations (size, color, etc.) with their own SKU, price, stock, and weight. Do not treat the top-level product as the full picture if `combinations` is non-empty.

- **Private endpoints require merchant-authorized OAuth:** Orders, customers, and coupons are gated behind OAuth tokens that require the merchant to install an app in their control panel. These cannot be obtained through passive reconnaissance — the merchant must explicitly grant access.

- **Rate limit is generous but real:** The public API allows 600 requests per minute. Avoid aggressive enumeration that approaches this limit. For large catalogs, spread requests and use `limit=100` (the maximum per page).

- **`profile` endpoint is the highest-value starting point:** The profile endpoint returns the store name, canonical URL, company address, social media links, enabled payment methods, and currency — rich reconnaissance data with no auth required. Always query it first.
