---
framework: sfcc
version: "current"
last_updated: "2026-04-28"
author: "@neotherapper"
status: official
---

# Salesforce Commerce Cloud (SFCC) — Tech Pack

SFCC (formerly Demandware, acquired by Salesforce in 2016) is an enterprise SaaS e-commerce platform used by major retailers globally. The platform ships continuous monthly releases (e.g., B2C Commerce 26.4 is current as of early 2026). SFCC has two API families: the modern SCAPI (2021+, OAuth 2.1 via SLAS) and the legacy OCAPI (deprecated but still widely deployed).

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `demandware.net` in HTML | HTML source | Hostname present in `<script src>`, `<img src>`, or CDN references | Definitive |
| `commercecloud.salesforce.com` in HTML | HTML source | Hostname present in script tags, API calls, or CDN references | Definitive |
| `dwanonymous_` cookie | Cookie | Demandware anonymous session cookie; prefix is platform-invariant | Definitive |
| `dwsid` cookie | Cookie | Demandware session ID cookie | Definitive |
| `dw_*` cookie pattern | Cookie | Any cookie prefixed with `dw` (dwanonymous, dwsid, dw_dnt) | Definitive |
| `dw.js` script loaded | Script tag | Script src contains `dw.js`; Demandware analytics loader | Definitive |
| `x-dw-request-base-url` response header | HTTP header | Set by the platform on all storefront responses | Definitive |
| `Sites-{SiteID}-Site` URL pattern | URL | Appears in storefront controller URLs and static asset paths | Definitive |
| `window.SFRA` JS global | JS global | Present on Storefront Reference Architecture (SFRA) storefronts | High |
| `window.SiteControllerURL` JS global | JS global | Set by SFRA; contains the site controller base URL | High |
| `__VERSION__` JS global | JS global | Salesforce Commerce platform version string | High |
| `cdn.salesforce.com` CDN reference | HTML source | CDN hostname in script or asset URLs | High |
| Wappalyzer category `Salesforce Commerce Cloud` | Extension | Wappalyzer fingerprints SFCC via cookie and script patterns | High |

**Extract site and platform signals from HTML:**

```bash
# Detect Demandware/SFCC fingerprint:
curl -s https://STORE_DOMAIN/ | grep -oi 'demandware\|commercecloud\|dwanonymous\|Sites-'

# Extract the SiteID from Sites-{SiteID}-Site pattern:
curl -s https://STORE_DOMAIN/ | grep -oP 'Sites-\K[^-/"]+(?=-Site)'

# Extract org ID from SCAPI URLs embedded in JS (format: f_ecom_{realm}_{tenant}):
curl -s https://STORE_DOMAIN/ | grep -oP 'organizations/\K[^/"?]+'

# Check SFRA config object for site metadata:
curl -s https://STORE_DOMAIN/ | grep -o 'window\.SFRA\s*=\s*{[^<]*' | head -c 500
```

## 2. Default API Surfaces

### 2a. SCAPI — Shopper API (Modern, 2021+)

Base URL: `https://api.commercecloud.salesforce.com/`

All SCAPI endpoints require OAuth 2.1 Bearer token via SLAS (see Section 4).

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://api.commercecloud.salesforce.com/customer/shopper-login/v1/organizations/{org_id}/oauth2/token` | POST | Basic (client_id:secret) or public client | SLAS token endpoint; guest and registered shopper flows |
| `https://api.commercecloud.salesforce.com/product/shopper-products/v1/organizations/{org_id}/products` | GET | Bearer | Product details; `ids` param for batch lookup |
| `https://api.commercecloud.salesforce.com/product/shopper-products/v1/organizations/{org_id}/categories` | GET | Bearer | Category tree; `id` and `levels` params |
| `https://api.commercecloud.salesforce.com/search/shopper-search/v1/organizations/{org_id}/product-search?q={q}&siteId={site_id}` | GET | Bearer | Product search with sorting and refinements |
| `https://api.commercecloud.salesforce.com/checkout/shopper-baskets/v1/organizations/{org_id}/baskets` | POST | Bearer | Create basket (cart) |
| `https://api.commercecloud.salesforce.com/checkout/shopper-baskets/v1/organizations/{org_id}/baskets/{basket_id}` | GET | Bearer | Retrieve basket contents |
| `https://api.commercecloud.salesforce.com/customer/shopper-customers/v1/organizations/{org_id}/customers/{customer_no}` | GET | Bearer | Authenticated customer profile |
| `https://api.commercecloud.salesforce.com/pricing/shopper-promotions/v1/organizations/{org_id}/promotions` | GET | Bearer | Active promotions; `ids` param |
| `https://api.commercecloud.salesforce.com/checkout/shopper-orders/v1/organizations/{org_id}/orders` | POST | Bearer | Place order from basket |

### 2b. OCAPI — Open Commerce API (Legacy, Deprecated)

Base URL: `https://{instance}.commercecloud.salesforce.com/s/{site_id}/dw/shop/v{version}/`

OCAPI is officially deprecated but still widely deployed on stores built before 2022. Common versions in active use: `v22_10`, `v23_2`; version format for recent years follows `v{yy}_{n}` (e.g., `v24_1`, `v25_2`).

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `{base}/products/{product_id}` | GET | `x-dw-client-id` header or Basic | Single product with images, variants, prices |
| `{base}/product_search?q={q}&count=25` | GET | `x-dw-client-id` header | Product search; public client ID required |
| `{base}/categories/{category_id}?levels=3` | GET | `x-dw-client-id` header | Category tree with subcategories |
| `{base}/baskets` | POST | `x-dw-client-id` header + `dwsid` cookie | Create shopping basket |
| `{base}/baskets/{basket_id}` | GET | `x-dw-client-id` header + session cookie | Retrieve basket |
| `{base}/sessions` | POST | `x-dw-client-id` header | Create session; returns `dwsid` cookie |

**Store controller routes (SFRA — public):**

| Path | Description |
|------|-------------|
| `/` | Homepage |
| `/search?q={query}` | Search results page |
| `/product/{product_id}` | Product detail page |
| `/category/{category_id}` | Category listing page |
| `/on/demandware.store/Sites-{site_id}-Site/default/Checkout-Begin` | Checkout start (session required) |
| `/on/demandware.store/Sites-{site_id}-Site/default/Cart-Show` | Cart page |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.SFRA` | View page source or browser console | Site controller URL, locale, currency, checkout URL |
| `window.SiteControllerURL` | Browser console | Base URL for SFRA controller requests |
| `window.__VERSION__` | Browser console | Platform version string |
| Inline `<script>` tags in HTML | View page source | `site_id`, `locale`, OCAPI client ID sometimes hardcoded |
| SFRA `require.config` block | View page source | Module paths, cart URL, search URL |
| `Sites-{SiteID}-Site` URL pattern | Network requests / page source | SiteID extraction |
| SCAPI URLs in loaded JS bundles | Browser DevTools Network tab | `organization_id` in path (`f_ecom_{realm}_{tenant}`) |
| `configurator.cquotient.com` | Network traffic | Einstein Recommendations configuration endpoint |
| `data-pid` attributes on HTML elements | View page source | Product IDs embedded in PDP/PLP markup |

## 4. Auth Patterns

### SCAPI — SLAS (Shopper Login and API Security Service)

| Pattern | Location | Notes |
|---------|----------|-------|
| Guest token via `client_credentials` | POST to `/oauth2/token` body | `channel_id` (siteId) is now required; returns `access_token` and `refresh_token` |
| Registered shopper token via PKCE | POST to `/oauth2/token` body | `grant_type=authorization_code_pkce`; full OAuth 2.1 PKCE flow |
| `Authorization: Bearer {access_token}` | HTTP request header | All SCAPI Shopper API calls |
| `Authorization: Basic base64({client_id}:{client_secret})` | HTTP request header | Private SLAS client token requests |
| JWT enhancements (March 2026) | Token payload | SLAS JWTs now include additional claims (sub, sfdc_community_id) |

**Guest access token — SLAS (private client):**

```bash
# Obtain a guest access token via SLAS (private client):
POST https://api.commercecloud.salesforce.com/customer/shopper-login/v1/organizations/{org_id}/oauth2/token
  Content-Type: application/x-www-form-urlencoded
  Authorization: Basic base64({client_id}:{client_secret})
  Body: grant_type=client_credentials&channel_id={site_id}

# Returns: {"access_token": "...", "token_type": "Bearer", "expires_in": 1800}
```

**Guest access token — SLAS (public client, no secret):**

```bash
# Public client guest flow — no client secret required:
POST https://api.commercecloud.salesforce.com/customer/shopper-login/v1/organizations/{org_id}/oauth2/token
  Content-Type: application/x-www-form-urlencoded
  Body: grant_type=client_credentials&channel_id={site_id}&client_id={public_client_id}
```

### OCAPI Auth

| Pattern | Location | Notes |
|---------|----------|-------|
| `x-dw-client-id: {client_id}` | HTTP request header | Public OCAPI client ID; often visible in browser network requests |
| `dwanonymous_*` cookie | Cookie jar | Session continuity for anonymous OCAPI calls |
| `dwsid` cookie | Cookie jar | Session ID; obtained via `POST {base}/sessions` |
| Basic auth | HTTP request header | Used on some non-public OCAPI endpoints |

**Locate OCAPI client ID in browser:**

```bash
# Find the OCAPI client ID embedded in JS bundles:
curl -s https://STORE_DOMAIN/ | grep -oP '(?:client.?id|clientId)["\s:=]+\K[a-zA-Z0-9_-]{10,}'

# Or extract from network traffic — look for x-dw-client-id header in XHR requests
```

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `/on/demandware.static/-/Sites-{catalog}/default/` | Product images and catalog static files |
| `/on/demandware.static/-/Library-Sites-{shared}/default/` | Shared library assets (banners, content slots) |
| `/s/{site_id}/on/demandware.static/Sites-{site_id}-Site/default/js/main.js` | SFRA main JS bundle |
| `/s/{site_id}/on/demandware.static/Sites-{site_id}-Site/default/js/vendor.js` | SFRA vendor bundle |
| `/s/{site_id}/on/demandware.static/Sites-{site_id}-Site/default/css/` | SFRA stylesheet assets |
| `/on/demandware.static/-/Sites-{site_id}/default/` | Custom cartridge static assets |
| `/on/demandware.store/Sites-{site_id}-Site/default/__Analytics-Start` | Demandware analytics endpoint; always present |

Extract asset URLs from HTML `<script src>` and `<link href>` tags — the site ID in paths is store-specific and must be read from the live page. Static paths follow a predictable structure once the site ID is known.

## 6. Source Map Patterns

SFRA's standard build pipeline does not publish source maps to the CDN. Custom cartridge JS bundles are rarely deployed with source maps. Source maps are effectively absent on the vast majority of SFCC storefronts.

**Check for source maps on SFRA JS bundles:**

```bash
# Extract a real bundle URL from the page:
SCRIPT_URL=$(curl -s https://STORE_DOMAIN/ | grep -oP 'https://[^"]+demandware\.static[^"]+\.js' | head -1)
# Probe for a .map file:
curl -I "${SCRIPT_URL}.map"
# Check for SourceMap response header on the script itself:
curl -I "${SCRIPT_URL}" | grep -i sourcemap
```

**Headless SFCC (PWA Kit / SCAPI-backed React app):**

```bash
# PWA Kit (React/Next.js or Remix backed by SCAPI) may expose source maps:
curl -I https://STORE_DOMAIN/_next/static/chunks/pages/index.js.map
# Check SourceMap header on chunk assets:
curl -I https://STORE_DOMAIN/static/js/main.chunk.js
```

Source maps may appear on PWA Kit headless deployments depending on the build configuration; absent on all standard SFRA Liquid-equivalent (server-rendered) storefronts.

## 7. Common Plugins & Extensions

| Integration | API it adds | Detection signal |
|-------------|-------------|------------------|
| Einstein Recommendations | Product recommendation slots via `api.cquotient.com` | `api.cquotient.com` or `cdn.cquotient.com` in network traffic; `configurator.cquotient.com` config requests |
| Akamai WAF | CDN and WAF layer; not a store feature but universal | `akamai` or `akamaiedge.net` in response headers (`server`, `via`); aggressive 403 on curl probes |
| Cloudflare WAF | CDN and WAF layer; common on custom-domain stores | `cf-ray`, `cf-cache-status` response headers |
| Klaviyo | Email/SMS marketing; JS tracking events | `//a.klaviyo.com/` script in HTML; `_kx` cookie |
| Bazaarvoice | Product reviews widget | `display.ugc.bazaarvoice.com` script tag; `/bvstaging/` paths |
| Yotpo | Product reviews | `staticw2.yotpo.com` script tag |
| Algolia | Search-as-a-service replacing native OCAPI search | Network requests to `*.algolia.net` or `*.algolianet.com`; `cdn.jsdelivr.net/npm/algoliasearch` or `cdn.jsdelivr.net/npm/instantsearch.js` script tags |
| PowerReviews | Product reviews | `ui.powerreviews.com` script tag |
| Salesforce Order Management (OMS) | Order lifecycle APIs | `ordermanagement.salesforce.com` references in JS or network |
| Adyen | Payment processing | `//checkoutshopper-live.adyen.com/` script |
| Stripe | Payment processing (less common on enterprise SFCC) | `js.stripe.com` script tag |

## 8. Known Public Data

Unlike Shopify, SFCC has no unauthenticated product catalog API. Public data is limited to what is rendered in HTML or accessible via standard sitemap conventions.

| Endpoint / Location | Data | Notes |
|--------------------|------|-------|
| `/sitemap.xml` | Top-level sitemap index | Enterprise sitemaps are large; often a sitemap index linking to multiple child sitemaps |
| `/sitemap-products.xml` (or similar) | All product URLs | Filename varies; discover by reading sitemap index |
| `/sitemap-categories.xml` (or similar) | All category URLs | Filename varies |
| HTML page source of PDP | Product ID, name, price, images, description | Rendered server-side; accessible without auth via standard GET |
| HTML page source of PLP | Category products list with IDs and prices | Server-rendered; paginated via query string |
| `data-pid` attributes on HTML | Product IDs on PDP/PLP pages | Reliable extraction point without API auth |
| `{base}/product_search?q=test&count=5` (OCAPI) | Product search results | Requires valid OCAPI `x-dw-client-id`; client ID sometimes visible in JS |
| `{base}/categories/root?levels=2` (OCAPI) | Category tree | Requires valid OCAPI `x-dw-client-id` |
| `/on/demandware.store/Sites-{site_id}-Site/default/__Analytics-Start` | Demandware analytics pixel | Always publicly accessible; confirms store is live |

## 9. Probe Checklist

- [ ] `HEAD https://STORE_DOMAIN/` — check response headers for `x-dw-request-base-url` (Definitive); check `Set-Cookie` for `dwanonymous_*` and `dwsid` (Definitive)
- [ ] `GET https://STORE_DOMAIN/` — grep HTML for `demandware`, `dwanonymous`, `Sites-`, `window.SFRA`, `window.SiteControllerURL` to confirm SFCC fingerprint
- [ ] Extract SiteID from `Sites-{SiteID}-Site` pattern in page source or static asset URLs
- [ ] Extract organization ID from SCAPI URLs in JS bundles — pattern: `organizations/f_ecom_` — captures `{org_id}` for SCAPI calls
- [ ] `GET https://STORE_DOMAIN/on/demandware.store/Sites-{site_id}-Site/default/` — confirms Demandware store controller is active; 200 or redirect is positive signal
- [ ] `GET https://STORE_DOMAIN/sitemap.xml` — retrieve sitemap index; follow child sitemap links to enumerate product and category URLs
- [ ] Attempt OCAPI: `GET {base}/product_search?q=test&count=5&client_id={client_id}` — if client ID found in JS, test OCAPI product search
- [ ] Attempt OCAPI: `GET {base}/categories/root?levels=2&client_id={client_id}` — retrieve category tree
- [ ] If org_id found: `POST` SLAS token endpoint with `grant_type=client_credentials&channel_id={site_id}` — obtain guest Bearer token for SCAPI
- [ ] If Bearer token obtained: `GET` SCAPI product search `https://api.commercecloud.salesforce.com/search/shopper-search/v1/organizations/{org_id}/product-search?q=test&siteId={site_id}` — confirm SCAPI access
- [ ] Check browser DevTools Network tab for `x-dw-client-id` header in XHR requests — exposes OCAPI client ID
- [ ] Check browser DevTools Network tab for `api.cquotient.com` requests — confirms Einstein Recommendations integration
- [ ] Scan HTML `<script src>` tags for third-party signals — Klaviyo, Bazaarvoice, Adyen, PowerReviews, Algolia
- [ ] `GET https://STORE_DOMAIN/sitemap.xml` — note total number of product URLs for catalog size estimation

## 10. Gotchas

- **Enterprise WAF blocks all curl probes:** Akamai and Cloudflare WAFs are effectively universal on SFCC production stores. Curl probes will return 403 or be silently dropped. All actual probing must be done via browser fetch or DevTools network capture. The probe checklist above assumes browser-based access for live stores.

- **OCAPI is deprecated — SCAPI is the future:** Salesforce officially deprecated OCAPI in 2022. New stores are built on SCAPI. However, the majority of live enterprise storefronts still use OCAPI (built pre-2022), and OCAPI will remain supported for years. Always probe for both; many stores support both simultaneously.

- **SCAPI requires OAuth 2.1 — no unauthenticated product APIs:** Unlike Shopify's public `/products.json`, SFCC SCAPI has no unauthenticated catalog access. Every SCAPI call requires a Bearer token from SLAS. Guest tokens are obtainable without shopper credentials but still require a registered `client_id` (and optionally `client_secret`).

- **`channel_id` is now required for guest tokens:** As of early 2025, SLAS enforces `channel_id` (the site ID) on `client_credentials` grant requests. Omitting it returns 400. Always include `channel_id={site_id}` in the token request body.

- **Site ID and instance name are different identifiers:** The Site ID (`Sites-{SiteID}-Site`) is a logical identifier for the storefront. The instance name (`{instance}.commercecloud.salesforce.com`) is the hosting infrastructure identifier. Production stores use custom domains that hide the instance name — use `demandware.net` CDN references or the `x-dw-request-base-url` header to discover the instance name.

- **Organization ID format is decodable:** The `org_id` in SCAPI URLs follows the format `f_ecom_{realm}_{tenant}`. This is extractable from any SCAPI URL embedded in JS bundles or network traffic. Knowing the org_id is the key to all SCAPI calls.

- **SFRA vs SiteGenesis are different fingerprints:** SFRA (Storefront Reference Architecture, 2018+) is the modern frontend and sets `window.SFRA`. SiteGenesis (pre-2018, legacy) does not set this global but still uses the same `demandware.net` cookies and URLs. Most live enterprise stores have migrated to SFRA; SiteGenesis stores are increasingly rare.

- **OCAPI version numbers follow the year:** OCAPI version URLs use the pattern `v{yy}_{n}` — e.g., `v22_10`, `v23_2`, `v24_1`. A store may support multiple OCAPI versions simultaneously. Try the most recent version first; fall back if a 404 is returned. Starting with B2C Commerce 26.2, version numbers with leading zeros are rejected with 400.

- **Einstein Recommendations use a separate domain:** AI-powered product recommendations are served from `api.cquotient.com` (the original Demandware AI company). These requests are visible in browser network traffic and confirm Einstein Recommendations integration. The `configurator.cquotient.com` endpoint handles configuration.

- **Sandbox URLs reveal instance structure:** Sandbox instances follow the URL pattern `{instance}-{realm}-{account}.commercecloud.salesforce.com`. Production stores use custom domains and never expose this structure directly.

- **PWA Kit is a different fingerprint from SFRA:** Salesforce PWA Kit (React/Next.js) is SFCC's headless frontend. It calls SCAPI but renders as a React SPA — standard SFRA signals (`window.SFRA`, `demandware.static` paths) are absent. Detect PWA Kit by React chunk patterns (`/_next/`, `/static/js/`), SCAPI calls in network traffic, and Salesforce Commerce Cloud response headers.

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
import sys
try:
    import mmh3
    data = sys.stdin.buffer.read()
    print('Favicon hash:', mmh3.hash(data))
except ImportError:
    print('Install mmh3: pip install mmh3')
"

# Search Shodan for same favicon (indicates shadow IT subdomains)
# site:shodan.io search: icon_hash:{hash}
```

**What it reveals:** Hidden subdomains running same framework stack as main site.

### Source Map Discovery

Check for source maps across all JS bundles:

```bash
# Extract all JS bundle URLs from HTML
curl -s "https://{domain}/" | grep -oP 'src="[^"]+\.js[^"]*"' | grep -oP '"[^"]+"' | tr -d '"' > js_urls.txt

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
| Express | `/api/*`, `/v1/*`, `/health` |
| Astro | `/_astro/*`, `/api/*` |
| Ghost | `/ghost/api/*`, `/members/api/*` |

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

