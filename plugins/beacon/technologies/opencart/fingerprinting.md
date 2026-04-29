# OpenCart Framework Fingerprinting Guide

## Framework Overview
OpenCart is an open-source e-commerce platform written in PHP. It provides a complete solution for online stores with features like product management, shopping cart functionality, checkout processes, and multiple payment gateway integrations.

## Fingerprinting Patterns

### 1. Static File Patterns
OpenCart has distinctive static file patterns:
- `/catalog/` - Frontend catalog files
- `/admin/` - Admin interface (sometimes with randomized name)
- `/system/` - Core system files
- `/image/` - Image uploads and cache
- `/download/` - Downloadable product files
- `/vqmod/` or `/storage/modification/` - Modification systems
- `/assets/` - CSS, JS, and other assets
- `/theme/` - Theme files directory

### 2. HTTP Headers
Look for these OpenCart-specific headers:
```
Server: Apache/2.4.X
X-Powered-By: PHP/7.X.X or PHP/8.X.X
Set-Cookie: OCSESSID=[hash]
```

### 3. HTML Meta Tags
OpenCart apps often include:
```html
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="catalog/view/theme/[theme_name]/stylesheet/stylesheet.css" rel="stylesheet">
```

### 4. Common Routes
Standard OpenCart routes:
- `/` - Storefront homepage
- `/index.php?route=account/login` - Login
- `/index.php?route=account/register` - Registration
- `/index.php?route=checkout/cart` - Shopping cart
- `/index.php?route=checkout/checkout` - Checkout
- `/index.php?route=product/category` - Product categories
- `/index.php?route=product/product` - Product details
- `/index.php?route=account/account` - Customer account
- `/index.php?route=information/contact` - Contact form

### 5. Error Pages
OpenCart error pages:
- **404**: "The page you requested cannot be found!"
- **403**: Access denied message
- **Maintenance mode**: "We are currently performing some scheduled maintenance"
- **Database errors**: SQL error messages in development mode

### 6. Version Fingerprinting
Detect OpenCart version through:
- `/admin/view/javascript/common.js` - Contains version info
- `/system/startup.php` - Core file with version markers
- Admin login footer - Shows version number
- Database - `oc_setting` table contains version info
- Error messages - Version-specific patterns

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/admin
/catalog
/system
/image
/download
/vqmod
/storage
```

### 2. Common File Discovery
Look for these files:
```
config.php
admin/config.php
index.php
system/startup.php
system/library/config.php
```

### 3. Framework-Specific Endpoints
Check these OpenCart-specific endpoints:
```
/index.php?route=product/search
/index.php?route=account/forgotten
/admin/index.php
/install/
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000
```

### Vulnerable Patterns
- Exposed `config.php` files with database credentials
- Directory listing enabled
- Default admin credentials
- Unprotected admin directory
- Outdated OpenCart installations
- Vulnerable extensions/modules
- SQL injection vulnerabilities
- Missing CSRF protection
- Unprotected file uploads

## Technology Stack Integration

### Common OpenCart Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| MySQL | Database | Database connection strings |
| Bootstrap | CSS framework | Bootstrap CSS classes |
| jQuery | Frontend JS | `jquery.js` references |
| Font Awesome | Icon library | `font-awesome.css` |
| VQMod/OCMod | Modifications | `/vqmod/` or `/storage/modification/` |
| Payment Gateways | Payments | Payment module files |
| Caching | Performance | Cache directory structure |

## Example Fingerprinting Commands

```bash
# Check for OpenCart headers
curl -I https://example.com

# Check for OpenCart-specific files
curl -I https://example.com/catalog/view/theme/default/stylesheet/stylesheet.css

# Check OpenCart error pages
curl -i https://example.com/nonexistent-page

# Check version via admin JavaScript
curl https://example.com/admin/view/javascript/common.js | grep 'OpenCart'

# Brute-force admin directory
gobuster dir -u https://example.com -w /wordlist.txt -x php -b 404
```

## False Positives
- Custom PHP applications with similar structure
- Other PHP e-commerce solutions
- CMS platforms with e-commerce extensions
- Generic PHP applications
- Websites using similar jQuery/Bootstrap frontend

## Fingerprinting Tooling
- Directory enumeration
- HTTP header analysis
- File pattern recognition
- Error page analysis
- JavaScript/CSS analysis
- Cookie pattern analysis

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns