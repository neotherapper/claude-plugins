# woocommerce.com — Research Summary

## Site Overview
| Property | Value |
|----------|-------|
| URL | https://woocommerce.com |
| Framework | WordPress 6.9.4 |
| Platform | WordPress VIP |
| Server | nginx |
| CDN | Cloudflare |
| E-commerce | WooCommerce 9.x |

## Quick API Reference

### Public Endpoints (No Auth Required)
| Endpoint | Method | Notes |
|----------|--------|-------|
| [wp-json/wc/store/v1/products](wp-json/wc/store/v1/products) | GET | Store API - 100 products per page |
| [wp-json/wc/store/v1/products/categories](wp-json/wc/store/v1/products/categories) | GET | 95 categories |
| [wp-json/wc/store/v1/cart](wp-json/wc/store/v1/cart) | GET | Session-bound cart |

### Authenticated Endpoints (Consumer Key Required)
| Endpoint | Method | Notes |
|----------|--------|-------|
| `/wp-json/wc/v3/products` | GET | Requires Consumer Key |
| `/wp-json/wc/v3/orders` | GET/POST | Requires auth |
| `/wp-json/wc/v3/system_status` | GET | Full environment dump |

### AJAX Endpoints
| Endpoint | Method | Notes |
|----------|--------|-------|
| `/?wc-ajax=get_refreshed_fragments` | POST | Cart fragments |

## Discovery Summary
- ✓ REST API enabled
- ✓ WooCommerce namespaces: wc/v3, wc/store/v1, wc/v2
- ✓ Public Store API accessible (no auth)
- ✓ WC REST API gated (auth required)
- ✓ AJAX cart endpoints active

## Output Files
- [tech-stack.md](tech-stack.md) — Framework and infrastructure details
- [site-map.md](site-map.md) — All discovered URLs
- [constants.md](constants.md) — Taxonomy IDs and config
- [api-surfaces/woocommerce-store-api.md](api-surfaces/woocommerce-store-api.md) — Store API details