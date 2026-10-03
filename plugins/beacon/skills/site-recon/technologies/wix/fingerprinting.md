# Wix Framework Fingerprinting Guide

## Framework Overview
Wix is a popular cloud-based website builder with integrated e-commerce capabilities. It provides an all-in-one solution for creating websites, online stores, and business applications with drag-and-drop tools. Wix serves over 200 million users worldwide and is particularly popular among small businesses, entrepreneurs, and creative professionals.

## Fingerprinting Patterns

### 1. HTTP Headers
Wix applications have distinctive HTTP headers:
```
X-Wix-Request-Id: [request-id]
X-Wix-Website: [website-id]
Server: nginx
X-Wix-Cache-Hit: [true/false]
```

### 2. Static File Patterns
Wix has distinctive static file patterns:
- `/_partials/` - Partial component files
- `/_api/` - Wix API endpoints
- `/_apps/` - Wix application files
- `/_public/` - Public assets
- `/assets/` - Site assets
- `/files/` - Uploaded files
- `/static.parastorage.com/` - CDN-hosted static assets

### 3. HTML Meta Tags
Wix sites typically include these meta tags:
```html
<meta property="wix-domain" content="true">
<meta name="generator" content="Wix.com Website Builder">
<meta name="wix-site-root-id" content="[site-id]">
<meta name="wix-site-id" content="[site-id]">
<meta name="wix-stylesheet-fingerprint" content="[hash]">
```

### 4. JavaScript Globals
Wix exposes these global variables:
```javascript
window.__WIX_BLOCKS__ = {};
window.__WIX_BUILD_IDENTIFIER__ = "[build-id]";
window.__WIX_DOMAIN__ = "wix.com";
window.wix = {
  site: {
    id: "[site-id]",
    name: "[site-name]"
  }
};
window.Wix = {
  Statics: {
    baseURL: "https://static.parastorage.com/"
  }
};
```

### 5. Common Routes
Standard Wix routes:
- `/` - Homepage
- `/_api/wix-site/v1/site` - Site information API
- `/_api/wix-ecom/v1/cart` - Shopping cart
- `/_api/wix-ecom/v1/checkout` - Checkout process
- `/_api/wix-bookings/v1/calendar` - Booking functionality
- `/_pages/[page-id]` - Individual pages
- `/blog` - Blog functionality
- `/store` - E-commerce storefront
- `/account` - User account area
- `/search` - Search functionality

### 6. API Endpoints
Wix exposes multiple APIs:

**Site API:**
- `/_api/wix-site/v1/site` - Site information
- `/_api/wix-site/v1/pages` - Page listing

**E-commerce API:**
- `/_api/wix-ecom/v1/cart` - Cart management
- `/_api/wix-ecom/v1/checkout` - Checkout process
- `/_api/wix-ecom/v1/products` - Product listing
- `/_api/wix-ecom/v1/categories` - Category listing
- `/_api/wix-ecom/v1/orders` - Order management

**Bookings API:**
- `/_api/wix-bookings/v1/calendar` - Booking calendar
- `/_api/wix-bookings/v1/staff` - Staff information
- `/_api/wix-bookings/v1/services` - Service listing

### 7. Error Pages
Wix error pages:
- **404**: "Page not found" with Wix branding
- **500**: "Something went wrong" with support links
- Maintenance: "Website under maintenance" page

### 8. Version Fingerprinting
Detect Wix version through:
- `X-Wix-Render-Version` header
- `window.__WIX_BUILD_IDENTIFIER__` global variable
- `/_api/wix-site/v1/site` endpoint response
- Wix meta generator tag version
- `X-Wix-Cache-Hit` header patterns

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/_api/
/_partials/
/_apps/
/_public/
/assets/
/files/
```

### 2. Common File Discovery
Look for these files:
```
/"_wix-ecommerce.js"
/"_wix-bookings.js"
/"_wix-renderer.js"
/static.parastorage.com/services/wix/"
```

### 3. Framework-Specific Endpoints
Check these Wix-specific endpoints:
```
/_api/wix-site/v1/site
/_api/wix-ecom/v1/cart
/_api/wix-ecom/v1/products
/_pages/[page-id]
/static.parastorage.com/services/
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self' *.parastorage.com *.wixstatic.com
```

### Vulnerable Patterns
- Exposed API endpoints without authentication
- Unprotected dynamic pages
- Missing security headers
- Hardcoded API keys in JavaScript
- Unrestricted file uploads
- Cross-site scripting vulnerabilities
- CSRF vulnerabilities
- Unsecured payment processing

## Technology Stack Integration

### Common Wix Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| React | Frontend framework | `_wix-react` files, React syntax |
| Node.js | Backend runtime | Wix server APIs, Node.js modules |
| MongoDB | Database | Wix data management APIs |
| CDN | Asset delivery | `static.parastorage.com` |
| Wix Apps | Integrations | `/_apps/` directory, Wix app marketplace |
| Payment Gateways | Payments | Wix payment API usage |

## Example Fingerprinting Commands

```bash
# Check Wix headers
curl -I https://example.com

# Check Wix API endpoints
curl -I https://example.com/_api/wix-site/v1/site

# Extract Wix site information
curl https://example.com/_api/wix-site/v1/site

# Check for Wix meta tags
curl https://example.com | grep -i "wix"

# Check Wix static files
curl -I https://example.com/static.parastorage.com/services/wix/

# Check Wix cart functionality
curl -I https://example.com/_api/wix-ecom/v1/cart
```

## False Positives
- Custom websites using similar CDN patterns
- Static sites with Wix-like meta tags
- Websites using similar naming conventions
- Other website builders with API endpoints

## Fingerprinting Tooling
- HTTP header analysis for Wix-specific headers
- HTML meta tag analysis
- JavaScript global detection
- API endpoint discovery
- Static file pattern detection
- CDN pattern recognition

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns