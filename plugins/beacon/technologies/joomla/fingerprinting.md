# Joomla Framework Fingerprinting Guide

## Framework Overview
Joomla is an open-source content management system (CMS) that powers millions of websites and applications. It's written in PHP and uses MySQL for data storage. Joomla supports e-commerce through extensions like VirtueMart, HikaShop, and J2Store, making it a popular choice for websites ranging from simple blogs to complex enterprise portals.

## Fingerprinting Patterns

### 1. Static File Patterns
Joomla has distinctive static file patterns:
- `/media/system/js/` - Core Joomla JavaScript
- `/media/system/css/` - Core Joomla CSS
- `/templates/` - Template directories
- `/components/` - Component directories
- `/modules/` - Module directories
- `/plugins/` - Plugin directories
- `/administrator/` - Admin interface
- `/cache/` - Cache directory (often restricted)
- `/images/` - Media uploads
- `/language/` - Language files

### 2. HTTP Headers
Joomla sites often show these headers:
```
X-Generator: Joomla! - Open Source Content Management
Server: Apache/2.4.X
X-Powered-By: PHP/7.X.X or PHP/8.X.X
Set-Cookie: [session-cookie]
```

### 3. HTML Meta Tags
Joomla sites typically include these meta tags:
```html
<meta name="generator" content="Joomla! - Open Source Content Management" />
<meta name="keywords" content="[site-keywords]" />
<meta name="description" content="[site-description]" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
```

### 4. Common Routes
Standard Joomla routes:
- `/` - Frontend homepage
- `/administrator/` - Admin interface
- `/index.php` - Front controller
- `/component/[component-name]` - Component routes
- `/[menu-alias]` - SEO-friendly URLs
- `/index.php?option=com_[component]` - Legacy component URLs
- `/api` - Joomla API (version 4+)
- `/installation/` - Installation directory (if not removed)

### 5. Error Pages
Joomla error pages typically show:
- **404**: "The page you requested was not found" with Joomla branding
- **500**: Server error with Joomla error details
- **403**: Access denied page
- Maintenance: "This site is down for maintenance"

### 6. Version Fingerprinting
Detect Joomla version through:
- `/administrator/manifests/files/joomla.xml`
- `/media/system/js/core.js` (contains version info)
- `/language/en-GB/en-GB.xml`
- Admin login page footer (shows version)
- `/administrator/components/com_admin/sql/updates/`
- Database `#__schemas` table contains version info

### 7. E-commerce Patterns
Joomla e-commerce via popular extensions:

**VirtueMart:**
- `/components/com_virtuemart/`
- `/media/com_virtuemart/`
- `/index.php?option=com_virtuemart`
- `virtuemart` in cookies

**HikaShop:**
- `/components/com_hikashop/`
- `/media/com_hikashop/`
- `/index.php?option=com_hikashop`
- `hikashop` in cookies

**J2Store:**
- `/components/com_j2store/`
- `/media/com_j2store/`
- `/index.php?option=com_j2store`
- `j2store` in session data

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/administrator/
/components/
/modules/
/plugins/
/templates/
/media/
/cache/
/images/
```

### 2. Common File Discovery
Look for these files:
```
configuration.php
joomla.xml
index.php
administrator/manifests/files/joomla.xml
language/en-GB/en-GB.xml
```

### 3. Framework-Specific Endpoints
Check these Joomla-specific endpoints:
```
/administrator/
/index.php?option=com_content
/index.php?option=com_users
/api/index.php/v1/
/media/system/js/core.js
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=31536000
```

### Vulnerable Patterns
- Missing `.htaccess` file in `/administrator/`
- Default admin credentials
- Not removing `/installation/` directory
- Outdated Joomla core and extensions
- Exposed `/configuration.php` file
- Weak file permissions
- Directory listing enabled
- Missing security extensions (Admin Tools, RSFirewall)
- Unpatched vulnerabilities in extensions

## Technology Stack Integration

### Common Joomla Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| MySQL | Database | Database configuration in `/configuration.php` |
| Apache/Nginx | Web server | Server headers |
| VirtueMart | E-commerce | `/components/com_virtuemart/` |
| HikaShop | E-commerce | `/components/com_hikashop/` |
| J2Store | E-commerce | `/components/com_j2store/` |
| K2 | Content | `/components/com_k2/` |
| Redis | Caching | Cache configuration |
| PHP | Server scripting | PHP version in headers |

## Example Fingerprinting Commands

```bash
# Check for Joomla headers
curl -I https://example.com

# Check for Joomla generator meta tag
curl https://example.com | grep -i "Joomla"

# Check for Joomla admin interface
curl -I https://example.com/administrator/

# Check for Joomla core JavaScript
curl -I https://example.com/media/system/js/core.js

# Check for Joomla version file
curl -I https://example.com/administrator/manifests/files/joomla.xml

# Check for e-commerce extensions
curl -I https://example.com/components/com_virtuemart/
```

## False Positives
- Mambo CMS (Joomla fork with similar structure)
- Custom PHP applications with similar directory structure
- Other PHP-based CMS platforms
- Installations with renamed `/administrator/` directory
- Static sites with Joomla-like meta tags

## Fingerprinting Tooling
- HTTP header analysis
- HTML meta tag detection
- Static file pattern analysis
- Error page analysis
- Directory enumeration
- Version file detection
- E-commerce extension detection

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns