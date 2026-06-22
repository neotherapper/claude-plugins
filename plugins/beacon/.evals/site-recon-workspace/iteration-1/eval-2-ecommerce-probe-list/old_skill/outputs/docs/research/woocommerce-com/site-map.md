# woocommerce.com — Site Map

## Discovered URLs

### REST API Endpoints
| Endpoint | Namespace | Auth | Status |
|----------|----------|------|--------|
| `/wp-json/` | wp/v2 | None | ✓ 200 |
| `/wp-json/wc/v3/` | wc/v3 | Consumer Key | ✓ 200 |
| `/wp-json/wc/v3/products` | wc/v3 | Consumer Key | 401 (auth required) |
| `/wp-json/wc/store/v1/products` | wc/store/v1 | None | ✓ 200 (100 items) |
| `/wp-json/wc/store/v1/categories` | wc/store/v1 | None | ✓ 200 (95 categories) |
| `/wp-json/wc/store/v1/cart` | wc/store/v1 | Session | ✓ 200 |

### AJAX Endpoints
| Endpoint | Method | Auth | Status |
|----------|--------|------|--------|
| `/?wc-ajax=get_refreshed_fragments` | POST | Cookie | ✓ 200 |

### Legacy Endpoints
| Endpoint | Notes |
|----------|-------|
| `/feed/` | Accessible (empty output?) |

### JS Assets
| Path | Status |
|------|--------|
| `/wp-content/plugins/woocommerce/assets/js/frontend/woocommerce.min.js` | ✓ 200 |

### Discovery Signatures
- `/robots.txt` — ✓ 200
- Sitemap: disabled or not accessible