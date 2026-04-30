# Shopware Framework Fingerprinting Guide

## Framework Overview
Shopware is a leading open-source e-commerce platform primarily used in the DACH region (Germany, Austria, Switzerland). Built on Symfony and PHP, Shopware offers three distinct API layers: Store API for frontend interactions, Admin API for back-office operations, and Sync API for bulk operations. Shopware 6 is particularly popular among specialty retailers and pen/stationery stores.

## Fingerprinting Patterns

### 1. HTTP Headers
Shopware applications have distinctive HTTP headers:
```
sw-version: 6.7.9.0
x-shopware-cache-id: [cache-ids]
sw-storefront-url: [base-url]
X-Generator: Shopware
Server: nginx/Apache
```

### 2. Cookies
Look for these Shopware-specific cookies:
```
sw-context-token=[hash] - Session state cookie
sw-currency=[currency-code] - Active currency
sw-language=[language-id] - Active language UUID
OCSESSID=[hash] - Session identifier
```

### 3. Static File Patterns
Shopware has distinctive file patterns:
- `/theme/[hash]/js/all.js` - Compiled theme JavaScript
- `/theme/[hash]/css/all.css` - Compiled theme CSS
- `/bundles/` - Symfony bundle assets
- `/storefront/` - Storefront assets
- `/admin/` - Administration interface (may be IP-restricted)
- `/media/` - Media files
- `/files/` - Downloadable content

### 4. JavaScript Globals
Shopware exposes these global variables:
```javascript
window.__sw = {
  accessKey: "SWSCXXXXXXXXXX",
  contextToken: "[token]",
  languageId: "[uuid]",
  currencyId: "[uuid]"
};
window.sw = window.__sw;
```

### 5. Common Routes
Standard Shopware routes:
- `/` - Storefront homepage
- `/store-api/` - Store API endpoints
- `/api/` - Admin API endpoints
- `/checkout` - Checkout process
- `/account` - Customer account area
- `/search` - Search functionality
- `/widgets/` - AJAX widgets and components
- `/navigation/` - Category navigation
- `/detail/` - Product detail pages
- `/listing/` - Product listings

### 6. API Endpoints
Shopware exposes multiple APIs:

**Store API (public, requires sw-access-key):**
- `/store-api/context` - Session context management
- `/store-api/info` - Shop information
- `/store-api/product` - Product data
- `/store-api/product-listing/{categoryId}` - Product listings
- `/store-api/search` - Search functionality
- `/store-api/search-suggest` - Search autocomplete
- `/store-api/cart` - Shopping cart management
- `/store-api/customer` - Customer account management

**Admin API (requires OAuth 2.0 authentication):**
- `/api/oauth/token` - OAuth token endpoint
- `/api/_info/version` - Shopware version
- `/api/_info/config` - System configuration
- `/api/_info/openapi3.json` - OpenAPI specification
- `/api/product` - Product management
- `/api/category` - Category management
- `/api/order` - Order management

**Bulk API:**
- `/api/_action/sync` - Bulk operations endpoint

### 7. Error Pages
Shopware error pages:
- **404**: Theme-based 404 page
- **412**: "No matching sales channel found" (missing access key)
- **500**: Server error with Symfony branding in development
- **Maintenance**: "We are performing maintenance" message

### 8. Version Fingerprinting
Detect Shopware version through:
- `sw-version` HTTP header
- `/store-api/info` endpoint response
- `/api/_info/version` endpoint (admin auth required)
- `/api/_info/config` endpoint (admin auth required)
- Meta generator tag: `<meta name="generator" content="Shopware" />`
- JavaScript files (contains version references)

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/admin
/store-api
/api
/theme
/bundles
/storefront
/files
/media
```

### 2. Common File Discovery
Look for these files:
```
config.php
composer.json
composer.lock
vendor/symfony/
vendor/shopware/
```

### 3. Framework-Specific Endpoints
Check these Shopware-specific endpoints:
```
/store-api/context
/store-api/info
/store-api/search-suggest
/api/_info/version
/api/_info/config
/api/_info/openapi3.json
/admin
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
Strict-Transport-Security: max-age=31536000
```

### Vulnerable Patterns
- Exposed `composer.json`/`composer.lock` files
- Unprotected `/api/_info/openapi3.json` endpoint
- Missing admin interface IP restrictions
- Default admin credentials
- Outdated Shopware versions
- Unprotected media directories
- Missing CSRF protection
- Unsecured payment gateway integrations
- Publicly accessible Symfony debug toolbar

## Technology Stack Integration

### Common Shopware Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| Symfony | PHP Framework | Symfony components, `_profiler` route |
| Doctrine | ORM | Entities directory, configuration files |
| Twig | Templating | `.twig` template files |
| Vue.js | Storefront JS | `vendor/shopware/storefront/Resources/app/storefront/src/` |
| jQuery | Legacy Storefront | `jquery.js` in assets |
| Webpack | Asset build | `/theme/[hash]/` pattern, build manifest |
| Elasticsearch | Search | Search configuration, `/api/search/` |
| MySQL | Database | Database configuration, Doctrine entities |
| Redis | Caching | Cache configuration, performance settings |

## Example Fingerprinting Commands

```bash
# Check Shopware headers
curl -I https://example.com

# Check Store API info endpoint
curl -H "sw-access-key: SWSCXXXXXXXXXX" https://example.com/store-api/info

# Extract access key from page source
curl -s https://example.com | grep -oP 'SWSC[A-Za-z0-9]+'

# Test for public Admin API spec
curl -I https://example.com/api/_info/openapi3.json

# Check version via Store API
curl -H "sw-access-key: SWSCXXXXXXXXXX" https://example.com/store-api/info | grep -i "swVersion"

# Check theme assets
curl -I https://example.com/theme/[hash]/js/all.js
```

## False Positives
- Symfony applications without Shopware
- Other Symfony-based e-commerce platforms
- Custom-built online stores
- Installations with disabled Store API
- Headless deployments without public Store API

## Fingerprinting Tooling
- HTTP header analysis for `sw-version`, `x-shopware-cache-id`
- Cookie pattern analysis for `sw-context-token`
- JavaScript global detection for `window.__sw`
- API endpoint discovery for `/store-api/`
- File pattern analysis for `/theme/[hash]/`
- Error page analysis for Shopware-specific errors

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns