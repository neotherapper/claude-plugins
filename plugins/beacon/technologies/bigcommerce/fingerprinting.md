# BigCommerce Framework Fingerprinting Guide

## Framework Overview
BigCommerce is a leading cloud-based e-commerce platform designed for scaling businesses. It provides a comprehensive set of features for online stores including product management, shopping cart functionality, checkout processes, and multi-channel selling. BigCommerce is particularly popular among mid-sized to enterprise businesses.

## Fingerprinting Patterns

### 1. HTTP Headers
BigCommerce applications have distinctive HTTP headers:
```
X-Bc-Api-Version: [version]
X-Bc-Store-Version: [version]
Server: BC/ocst-[version]
X-Site-Id: [store-id]
```

### 2. Static File Patterns
BigCommerce has distinctive static file patterns:
- `/bc-static/` - BigCommerce static assets
- `/product-images/` - Product images directory
- `/content/` - Content assets
- `/stencil/` - Theme assets
- `/assets/js/` - JavaScript files
- `/assets/css/` - Stylesheets
- `/s/[store-hash]/file/[file-id]` - File uploads

### 3. HTML Meta Tags
BigCommerce apps often include these meta tags:
```html
<meta name="generator" content="BigCommerce" />
<meta name="store-id" content="[store-id]" />
<meta name="stencil-version" content="[version]" />
<meta name="api-version" content="[version]" />
```

### 4. JavaScript Globals
BigCommerce exposes these global variables:
```javascript
window.store_hash = "[hash]";
window.stencil_version = "[version]";
window.bigcommerce = {
  store_hash: "[hash]",
  store_url: "https://store-[hash].mybigcommerce.com"
};
```

### 5. Common Routes
Standard BigCommerce routes:
- `/` - Storefront homepage
- `/api/storefront/` - Storefront API endpoints
- `/api/v2/` - REST API endpoints
- `/checkout` - Checkout process
- `/cart` - Shopping cart
- `/account.php` - Customer account
- `/login.php` - Customer login
- `/search.php` - Product search
- `/wishlist.php` - Wishlist functionality
- `/pages/` - Content pages

### 6. API Endpoints
BigCommerce exposes multiple API surfaces:

**Storefront API (requires Storefront API token):**
- `/api/storefront/cart` - Shopping cart management
- `/api/storefront/products` - Product data
- `/api/storefront/categories` - Category management
- `/api/storefront/brands` - Brand management
- `/api/storefront/checkout` - Checkout process

**REST API (BASIC AUTH or OAUTH):**
- `/api/v2/store` - Store information
- `/api/v2/products` - Product management
- `/api/v2/categories` - Category management
- `/api/v2/orders` - Order management
- `/api/v2/customers` - Customer management
- `/api/v2/payment_methods` - Payment methods
- `/api/v2/shipping_methods` - Shipping methods

**GraphQL Storefront API:**
- `/graphql` - GraphQL endpoint for storefront data

### 7. Error Pages
BigCommerce error pages:
- **404**: Customizable 404 page
- **500**: Server error with BigCommerce branding
- **503**: "Store Unavailable" page
- **Maintenance**: "This store is temporarily closed for maintenance"

### 8. Version Fingerprinting
Detect BigCommerce version through:
- `X-Bc-Api-Version` HTTP header
- `X-Bc-Store-Version` HTTP header
- `/api/v2/store` endpoint response
- Meta tags in HTML source
- JavaScript globals exposing version
- Theme files containing version references

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/api/
/bc-static/
/stencil/
/assets/
/product-images/
/content/
```

### 2. Common File Discovery
Look for these files:
```
/.well-known/bigcommerce/
/config.json
/store-profile
/theme/
```

### 3. Framework-Specific Endpoints
Check these BigCommerce-specific endpoints:
```
/api/storefront/cart
/api/storefront/products
/api/v2/store
/graphql
/.well-known/bigcommerce/
/stencil/config.js
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self' *.bigcommerce.com
```

### Vulnerable Patterns
- Exposed Storefront API tokens
- Unprotected REST API endpoints
- Missing IP restrictions for admin access
- Default credentials for admin interface
- Unpatched version vulnerabilities
- Exposed sensitive data in JavaScript
- Missing CSRF protection on forms
- Unsecured GraphQL endpoints

## Technology Stack Integration

### Common BigCommerce Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| Stencil | Frontend templating | `/stencil/` directory, theme files |
| Handlebars | Templating engine | Handlebars syntax in templates |
| JavaScript | Frontend logic | `/assets/js/` files, global variables |
| CDN | Asset delivery | `cdn*.bigcommerce.com` domains |
| Payment Gateways | Payments | Payment method configurations |
| ERP Systems | Enterprise integration | `/api/v2/` endpoint usage |
| CMS | Content management | `/pages/`, `/blog/` routes |

## Example Fingerprinting Commands

```bash
# Check BigCommerce headers
curl -I https://example.com

# Check Storefront API
curl -I https://example.com/api/storefront/cart

# Extract version from headers
curl -I https://example.com | grep -i "X-Bc"

# Check for BigCommerce meta tags
curl https://example.com | grep -i "BigCommerce"

# Check REST API (may require auth)
curl -u username:api_token https://example.com/api/v2/store

# Check GraphQL endpoint
curl -I https://example.com/graphql
```

## False Positives
- Custom-built stores using similar API patterns
- Other e-commerce platforms with `/api/` endpoints
- Static sites using similar CDN structures
- Generic cloud hosting with BigCommerce-like headers

## Fingerprinting Tooling
- HTTP header analysis for BigCommerce-specific headers
- Static file pattern detection for `/bc-static/`
- JavaScript global detection for BigCommerce variables
- API endpoint discovery for `/api/storefront/`
- HTML meta tag analysis
- Error page analysis

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns