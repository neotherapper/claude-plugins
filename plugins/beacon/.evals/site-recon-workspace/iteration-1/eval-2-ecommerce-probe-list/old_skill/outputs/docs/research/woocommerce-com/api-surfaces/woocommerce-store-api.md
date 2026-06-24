# WooCommerce Store API Surface

## Overview
The Store API (`/wp-json/wc/store/v1/`) is the modern headless API for WooCommerce Blocks. All endpoints are publicly accessible without authentication.

## Endpoints Discovered

### Products
| Endpoint | Method | Auth | Description |
|-----------|--------|------|-------------|
| `/wc/store/v1/products` | GET | None | Product list (public, paginated) |
| `/wc/store/v1/products/{id}` | GET | None | Single product |
| `/wc/store/v1/products/categories` | GET | None | Category list |

### Cart
| Endpoint | Method | Auth | Description |
|-----------|--------|------|-------------|
| `/wc/store/v1/cart` | GET | Session | Current cart state |

## Product Schema (Store API)
```json
{
  "id": 18734006521588,
  "name": "Smart Dynamic Pricing",
  "slug": "smart-dynamic-pricing",
  "type": "simple",
  "permalink": "https://woocommerce.com/products/smart-dynamic-pricing/",
  "sku": "",
  "short_description": "...",
  "description": "...",
  "price": "...",
  "regular_price": "...",
  "sale_price": "",
  "on_sale": false,
  "purchasable": false,
  "total_sales": 0,
  "rating_count": 0,
  "average_rating": "0.00",
  "categories": [...],
  "tags": [...],
  "images": [...],
  "attributes": [...]
}
```

## Limits
- Max products per page: 100
- Public access: Yes (no auth required)