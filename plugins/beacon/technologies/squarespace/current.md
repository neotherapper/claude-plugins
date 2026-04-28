---
framework: squarespace
version: "current"
last_updated: "2026-04-28"
author: "@neotherapper"
status: official
---

# Squarespace Commerce — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `static1.squarespace.com` in HTML | HTML source | CDN hostname in `<script src>` or `<link href>` for CSS/JS/file assets | Definitive |
| `images.squarespace-cdn.com` in HTML | HTML source | Product and page image CDN hostname in `<img src>` | Definitive |
| `window.Static` JS global | JS global | Squarespace site config object; set as `var Static = window.Static \|\| {}; Static.SQUARESPACE_CONTEXT = {...}` in page source | Definitive |
| `window.Y.Squarespace` JS global | JS global | Squarespace namespace present in page source | Definitive |
| `window.SQUARESPACE_TEMPLATE` JS global | JS global | Template config object present in page source | Definitive |
| `sqs-*` CSS class names | HTML source | Squarespace-specific class names on DOM elements (e.g. `sqs-image-block`, `sqs-code-block`, `sqs-block-button`, `sqs-announcement-bar-dropzone`) | Definitive |
| `squarespace.com` in canonical URL | HTML meta | `<link rel="canonical">` contains squarespace.com | Definitive |
| `.squarespace.com` domain | Domain | Unbranded Squarespace site using default subdomain | Definitive |
| `data-name="static-context"` script tag | HTML source | `<script data-name="static-context">` wrapping the `Static.SQUARESPACE_CONTEXT` assignment | Definitive |
| `{.} Squarespace` HTML comment | HTML source | Template comment marker in page source | High |
| `crumb` cookie | Browser cookies | Session CSRF token set by Squarespace; documented in Squarespace cookie policy as "Session — Prevents cross-site request forgery" | High |
| `crumb` hidden field in forms | HTML source | Same CSRF token value embedded in HTML form elements | High |
| `X-ServedBy` response header | HTTP header | Fastly CDN header indicating Squarespace hosting | High |
| Wappalyzer detection | Browser extension | Wappalyzer identifies Squarespace | High |

**Extract site config and store identifiers from HTML:**

```bash
# Check for Squarespace fingerprints and window.Static object:
curl -s https://SITE_DOMAIN/ | grep -o 'window\.Static\s*=\s*{[^<]*' | head -c 500

# Extract websiteId from page source:
curl -s https://SITE_DOMAIN/ | grep -oP '"websiteId"\s*:\s*"\K[^"]+'

# Extract siteId from page source:
curl -s https://SITE_DOMAIN/ | grep -oP '"siteId"\s*:\s*"\K[^"]+'

# Extract collection config from page source:
curl -s https://SITE_DOMAIN/ | grep -oP '"collection"\s*:\s*\{[^}]+' | head -c 500

# Check for CDN fingerprint and CSRF crumb field:
curl -s https://SITE_DOMAIN/ | grep -E 'static1\.squarespace\.com|images\.squarespace-cdn\.com|sqs-|window\.Static|crumb'

# Confirm sqs- CSS class presence (definitive fingerprint):
curl -s https://SITE_DOMAIN/ | grep -oP 'class="[^"]*sqs-[^"]*"' | head -10
```

## 2. Default API Surfaces

### Internal APIs (session-based, observable via DevTools — no API key required)

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://SITE_DOMAIN/?format=json-pretty` | GET | None | Full site page data as JSON — `json-pretty` is the form documented by Squarespace; `?format=json` also observed to work in practice as a compact variant |
| `https://SITE_DOMAIN/products?format=json-pretty` | GET | None | Product listing as JSON; also try `/shop`, `/store`, `/collection`; store page path varies per site |
| `https://SITE_DOMAIN/{product-slug}?format=json-pretty` | GET | None | Single product detail including variants, prices, images |
| `https://SITE_DOMAIN/search?format=json-pretty&q={query}` | GET | None | Search results as JSON; filter by `contentType: "product"` |
| `https://SITE_DOMAIN/sitemap.xml` | GET | None | Full site sitemap; enumerate product and page URLs |
| `https://SITE_DOMAIN/api/shop/cart/full` | GET | Session cookie | Full cart contents with line items and totals (session-based) |
| `https://SITE_DOMAIN/api/shop/cart` | POST | Session cookie + `crumb` | Cart mutation; requires CSRF crumb token |

Note: The internal `?format=json-pretty` endpoint is not a stable alternative to the official API. Squarespace explicitly documents it as a development/debugging tool. It works on any Squarespace page type (homepage, store, product, blog, search). Pagination via this endpoint returns approximately 20 items per page with a next-page offset link.

### Official Commerce API (API key required — `https://api.squarespace.com/{version}/`)

As of 2025, Squarespace uses integer versioning (v1, v2, v3 — non-SemVer). v2 is current and recommended for new integrations; v1.0 and v1.1 remain supported as legacy.

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://api.squarespace.com/v2/commerce/products` | GET | `Authorization: Bearer {api_key}` | Product catalog — v2 is current; supports physical, service, gift card, and download product types |
| `https://api.squarespace.com/v2/commerce/products/{ids}` | GET | `Authorization: Bearer {api_key}` | Specific products by ID including variants and images |
| `https://api.squarespace.com/v2/commerce/inventory` | GET | `Authorization: Bearer {api_key}` | Full inventory data with per-variant stock levels |
| `https://api.squarespace.com/v2/commerce/orders` | GET | `Authorization: Bearer {api_key}` | Order list with cursor-based pagination |
| `https://api.squarespace.com/v2/commerce/transactions` | GET | `Authorization: Bearer {api_key}` | Transaction records |
| `https://api.squarespace.com/v2/commerce/store-pages` | GET | `Authorization: Bearer {api_key}` | Retrieve all store pages for the site |
| `https://api.squarespace.com/v2/commerce/profiles` | GET | `Authorization: Bearer {api_key}` | Customer profiles (read-only) |

All official Commerce API endpoints use HTTPS, REST conventions, and `Authorization: Bearer {api_key}` authentication. Responses use cursor-based pagination: `pagination.nextPageCursor`, `pagination.hasNextPage`, and `pagination.nextPageUrl`.

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.Static` | View page source or browser console | Squarespace site config namespace; initialized as `var Static = window.Static \|\| {}` |
| `window.Static.SQUARESPACE_CONTEXT` | Browser console or `<script data-name="static-context">` in page source | Full site context: websiteId, siteId, facebookAppId, rollups, collection data, authenticatedAccount, locale, currency, template ID |
| `window.Y.Squarespace` | Browser console | Squarespace namespace; page context and site metadata |
| `window.SQUARESPACE_TEMPLATE` | View page source | Template name and configuration |
| Inline `<script>` JSON blocks | View page source | Store collection IDs, product variant data, pricing embedded in page |
| `/?format=json-pretty` response body | HTTP GET | `collection`, `items`, `pagination`, `website` fields — full structured data |
| `crumb` cookie | Browser cookies | Session CSRF token; documented by Squarespace as preventing CSRF; changes per session |
| `SiteUserInfo` cookie | Browser cookies | Customer session state for authenticated browsing |

**Extract store page URL and collection structure:**

```bash
# Get the full JSON context from homepage (json-pretty is the documented form):
curl -s "https://SITE_DOMAIN/?format=json-pretty" | python3 -m json.tool | head -100

# Both forms work in practice:
curl -s "https://SITE_DOMAIN/?format=json" | python3 -m json.tool | head -100

# Find the store collection page from sitemap:
curl -s "https://SITE_DOMAIN/sitemap.xml" | grep -oP '<loc>[^<]+</loc>' | grep -i 'shop\|store\|products\|collection'

# Probe common store page paths as JSON:
for path in /shop /store /products /collection; do
  echo "--- $path ---"
  curl -s -o /dev/null -w "%{http_code}" "https://SITE_DOMAIN${path}?format=json-pretty"
  echo
done
```

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| `Authorization: Bearer {api_key}` | HTTP request header | Official Commerce API; API key generated in Squarespace admin panel under Settings > Advanced > API Keys |
| `crumb` cookie value | Cookie jar | Session CSRF token; documented by Squarespace; must be sent with all internal POST requests; changes every session |
| `crumb` hidden form field | HTML form elements | Same CSRF token value embedded in form HTML; changes per session |
| `SiteUserInfo` session cookie | Cookie jar | Customer session cookie set on login; required for authenticated internal API calls |

**Extract crumb CSRF token from page source:**

```bash
# Extract crumb value from HTML source (hidden form field):
curl -s -c /tmp/sqs-cookies.txt https://SITE_DOMAIN/ | grep -oP 'name="crumb"\s+value="\K[^"]+'

# Extract crumb from cookies after page load:
grep crumb /tmp/sqs-cookies.txt

# Use crumb in a POST request to internal cart API:
CRUMB=$(curl -s -c /tmp/sqs-cookies.txt https://SITE_DOMAIN/ | grep -oP 'name="crumb"\s+value="\K[^"]+')
curl -s -b /tmp/sqs-cookies.txt -X POST "https://SITE_DOMAIN/api/shop/cart" \
  -H "Content-Type: application/json" \
  -d "{\"crumb\":\"$CRUMB\", ...}"
```

Note: The official Commerce API key is generated in the Squarespace admin dashboard under Settings > Advanced > API Keys. It is not obtainable without store owner access. For passive recon, rely entirely on `?format=json-pretty` internal endpoints.

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `https://static1.squarespace.com/static/` | Theme static assets — CSS, JS, fonts; also hosts CSS custom files and unlinked uploaded files |
| `https://static1.squarespace.com/static/squarespace.legacy.latest-en.js` | Squarespace Universal JS (core framework) |
| `https://static1.squarespace.com/static/ta/*/js/*.js` | Squarespace template-specific JS bundles |
| `https://images.squarespace-cdn.com/content/` | Product and page images via Squarespace image CDN (used for Asset Library and image block uploads) |
| `https://sqs-video.com/` | Squarespace-hosted video assets |
| `https://SITE_DOMAIN/universal/scripts-compressed/` | Site-compiled JS bundle path (template-dependent) |

CDN hostname notes: `static1.squarespace.com` hosts CSS custom files and unlinked file uploads; `images.squarespace-cdn.com` hosts images uploaded via Asset Library or image block GUI. Both are current CDN hostnames (confirmed 2025-2026). Extract actual asset URLs from live page `<script src>` tags — the template ID embedded in CDN paths is site-specific.

```bash
# Extract all Squarespace CDN asset URLs from page source:
curl -s https://SITE_DOMAIN/ | grep -oP 'https://static1\.squarespace\.com/static/[^"]+\.js'

# Extract product image CDN references:
curl -s https://SITE_DOMAIN/ | grep -oP 'https://images\.squarespace-cdn\.com/[^"?]+' | sort -u | head -20
```

## 6. Source Map Patterns

Squarespace CDN-hosted JS assets typically do **not** include source maps. Squarespace controls the build pipeline and does not publish source maps for its platform JS.

**Check for source maps on CDN assets:**

```bash
# Extract a CDN script URL then probe for .map:
SCRIPT_URL=$(curl -s https://SITE_DOMAIN/ | grep -oP 'https://static1\.squarespace\.com/static/[^"]+\.js' | head -1)
curl -I "${SCRIPT_URL}.map"

# Check for SourceMap response header on core JS:
curl -I "https://static1.squarespace.com/static/squarespace.legacy.latest-en.js"
```

Source maps are not expected to be present. Squarespace is a closed SaaS platform and does not expose source maps through its CDN.

## 7. Common Plugins & Extensions

| App/Integration | API it adds | Detection signal |
|-----------------|-------------|-----------------|
| Squarespace Email Campaigns | Native email marketing | No external script; managed within Squarespace admin |
| Squarespace Scheduling (Acuity) | Appointment booking widget | `acuityscheduling.com` iframe or script in page HTML |
| Squarespace Member Areas | Gated content and subscriptions | `/config/authentication-required` response on member pages |
| Klaviyo | Email/SMS marketing events | `//a.klaviyo.com/` script in HTML; `_kx` cookie |
| Typeform | Embedded forms | `embed.typeform.com` script in HTML |
| Stripe (direct) | Payment processing | `js.stripe.com` script in HTML (used by Squarespace Commerce natively) |
| PayPal (direct) | Payment processing | `paypal.com/sdk/js` script (Squarespace Commerce native integration) |
| Google Analytics | Site analytics | `gtag.js` or `analytics.js` in page source; `_ga` cookie |
| Facebook Pixel | Ad conversion tracking | `connect.facebook.net/en_US/fbevents.js` in page source |
| Afterpay / Clearpay | Buy now, pay later | `js.afterpay.com` script in HTML |
| Instagram feed | Social media embed | `instagram.com/embed.js` or `elfsight.com` script |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `/?format=json-pretty` | Full page data including site config, collection info, item listings | Works on any Squarespace page; no auth required; `?format=json` also observed to work; ~20 items per page with pagination offset |
| `/products?format=json-pretty` (or `/shop`, `/store`) | Product listing with names, slugs, prices, variants, images | Store page path varies by template; find from sitemap; store pages load up to 200 products at a time |
| `/{product-slug}?format=json-pretty` | Single product with all variants, pricing, images, descriptions, inventory state | Use slug from sitemap or listing response |
| `/search?format=json-pretty&q={query}` | All content types matching query; filter `contentType: "product"` for products | Returns blog, events, products, pages — must filter |
| `/sitemap.xml` | All product, page, blog, and event URLs | Best starting point; reveals store page path and all product slugs |
| `/api/shop/cart/full` | Current session cart state with line items and totals | Session-based; useful to observe cart schema |
| Product page HTML (JSON-LD) | Built-in Product schema auto-generated by Squarespace on product pages | Squarespace automatically emits JSON-LD `<script type="application/ld+json">` with product name, price, availability; limited in detail but no auth needed |

## 9. Probe Checklist

- [ ] `HEAD https://SITE_DOMAIN/` — check `X-ServedBy` header for Fastly/Squarespace pattern; confirm CDN response
- [ ] `GET https://SITE_DOMAIN/` — grep HTML for `static1.squarespace.com`, `window.Static`, `sqs-*` class names, `data-name="static-context"` script tag, `crumb` hidden field to confirm Squarespace fingerprint
- [ ] Extract `window.Static.SQUARESPACE_CONTEXT` from `<script data-name="static-context">` in page source — capture `websiteId`, `siteId`, template ID, collection structure, locale, currency, facebookAppId
- [ ] `GET https://SITE_DOMAIN/?format=json-pretty` — full site JSON data; always works; reveals site config, page collection, item listings; note `?format=json` also observed to work as compact form
- [ ] `GET https://SITE_DOMAIN/sitemap.xml` — parse full site structure to find store page path (`/shop`, `/store`, `/products`) and enumerate all product slugs
- [ ] `GET https://SITE_DOMAIN/{store-path}?format=json-pretty` — product listing as JSON with names, prices, variants; store path found from sitemap; up to 200 products per page
- [ ] `GET https://SITE_DOMAIN/{product-slug}?format=json-pretty` — single product detail JSON including all variants, option names, pricing tiers, images; on 7.1 sites check `/p/` segment in product URL pattern
- [ ] `GET https://SITE_DOMAIN/search?format=json-pretty&q=test` — confirm search active; note total result count; filter `contentType: "product"` for store size estimate
- [ ] Extract `websiteId` and `siteId` from `/?format=json-pretty` response — store for reference in all further requests
- [ ] Extract `crumb` CSRF token from page source or cookies — required for any internal POST requests
- [ ] `GET https://SITE_DOMAIN/api/shop/cart/full` — observe cart JSON schema (session-based, may return empty cart)
- [ ] Check product page HTML for `<script type="application/ld+json">` — Squarespace auto-emits Product JSON-LD on product pages
- [ ] Scan HTML `<script src>` tags for third-party integration signals — check for Klaviyo, Acuity, Afterpay, Facebook Pixel, Google Analytics
- [ ] Determine Squarespace version (7.0 vs 7.1) from page structure or `SQUARESPACE_CONTEXT` — affects product URL patterns

## 10. Gotchas

- **`?format=json-pretty` is the documented form; `?format=json` also works:** Squarespace's developer documentation specifically names `?format=json-pretty` as the parameter to append to any page URL to view JSON data. The pack previously used `?format=json` throughout — both are observed to work in practice, but `json-pretty` is the documented form. Squarespace explicitly warns this is not a stable alternative to the official API and should not be used as a replacement.

- **Product URL structure differs between version 7.0 and 7.1:** In Squarespace 7.1, product URLs always include a fixed `/p/` segment: `{store-page-url}/p/{product-slug}` (e.g. `/store/p/my-product`). This `/p/` cannot be removed or customized. In Squarespace 7.0, products may use `/products/{slug}`, `/shop/{slug}`, or `/{store-page}/{product-slug}` depending on template. Identify the version before assuming URL structure. Find actual patterns from `sitemap.xml` or the store listing JSON.

- **Official API is now versioned as v2 (integer versioning):** The base path `1.0/` used in the original pack is legacy. As of 2025, Squarespace uses integer versioning (v1, v2, v3 — non-SemVer). v2 is current and recommended for Products, Inventory, and Orders. v1.0 and v1.1 remain supported. Use `https://api.squarespace.com/v2/commerce/...` for new integrations.

- **Official API pagination is cursor-based:** The official Commerce API uses `pagination.nextPageCursor`, `pagination.hasNextPage`, and `pagination.nextPageUrl` in responses. The `cursor` parameter cannot be combined with other query parameters. Responses return up to 50 items per page. The internal `?format=json-pretty` endpoint returns ~20 items per page with a separate offset-based next-page link.

- **Store page URL varies by template and merchant configuration:** The e-commerce store page may be at `/shop`, `/store`, `/products`, `/collection`, or a custom URL slug. Do not hard-code `/shop`. Find the actual path from `sitemap.xml` or the `/?format=json-pretty` collection listing.

- **Custom domains hide `.squarespace.com`:** Merchants use custom domains and the `.squarespace.com` subdomain does not appear in HTML. Use `static1.squarespace.com` CDN references in HTML as the definitive fingerprint — not the domain name.

- **Commerce is plan-gated:** Squarespace Commerce features (products, checkout, inventory) are only available on Business and Commerce plan subscriptions. Not all Squarespace sites have a store. Confirm commerce presence via `sitemap.xml` product URLs or `?format=json-pretty` on the store page before assuming Commerce is enabled.

- **Official API requires store owner access:** The official Commerce API (`api.squarespace.com/v2/`) requires an API key generated in the Squarespace admin panel. This is not obtainable without store owner credentials. For external recon, rely entirely on `?format=json-pretty` internal endpoints and `sitemap.xml`.

- **`crumb` is a per-session CSRF token:** Squarespace's own cookie policy documents the `crumb` cookie as a session-scoped CSRF prevention mechanism. The value changes with each new session. It must be extracted from the current page source or cookies before each POST request to internal APIs. Using a stale `crumb` will cause POST requests to fail.

- **Search results include all content types:** The `/search?format=json-pretty&q=` endpoint returns products, blog posts, events, and pages mixed together. Filter by `contentType: "product"` in the JSON response to isolate product results. The `totalSize` field reflects all content types, not just products.

- **Squarespace auto-emits Product JSON-LD on product pages:** Squarespace automatically generates basic `<script type="application/ld+json">` Product schema on product pages with name, price, and availability. This is limited and not customizable by the merchant. It is useful for recon as an additional source of product data without needing `?format=json-pretty`.

- **Stripe and PayPal are native integrations:** Squarespace Commerce uses Stripe and PayPal natively for payment processing. Presence of `js.stripe.com` in HTML on a Squarespace site is expected and does not indicate a custom Stripe integration.

- **Squarespace Commerce has ~88,000 active stores:** It is a mid-market e-commerce platform with deep template integration. All commerce functionality (cart, checkout, inventory) is managed natively within Squarespace — no separate storefront app is used.
