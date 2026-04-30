---
framework: wix
version: "current"
last_updated: "2026-04-28"
author: "@neotherapper"
status: official
---

# Wix Stores — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `wix.com` or `wixsite.com` domain | Domain | Site is hosted on Wix's own domain | Definitive |
| `static.wixstatic.com` in HTML | HTML source | Wix user-asset CDN hostname in `<img src>`, `<script src>`, or `<link href>` | Definitive |
| `window.Wix` JS global | JS global | Object present in page source or browser console | Definitive |
| `X-Wix-Application-Instance-Id` response header | HTTP header | Present on responses from Wix-hosted sites | Definitive |
| `x-wix-request-id` response header | HTTP header | Unique request-trace header Wix injects on every response; documented in Wix support tooling | High |
| `/_api/wix-ecommerce-storefront-web/api` in network | Network request | POST target visible in browser DevTools network tab | Definitive (Wix Stores) |
| `wix-stores` in HTML or script tags | HTML source | String present in page markup or script attributes | High |
| `wixstores` in JSON responses | JSON body | Key or value present in API JSON responses | High |
| `fedops.wix.com` or `bi.wix.com` analytics scripts | Script tag | Wix platform analytics loaded via script tag | High |
| `fedops.logger.sessionId` cookie | Cookie jar | First-party Wix resilience/analytics cookie set on all Wix sites | High |
| `.wix.com` in canonical URL meta tags | HTML source | `<link rel="canonical">` or `<meta property="og:url">` contains `.wix.com` | High |
| `<meta http-equiv="X-Wix-Meta-Site-Id">` in HTML | HTML source | Meta tag injected by Wix renderer; contains metaSiteId value directly | High |
| `wixBiSession` object in page source | HTML source | BI/analytics session bootstrap object embedded in inline `<script>`; always present on Wix pages | High |
| Wappalyzer detection | Browser extension | Wappalyzer identifies Wix or Wix Stores | High |

**Extract Wix instance and site IDs from HTML:**

```bash
# Extract window.__wix_site__ bootstrap data from page source:
curl -s {site} | grep -oP 'window\.__wix_site__\s*=\s*\{[^<]+' | head -c 500

# Extract metaSiteId from JSON bootstrap — required for some internal API calls:
curl -s {site} | grep -oP '"metaSiteId"\s*:\s*"\K[^"]+'

# Extract metaSiteId from meta tag (alternative path — check both):
curl -s {site} | grep -oP '<meta[^>]+X-Wix-Meta-Site-Id[^>]+content="\K[^"]+'

# Extract siteId:
curl -s {site} | grep -oP '"siteId"\s*:\s*"\K[^"]+'

# Check for X-Wix response headers (both confirmed signals):
curl -sI {site} | grep -i "x-wix"
```

## 2. Default API Surfaces

### Internal Storefront API (browser-observable, unauthenticated)

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `{site}/_api/wix-ecommerce-storefront-web/api` | POST | `XSRF-TOKEN` cookie + `X-XSRF-TOKEN` header | Main GraphQL-like internal storefront API; observable via browser DevTools |
| `{site}/_api/wix-ecommerce-reader/v1/catalog/products/query` | POST | `XSRF-TOKEN` cookie + `X-XSRF-TOKEN` header | Product catalog query; paginated; body `{"query":{}}` returns all products |
| `{site}/_api/wix-ecommerce-reader/v1/catalog/categories/query` | POST | `XSRF-TOKEN` cookie + `X-XSRF-TOKEN` header | Category listing; body `{"query":{}}` returns all categories |
| `{site}/_api/wix-stores-web/api/v1/stores/settings` | GET | `svSession` cookie | Store settings including currency, locale, shipping |
| `{site}/sitemap.xml` | GET | None | Wix sitemap index; links to individual per-product-type sitemaps |
| `{site}/store-products-sitemap.xml` | GET | None | Dedicated Wix Stores product sitemap; direct enumeration of all product page URLs |

### Official Wix Stores REST API — Catalog V1 (OAuth or API Key)

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://www.wixapis.com/stores/v1/products/query` | POST | OAuth Bearer or API Key | Query product catalog; current stable endpoint |
| `https://www.wixapis.com/stores/v1/collections/query` | POST | OAuth Bearer or API Key | Query collections |
| `https://www.wixapis.com/stores/v1/inventory/query` | POST | OAuth Bearer or API Key | Query inventory |

### Official Wix Stores REST API — Catalog V3 (rolling out 2025, beta then GA)

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://www.wixapis.com/stores/v3/products/query` | POST | OAuth Bearer or API Key | Query products; more detailed variant + inventory model than V1 |
| `https://www.wixapis.com/stores/v3/products/search` | POST | OAuth Bearer or API Key | Free-text product search; must specify `search.fields` |
| `https://www.wixapis.com/stores/v3/products/count` | POST | OAuth Bearer or API Key | Count products matching filter |
| `https://www.wixapis.com/stores/v3/products/slug/{slug}` | GET | OAuth Bearer or API Key | Get product by URL slug |

Catalog V3 replaces Catalog V1 over time. New users get V3 by default; existing stores migrate. V1 remains supported during transition.

### Official Wix eCommerce REST API — Cart / Checkout / Orders

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://www.wixapis.com/ecom/v1/carts/{id}/create-checkout` | POST | OAuth Bearer or API Key | Convert cart to checkout |
| `https://www.wixapis.com/ecom/v1/checkouts/{id}/checkout-url` | GET | OAuth Bearer or API Key | Get checkout URL |
| `https://www.wixapis.com/ecom/v1/orders/query` | POST | OAuth Bearer or API Key | Query orders |

Note: The eCommerce API (`/ecom/v1/`) manages cart, checkout, and orders. The Stores API (`/stores/v1/` and `/stores/v3/`) manages the product catalog and inventory. These are distinct namespaces on the same platform.

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.__wix_site__` | View page source or browser console | Site ID, meta site ID, locale, currency, site name |
| `window.Wix` | Browser console | Wix platform SDK object; exposes instance data and event hooks |
| `wixBiSession` | Inline `<script>` in page source | BI/analytics session object; contains `viewerSessionId`, `initialTimestamp`, and service topology URLs |
| `"metaSiteId"` in page source | `grep -oP '"metaSiteId"\s*:\s*"\K[^"]+'` | Unique site identifier required for some internal API calls |
| `<meta http-equiv="X-Wix-Meta-Site-Id">` | Page `<head>` meta tag | Alternative extraction path for metaSiteId; check this if JSON grep fails |
| `"siteId"` in page source | `grep -oP '"siteId"\s*:\s*"\K[^"]+'` | Site-level ID distinct from metaSiteId |
| `svSession` cookie | Browser cookie jar | Session token for internal API authentication |
| `XSRF-TOKEN` cookie | Browser cookie jar | CSRF token; must also be sent as `X-XSRF-TOKEN` request header on all internal POSTs |
| Inline `<script>` tags in HTML | View page source | Wix app configuration, instance IDs, Google Analytics IDs often co-located |
| `static.parastorage.com` scripts | Script tag | Wix static platform assets; version info embedded in CDN path |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| `svSession` cookie | Cookie jar | Session token extracted from browser; required for internal storefront API calls |
| `XSRF-TOKEN` cookie | Cookie jar | CSRF token; must match `X-XSRF-TOKEN` request header on all internal POST requests |
| `X-XSRF-TOKEN: TOKEN` | HTTP request header | Must be sent alongside `XSRF-TOKEN` cookie for all internal POST endpoints |
| `Authorization: Bearer ACCESS_TOKEN` | HTTP request header | Official Wix REST API via OAuth 2.0; obtained through Wix app installation flow |
| `Authorization: <API_KEY>` + `wix-site-id: <SITE_ID>` | HTTP request headers | API key auth for official REST API; no OAuth app installation needed; generated via Wix dashboard API Key Manager |
| `Authorization: <API_KEY>` + `wix-account-id: <ACCOUNT_ID>` | HTTP request headers | API key auth for account-level REST API calls |

**API key authentication (simpler than OAuth for merchant-owned access):**

```bash
# Site-level REST API call using an API key (no OAuth app installation required):
curl -s -X POST 'https://www.wixapis.com/stores/v1/products/query' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: <YOUR_API_KEY>' \
  -H 'wix-site-id: <SITE_ID>' \
  -d '{"query":{}}'
