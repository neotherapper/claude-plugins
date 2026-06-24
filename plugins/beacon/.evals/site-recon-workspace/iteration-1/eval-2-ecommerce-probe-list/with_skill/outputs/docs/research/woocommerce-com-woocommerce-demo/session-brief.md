# Session Brief — woocommerce-com-woocommerce-demo

## Infrastructure
- **Framework:** WordPress 6.9.4 + WooCommerce 10.7.0-rc.1
- **Source:** `x-powered-by: WordPress VIP` (HTTP header) + `wcAnalytics.woo_version` (JS global)
- **Hosting:** WordPress VIP (VIP)
- **CDN:** Unknown (WP VIP behind nginx)
- **Auth:** None for Store API; Consumer key/secret for REST API v3
- **Bot protection:** None detected on curl

## Tool Availability
- [AVAILABLE] curl
- [AVAILABLE] grep
- [AVAILABLE] python3
- [TOOL-UNAVAILABLE:wappalyzer]
- [TOOL-UNAVAILABLE:chrome-devtools-mcp]

## Tech Pack
- [LOADED:woocommerce:10.x] - from wcAnalytics JS global, version: 10.7.0-rc.1

## Discovered Endpoints

| Endpoint | Method | Auth | Phase | Notes |
|----------|--------|------|-------|-------|
| `/wp-json/wc/store/v1/products` | GET | None | 5 | Product listing - working |
| `/wp-json/wc/store/v1/products/{id}` | GET | None | 5 | Single product - working |
| `/wp-json/wc/store/v1/products/collection-data` | GET | None | 5 | Collection aggregates - working |
| `/wp-json/wc/store/v1/products/categories` | GET | None | 5 | Product categories - working |
| `/wp-json/wc/store/v1/products/tags` | GET | None | 5 | Product tags - working |
| `/wp-json/wc/store/v1/products/attributes` | GET | None | 5 | Product attributes - working |
| `/wp-json/wc/store/v1/products/brands` | GET | None | 5 | Product brands - working |
| `/wp-json/wc/v3/products` | GET | 401 | 5 | REST API v3 - auth required |
| `/?wc-ajax=get_refreshed_fragments` | GET | None | 5 | Cart fragments - working |
| `/wp-json/wc/store/v1/cart` | GET | None | 5 | Cart - working |
| `/wp-json/wc/store/v1/checkout` | POST | None | 5 | Checkout - working |
| `/wp-json/` | GET | None | 2 | WP REST API root |

## E-commerce Probe Results
- Products API: YES - `/wp-json/wc/store/v1/products` returns product data
- REST v3 products: 401 (requires consumer key)
- Cart AJAX: YES - `wc-ajax=get_refreshed_fragments` returns cart hash
- Search: Not probed (store is marketplace, not demo store)

## Session Complete
[P1✓] Scaffold and tool check
[P2✓] Passive recon
[P3✓] Fingerprint
[P4✓] Tech pack (woocommerce:10.x)
[P5✓] Known patterns + e-commerce probes
[P6✓] Feeds & structure (WP REST API)
[P7✓] JS & source maps
[P8✓] OpenAPI detect (not found)
[P9✓] OSINT (not needed)
[P10✓] Browse plan (not needed - all APIs detected via curl)
[P11✓] Active browse (skipped - static detection sufficient)
[P12✓] Document

Note: `/woocommerce-demo/` path returns 404. This is actually the main WooCommerce.com marketplace site which has Store API enabled for product browsing.