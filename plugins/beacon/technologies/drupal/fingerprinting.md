# Drupal Framework Fingerprinting Guide

## Framework Overview
Drupal is a powerful open-source content management system known for its flexibility, scalability, and enterprise-grade capabilities. It powers millions of websites including government sites, educational institutions, and large corporate portals. Drupal supports e-commerce through modules like Drupal Commerce and Ubercart, making it a popular choice for complex, content-rich websites with e-commerce functionality.

## Fingerprinting Patterns

### 1. Static File Patterns
Drupal has distinctive static file patterns:
- `/core/` - Drupal core directory
- `/modules/` - Core and custom modules
- `/themes/` - Theme directories
- `/sites/` - Site-specific files
- `/sites/default/files/` - Uploaded files
- `/profiles/` - Installation profiles
- `/libraries/` - Third-party libraries
- `/vendor/` - Composer dependencies
- `/misc/` - Core miscellaneous files

### 2. HTTP Headers
Drupal sites often show these headers:
```
X-Generator: Drupal [version] (https://www.drupal.org)
X-Drupal-Cache: HIT/MISS
X-Drupal-Dynamic-Cache: HIT/MISS
Cache-Control: max-age=[seconds]
```

### 3. HTML Meta Tags
Drupal sites typically include these meta tags:
```html
<meta name="Generator" content="Drupal [version] (https://www.drupal.org)" />
<meta name="MobileOptimized" content="width" />
<meta name="HandheldFriendly" content="true" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
```

### 4. Common Routes
Standard Drupal routes:
- `/admin/` - Admin dashboard
- `/user/` - User account area
- `/node/[id]` - Content nodes
- `/taxonomy/term/[id]` - Taxonomy terms
- `/comment/reply/[node-id]` - Comment replies
- `/search` - Search functionality
- `/system/files/` - System files
- `/batch` - Batch processing
- `/update.php` - Update script (if accessible)
- `/install.php` - Install script (if accessible)

### 5. API Endpoints
Drupal exposes multiple APIs:

**REST API (Drupal 8+):
- `/node` - Node endpoints
- `/taxonomy/term` - Taxonomy endpoints
- `/user` - User endpoints
- `/comments` - Comment endpoints
- `/entity/[entity-type]` - Entity endpoints

**JSON:API (Drupal 8.4+):
- `/jsonapi/node/[node-type]`
- `/jsonapi/user/user`
- `/jsonapi/taxonomy_term/[vocabulary]`
- `/jsonapi/comment/comment`

**Views REST Export (when configured):**
- `/views/[view-name].json`

### 6. Error Pages
Drupal error pages:
- **404**: "Page not found" with Drupal branding
- **403**: "Access denied" page
- **500**: "Internal Server Error" with Drupal details
- **Maintenance**: "Site under maintenance" page

### 7. Version Fingerprinting
Detect Drupal version through:
- `X-Generator` HTTP header
- Meta generator tag
- `/core/lib/Drupal.php` (contains version constant)
- Admin footer version information
- `/CHANGELOG.txt` (if accessible)
- `/core/CORE_VERSION.txt`
- Database `{system}` table contains version
- `/core/modules/system/system.module` (contains version)

### 8. E-commerce Patterns
Drupal e-commerce via popular modules:

**Drupal Commerce:**
- `/admin/commerce` - Commerce admin
- `/cart` - Shopping cart
- `/checkout` - Checkout process
- `/products` - Product listings
- `/orders` - Order management
- `commerce_` prefix in cookies and database tables

**Ubercart:**
- `/cart` - Shopping cart
- `/checkout` - Checkout process
- `/user/[uid]/orders` - User orders
- `uc_` prefix in cookies and URLs

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/core/
/modules/
/sites/
/themes/
/profiles/
```

### 2. Common File Discovery
Look for these files:
```
/CHANGELOG.txt
/core/lib/Drupal.php
/core/CORE_VERSION.txt
/update.php
/install.php
```

### 3. Framework-Specific Endpoints
Check these Drupal-specific endpoints:
```
/admin/
/user/
/node/
/jsonapi/
/system/files/
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Drupal-Cache: [cache-status]
Cache-Control: [cache-settings]
```

### Vulnerable Patterns
- Missing `.htaccess` files in key directories
- Not securing `/install.php` and `/update.php`
- Default admin credentials
- Missing security updates
- Exposed `/CHANGELOG.txt`
- Weak file permissions (especially `/sites/default/files/`)
- Directory listing enabled
- Missing security modules (Paranoia, Security Kit)
- Unprotected cron.php access
- Missing brute force protection

## Technology Stack Integration

### Common Drupal Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| PHP | Server scripting | PHP version in headers |
| MySQL/PostgreSQL | Database | Database configuration files |
| Drush | CLI tool | `/vendor/bin/drush` |
| Solr | Search | Solr integration modules |
| Redis | Caching | Redis configuration |
| Memcached | Caching | Memcached configuration |
| PHPUnit | Testing | `/core/tests/` directory |
| Drupal Commerce | E-commerce | `/modules/commerce/` |
| Ubercart | E-commerce | `/modules/ubercart/` |
| Varnish | Caching | Varnish headers |

## Example Fingerprinting Commands

```bash
# Check Drupal headers
curl -I https://example.com

# Check Drupal generator meta tag
curl https://example.com | grep -i "Drupal"

# Check for Drupal core directory
curl -I https://example.com/core/

# Check for Drupal version files
curl -I https://example.com/CHANGELOG.txt

# Check for Drupal admin interface
curl -I https://example.com/admin/

# Check for Drupal REST API
curl -I https://example.com/jsonapi/
```

## False Positives
- Custom Drupal-based applications
- Other PHP CMS platforms with similar structures
- Drupal installations with custom admin paths
- Drupal distributions with different file structures
- Websites using Drupal-like caching mechanisms
- Static sites with Drupal meta tags accidentally left behind

## Fingerprinting Tooling
- HTTP header analysis for `X-Generator`, `X-Drupal-Cache`
- HTML meta tag detection
- Static file pattern analysis
- Directory enumeration
- Version file detection
- Error page analysis
- API endpoint discovery
- E-commerce module detection

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns