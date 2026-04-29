# PrestaShop Framework Fingerprinting Guide

## Framework Overview
PrestaShop is an open-source e-commerce solution written in PHP. It's one of the most popular e-commerce platforms globally, offering a comprehensive set of features for online stores including product management, cart functionality, checkout processes, and payment gateways.

## Fingerprinting Patterns

### 1. Static File Patterns
PrestaShop has distinctive static file patterns:
- `/themes/` - Theme directories
- `/modules/` - Module directories
- `/js/` - JavaScript files
- `/css/` - Stylesheets
- `/img/` - Image assets
- `/upload/` - Uploaded files
- `/cache/` - Cache files (often restricted)
- `/override/` - Core overrides
- `/admin[xxx]/` - Admin directory (randomized)

### 2. HTTP Headers
Look for these PrestaShop-specific headers:
```
X-Generator: PrestaShop
Server: Apache/2.4.XX
X-Powered-By: PHP/8.X.X
Set-Cookie: PrestaShop-[hash]
```

### 3. HTML Meta Tags
PrestaShop apps often include:
```html
<meta name="generator" content="PrestaShop" />
<meta name="robots" content="index,follow" />
<link rel="stylesheet" href="/themes/[theme_name]/css/global.css" />
```

### 4. Common Routes
Standard PrestaShop routes:
- `/` - Storefront
- `/admin[xxx]/` - Admin interface (randomized)
- `/api/` - REST API
- `/cart` - Shopping cart
- `/order` - Checkout process
- `/my-account` - Customer account
- `/search` - Product search
- `/contact-us` - Contact form
- `/content/` - CMS pages

### 5. API Patterns
PrestaShop REST API endpoints:
- `/api/products` - Product management
- `/api/categories` - Product categories
- `/api/customers` - Customer management
- `/api/orders` - Order management
- `/api/carts` - Shopping cart management
- `/api/addresses` - Customer addresses
- `/api/order_states` - Order statuses
- `/api/languages` - Language management

### 6. Error Pages
PrestaShop error pages:
- **404**: Custom themed 404 page
- **403**: Access denied page
- **500**: Server error with PrestaShop branding
- Maintenance mode: "This store is currently undergoing maintenance" message

### 7. Version Fingerprinting
Detect PrestaShop version through:
- `/config/settings.inc.php` - If exposed, contains version constants
- Admin login page - Often shows version in footer
- `/modules/` directory - Module files may contain version info
- Database tables - `ps_configuration` table contains version info
- Error messages - May reveal version in development mode

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/themes/
/modules/
/admin*
/upload/
/js/
/css/
/cache/
override/
```

### 2. Common File Discovery
Look for these files:
```
config/settings.inc.php
config/config.inc.php
init.php
header.php
footer.php
```

### 3. Framework-Specific Endpoints
Check for PrestaShop-specific endpoints:
```
/api/
/api/products
/admin*/index.php
/install/
/module/[module_name]/[action]
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
Strict-Transport-Security: max-age=31536000
```

### Vulnerable Patterns
- Exposed `config/settings.inc.php` file
- Directory listing enabled
- Default admin credentials
- Outdated modules with vulnerabilities
- Exposed database backup files
- Unprotected admin directory
- Missing CSRF protection
- Unsecured API endpoints
- Maintenance mode enabled without IP restriction

## Technology Stack Integration

### Common PrestaShop Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| MySQL | Database | Database connection strings |
| Smarty | Templating | `.tpl` files in themes |
| Apache/Nginx | Web server | Server headers |
| jQuery | Frontend JS | `jquery.js` in assets |
| Bootstrap | CSS framework | Bootstrap CSS classes |
| Payment Gateways | Payments | Payment module directories |
| Redis | Caching | Cache configuration files |

## Example Fingerprinting Commands

```bash
# Check for PrestaShop headers
curl -I https://example.com

# Check for common PrestaShop files
curl -I https://example.com/config/settings.inc.php

# Check PrestaShop error pages
curl -i https://example.com/nonexistent-page

# Probe PrestaShop API endpoints
curl -I https://example.com/api/products

# Check for admin directory
gobuster dir -u https://example.com -w /wordlist.txt -x php
```

## False Positives
- Custom PHP applications with similar structure
- Other e-commerce platforms (Magento, WooCommerce)
- CMS platforms with e-commerce modules
- Generic PHP applications with `/modules/` directory
- Custom themed online stores

## Fingerprinting Tooling
- HTTP header analysis for PrestaShop-specific headers
- Directory enumeration for PrestaShop file patterns
- API endpoint discovery and analysis
- Error page analysis for PrestaShop branding
- JavaScript/CSS asset analysis

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns