# woocommerce.com Research

## Overview
Research target: woocommerce.com (WooCommerce.com marketplace demo store)

## Infrastructure
| Component | Value |
|----------|-------|
| **Framework** | WordPress 6.9.4 |
| **E-commerce** | WooCommerce 10.7.0-rc.1 |
| **Hosting** | WordPress VIP (nginx) |
| **CDN** | WP VIP |
| **Auth** | None (Store API) / Consumer key (REST API v3) |

## Tech Pack
| Framework | Version | Source |
|-----------|---------|--------|
| WordPress | 6.9.4 | generator meta |
| WooCommerce | 10.7.0-rc.1 | wcAnalytics JS global |

## Discovered APIs

### WooCommerce Store API (No Auth)
- `GET /wc/store/v1/products` — Product listing
- `GET /wc/store/v1/products/{id}` — Single product
- `GET /wc/store/v1/products/collection-data` — Collection aggregates
- `GET /wc/store/v1/products/categories` — Product categories
- `GET /wc/store/v1/products/tags` — Product tags
- `GET /wc/store/v1/products/attributes` — Product attributes
- `GET /wc/store/v1/products/brands` — Product brands
- `GET /wc/store/v1/cart` — Cart (requires nonce)
- `POST /wc/store/v1/checkout` — Checkout

### WooCommerce REST API v3 (Auth Required)
- `GET /wc/v3/products` — 401 Unauthorized
- `GET /wc/v3/orders` — Requires auth
- Auth via consumer key/secret

### Legacy AJAX
- `GET /?wc-ajax=get_refreshed_fragments` — Cart fragments

## Quick Reference
```bash
# Products (no auth)
curl https://woocommerce.com/wp-json/wc/store/v1/products?per_page=5

# Categories
curl https://woocommerce.com/wp-json/wc/store/v1/products/categories

# Cart fragments
curl "https://woocommerce.com/?wc-ajax=get_refreshed_fragments"
```

## Status
- **PHASE-11-SKIPPED** — All APIs detected via curl probes
- **OPENAPI_STATUS:** Not generated (static detection sufficient)