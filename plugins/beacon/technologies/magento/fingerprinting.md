# Magento Framework Fingerprinting Guide

## Framework Overview
Magento, now Adobe Commerce, is a powerful open-source e-commerce platform written in PHP. It's known for its scalability, flexibility, and extensive feature set, making it a popular choice for mid-sized to large online stores with complex requirements.

## Fingerprinting Patterns

### 1. HTTP Headers
Magento sites often show these headers:
```
X-Magento-Cache-Debug: [HIT|MISS]
X-Magento-Tags: [cache-tags]
Set-Cookie: frontend=[session-id]
Set-Cookie: mage-cache-sessid=true
Server: nginx/Apache
```

### 2. Static File Patterns
Magento has distinctive static file patterns:
- `/pub/static/` - Compiled static assets
- `/static/` - Legacy static assets directory
- `/media/` - Uploaded media files
- `/skin/` - Legacy theme files
- `/js/mage/` - Magento core JavaScript
- `/skin/frontend/[package]/[theme]/` - Theme assets
- `/pub/media/catalog/` - Product images
- `/app/` - Core application directory (restricted)

### 3. HTML Meta Tags
Magento sites typically include:
```html
<meta name="generator" content="Magento [version] | Adobe Commerce [version]" />
<meta name="description" content="Default Description" />
<script type="text/x-magento-init">
<meta name="robots" content="INDEX,FOLLOW" />
```

### 4. JavaScript Globals
Magento exposes these global variables:
```javascript
window.Magento = {
  init: function() {...},
  uri: {
    baseUrl: "https://example.com/",
    currentUrl: "https://example.com/"
  }
};
window.requirejs = {...};
```

### 5. Common Routes
Standard Magento routes:
- `/` - Storefront
- `/index.php/` - Front controller
- `/admin/` - Admin interface (customizable path)
- `/checkout/` - Checkout process
- `/cart/` - Shopping cart
- `/customer/account/` - Customer account
- `/catalog/` - Product catalog
- `/sales/order/history/` - Order history
- `/wishlist/` - Wishlist functionality
- `/rest/` - REST API endpoints
- `/soap/` - SOAP API endpoints

### 6. API Endpoints
Magento exposes multiple APIs:

**REST API:**
- `/rest/V1/products` - Product management
- `/rest/V1/categories` - Category management
- `/rest/V1/customers` - Customer management
- `/rest/V1/orders` - Order management
- `/rest/V1/carts` - Shopping cart management
- `/rest/V1/inventory` - Inventory management

**GraphQL API:**
- `/graphql` - GraphQL endpoint

**SOAP API:**
- `/soap/default?wsdl&services=...` - SOAP endpoint

### 7. Error Pages
Magento error pages:
- **404**: "Whoops, our bad..." with Magento branding
- **503**: "Service Temporarily Unavailable" maintenance page
- **500**: Server error with Magento branding
- **Maintenance**: "The server is temporarily unable to service your request"

### 8. Version Fingerprinting
Detect Magento version through:
- Meta generator tag (`Magento [version]`)
- `/magento_version` endpoint
- `/pub/errors/report` (contains version info)
- `/composer.lock` file (contains exact version)
- JavaScript files containing version references
- Admin login page footer (shows version)
- `/pub/static/adminhtml/Magento/backend/` (versioned assets)

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/pub/
/media/
/js/
/skin/
/app/
```

### 2. Common File Discovery
Look for these files:
```
/composer.json
/composer.lock
/pub/errors/report
/magento_version
```

### 3. Framework-Specific Endpoints
Check these Magento-specific endpoints:
```
/rest/V1/products
/graphql
/soap/default?wsdl
/magento_version
/admin/
/checkout/
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self' *.magento.com
```

### Vulnerable Patterns
- Exposed `/app/etc/local.xml` (contains database credentials)
- Missing admin path customization
- Default admin credentials
- Unpatched security vulnerabilities
- Exposed `/downloader/` directory
- Missing `.htaccess` files in `/pub/`
- Directory listing enabled
- Unsecured REST/SOAP/GraphQL APIs
- Missing WAF protection
- Cron scripts accessible

## Technology Stack Integration

### Common Magento Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| MySQL | Database | Database configuration |
| Redis | Caching | Redis cache configuration |
| Varnish | Caching | Varnish headers |
| Elasticsearch | Search | Search configuration |
| RabbitMQ | Messaging | Queue configuration |
| PHP | Server scripting | PHP version |
| Composer | Dependency management | `/composer.json` |
| LESS | CSS preprocessor | `.less` files |
| RequireJS | JavaScript loading | `requirejs-config.js` |

## Example Fingerprinting Commands

```bash
# Check Magento headers
curl -I https://example.com

# Check Magento version endpoint
curl -I https://example.com/magento_version

# Check for Magento meta tags
curl https://example.com | grep -i "Magento"

# Check REST API
curl -I https://example.com/rest/V1/products

# Check GraphQL endpoint
curl -I https://example.com/graphql

# Check error reports
curl -I https://example.com/pub/errors/report
```

## False Positives
- Custom e-commerce solutions using similar routes
- Other PHP applications with `/skin/` or `/media/` directories
- Magento templates used on other platforms
- Sites with Magento-like admin interfaces
- Other Adobe Commerce products

## Fingerprinting Tooling
- HTTP header analysis for Magento-specific headers
- Static file pattern detection
- JavaScript global detection
- API endpoint discovery
- Meta tag analysis
- Version endpoint probing
- Error page analysis

## Changelog
- 2026-04-30: Initial guide creation
- Future: Add version-specific fingerprinting patterns