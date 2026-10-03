# TYPO3 Framework Fingerprinting Guide

## Framework Overview
TYPO3 is a powerful open-source enterprise content management system written in PHP. It's known for its scalability, security, and extensibility, making it a popular choice for complex websites, intranets, and web applications, particularly in Europe and among government organizations.

## Fingerprinting Patterns

### 1. Static File Patterns
TYPO3 has distinctive static file patterns:
- `/typo3/` - TYPO3 backend directory
- `/typo3conf/` - Configuration directory
- `/fileadmin/` - File management
- `/typo3temp/` - Temporary files
- `/uploads/` - Uploaded content
- `/typo3_src/` - Core source directory
- `/typo3/sysext/` - System extensions
- `/typo3conf/ext/` - Installed extensions
- `/typo3conf/LocalConfiguration.php` - Local configuration

### 2. HTTP Headers
TYPO3 sites often show these headers:
```
X-Generator: TYPO3 CMS
X-TYPO3-Content-Length: [length]
X-UA-Compatible: IE=edge
Set-Cookie: fe_typoscript=[hash]
```

### 3. HTML Meta Tags
TYPO3 sites typically include:
```html
<meta name="generator" content="TYPO3 CMS" />
<meta name="robots" content="index,follow" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
```

### 4. JavaScript Globals
TYPO3 exposes these global variables:
```javascript
TYPO3 = {
 settings: {
 AJAX: {...},
 CSRF: {
 token: "[token]",
 parameterName: "tx_csrftoken"
 }
 },
 configuration: {...},
 lang: {...}
};
```

### 5. Common Routes
Standard TYPO3 routes:
- `/typo3/` - Backend login
- `/typo3/install/` - Install tool (restricted)
- `/?id=[page-id]` - Page rendering
- `/?type=146775` - AJAX endpoints
- `/fileadmin/` - File management
- `/?eID=[extension-id]` - Extension endpoints
- `/_assets/` - Asset management
- `/index.php` - Front controller

### 6. API Endpoints
TYPO3 exposes multiple APIs:

**Core AJAX API:**
```
POST /?type=146775
Params: {
 ajax: [route],
 tx_csrftoken: [token],
 parameters: {...}
}
```

**Extension APIs:**
- `/api/[extension-key]` (REST API extensions)
- `/rest/` (REST API endpoints)
- `/graphql` (GraphQL extensions)

**Frontend APIs:**
- `/?type=12345&tx_[extension][action]=...`

### 7. Error Pages
TYPO3 error pages:
- **404**: Default or custom 404 page
- **500**: "Oops, an error occurred!" with reference code
- **403**: Access denied page
- **Maintenance**: Site under maintenance message

### 8. Version Fingerprinting
Detect TYPO3 version through:
- `X-Generator` HTTP header
- Meta generator tag
- `/typo3/sysext/core/Classes/Core/CmsVersion.php`
- `/typo3/install/` (shows version)
- `/typo3conf/LocalConfiguration.php`
- `/typo3conf/PackageStates.php`
- Error page reference codes
- `/typo3/sysext/core/Documentation/Changelog/`

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/typo3/
/typo3conf/
/fileadmin/
/uploads/
/typo3temp/
```

### 2. Common File Discovery
Look for these files:
```
/typo3conf/LocalConfiguration.php
/typo3conf/PackageStates.php
/typo3/install/index.php
/typo3/sysext/core/Classes/Core/CmsVersion.php
```

### 3. Framework-Specific Endpoints
Check these TYPO3-specific endpoints:
```
/typo3/
/typo3/install/
/?type=146775
/typoscript/
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self'
```

### Vulnerable Patterns
- Exposed `/typo3/install/` directory
- Default backend credentials
- Not restricting `/fileadmin/` access
- Missing `.htaccess` files in `/typo3/`
- Unpatched security vulnerabilities
- Exposed `LocalConfiguration.php`
- Weak file permissions
- Missing CSRF protection
- Unsecured AJAX endpoints
- Directory listing enabled

## Technology Stack Integration

### Common TYPO3 Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| MySQL | Database | Database configuration |
| RealURL | SEO URLs | RealURL configuration |
| Fluid | Templating | Fluid template files |
| Solr | Search | Solr configuration |
| Redis | Caching | Redis configuration |
| PHP | Server scripting | PHP version |
| Composer | Dependency management | `/composer.json` |
| Varnish | Caching | Varnish headers |

## Example Fingerprinting Commands

```bash
# Check TYPO3 headers
curl -I https://example.com

# Check for TYPO3 meta tags
curl https://example.com | grep -i "TYPO3"

# Check TYPO3 backend
curl -I https://example.com/typo3/

# Check install tool
curl -I https://example.com/typo3/install/

# Check AJAX endpoint
curl -I "https://example.com/?type=146775"
```

## False Positives
- Custom TYPO3 distributions
- Other PHP applications with similar directory structures
- Sites using former TYPO3 integrations
- Sites with `/typo3/` admin interface from other CMS
- Migrated sites with residual TYPO3 files

## Fingerprinting Tooling
- HTTP header analysis for TYPO3-specific headers
- HTML meta tag detection
- Static file pattern analysis
- Directory enumeration
- Version file detection
- AJAX endpoint detection
- Configuration file analysis

## Changelog
- 2026-04-30: Initial guide creation
- Future: Add version-specific fingerprinting patterns