```

**Extract session tokens from a live browser session (internal APIs):**

```bash
# Internal APIs require the XSRF token as both a cookie and a header.
# Capture these from browser DevTools (Application > Cookies) or a live curl session:

# Test internal product query with session tokens (replace TOKEN and SESSION values):
curl -s -X POST '{site}/_api/wix-ecommerce-reader/v1/catalog/products/query' \
  -H 'Content-Type: application/json' \
  -H 'X-XSRF-TOKEN: {xsrf_token}' \
  -b 'XSRF-TOKEN={xsrf_token}; svSession={sv_session}' \
  -d '{"query":{}}'

# Store settings (GET, svSession cookie only):
curl -s '{site}/_api/wix-stores-web/api/v1/stores/settings' \
  -b 'svSession={sv_session}'
```

Note: The internal Wix APIs are not officially documented. Cookie values are tied to a browser session and expire. The official REST API (OAuth or API key) is the only stable, supported integration path.

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `https://static.parastorage.com/...` | Wix platform static assets CDN; core Wix runtime JS |
| `https://static.wixstatic.com/...` | User-uploaded assets; product images, theme media |
| `https://siteassets.parastorage.com/...` | Site-specific assets built and hosted by Wix |
| `https://apps.wixstatic.com/{app_id}/...` | Individual Wix app bundles (Wix Stores, Wix Bookings, etc.); app_id is a UUID |
| `https://bo.wix.com/...` | Wix back-office assets |
| `@wix/sdk` | npm package | Wix JS SDK for headless; manages authentication and platform communication |
| `@wix/stores` | npm package | Wix Stores module for the JS SDK; exposes `queryProducts()` and catalog operations |

Wix also offers a headless commerce path via the JavaScript SDK (`@wix/sdk`, `@wix/stores` npm packages). When a Wix site is accessed as a headless frontend (e.g., Next.js), the network requests will target the official REST API rather than the internal `/_api/` paths. Detect the SDK via the npm packages in `package.json` or lock files.

Extract actual script URLs from HTML `<script src>` tags — app UUIDs in CDN paths are app-specific and must be read from the live page. Wix compiles and hosts all JS; there is no merchant-controlled webpack build.

## 6. Source Map Patterns

Wix-hosted JS bundles are compiled and minified by Wix's build system. Source maps are generally **not** exposed on production CDN assets.

**Check for source maps on Wix CDN assets:**

```bash
# Extract a Wix platform script URL from page source:
SCRIPT_URL=$(curl -s {site} | grep -oP 'https://static\.parastorage\.com/[^"]+\.js' | head -1)

# Probe for a .map file:
curl -I "${SCRIPT_URL}.map"

# Check for SourceMap header on a known bundle:
curl -sI "${SCRIPT_URL}" | grep -i sourcemap
```

Source maps are not available on standard Wix-hosted stores. Wix does not expose build artifacts or source maps through any documented mechanism.

## 7. Common Plugins & Extensions

| App/Integration | API it adds | Detection signal |
|-----------------|-------------|------------------|
| Wix Bookings | Appointment scheduling; `/_api/wix-bookings/` routes | `wix-bookings` in HTML or network requests; distinct from Wix Stores |
| Wix Events | Event ticketing; `/_api/wix-events/` routes | `wix-events` in HTML or network requests |
| Wix Blog | Blog posts; `/_api/wix-blog/` routes | `wix-blog` in page source |
| Google Analytics | GA4 tracking events | `gtag.js` or `analytics.js` script tag; GA ID co-located with Wix instance data in HTML |
| Facebook Pixel | Pixel events on product pages | `connect.facebook.net/fbevents.js` script tag |
| Wix Multilingual | Multi-language site support | `mlang` URL prefix or `?lang=` query param; language switcher UI component |
| Wix Members | Customer accounts and login | `/account/` or `/members/` routes; `wix-members` in network requests |
| Wix Chat | Live chat widget embedded in pages | `wix-chat` in HTML or `/_api/wix-chat/` in network requests |
| Wix Forms | Contact and lead capture forms | `wix-forms` app UUID in script src; `/_api/wix-forms/` in network requests |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `{site}/sitemap.xml` | Sitemap index linking to all per-type sitemaps | Wix auto-generates; contains references to `store-products-sitemap.xml` and other sub-sitemaps |
| `{site}/store-products-sitemap.xml` | All Wix Stores product page URLs | Dedicated product sitemap; use this for direct product slug enumeration without API access |
| `{site}/_api/wix-ecommerce-reader/v1/catalog/products/query` | Full product catalog with variants, images, prices | POST with `{"query":{}}` body; requires `XSRF-TOKEN` cookie + header; paginated |
| `{site}/_api/wix-ecommerce-reader/v1/catalog/categories/query` | Category tree | POST with `{"query":{}}` body; requires `XSRF-TOKEN` cookie + header |
| `{site}/_api/wix-stores-web/api/v1/stores/settings` | Store currency, locale, shipping config | GET; requires `svSession` cookie |
| `static.wixstatic.com` image URLs | Product images and media | Directly accessible without auth; extracted from product API responses |

**Product URL slug pattern (default, before SEO customization):**

Wix Stores product URLs follow a default pattern: `{site}/product-page/{product-name-slug}`. A product named "Red Wool Sweater" gets the URL `/product-page/red-wool-sweater`. Merchants can customize or remove the `product-page` prefix in SEO Settings. Always verify the prefix by checking `store-products-sitemap.xml` rather than assuming the default.

## 9. Probe Checklist

- [ ] `HEAD {site}` — check response headers for `X-Wix-Application-Instance-Id` and `x-wix-request-id`; presence of either confirms Wix platform
- [ ] `GET {site}` — grep HTML source for `window.Wix`, `static.wixstatic.com`, `/_api/`, `wixstores`, `wixBiSession`, and `X-Wix-Meta-Site-Id` meta tag
- [ ] Extract `metaSiteId` from page source — check both JSON bootstrap (`grep -oP '"metaSiteId"\s*:\s*"\K[^"]+'`) and the `<meta http-equiv="X-Wix-Meta-Site-Id">` tag
- [ ] Extract `siteId` from page source — required for API key auth context header
- [ ] Extract `window.__wix_site__` bootstrap object — capture locale, currency, and site identity metadata
- [ ] `GET {site}/sitemap.xml` — parse sitemap index; look for `store-products-sitemap.xml` reference to confirm Wix Stores is active
- [ ] `GET {site}/store-products-sitemap.xml` — parse dedicated product sitemap; extract all product slugs and confirm URL prefix in use
- [ ] Capture `XSRF-TOKEN` and `svSession` cookies from a live browser session visiting the store
- [ ] `POST {site}/_api/wix-ecommerce-reader/v1/catalog/products/query` with `{"query":{}}` — enumerate product catalog; note pagination
- [ ] `POST {site}/_api/wix-ecommerce-reader/v1/catalog/categories/query` with `{"query":{}}` — enumerate category tree
- [ ] `GET {site}/_api/wix-stores-web/api/v1/stores/settings` — retrieve store currency and locale config
- [ ] `POST {site}/_api/wix-ecommerce-storefront-web/api` — probe main storefront API (observe request/response shape via DevTools)
- [ ] Scan HTML `<script src>` tags for third-party signals — check for Google Analytics, Facebook Pixel, Wix Bookings, Wix Events, Wix Members
- [ ] Scan `package.json` or lock files for `@wix/sdk`, `@wix/stores` — indicates headless commerce setup; REST API will be targeted instead of internal `/_api/` paths

## 10. Gotchas

- **Internal APIs are undocumented and unstable:** All `/_api/` endpoints are private Wix internals. Wix changes them without notice, including the UUID-based app identifiers in paths. Treat every internal API path as potentially ephemeral. The official Wix REST API (`https://www.wixapis.com/`) is the only stable integration surface.

- **`XSRF-TOKEN` must appear in both the cookie and request header:** All internal POST requests to `/_api/` require the `XSRF-TOKEN` value to be set as both a cookie and an `X-XSRF-TOKEN` request header simultaneously. Sending only the cookie or only the header will result in a `403 Forbidden` response.

- **Two official auth methods — OAuth and API key:** The original pack only documented OAuth. Wix also supports API key authentication (generated via the Wix dashboard API Key Manager), which avoids the full OAuth app installation flow. API key calls require the `Authorization` header plus either `wix-site-id` (for site-level calls) or `wix-account-id` (for account-level calls). API keys are the simpler path when you have merchant cooperation.

- **Catalog V3 is the future, V1 still current:** The official REST API is splitting into two catalog versions. `stores/v1/` remains stable. `stores/v3/` (with richer variant and inventory models) is rolling out to new stores first and will eventually replace V1. Both coexist during migration. The internal `/_api/wix-ecommerce-reader/v1/` paths are unrelated to the official V1/V3 versioning.

- **eCommerce API (`/ecom/v1/`) is separate from Stores API (`/stores/v1/`):** Cart, checkout, and orders live under `wixapis.com/ecom/v1/`. Product catalog, collections, and inventory live under `wixapis.com/stores/v1/` (or `stores/v3/`). These are distinct namespaces. A Wix site's cart/checkout flow goes through the eCommerce namespace even when its products are managed in Stores.

- **Custom domains hide all Wix signals except the CDN:** Merchants can point any custom domain at their Wix site. In that case, `wix.com` or `wixsite.com` will not appear in the URL. Rely on `static.wixstatic.com` CDN references in HTML and the `X-Wix-Application-Instance-Id` / `x-wix-request-id` response headers as primary fingerprinting signals, not the domain.

- **Wix Stores is distinct from other Wix verticals:** Wix hosts multiple product verticals on the same platform (Wix Bookings, Wix Events, Wix Blog). Confirm e-commerce capability specifically by looking for `wixstores` in the page source or `/_api/wix-ecommerce-` in network requests — and by checking for `store-products-sitemap.xml`. A Wix site without Wix Stores enabled will not have these signals.

- **Product slugs follow a predictable pattern but the prefix is customizable:** Unlike the previous pack's assertion that product slugs are entirely unpredictable, the default URL prefix is `product-page/` and the slug is derived from the product name. However, merchants can customize or remove the prefix in SEO Settings. Always read the actual prefix from `store-products-sitemap.xml` rather than guessing.

- **`metaSiteId` is needed for some API calls — check two locations:** Always extract the `metaSiteId` from the page source early in a probe session. It appears in two places: the inline JSON bootstrap (`"metaSiteId":"..."`) and as a `<meta http-equiv="X-Wix-Meta-Site-Id" content="...">` tag in the HTML `<head>`. Check both.

- **Product images are always on `static.wixstatic.com`:** Even without API access, product image URLs can be harvested directly from HTML on product listing pages. The CDN requires no authentication and the URL structure is stable.

- **Headless Wix changes the observable network surface:** Wix now supports headless deployments (Next.js, etc.) via `@wix/sdk` and `@wix/stores` npm packages. A headless Wix store will not emit the internal `/_api/` requests visible in DevTools — it will instead make calls to `www.wixapis.com` REST endpoints. Detect headless mode by the absence of internal API calls and the presence of `@wix/sdk` in the site's dependency manifest.

- **`~825k stores` figure is outdated:** As of 2025-2026, Wix powers approximately 3.5 million active e-commerce stores globally, making it a major player in the SMB e-commerce space. The old figure significantly understated its scale.

## 12. Framework-Specific Google Dorks

Use these Google search queries to discover exposed endpoints, configuration files, and documentation for this framework.

### Discovery Queries

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:/_api/wix-ecommerce-storefront-web/` | Wix Stores internal API |
| `site:{domain} inurl:static.wixstatic.com` | Wix CDN-hosted assets |
| `site:{domain} "wix" "api"` | Wix Stores API references |
| `site:{domain} "wix" "storefront"` | Wix storefront configuration |

### Complete Dork List for Wix

```
# API endpoints
site:{domain} inurl:/_api/wix-ecommerce-storefront-web/
site:{domain} inurl:/api.wixapis.com/stores/v2/
site:{domain} inurl:/sitemap.xml

# Framework-specific paths
site:{domain} inurl:static.wixstatic.com
site:{domain} inurl:/shop/

# Configuration files
site:{domain} filetype:js "window.__wix_site__"
site:{domain} filetype:js "svSession"

# Documentation/leaks
site:{domain} "Wix" "api" "endpoint"
site:{domain} "XSRF-TOKEN" "cookie"

# Admin/debug paths
site:{domain} inurl:/_api/wix-ecommerce-storefront-web/
site:{domain} inurl:/account/
```

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
