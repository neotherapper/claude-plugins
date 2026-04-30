# WooCommerce Framework Fingerprinting Guide

## Framework Overview
WooCommerce is a flexible open-source e-commerce plugin for WordPress. It transforms WordPress websites into customizable online stores, offering features like product management, shopping cart functionality, payment processing, and order management. WooCommerce powers over 28% of all online stores.

## Fingerprinting Patterns

### 1. Static File Patterns
WooCommerce has distinctive static file patterns:
- `/wp-content/plugins/woocommerce/` - WooCommerce plugin directory
- `/wp-content/themes/[theme]/woocommerce/` - Theme overrides
- `/wp-content/uploads/woocommerce_uploads/` - Uploaded files
- `/wp-content/plugins/woocommerce/assets/` - WooCommerce assets
- `/wp-content/cache/woocommerce/` - WooCommerce cache
- `/wp-json/wc/` - REST API endpoints
- `/cart/` - Shopping cart
- `/checkout/` - Checkout process
- `/my-account/` - Customer account
- `/shop/` - Product catalog

### 2. HTTP Headers
WooCommerce-enhanced WordPress sites often show:
```
X-WooCommerce-Version: [version]
Set-Cookie: wp_woocommerce_session=[hash]
Set-Cookie: woocommerce_cart_hash=[hash]
Set-Cookie: woocommerce_items_in_cart=[number]
```

### 3. HTML Meta Tags
WooCommerce stores typically include:
```html
<meta name="woocommerce-ver" content="[version]">
<link rel="stylesheet" id="woocommerce-general-css" href="/wp-content/plugins/woocommerce/assets/css/woocommerce.css" />
<script type='text/javascript' src='/wp-content/plugins/woocommerce/assets/js/frontend/woocommerce.min.js'></script>
```

### 4. JavaScript Globals
WooCommerce exposes these global variables:
```javascript
window.wc_add_to_cart_params = {...};
window.woocommerce_params = {
  ajax_url: "/wp-admin/admin-ajax.php",
  wc_ajax_url: "?wc-ajax=...",
  cart_url: "https://example.com/cart/"
};
window.wc_cart_fragments_params = {...};
```

### 5. Common Routes
WooCommerce standard routes:
- `/cart/` - Shopping cart
- `/checkout/` - Checkout process
- `/my-account/` - Customer account
- `/shop/` - Product catalog
- `/product/[product-slug]/` - Single product
- `/product-category/[category-slug]/` - Product category
- `/wishlist/` - Wishlist functionality (with plugin)
- `/compare/` - Product comparison (with plugin)
- `/wp-json/wc/v3/` - REST API
- `/?wc-ajax=[action]` - AJAX endpoints

### 6. API Endpoints
WooCommerce exposes multiple APIs:

**REST API (current version):**
- `/wp-json/wc/v3/products` - Product management
- `/wp-json/wc/v3/orders` - Order management
- `/wp-json/wc/v3/customers` - Customer management
- `/wp-json/wc/v3/coupons` - Coupon management
- `/wp-json/wc/v3/products/reviews` - Review management
- `/wp-json/wc/v3/payment_gateways` - Payment methods
- `/wp-json/wc/v3/shipping_methods` - Shipping methods

**REST API (legacy versions):**
- `/wp-json/wc/v2/` (previous version)
- `/wp-json/wc/v1/` (oldest version)

**WooCommerce AJAX API:**
- `/?wc-ajax=get_refreshed_fragments` - Cart fragments
- `/?wc-ajax=add_to_cart` - Add to cart
- `/?wc-ajax=apply_coupon` - Apply coupon

### 7. Version Fingerprinting
Detect WooCommerce version through:
- `X-WooCommerce-Version` HTTP header
- Meta tag: `<meta name="woocommerce-ver" content="[version]">`
- WooCommerce status page: `/wp-admin/admin.php?page=wc-status`
- REST API header: `X-WC-Version`
- `/wp-content/plugins/woocommerce/readme.txt`
- `/wp-content/plugins/woocommerce/woocommerce.php` (contains version)
- Admin footer version in `/wp-admin/`

### 8. Database Patterns
WooCommerce uses specific database tables:
- `wp_woocommerce_sessions` - Customer sessions
- `wp_woocommerce_api_keys` - API keys
- `wp_woocommerce_downloadable_product_permissions` - Download permissions
- `wp_woocommerce_order_items` - Order items
- `wp_woocommerce_payment_tokens` - Payment tokens

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/wp-content/plugins/woocommerce/
/wp-content/uploads/woocommerce_uploads/
/wp-json/wc/
```

### 2. Common File Discovery
Look for these files:
```
/wp-content/plugins/woocommerce/readme.txt
/wp-content/plugins/woocommerce/woocommerce.php
/wp-content/themes/[theme]/woocommerce/
```

### 3. Framework-Specific Endpoints
Check these WooCommerce-specific endpoints:
```
/wp-json/wc/v3/products
/cart/
/checkout/
/shop/
/?wc-ajax=get_refreshed_fragments
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=31536000
```

### Vulnerable Patterns
- Exposed REST API credentials
- Missing authentication for admin areas
- Directory listing enabled in `/wp-content/`
- Unsecured `/wp-json/` endpoints
- Exposed WooCommerce status information
- Missing updates for WooCommerce core and extensions
- Unprotected `/cart/` and `/checkout/` routes
- SQL injection vulnerabilities in custom queries
- Cross-site scripting in product pages
- Insecure payment gateway integrations

## Technology Stack Integration

### Common WooCommerce Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| WordPress | CMS | WordPress core patterns |
| WordPress REST API | Content API | `/wp-json/` |
| Payment Gateways | Payments | Payment gateway plugins |
| Shipping Services | Shipping | Shipping method plugins |
| Facebook for WooCommerce | Social selling | `/wp-content/plugins/facebook-for-woocommerce/` |
| Google Analytics | Tracking | `analytics.js` |
| Subscription plugins | Subscriptions | Subscription management routes |
| Membership plugins | Membership | Membership management routes |
| Booking plugins | Bookings | Booking management routes |

## Example Fingerprinting Commands

```bash
# Check WooCommerce headers
curl -I https://example.com

# Check WooCommerce REST API
curl -I https://example.com/wp-json/wc/v3/products

# Check for WooCommerce meta tags
curl https://example.com | grep -i "woocommerce"

# Check for WooCommerce cart fragments
curl -I "https://example.com/?wc-ajax=get_refreshed_fragments"

# Check WooCommerce version
curl https://example.com/wp-content/plugins/woocommerce/readme.txt

# Check WooCommerce plugin file
curl https://example.com/wp-content/plugins/woocommerce/woocommerce.php | grep -i "Version:"
```

## False Positives
- WordPress sites without WooCommerce
- Custom WordPress e-commerce solutions
- Other WordPress e-commerce plugins
- Sites with WooCommerce-like routing but different backends
- WordPress sites with `/shop/` but no WooCommerce
- Static sites with similar asset patterns

## Fingerprinting Tooling
- HTTP header analysis for WooCommerce headers
- Static file pattern detection
- REST API endpoint discovery
- JavaScript global detection
- Meta tag analysis
- Route pattern recognition
- Version file detection

## Changelog
- 2026-04-30: Initial guide creation
- Future: Add version-specific fingerprinting patterns