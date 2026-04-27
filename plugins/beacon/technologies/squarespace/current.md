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
| `static1.squarespace.com` in HTML | HTML source | CDN hostname in `<script src>` or `<link href>` | Definitive |
| `images.squarespace-cdn.com` in HTML | HTML source | Product image CDN hostname in `<img src>` | Definitive |
| `window.Static` JS global | JS global | Squarespace site config object present in page source | Definitive |
| `window.Y.Squarespace` JS global | JS global | Squarespace namespace present in page source | Definitive |
| `window.SQUARESPACE_TEMPLATE` JS global | JS global | Template config object present in page source | Definitive |
| `sqs-*` CSS class names | HTML source | Squarespace-specific class names on DOM elements | Definitive |
| `squarespace.com` in canonical URL | HTML meta | `<link rel="canonical">` contains squarespace.com | Definitive |
| `.squarespace.com` domain | Domain | Unbranded Squarespace site using default subdomain | Definitive |
| `{.} Squarespace` HTML comment | HTML source | Template comment marker in page source | High |
| `crumb` hidden field in forms | HTML source | Squarespace CSRF token field present in form elements | High |
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
```

## 2. Default API Surfaces

### Internal APIs (session-based, observable via DevTools — no API key required)

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://SITE_DOMAIN/?format=json` | GET | None | Full site page data as JSON — always works, undocumented |
| `https://SITE_DOMAIN/products?format=json` | GET | None | Product listing as JSON; also try `/shop`, `/store`, `/collection` |
| `https://SITE_DOMAIN/{product-slug}?format=json` | GET | None | Single product detail including variants, prices, images |
| `https://SITE_DOMAIN/search?format=json&q={query}` | GET | None | Search results as JSON; filter by `contentType: "product"` |
| `https://SITE_DOMAIN/sitemap.xml` | GET | None | Full site sitemap; enumerate product and page URLs |
| `https://SITE_DOMAIN/api/commerce/inventory` | GET | Session cookie | Inventory data; session-based |
| `https://SITE_DOMAIN/api/commerce/useraccountapi` | GET | Session cookie | Customer account info; session-based |
| `https://SITE_DOMAIN/api/shop/cart/full` | GET | Session cookie | Full cart contents with line items and totals |
| `https://SITE_DOMAIN/api/shop/cart` | POST | Session cookie + `crumb` | Cart mutation; requires CSRF crumb token |

### Official Commerce API (API key required — `https://api.squarespace.com/1.0/`)

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://api.squarespace.com/1.0/commerce/inventory` | GET | `Authorization: Bearer {api_key}` | Full inventory data |
| `https://api.squarespace.com/1.0/commerce/orders` | GET | `Authorization: Bearer {api_key}` | Order list with pagination |
| `https://api.squarespace.com/1.0/commerce/products` | GET | `Authorization: Bearer {api_key}` | Product catalog via official API |
| `https://api.squarespace.com/1.0/commerce/transactions` | GET | `Authorization: Bearer {api_key}` | Transaction records |
| `https://api.squarespace.com/1.0/data/stores/{store_id}/products` | GET | `Authorization: Bearer {api_key}` | Store-specific product list |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.Static` | View page source or browser console | Site config: locale, currency, base URL, template ID, collection data |
| `window.Y.Squarespace` | Browser console | Squarespace namespace; page context and site metadata |
| `window.SQUARESPACE_TEMPLATE` | View page source | Template name and configuration |
| `window.Static.SQUARESPACE_CONTEXT` | Browser console | Full site context: websiteId, siteId, collection, authenticatedAccount |
| Inline `<script>` JSON blocks | View page source | Store collection IDs, product variant data, pricing embedded in page |
| `/?format=json` response body | HTTP GET | `collection`, `items`, `pagination`, `website` fields — full structured data |
| `crumb` cookie | Browser cookies | CSRF token value; required for all internal POST requests |
| `SiteUserInfo` cookie | Browser cookies | Customer session state for authenticated browsing |

**Extract store page URL and collection structure:**

```bash
# Get the full JSON context from homepage:
curl -s "https://SITE_DOMAIN/?format=json" | python3 -m json.tool | head -100

# Find the store collection page from sitemap:
curl -s "https://SITE_DOMAIN/sitemap.xml" | grep -oP '<loc>[^<]+</loc>' | grep -i 'shop\|store\|products\|collection'

# Probe common store page paths as JSON:
for path in /shop /store /products /collection; do
  echo "--- $path ---"
  curl -s -o /dev/null -w "%{http_code}" "https://SITE_DOMAIN${path}?format=json"
  echo
done
```

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| `Authorization: Bearer {api_key}` | HTTP request header | Official Commerce API; API key generated in Squarespace admin panel under Settings > Advanced > API Keys |
| `crumb` cookie value | Cookie jar | CSRF token; extracted from page source or cookies; must be sent with all internal POST requests |
| `crumb` hidden form field | HTML form elements | Same CSRF token embedded in form HTML; changes per session |
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

Note: The official Commerce API key is generated in the Squarespace admin dashboard under Settings > Advanced > API Keys. It is not obtainable without store owner access. For passive recon, rely entirely on `?format=json` internal endpoints.

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `https://static1.squarespace.com/static/` | Theme static assets — CSS, JS, fonts |
| `https://static1.squarespace.com/static/squarespace.legacy.latest-en.js` | Squarespace Universal JS (core framework) |
| `https://static1.squarespace.com/static/ta/*/js/*.js` | Squarespace template-specific JS bundles |
| `https://images.squarespace-cdn.com/content/` | Product and page images via Squarespace image CDN |
| `https://sqs-video.com/` | Squarespace-hosted video assets |
| `https://SITE_DOMAIN/universal/scripts-compressed/` | Site-compiled JS bundle path (template-dependent) |

Extract actual asset URLs from HTML `<script src>` tags — the template ID in CDN paths is site-specific and must be read from the live page.

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
| `/?format=json` | Full page data including site config, collection info, item listings | Always works on any Squarespace page; no auth required |
| `/products?format=json` (or `/shop`, `/store`) | Product listing with names, slugs, prices, variants, images | Store page path varies by template; find from sitemap |
| `/{product-slug}?format=json` | Single product with all variants, pricing, images, descriptions, inventory state | Product slug from sitemap or listing response |
| `/search?format=json&q={query}` | All content types matching query; filter `contentType: "product"` for products | Returns blog, events, products, pages — must filter |
| `/sitemap.xml` | All product, page, blog, and event URLs | Best starting point; reveals store page path and all product slugs |
| `/api/shop/cart/full` | Current session cart state with line items and totals | Session-based; useful to observe cart schema |

## 9. Probe Checklist

- [ ] `HEAD https://SITE_DOMAIN/` — check `X-ServedBy` header for Fastly/Squarespace pattern; confirm CDN response
- [ ] `GET https://SITE_DOMAIN/` — grep HTML for `static1.squarespace.com`, `window.Static`, `sqs-*` class names, `crumb` hidden field to confirm Squarespace fingerprint
- [ ] Extract `window.Static` from page source — capture `websiteId`, `siteId`, template ID, collection structure, locale, currency
- [ ] `GET https://SITE_DOMAIN/?format=json` — full site JSON data; always works; reveals site config, page collection, item listings
- [ ] `GET https://SITE_DOMAIN/sitemap.xml` — parse full site structure to find store page path (`/shop`, `/store`, `/products`) and enumerate all product slugs
- [ ] `GET https://SITE_DOMAIN/{store-path}?format=json` — product listing as JSON with names, prices, variants; store path found from sitemap
- [ ] `GET https://SITE_DOMAIN/{product-slug}?format=json` — single product detail JSON including all variants, option names, pricing tiers, images
- [ ] `GET https://SITE_DOMAIN/search?format=json&q=test` — confirm search active; note total result count; filter `contentType: "product"` for store size estimate
- [ ] Extract `websiteId` and `siteId` from `/?format=json` response — store for reference in all further requests
- [ ] Extract `crumb` CSRF token from page source or cookies — required for any internal POST requests
- [ ] `GET https://SITE_DOMAIN/api/shop/cart/full` — observe cart JSON schema (session-based, may return empty cart)
- [ ] Scan HTML `<script src>` tags for third-party integration signals — check for Klaviyo, Acuity, Afterpay, Facebook Pixel, Google Analytics

## 10. Gotchas

- **`?format=json` is the single most powerful recon technique:** Appending `?format=json` to any Squarespace page URL returns that page's full structured JSON data — no auth required. This works on the homepage, store pages, product pages, blog pages, and search. It reveals product names, prices, variants, descriptions, images, and site config in one request. Always start here.

- **Store page URL varies by template and merchant configuration:** The e-commerce store page may be at `/shop`, `/store`, `/products`, `/collection`, or a custom URL slug. Do not hard-code `/shop`. Find the actual path from `sitemap.xml` or the `/?format=json` collection listing.

- **Custom domains hide `.squarespace.com`:** Merchants use custom domains and the `.squarespace.com` subdomain does not appear in HTML. Use `static1.squarespace.com` CDN references in HTML as the definitive fingerprint — not the domain name.

- **Commerce is plan-gated:** Squarespace Commerce features (products, checkout, inventory) are only available on Business and Commerce plan subscriptions. Not all Squarespace sites have a store. Confirm commerce presence via `sitemap.xml` product URLs or `?format=json` on the store page before assuming Commerce is enabled.

- **Official API requires store owner access:** The official Commerce API (`api.squarespace.com/1.0/`) requires an API key generated in the Squarespace admin panel. This is not obtainable without store owner credentials. For external recon, rely entirely on `?format=json` internal endpoints and `sitemap.xml`.

- **`crumb` is a per-session CSRF token:** The `crumb` value changes with each new session. It must be extracted from the current page source or cookies before each POST request to internal APIs. Using a stale `crumb` will cause POST requests to fail with a CSRF error.

- **Search results include all content types:** The `/search?format=json&q=` endpoint returns products, blog posts, events, and pages mixed together. Filter by `contentType: "product"` in the JSON response to isolate product results. The `totalSize` field reflects all content types, not just products.

- **Product URL patterns are template-dependent:** Product pages use either `/products/{slug}` or `/shop/{slug}` or `/{store-page-slug}/{product-slug}` depending on the Squarespace template version and store configuration. Enumerate slugs from `sitemap.xml` or the store listing `?format=json` response rather than guessing URL structure.

- **Squarespace Commerce has ~88,000 active stores:** It is a mid-market e-commerce platform with deep template integration. All commerce functionality (cart, checkout, inventory) is managed natively within Squarespace — no separate storefront app is used.

- **Stripe and PayPal are native integrations:** Squarespace Commerce uses Stripe and PayPal natively for payment processing. Presence of `js.stripe.com` in HTML on a Squarespace site is expected and does not indicate a custom Stripe integration.
