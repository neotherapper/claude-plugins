# Sylius Framework Fingerprinting Guide

## Framework Overview
Sylius is an open-source headless e-commerce framework built on Symfony. It's designed for customization and flexibility, providing a complete e-commerce solution with features like product management, cart functionality, checkout, and payments.

## Fingerprinting Patterns

### 1. Static File Patterns
Sylius applications have these distinctive static file patterns:
- `/assets/shop/css/` - Shop frontend CSS
- `/assets/admin/css/` - Admin interface CSS
- `/bundles/` - Symfony bundle assets
- `/build/` - Webpack/Vite build assets (when using Encore)
- `/themes/` - Custom theme directories
- `/public/media/` - Uploaded media files

### 2. HTTP Headers
Look for these Sylius-specific headers:
```
X-Generator: Sylius
Server: nginx/Apache (often configured with Symfony)
X-Powered-By: PHP/x.y.z
```

### 3. HTML Meta Tags
Sylius apps often include these meta tags:
```html
<meta name="generator" content="Sylius"/>
<meta name="robots" content="noindex, follow"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
```

### 4. Common Routes
Sylius has these standard routes:
- `/shop/` - Customer storefront
- `/admin/` - Administration panel
- `/api/` - REST API endpoints
- `/api/v2/` - API Platform based endpoints
- `/checkout/` - Multi-step checkout
- `/account/` - Customer account area
- `/cart/` - Shopping cart
- `/products/` - Product listings
- `/login` - Authentication
- `/register` - Registration

### 5. API Patterns
Sylius REST API endpoints:
- `/api/products` - Product management
- `/api/taxons` - Product categories
- `/api/orders` - Order management
- `/api/customers` - Customer management
- `/api/payment-methods` - Payment methods
- `/api/shipping-methods` - Shipping methods
- `/api/checkout` - Checkout endpoints

### 6. Error Pages
Sylius/Symfony error pages:
- **404**: "The requested URL was not found" with Symfony branding
- **500**: Symfony exception page in development, clean error in production
- **403**: "You are not allowed to access this page" 

### 7. Version Fingerprinting
Detect Sylius version through:
- `composer.lock` or `composer.json` files if exposed
- Error pages in development mode often show Sylius version
- API responses may include version headers
- `/admin/` login page may show version in footer
- JavaScript assets may contain version strings

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/admin
/api
/shop
/assets
/bundles
/themes
/public
/vendor
```

### 2. Common File Discovery
Look for these files:
```
composer.json
composer.lock
sylius.yml
config.yml
security.yml
parameters.yml
```

### 3. Framework-Specific Endpoints
Check these Sylius-specific endpoints:
```
/admin/dashboard
/admin/login
/api/doc
/api/v2/graphql
/_profiler
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

### Vulnerable Patterns
- Exposed `composer.json`/`composer.lock` files
- Missing admin route protection
- Enabled Symfony debug toolbar in production
- Exposed database credentials in configuration files
- Missing CSRF protection on forms
- Unsecured API endpoints
- Outdated dependencies with known vulnerabilities

## Technology Stack Integration

### Common Sylius Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| Symfony | PHP Framework | `symfony` in headers, `_profiler` route |
| Doctrine | ORM | Doctrine cache files, database queries |
| Twig | Templating | `.twig` files, Twig error messages |
| API Platform | API | `/api/doc`, `/api/v2/graphql` |
| Webpack/Vite | Asset management | `build/` directory, Encore references |
| Elasticsearch | Search | `/api/_search` endpoints |
| Redis | Caching | `Redis` in headers, cache files |
| PayU/Stripe | Payments | Payment method references |

## Example Fingerprinting Commands

```bash
# Check for Sylius headers
curl -I https://example.com/admin

# Check for common Sylius files
curl -I https://example.com/composer.json

# Check Sylius error pages
curl -i https://example.com/nonexistent-path

# Probe Sylius API endpoints
curl -I https://example.com/api/products

# Check Sylius version via admin footer
curl https://example.com/admin | grep -i "sylius"
```

## False Positives
- Symfony applications without Sylius
- Custom-built e-commerce solutions
- Other Symfony-based CMS platforms
- Apps using similar directory structures
- Deployments with standard Symfony configuration

## Fingerprinting Tooling
- Static file pattern analysis
- HTTP header analysis
- API endpoint discovery
- Error page analysis
- JavaScript/CSS asset analysis

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns