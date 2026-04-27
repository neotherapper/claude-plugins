# WooCommerce Store API Surface

## Overview
The WooCommerce Store API (`/wc/store/v1/`) provides public REST endpoints for customer-facing functionality without authentication.

## Endpoints

### Products
```
GET /wc/store/v1/products
GET /wc/store/v1/products/{id}
GET /wc/store/v1/products/collection-data
GET /wc/store/v1/products/attributes
GET /wc/store/v1/products/attributes/{id}
GET /wc/store/v1/products/attributes/{id}/terms
GET /wc/store/v1/products/categories
GET /wc/store/v1/products/brands
GET /wc/store/v1/products/reviews
GET /wc/store/v1/products/tags
```

**Example Request:**
```bash
curl https://woocommerce.com/wp-json/wc/store/v1/products?per_page=5
```

**Example Response:**
```json
[
  {
    "id": 18734006521588,
    "name": "Smart Dynamic Pricing",
    "slug": "smart-dynamic-pricing",
    "permalink": "https://woocommerce.com/products/smart-dynamic-pricing/",
    "prices": {
      "price": "12900",
      "regular_price": "12900",
      "sale_price": "12900",
      "currency_code": "USD"
    },
    "add_to_cart": {
      "text": "Add to cart",
      "url": "/wp-json/wc/store/v1/products?per_page=5&add-to-cart=18734006521588"
    }
  }
]
```

### Cart
```
GET /wc/store/v1/cart
POST /wc/store/v1/cart/add-item
POST /wc/store/v1/cart/remove-item
POST /wc/store/v1/cart/update-item
POST /wc/store/v1/cart/apply-coupon
POST /wc/store/v1/cart/remove-coupon
POST /wc/store/v1/cart/update-customer
POST /wc/store/v1/cart/select-shipping-rate
```

### Cart Items
```
GET /wc/store/v1/cart/items
POST /wc/store/v1/cart/items
DELETE /wc/store/v1/cart/items
GET /wc/store/v1/cart/items/{key}
PUT /wc/store/v1/cart/items/{key}
DELETE /wc/store/v1/cart/items/{key}
```

### Checkout
```
GET /wc/store/v1/checkout
POST /wc/store/v1/checkout
PUT /wc/store/v1/checkout
POST /wc/store/v1/checkout/{id}
GET /wc/store/v1/order/{id}
```

## Cart Fragments (Legacy AJAX)
```
GET /?wc-ajax=get_refreshed_fragments
```

**Response:**
```json
{
  "fragments": {
    "a.cart-button": "...",
    "a.cart-contents": "..."
  },
  "cart_hash": "20aa8bd0fef9e9f711ffa92c9b7a4d8e"
}
```

## Notes
- **Auth:** None required for Store API
- **Cross-origin:** Requires nonces from page context
- **Headers:** `Nonce` and `Nonce-Timestamp` required for cart/checkout writes