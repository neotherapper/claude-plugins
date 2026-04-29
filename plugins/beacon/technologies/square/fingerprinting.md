# Square Online Framework Fingerprinting Guide

## Framework Overview
Square Online (formerly Weebly) is an e-commerce and website building platform that integrates with Square's payment processing system. It offers easy-to-use tools for creating online stores, including product management, shopping cart functionality, and integrated payments.

## Fingerprinting Patterns

### 1. HTTP Headers
Square Online applications have these distinctive headers:
```
X-Square-Store-Id: [store-id]
X-Square-Site-Id: [site-id]
Server: Square
X-Square-Version: [version]
```

### 2. Static File Patterns
Square Online has distinctive static file patterns:
- `/static/weebly/` - Weebly/Square static assets
- `/files/` - Uploaded files
- `/scripts/` - Client-side scripts
- `/themes/` - Theme files
- `/shop/` - E-commerce functionality
- `/cdn-cgi/scripts/` - Cloudflare integration
- `/square/` - Square-specific functionality
- `/api/site/` - Square API endpoints

### 3. HTML Meta Tags
Square Online sites typically include:
```html
<meta name="generator" content="Square Online" />
<meta name="square-site-id" content="[site-id]" />
<meta name="square-store-id" content="[store-id]" />
```

### 4. JavaScript Globals
Square Online exposes these global variables:
```javascript
window.SQUARE = {
  site: {
    id: "[site-id]",
    storeId: "[store-id]"
  },
  version: "[version]"
};
window.WEEBLY = {
  site: {
    id: "[site-id]"
  }
};
```

### 5. Common Routes
Square Online standard routes:
- `/` - Homepage
- `/shop` - Product catalog
- `/cart` - Shopping cart
- `/checkout` - Checkout process
- `/account` - Customer account
- `/api/site/v1/` - Site API
- `/api/store/v1/` - Store API
- `/product/[product-slug]` - Product pages
- `/category/[category-slug]` - Category pages
- `/search` - Product search

### 6. API Endpoints
Square Online exposes multiple APIs:

**Site API:**
- `/api/site/v1/info` - Site information
- `/api/site/v1/pages` - Page listing
- `/api/site/v1/theme` - Theme information

**Store API:**
- `/api/store/v1/products` - Product listing
- `/api/store/v1/categories` - Category listing
- `/api/store/v1/cart` - Shopping cart management
- `/api/store/v1/checkout` - Checkout process
- `/api/store/v1/orders` - Order management
- `/api/store/v1/customers` - Customer management

### 7. Error Pages
Square Online error pages:
- **404**: "Page Not Found" with Square branding
- **500**: "Internal Server Error" with Square support links
- **503**: "Service Unavailable" during maintenance
- Maintenance: "This site is temporarily unavailable"

### 8. Version Fingerprinting
Detect Square Online version through:
- `X-Square-Version` HTTP header
- `/api/site/v1/info` endpoint response
- JavaScript globals containing version information
- Static file versions

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/shop
/cart
/api/
/static/
/themes/
/files/
```

### 2. Common File Discovery
Look for these files:
```
/_weebly/
/config.json
/theme/
```

### 3. Framework-Specific Endpoints
Check these Square Online-specific endpoints:
```
/api/site/v1/info
/api/store/v1/products
/api/store/v1/cart
/shop
/checkout
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self' *.squarecdn.com
```

### Vulnerable Patterns
- Exposed API keys in client-side code
- Missing security headers
- Unsecured payment processing forms
- Cross-site scripting vulnerabilities
- Missing CSRF protection
- Unprotected admin interface
- Unsecured file uploads
- Missing rate limiting on APIs

## Technology Stack Integration

### Common Square Online Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| Weebly | Legacy site builder | `/static/weebly/` files |
| Square Payments | Payment processing | Payment API endpoints |
| CDN | Asset delivery | `*.squarecdn.com` domains |
| Theme Engine | Design customization | `/themes/` directory |
| Shop Functionality | E-commerce | `/shop`, `/cart`, `/checkout` |
| Custom Scripts | Functionality | `/scripts/` directory |
| Form Builder | Lead capture | Contact form patterns |

## Example Fingerprinting Commands

```bash
# Check Square headers
curl -I https://example.com

# Check Store API
curl -I https://example.com/api/store/v1/products

# Extract version from headers
curl -I https://example.com | grep -i "X-Square"

# Check for Square meta tags
curl https://example.com | grep -i "Square Online"

# Check for Weebly legacy files
curl -I https://example.com/static/weebly/

# Check Square cart functionality
curl -I https://example.com/api/store/v1/cart
```

## False Positives
- Custom e-commerce stores using Square payments
- Websites built with other builders that integrate Square
- Static sites with similar naming conventions
- Custom stores resembling Square Online layout

## Fingerprinting Tooling
- HTTP header analysis for Square-specific headers
- HTML meta tag analysis
- JavaScript global detection
- API endpoint discovery
- Static file pattern detection
- Route pattern analysis
- CDN pattern recognition

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns