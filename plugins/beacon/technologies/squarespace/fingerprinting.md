# Squarespace Framework Fingerprinting Guide

## Framework Overview
Squarespace is a popular all-in-one website building and hosting platform with integrated e-commerce capabilities. It's known for its beautiful templates, drag-and-drop editor, and comprehensive features for creatives, small businesses, and online stores. Squarespace serves over 4 million websites globally.

## Fingerprinting Patterns

### 1. HTTP Headers
Squarespace applications have distinctive HTTP headers:
```
X-Squarespace-Layout: [layout-name]
X-Squarespace-Version: [version]
X-Squarespace-Template: [template-name]
Server: Squarespace
X-ContextId: [context-id]
```

### 2. Static File Patterns
Squarespace has distinctive static file patterns:
- `/static/` - Squarespace static assets
- `/s/` - Shortened asset URLs
- `/universal/` - Universal JavaScript files
- `/assets/` - Theme and site assets
- `/storage/google_fonts/` - Google Fonts cache
- `/storage/assets/` - Asset storage
- `/scripts/` - Squarespace JavaScript files

### 3. HTML Meta Tags
Squarespace sites typically include these meta tags:
```html
<meta name="generator" content="Squarespace" />
<meta name="squarespace-site-id" content="[site-id]" />
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="referrer" content="origin-when-cross-origin" />
```

### 4. JavaScript Globals
Squarespace exposes these global variables:
```javascript
window.Squarespace = {
  templateId: "[template-id]",
  siteMeta: {
    siteId: "[site-id]",
    templateId: "[template-id]",
    siteTitle: "[title]"
  }
};
window.STATIC_BASE_URL = "https://static1.squarespace.com";
window.Y = {
  Squarespace: {
    Template: {
      templateName: "[template-name]"
    }
  }
};
```

### 5. Common Routes
Standard Squarespace routes:
- `/` - Homepage
- `/api/commerce/v1/` - Commerce API
- `/api/site/v1/` - Site management API
- `/commerce` - Shopping cart
- `/checkout` - Checkout process
- `/account` - User account area
- `/search` - Search functionality
- `/product/` - Product pages
- `/category/` - Product categories
- `/shop` - Storefront
- `/blog` - Blog functionality
- `/contact` - Contact form

### 6. API Endpoints
Squarespace exposes multiple APIs:

**Commerce API:**
- `/api/commerce/v1/products` - Product listings
- `/api/commerce/v1/orders` - Order management
- `/api/commerce/v1/cart` - Shopping cart management
- `/api/commerce/v1/checkout` - Checkout process
- `/api/commerce/v1/customers` - Customer management

**Site API:**
- `/api/site/v1/info` - Site information
- `/api/site/v1/pages` - Page listings
- `/api/site/v1/collections` - Content collections
- `/api/site/v1/blog` - Blog management

**Payment API:**
- `/api/payment/v1/process` - Payment processing

### 7. Error Pages
Squarespace error pages:
- **404**: "Page Not Found" with Squarespace branding
- **500**: "Internal server error" with support links
- Maintenance: "This site is temporarily unavailable" page
- **403**: "Access denied" page

### 8. Version Fingerprinting
Detect Squarespace version through:
- `X-Squarespace-Version` HTTP header
- `/api/site/v1/info` endpoint response
- Squarespace meta generator tag version
- JavaScript globals exposing version information
- Template files containing version references

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/api/
/static/
/assets/
/universal/
/scripts/
/storage/
```

### 2. Common File Discovery
Look for these files:
```
/config.js
/theme.js
/universal/scripts-compressed.js
/static/
```

### 3. Framework-Specific Endpoints
Check these Squarespace-specific endpoints:
```
/api/commerce/v1/products
/api/site/v1/info
/api/site/v1/pages
/commerce
/checkout
/static/
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self' *.squarespace.com
```

### Vulnerable Patterns
- Exposed API endpoints without authentication
- Hardcoded API keys in client-side code
- Missing security headers
- Unprotected payment processing forms
- Cross-site scripting vulnerabilities
- CSRF vulnerabilities in forms
- Unsecured file uploads
- Missing access controls

## Technology Stack Integration

### Common Squarespace Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| Squarespace Commerce | E-commerce functionality | `/api/commerce/v1/` endpoints |
| Custom JavaScript | Frontend enhancements | `/assets/` files, custom scripts |
| Payment Gateways | Payment processing | `/api/payment/v1/` endpoints |
| CDN | Asset delivery | `static1.squarespace.com` domains |
| Analytics | Tracking | Google Analytics, Squarespace metrics |
| Custom CSS | Styling | `/assets/css/` files |

## Example Fingerprinting Commands

```bash
# Check Squarespace headers
curl -I https://example.com

# Check commerce API
curl -I https://example.com/api/commerce/v1/products

# Extract version from headers
curl -I https://example.com | grep -i "X-Squarespace"

# Check for Squarespace meta tags
curl https://example.com | grep -i "Squarespace"

# Check site information API
curl https://example.com/api/site/v1/info

# Check static files
curl -I https://example.com/static/
```

## False Positives
- Custom websites using similar CDN patterns
- Static sites with Squarespace-like meta tags
- Websites using similar naming conventions
- Other website builders with similar API patterns
- Custom Squarespace-like templates

## Fingerprinting Tooling
- HTTP header analysis for Squarespace-specific headers
- HTML meta tag analysis
- JavaScript global detection
- API endpoint discovery
- Static file pattern detection
- CDN pattern recognition
- Error page analysis

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns