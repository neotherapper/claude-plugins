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
| `X-Wix-Application-Instance-Id` response header | HTTP header | Present on any response from a Wix site | Definitive |
| `/_api/wix-ecommerce-storefront-web/api` in network | Network request | POST target visible in browser DevTools network tab | Definitive (Wix Stores) |
| `wix-stores` in HTML or script tags | HTML source | String present in page markup or script attributes | High |
| `wixstores` in JSON responses | JSON body | Key or value present in API JSON responses | High |
| `fedops.wix.com` or `bi.wix.com` analytics scripts | Script tag | Wix platform analytics loaded via script tag | High |
| `.wix.com` in canonical URL meta tags | HTML source | `<link rel="canonical">` or `<meta property="og:url">` contains `.wix.com` | High |
| Wappalyzer detection | Browser extension | Wappalyzer identifies Wix or Wix Stores | High |

**Extract Wix instance and site IDs from HTML:**

```bash
# Extract window.__wix_site__ bootstrap data from page source:
curl -s {site} | grep -oP 'window\.__wix_site__\s*=\s*\{[^<]+' | head -c 500

# Extract metaSiteId — required for some internal API calls:
curl -s {site} | grep -oP '"metaSiteId"\s*:\s*"\K[^"]+'

# Extract siteId:
curl -s {site} | grep -oP '"siteId"\s*:\s*"\K[^"]+'

# Check for X-Wix-Application-Instance-Id header:
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
| `{site}/sitemap.xml` | GET | None | Wix auto-generates sitemaps for all stores; best starting point for URL enumeration |

### Official Wix REST API (OAuth required)

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://www.wixapis.com/wix-ecommerce/v1/products` | GET | OAuth Bearer | Products; requires installed Wix app |
| `https://www.wixapis.com/wix-ecommerce/v1/collections` | GET | OAuth Bearer | Collections; requires installed Wix app |
| `https://www.wixapis.com/wix-ecommerce/v1/orders/query` | POST | OAuth Bearer | Orders; requires installed Wix app |
| `https://www.wixapis.com/wix-ecommerce/v1/inventory/query` | GET | OAuth Bearer | Inventory; requires installed Wix app |

OAuth app installation entry point: `https://manage.wix.com/premium-purchase-plan/dynamo`

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.__wix_site__` | View page source or browser console | Site ID, meta site ID, locale, currency, site name |
| `window.Wix` | Browser console | Wix platform SDK object; exposes instance data and event hooks |
| `"metaSiteId"` in page source | `grep -oP '"metaSiteId"\s*:\s*"\K[^"]+'` | Unique site identifier required for some internal API calls |
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

**Extract session tokens from a live browser session:**

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

Note: The internal Wix APIs are not officially documented. Cookie values are tied to a browser session and expire. The official OAuth API is the only stable, supported integration path.

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `https://static.parastorage.com/...` | Wix platform static assets CDN; core Wix runtime JS |
| `https://static.wixstatic.com/...` | User-uploaded assets; product images, theme media |
| `https://siteassets.parastorage.com/...` | Site-specific assets built and hosted by Wix |
| `https://apps.wixstatic.com/{app_id}/...` | Individual Wix app bundles (Wix Stores, Wix Bookings, etc.); app_id is a UUID |
| `https://bo.wix.com/...` | Wix back-office assets |

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
| `{site}/sitemap.xml` | All product, collection, and page URLs | Wix auto-generates; best starting point for enumerating store content and product slugs |
| `{site}/_api/wix-ecommerce-reader/v1/catalog/products/query` | Full product catalog with variants, images, prices | POST with `{"query":{}}` body; requires `XSRF-TOKEN` cookie + header; paginated |
| `{site}/_api/wix-ecommerce-reader/v1/catalog/categories/query` | Category tree | POST with `{"query":{}}` body; requires `XSRF-TOKEN` cookie + header |
| `{site}/_api/wix-stores-web/api/v1/stores/settings` | Store currency, locale, shipping config | GET; requires `svSession` cookie |
| `static.wixstatic.com` image URLs | Product images and media | Directly accessible without auth; extracted from product API responses |

Note: Product slugs are not guessable. Always use the catalog query API or sitemap to enumerate products before attempting direct product URL access.

## 9. Probe Checklist

- [ ] `HEAD {site}` — check response headers for `X-Wix-Application-Instance-Id`; its presence confirms Wix platform
- [ ] `GET {site}` — grep HTML source for `window.Wix`, `static.wixstatic.com`, `/_api/`, and `wixstores` to confirm Wix Stores
- [ ] Extract `metaSiteId` and `siteId` from page source — required for internal API calls; use `grep -oP '"metaSiteId"\s*:\s*"\K[^"]+'`
- [ ] Extract `window.__wix_site__` bootstrap object — capture locale, currency, and site identity metadata
- [ ] `GET {site}/sitemap.xml` — parse full site structure; extract all product and category URL slugs
- [ ] Capture `XSRF-TOKEN` and `svSession` cookies from a live browser session visiting the store
- [ ] `POST {site}/_api/wix-ecommerce-reader/v1/catalog/products/query` with `{"query":{}}` — enumerate product catalog; note pagination
- [ ] `POST {site}/_api/wix-ecommerce-reader/v1/catalog/categories/query` with `{"query":{}}` — enumerate category tree
- [ ] `GET {site}/_api/wix-stores-web/api/v1/stores/settings` — retrieve store currency and locale config
- [ ] `POST {site}/_api/wix-ecommerce-storefront-web/api` — probe main storefront API (observe request/response shape via DevTools)
- [ ] Scan HTML `<script src>` tags for third-party signals — check for Google Analytics, Facebook Pixel, Wix Bookings, Wix Events, Wix Members

## 10. Gotchas

- **Internal APIs are undocumented and unstable:** All `/_api/` endpoints are private Wix internals. Wix changes them without notice, including the UUID-based app identifiers in paths. Treat every internal API path as potentially ephemeral. The official Wix REST API (`https://www.wixapis.com/`) is the only stable integration surface.

- **`XSRF-TOKEN` must appear in both the cookie and request header:** All internal POST requests to `/_api/` require the `XSRF-TOKEN` value to be set as both a cookie and an `X-XSRF-TOKEN` request header simultaneously. Sending only the cookie or only the header will result in a `403 Forbidden` response.

- **Official API requires a Wix app installation:** The official Wix REST API uses OAuth 2.0 via Wix's app marketplace flow. There is no simple API key or public token equivalent to Shopify's Storefront token. Access requires installing a Wix app into the merchant's account — not feasible without merchant cooperation.

- **Custom domains hide all Wix signals except the CDN:** Merchants can point any custom domain at their Wix site. In that case, `wix.com` or `wixsite.com` will not appear in the URL. Rely on `static.wixstatic.com` CDN references in HTML and the `X-Wix-Application-Instance-Id` response header as primary fingerprinting signals, not the domain.

- **Wix Stores is distinct from other Wix verticals:** Wix hosts multiple product verticals on the same platform (Wix Bookings, Wix Events, Wix Blog). Confirm e-commerce capability specifically by looking for `wixstores` in the page source or `/_api/wix-ecommerce-` in network requests — a Wix site without Wix Stores enabled will not have these signals.

- **Product slugs are not guessable:** Unlike Shopify, Wix product URLs use platform-generated slugs that cannot be predicted. Always enumerate products via the catalog query API or sitemap before attempting direct product page access.

- **`metaSiteId` is needed for some API calls:** Always extract the `metaSiteId` from the page source early in a probe session. Some internal endpoints use it as a path or query parameter that cannot be inferred from other signals.

- **Product images are always on `static.wixstatic.com`:** Even without API access, product image URLs can be harvested directly from HTML on product listing pages. The CDN requires no authentication and the URL structure is stable.

- **`~825k stores globally` — significant market share:** Wix Stores has approximately 825,000 active stores, making it a meaningful e-commerce platform in the SMB segment. Wix sites frequently use custom domains, so CDN-based fingerprinting is more reliable than domain matching.
