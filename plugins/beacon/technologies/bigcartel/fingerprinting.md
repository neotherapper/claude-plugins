# Big Cartel Framework Fingerprinting Guide

## Framework Overview
Big Cartel is a simple e-commerce platform designed for artists, musicians, and small creative businesses. It offers easy-to-use tools for selling products online, with a focus on simplicity and creative control. Big Cartel is particularly popular among independent creators and small scale online stores.

## Fingerprinting Patterns

### 1. HTTP Headers
Big Cartel applications typically show:
```
X-BigCartel-Version: [version]
Server: Big Cartel
X-Runtime: [time]
```

### 2. Static File Patterns
Big Cartel has distinctive static file patterns:
- `/bigcartel.js` - Big Cartel JavaScript
- `/global.js` - Global functionality
- `/store.css` - Store styles
- `/images/` - Product images
- `/products/` - Product pages
- `/assets/` - Theme assets
- `/javascripts/` - Theme JavaScript
- `/stylesheets/` - Theme CSS

### 3. HTML Meta Tags
Big Cartel stores often include:
```html
<meta name="generator" content="Big Cartel" />
<meta property="og:site_name" content="Big Cartel" />
<meta name="bigcartel-store" content="[store-name]" />
```

### 4. JavaScript Globals
Big Cartel exposes these global variables:
```javascript
window.BigCartel = {
  store: {
    name: "[store-name]",
    url: "https://[store-name].bigcartel.com"
  },
  cart: {
    url: "/cart"
  }
};
```

### 5. Common Routes
Big Cartel standard routes:
- `/` - Storefront homepage
- `/products` - Product listing
- `/product/[product-name]` - Single product page
- `/category/[category-name]` - Category listing
- `/cart` - Shopping cart
- `/checkout` - Checkout process
- `/account` - Customer account
- `/contact` - Contact form
- `/search` - Product search

### 6. Error Pages
Big Cartel error pages:
- **404**: Customizable 404 page with Big Cartel branding
- **500**: Server error page
- Maintenance: "Store temporarily unavailable"

### 7. Version Fingerprinting
Detect Big Cartel version through:
- `X-BigCartel-Version` HTTP header
- Big Cartel JavaScript file versions
- Theme file structures
- Admin dashboard version indicators
- Downloaded asset file versions

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/products
/images
/assets
/javascripts
/stylesheets
```

### 2. Common File Discovery
Look for these files:
```
/bigcartel.js
/robots.txt
/sitemap.xml
```

### 3. Framework-Specific Endpoints
Check these Big Cartel-specific endpoints:
```
/products.json
/bigcartel.js
/checkout
/cart
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=31536000
```

### Vulnerable Patterns
- Missing CSRF protection
- Unsecured payment processing
- Exposed admin interface
- Hardcoded authentication tokens
- Missing security headers
- Cross-site scripting vulnerabilities
- Unprotected checkout process
- Missing CAPTCHA on forms

## Technology Stack Integration

### Common Big Cartel Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| Custom Domain | Branding | DNS records, domain mapping |
| Payment Gateways | Payments | Payment confirmation pages |
| Google Analytics | Tracking | `analytics.js` references |
| Custom CSS | Styling | Custom stylesheets |
| Custom JavaScript | Functionality | `/assets/` JavaScript files |
| MailChimp | Email marketing | MailChimp form embeds |

## Example Fingerprinting Commands

```bash
# Check Big Cartel headers
curl -I https://example.com

# Check for Big Cartel JavaScript
curl -I https://example.com/bigcartel.js

# Extract version from headers
curl -I https://example.com | grep -i "X-BigCartel-Version"

# Check for Big Cartel meta tags
curl https://example.com | grep -i "Big Cartel"

# Check product JSON endpoint
curl https://example.com/products.json
```

## False Positives
- Custom e-commerce stores with similar structures
- Generic online stores built with other platforms
- Websites using similar naming conventions
- Custom Big Cartel-like templates
- Other simple e-commerce solutions

## Fingerprinting Tooling
- HTTP header analysis for Big Cartel headers
- JavaScript file detection
- Meta tag analysis
- HTML structure analysis
- Route pattern recognition
- JSON endpoint analysis

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns