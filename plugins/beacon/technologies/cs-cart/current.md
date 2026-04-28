---
framework: cs-cart
version: "current"
last_updated: "2026-04-28"
author: "@neotherapper"
status: official
---

# CS-Cart (current) — Tech Pack

CS-Cart is an open-source PHP e-commerce platform built by Simtech Development, dominant in
Russia, Eastern Europe, and CIS countries. It ships in two editions: **CS-Cart** (single-store
or multi-storefront under one admin) and **CS-Cart Multi-Vendor** (marketplace edition where
independent vendors sell through one platform). Both editions share the same REST API structure
with Multi-Vendor adding the `/api/vendors/` entity. The platform uses a custom MVC framework
(`Tygh`) rather than a major PHP framework. Current stable series is **4.20.x**; earlier
production installs may run 4.17.x–4.19.x. All notes in this pack apply to 4.17.x–4.20.x
unless stated otherwise.

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `window.Tygh` JS global | JS global | Object present in inline/external scripts | Definitive |
| `?dispatch=` URL pattern | URL pattern | `index.php?dispatch=` present anywhere in source | Definitive |
| `sid_customer_` cookie | Cookie | Name prefix match (hash suffix varies per install) | Definitive |
| `cm-ajax` CSS class | HTML attribute | Class on AJAX-enabled forms and links | High |
| `/admin.php` accessible | URL probe | 200 or redirect — CS-Cart admin entry point | High |
| `/api/` endpoint present | URL probe | 200 = API enabled; 401 = enabled, key required; 404 = disabled | High |
| Wappalyzer result | MCP | `"CS-Cart"` | Definitive |
| `dispatch=products.view&product_id=` | URL pattern | Product page URL without SEO addon | High |
| `dispatch=categories.view&category_id=` | URL pattern | Category page URL without SEO addon | High |
| `sid_admin_` cookie | Cookie | Name prefix match — indicates logged-in admin session | High |
| `/api/vendors/` returns 200 or 401 | URL probe | Multi-Vendor edition only — distinguishes MV from single-store | Medium |
| `Tygh` string in JS file paths | HTML substring | `/js/tygh/` path in script src attributes | High |
| `design/themes/` in HTML src attributes | HTML substring | CS-Cart theme asset path pattern | Medium |

**Version extraction:**
```bash
# Inspect HTTP response headers — some configs expose version:
curl -sI {site} | grep -i "x-powered\|server\|via"

# Check page source for Tygh version comment or inline version variable:
curl -s {site} | grep -oiP 'CS-Cart\s+[\d.]+'

# Check admin panel login page title:
curl -s {site}/admin.php | grep -oiP 'CS-Cart\s+[\d.]+'

# API root may return version info in JSON (auth required on most installs):
curl -s --user email@example.com:API_KEY {site}/api/ | python3 -c "import sys,json; d=json.load(sys.stdin); print(d)"

# Changelog or version file (if source access is available):
# var/revision.txt or config/config.php may contain version string
```

**Note on version visibility:** CS-Cart does not emit a `<meta name="generator">` tag by default.
Version is most reliably extracted from the admin panel title tag or inline JS comments. On
locked-down production stores, version may be entirely opaque from the outside.

## 2. Default API Surfaces

All REST API endpoints use base path `{site}/api/`. Auth is HTTP Basic with admin email and
API key (`--user email@example.com:API_KEY`). **API access is disabled by default per-user
and must be explicitly enabled in the admin panel** (Profile > API Access tab). A 401 on any
endpoint is the normal state — it means API is available but unauthenticated, not that the
endpoint is broken. A 404 means the entity does not exist or the endpoint is unrecognized.

| Endpoint | Method(s) | Auth | Notes |
|----------|-----------|------|-------|
| `/api/` | GET | None* | API root — returns available entities list; *often returns 401 |
| `/api/products/` | GET | Key | Product catalog with pagination |
| `/api/products/{id}/` | GET, PUT, DELETE | Key | Single product by ID |
| `/api/categories/` | GET | Key | Full category tree |
| `/api/categories/{id}/` | GET, PUT, DELETE | Key | Single category |
| `/api/orders/` | GET, POST | Key | Order list and creation |
| `/api/orders/{id}/` | GET, PUT, DELETE | Key | Single order |
| `/api/users/` | GET, POST | Key | User/customer list |
| `/api/users/{id}/` | GET, PUT, DELETE | Key | Single user record |
| `/api/carts/` | GET | Key | Active shopping cart list |
| `/api/carts/{user_id}/` | GET, PUT, DELETE | Key | Cart for a specific user |
| `/api/shipments/` | GET, POST | Key | Shipment records |
| `/api/shipments/{id}/` | GET, PUT, DELETE | Key | Single shipment |
| `/api/shipping_methods/` | GET | Key | Configured shipping methods |
| `/api/payment_methods/` | GET | Key | Configured payment methods |
| `/api/currencies/` | GET | Key* | Currency list; may be public on some configs |
| `/api/languages/` | GET | Key* | Available store languages |
| `/api/langvars/` | GET, PUT | Key | Language variable strings |
| `/api/settings/` | GET, PUT | Key | Store settings (admin-level) |
| `/api/stores/` | GET | Key | Storefronts (CS-Cart multi-storefront edition) |
| `/api/taxes/` | GET, POST | Key | Tax rates and rules |
| `/api/statuses/` | GET | Key | Order and return status list |
| `/api/usergroups/` | GET, POST | Key | User permission groups |
| `/api/pages/` | GET, POST | Key | CMS pages (about, contact, etc.) |
| `/api/discussions/` | GET | Key | Product reviews and discussions |
| `/api/call_requests/` | GET | Key | Callback/call-me requests (since 4.3.5) |
| `/api/blocks/` | GET | Key | Layout blocks |
| `/api/product_features/` | GET, POST | Key | Product custom attributes/features |
| `/api/product_variations/` | GET, POST | Key | Product variations (configurable products) |
| `/api/product_variation_groups/` | GET | Key | Variation group containers |
| `/api/product_options/` | GET, POST | Key | Product option types (dropdown, checkbox, etc.) |
| `/api/product_option_combinations/` | GET | Key | Option value combinations |
| `/api/product_option_exceptions/` | GET | Key | Incompatible option combinations |
| `/api/master_products/` | GET | Key | Master products (Multi-Vendor catalog mode) |
| `/api/master_product_offers/` | GET | Key | Vendor offers on master products |
| `/api/vendors/` | GET, POST | Key | Vendor list — **Multi-Vendor only**; 404 on single-store |
| `/api/vendors/{company_id}/` | GET, PUT, DELETE | Key | Single vendor — Multi-Vendor only |
| `/api/auth/` | POST | None | Obtain session token via credentials |

**Storefront URL patterns (no API key):**
```
{site}/index.php?dispatch=products.view&product_id={N}      # Product page
{site}/index.php?dispatch=categories.view&category_id={N}   # Category page
{site}/index.php?dispatch=search.index&q={query}             # Search results
{site}/index.php?dispatch=checkout.cart                      # Cart page
{site}/index.php?dispatch=checkout.index                     # Checkout
{site}/index.php?dispatch=profiles.add                       # Registration page
{site}/index.php?dispatch=auth.login_form                    # Login page
```

**With SEO addon enabled (clean URL patterns):**
```
{site}/{product-seo-name}.html                               # Product page
{site}/{category-seo-name}/                                  # Category page (trailing slash)
{site}/{category}/{product-seo-name}.html                    # Product with category prefix
{site}/sitemap.xml                                            # XML sitemap (SEO addon only)
```

**API pagination and filtering:**
```bash
# Paginated product list (page 2, 25 per page):
curl --user email:KEY "{site}/api/products/?page=2&items_per_page=25"

# Filter products by category:
curl --user email:KEY "{site}/api/products/?category_id={N}"

# Filter orders by status:
curl --user email:KEY "{site}/api/orders/?status=P"  # P=Processed, C=Complete, etc.
```

**Response envelope format:**
```json
{
  "products": [ ... ],
  "params": {
    "page": 1,
    "items_per_page": 10,
    "total_items": 237
  }
}
```
Single-resource responses return the object directly (no envelope). Errors return HTTP 4xx
with a JSON body: `{"message": "...", "status": "error"}`.

## 3. Config / Constants Locations

| Location | What's there | How to access |
|----------|-------------|---------------|
| `window.Tygh` JS global | Global CS-Cart JS namespace — exposes store functions and config properties | JS eval in browser / grep page source |
| `index.php?dispatch=` URL params | Controller + mode routing; reveals entity types in use | URL observation |
| `/api/` root response | List of available API entities | GET with Key |
| `config/config.php` | DB credentials, installation path, `PRODUCT_TYPE` (cart vs multivendor) | Source only — blocked in production |
| `config/local_conf.php` | Instance-specific overrides (hostname, DB, protocol) | Source only |
| `var/revision.txt` | Build revision/version string | May be accessible via HTTP on misconfigured servers |
| `app/Tygh/Registry.php` | Central config registry | Source only |
| Admin panel `admin.php?dispatch=settings.manage` | All store settings (auth required) | Admin session |
| Product page HTML | `<script type="application/ld+json">` JSON-LD: name, price, availability, SKU, currency | HTML scrape — no auth |
| `/api/settings/?section=general` | Site name, company email, store language | Key required |
| `/api/currencies/` | All currencies with codes and exchange rates | Key (or public on some installs) |
| `/api/languages/` | All configured store languages with ISO codes | Key |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| HTTP Basic — email:API_key | `Authorization: Basic base64(email:key)` header | Primary REST API auth method |
| `--user` param (curl) | `curl --user admin@example.com:API_KEY` | Shorthand for HTTP Basic |
| Inline URL credentials | `{site}/api/users/?email=admin@example.com&api_key=KEY` | URL param alternative — visible in logs, avoid |
| `sid_customer_*` cookie | Storefront session — set on first visit | 32-char hex suffix varies per install |
| `sid_admin_*` cookie | Admin session cookie | Set only after successful admin login |
| CSRF token (`security_hash`) | Hidden form field in storefront forms | Required for state-mutating POST requests |
| Admin form token | `security_hash` hidden field | Admin panel forms; changes per session |

**API key generation (admin steps):**
1. Admin panel → Profile (admin user) → API Access tab
2. Check "Yes, allow this user to use the API"
3. Copy the auto-generated API key — this is the credential

**Auth examples:**
```bash
# List all products (HTTP Basic via --user):
curl --user admin@example.com:API_KEY -X GET "{site}/api/products/"

# Create a product (POST with JSON body):
curl --user admin@example.com:API_KEY \
  -X POST -H "Content-Type: application/json" \
  -d '{"product":"Test","price":"19.99","category_ids":[1]}' \
  "{site}/api/products/"

# Check Multi-Vendor status (vendors endpoint):
curl --user admin@example.com:API_KEY -sI "{site}/api/vendors/" | head -1
# HTTP/1.1 200 = Multi-Vendor; HTTP/1.1 404 = single-store
```

**Important:** API access is per-user. The admin account must have API access explicitly enabled.
A shared API key grants all permissions that the associated admin user has. There is no
per-endpoint scope system — it's all-or-nothing based on user admin level.

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `/js/tygh/core.js` | Tygh core — registers `window.Tygh` namespace |
| `/js/tygh/ajax.js` | CS-Cart AJAX extensions on jQuery; `submitForm` and `request` methods |
| `/js/tygh/microformat.js` | Microformat parser — drives `cm-ajax`, `cm-submit`, etc. |
| `/js/tygh/jquery.ceModal.js` | CS-Cart modal system |
| `/js/bundle.js` | Compiled JS bundle (theme-dependent; may include above) |
| `/design/themes/{theme}/media/js/*.js` | Theme-specific JavaScript |
| `/design/themes/{theme}/media/css/styles.css` | Theme primary stylesheet |
| `/js/addons/{addon_id}/*.js` | Addon-contributed JS — per-addon |
| `/design/themes/{theme}/templates/` | Smarty `.tpl` templates (not directly accessible in prod) |

**Tygh namespace confirmation:**
```bash
# Look for window.Tygh or Tygh.$ in page source — definitive CS-Cart signal:
curl -s {site} | grep -i "window\.Tygh\|Tygh\.\$"

# Look for cm-ajax class in forms (AJAX signal):
curl -s {site} | grep -c "cm-ajax"
```

## 6. Source Map Patterns

CS-Cart does **not** generate JavaScript source maps in production by default. Themes compiled
with webpack or Vite (custom themes or heavily modified installs) may expose `.map` files.

```bash
# Check theme JS bundle for source map comment:
curl -s {site}/design/themes/{theme}/media/js/bundle.js | grep "sourceMappingURL"

# Check Tygh core JS (rarely has maps in production):
curl -sI {site}/js/tygh/core.js.map

# Check addon JS bundles:
curl -sI {site}/js/addons/{addon_id}/addon.js.map
```

The active theme name appears in HTML src attributes: look for `/design/themes/{theme-name}/`
patterns. Common default themes include `responsive` (older) and the current default. Custom
themes from the CS-Cart marketplace may use any name.

## 7. Common Add-ons & Extensions

| Add-on | API / endpoint it adds | Detection signal |
|--------|----------------------|-----------------|
| SEO (built-in) | Converts `?dispatch=` to `.html` URLs; enables `/sitemap.xml` | Clean `.html` product URLs; `/sitemap.xml` returns 200 |
| Google Sitemap (built-in) | `/sitemap.xml` — products, categories, pages | GET `/sitemap.xml` returns XML |
| Call Requests (built-in) | `/api/call_requests/` — callback form submissions | `cm-call-request` form class in HTML |
| Discussions / Reviews (built-in) | `/api/discussions/` — product reviews | Review form on product pages |
| Product Variations (built-in) | `/api/product_variations/` — configurable products | Variation select dropdowns on product pages |
| Stripe Payment | Stripe.js loaded; `/index.php?dispatch=checkout.index` | `js.stripe.com` script tag |
| PayPal Payment | PayPal SDK loaded | `paypal.com/sdk/js` script tag |
| ShipStation Integration | Order sync via webhooks; no public endpoint | Admin-configured; not front-end visible |
| GDPR Compliance (official) | Cookie consent banner; `gdpr_accepted` cookie | Banner HTML on first visit |
| Age Verification | Age gate modal on landing | `cm-age-verification` JS class |
| Loyalty Points | `/index.php?dispatch=reward_points.list` | Reward points section in account |
| Multi-Vendor vendors panel | `/api/vendors/` active | Vendor store links on product pages |
| Vendor microstore | `{site}/vendor/{vendor_seo_name}/` | Vendor page URL with vendor slug |

**Marketplace add-on detection pattern:**
CS-Cart add-ons register controllers in `app/controllers/frontend/{addon_name}.php`. Their
front-end routes follow `index.php?dispatch={addon_name}.{mode}`. Enumerate by looking for
non-standard `dispatch=` values in page source links.

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `GET {site}/index.php?dispatch=products.view&product_id={N}` | Full product page HTML: name, price, description, images, options | No auth; iterate product_id from 1 upward |
| `GET {site}/index.php?dispatch=categories.view&category_id={N}` | Category listing: product names, prices, thumbnail images | No auth; iterate category_id |
| `GET {site}/index.php?dispatch=search.index&q={query}` | Search results page (HTML) | No auth |
| `GET {site}/sitemap.xml` | Full product/category/page URL list (SEO addon required) | No auth; most reliable product enumeration source |
| Product page `<script type="application/ld+json">` | JSON-LD: name, price, currency, availability, SKU, image URL | No auth; every product page |
| `GET {site}/api/products/` (with Key) | Full product catalog: IDs, names, prices, descriptions, category_ids, images | Auth required; 10 per page default |
| `GET {site}/api/categories/` (with Key) | Full category tree with parent_id, product_count, seo_name | Auth required |
| `GET {site}/api/currencies/` (with Key) | All currencies with ISO codes, exchange rates, symbols | Auth required; may be public |
| `GET {site}/api/languages/` (with Key) | Available languages with ISO codes | Auth required |
| `GET {site}/api/vendors/` (with Key) | All vendors: company names, ratings, storefronts (MV only) | Auth required; 404 on single-store |
| `GET {site}/api/shipping_methods/` (with Key) | Configured shipping carriers and methods | Auth required |
| `GET {site}/api/payment_methods/` (with Key) | Configured payment processors | Auth required |
| `GET {site}/api/pages/` (with Key) | CMS page list: titles, URLs, content | Auth required |

## 9. Probe Checklist

Run these in order. Record result (✓ 200 / ✗ 403 / – 404 / ? 401) for each.

- [ ] `HEAD {site}` — check `Set-Cookie` for `sid_customer_` prefix (definitive CS-Cart fingerprint)
- [ ] `GET {site}` — grep source for `window.Tygh`, `cm-ajax`, `?dispatch=`, `Tygh.$`; confirm platform and theme name from `/design/themes/{name}/` in src paths
- [ ] `GET {site}/admin.php` — confirm admin entry point; CS-Cart uses `admin.php` (not `/admin/`)
- [ ] `GET {site}/index.php?dispatch=products.view&product_id=1` — confirm storefront routing works; extract JSON-LD from response
- [ ] `GET {site}/index.php?dispatch=categories.view&category_id=1` — category listing page probe
- [ ] `GET {site}/index.php?dispatch=search.index&q=test` — search endpoint reachability
- [ ] `GET {site}/api/` — REST API status: 200=enabled, 401=enabled+key required, 404=disabled
- [ ] `GET {site}/api/products/` (with Key) — product list; note `params.total_items` for catalog size
- [ ] `GET {site}/api/products/1/` (with Key) — single product schema; inspect all available fields
- [ ] `GET {site}/api/categories/` (with Key) — full category tree
- [ ] `GET {site}/api/currencies/` (with Key) — multi-currency detection
- [ ] `GET {site}/api/languages/` (with Key) — multi-language detection
- [ ] `GET {site}/api/orders/` (with Key) — order list; note order status codes and volume
- [ ] `GET {site}/api/users/` (with Key) — user list; note total_items for user base size
- [ ] `GET {site}/api/vendors/` (with Key) — **200/401 = Multi-Vendor edition; 404 = single-store**
- [ ] `GET {site}/api/shipping_methods/` (with Key) — shipping carrier enumeration
- [ ] `GET {site}/api/payment_methods/` (with Key) — payment processor enumeration
- [ ] `GET {site}/api/stores/` (with Key) — multi-storefront detection (CS-Cart edition only)
- [ ] `GET {site}/api/settings/?section=general` (with Key) — store name, company email, base URL
- [ ] `GET {site}/sitemap.xml` — SEO addon status; 200 = addon active; 404 = addon off or htaccess missing
- [ ] Check product page `<script type="application/ld+json">` — extract name, price, SKU, currency, availability without API key
- [ ] Check `sid_admin_` cookie presence — only present after admin authentication
- [ ] `GET {site}/api/product_variations/` (with Key) — configurable product variant enumeration
- [ ] `GET {site}/api/discussions/` (with Key) — review data and sentiment signals
- [ ] `GET {site}/api/pages/` (with Key) — CMS page enumeration (about, contact, policy pages)

## 10. Gotchas

- **API access is per-user and off by default.** Unlike WordPress where `/wp-json/` works unauthenticated, CS-Cart's REST API requires an API key for every request and that key must be explicitly enabled on a user-by-user basis in the admin panel. A 401 on `/api/products/` is the normal state for a store where no API key has been generated. Do not treat 401 as a site-level block — it means the API surface is live and awaiting credentials.

- **Multi-Vendor vs. single-store is detectable via `/api/vendors/`.** The vendors endpoint only exists in the Multi-Vendor edition. A 200 or 401 response confirms Multi-Vendor; a 404 confirms the standard CS-Cart edition. This matters because Multi-Vendor stores have vendor-scoped products, vendor microstore pages (`/vendor/{slug}/`), and separate vendor admin panels that affect what data is visible through the API.

- **`/admin.php` — not `/admin/`.** CS-Cart's admin entry point is `admin.php` in the webroot, not a directory. A directory scan looking for `/admin/` will miss it. CS-Cart does not randomize the admin path by default (unlike PrestaShop).

- **Dispatch routing is the primary fingerprint — SEO addon obscures it.** When the SEO addon is active, storefront URLs become clean `.html` paths and `?dispatch=` patterns disappear from visible URLs. However, the internal routing still works — you can always probe `{site}/index.php?dispatch=products.view&product_id=1` directly regardless of whether friendly URLs are enabled.

- **`/sitemap.xml` requires the SEO addon.** CS-Cart does not generate a sitemap by default. The sitemap is produced only when the SEO add-on is installed and an htaccess rewrite rule is present. A 404 on `/sitemap.xml` is not conclusive — try `{site}/index.php?dispatch=sitemap.view` as an alternative to check if the sitemap controller exists.

- **`window.Tygh` is the most reliable unauthenticated fingerprint.** It is present on every CS-Cart storefront page regardless of SEO addon status, theme, or customizations. Combined with `cm-ajax` in HTML and `sid_customer_*` cookie, three independent definitive signals are available without any authentication.

- **API response pagination defaults to 10 items.** The default `items_per_page` for list endpoints is 10. Always check `params.total_items` in the first response and calculate the number of pages needed. Use `?items_per_page=250` (maximum) to minimize round trips. For stores with thousands of products, iterate pages rather than assuming a single request returns everything.

- **Product IDs are sequential integers starting from 1.** CS-Cart uses auto-increment integer IDs for products, categories, users, and orders. Iterating `product_id` from 1 upward via `?dispatch=products.view&product_id={N}` is a reliable unauthenticated enumeration technique when the API is unavailable. 404 responses do not indicate the end — IDs with deleted products are skipped. Use the sitemap or API for complete coverage.

- **Multi-storefront (CS-Cart edition) vs. Multi-Vendor are separate concepts.** CS-Cart (non-MV) supports multiple storefronts sharing one database but presenting different domains/themes. These are not vendor-separated — they're sub-stores of the same company. The `/api/stores/` endpoint enumerates storefronts; `/api/vendors/` enumerates vendor accounts. Do not conflate them.

- **Session cookies use a hash suffix — use prefix matching.** `sid_customer_` is followed by a 32-character hex hash that varies per installation (generated at install time from the store's secret key). The admin session cookie follows the same pattern: `sid_admin_{hash}`. Detection must be a prefix match (`sid_customer_` or `sid_admin_`) rather than an exact cookie name match.

- **HTTP Basic auth three ways — avoid URL embedding.** CS-Cart accepts the API key via: (1) `Authorization: Basic base64(email:key)` header, (2) `--user email:key` curl shorthand, or (3) inline in the URL as `?email=...&api_key=...`. The third method exposes credentials in server access logs — always prefer the Authorization header.

- **Order statuses use single-letter codes — verify via `/api/statuses/`.** CS-Cart order statuses are single uppercase letters (e.g., `P`=Processed, `C`=Complete, `O`=Open, `F`=Failed). The full set — including any custom statuses added by the store — is returned by `GET /api/statuses/?type=O` (O=order). Always fetch `/api/statuses/` first rather than hardcoding status letters; custom installs may define additional codes and re-map defaults. Use `/api/orders/?status=P` with the correct letter to filter the order list.

- **JSON-LD on product pages is the fastest zero-auth data source.** Every CS-Cart product page (both `?dispatch=` and SEO `.html` URLs) contains a `<script type="application/ld+json">` block with the product's name, price, currency, availability (`InStock`/`OutOfStock`), SKU, brand, and primary image URL. This requires no API key and works even when the REST API is disabled. Pair with sitemap-derived URL lists for full catalog coverage.

- **Add-on controllers follow a predictable dispatch pattern.** Every installed add-on that exposes a front-end controller registers a dispatch value `{addon_id}.{mode}`. Read the page source for non-standard `dispatch=` values (anything that is not products, categories, search, checkout, auth, profiles, order, sitemap) — these reveal installed add-ons. Admin-panel add-on dispatch values follow the same pattern via `admin.php?dispatch={addon}.manage`.
