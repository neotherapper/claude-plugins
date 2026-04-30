# Drupal Tech Pack

## Framework Identification
**Name**: Drupal
**Type**: Enterprise Content Management System
**Language**: PHP

## Fingerprinting Rules
```yaml
rules:
  - name: drupal-generator-header
    description: Detect Drupal via generator header
    pattern: "X-Generator: Drupal"
    type: header
    confidence: definitive
    
  - name: drupal-core-directory
    description: Detect Drupal via core directory
    pattern: "/core/"
    type: path
    confidence: high
    
  - name: drupal-changelog-file
    description: Detect Drupal via changelog file
    pattern: "/CHANGELOG\\.txt$"
    type: path
    confidence: medium
    
  - name: drupal-generator-meta
    description: Detect Drupal via meta generator tag
    pattern: 'content="Drupal"'
    type: body
    confidence: definitive
    
  - name: drupal-modules-structure
    description: Detect Drupal via modules directory structure
    pattern: "/modules/[^/]+/"
    type: path
    confidence: high
    
  - name: drupal-jsonapi
    description: Detect Drupal via JSON:API endpoints
    pattern: "/jsonapi/"
    type: path
    confidence: high
    
  - name: drupal-admin-path
    description: Detect Drupal via admin path
    pattern: "/admin/"
    type: path
    confidence: high
    
  - name: drupal-rest-api
    description: Detect Drupal via REST API endpoints
    pattern: "/node/(\\d+|page)"
    type: path
    confidence: medium
    
  - name: drupal-cache-headers
    description: Detect Drupal via cache headers
    pattern: "X-Drupal-Cache|X-Drupal-Dynamic-Cache"
    type: header
    confidence: high
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for `X-Generator: Drupal` header
- Look for Drupal generator meta tag
- Probe `/core/` directory
- Check for `/CHANGELOG.txt` accessibility
- Look for cache headers (`X-Drupal-Cache`)
- Check for `/admin/` directory

### Phase 4: Directory Enumeration
- Enumerate `/core/`, `/modules/`, `/sites/` directories
- Check `/themes/` directory for installed themes
- Probe `/profiles/` directory for installation profiles
- Look for `/libraries/` directory for third-party libraries
- Check `/vendor/` for Composer dependencies

### Phase 5: Known Patterns
- Apply Drupal-specific discovery probes
- Check common admin routes (`/admin/`)
- Probe REST API endpoints (`/node`, `/user`)
- Check JSON:API endpoints (`/jsonapi/`)
- Look for Views export endpoints
- Check for e-commerce module patterns

### Phase 6: API Analysis
- Analyze REST API (`/node`, `/user`, `/comments`)
- Test JSON:API (`/jsonapi/`)
- Check Views REST Export endpoints
- Document authentication requirements
- Identify available resources and endpoints
- Analyze response formats

### Phase 7: Version Analysis
- Extract version from `X-Generator` header
- Check `/CHANGELOG.txt` for version info
- Look for version in `/core/CORE_VERSION.txt`
- Extract version from `/core/lib/Drupal.php`
- Check admin footer version info
- Identify Drupal 7 vs Drupal 8+ patterns

### Phase 8: E-commerce Detection
- Check for Drupal Commerce (`/cart`, `/checkout`, `/modules/commerce/`)
- Look for Ubercart (`/cart`, `/checkout`, `/modules/ubercart/`)
- Probe for product catalog pages
- Check for order management routes
- Look for payment integration patterns

## Common Drupal API Patterns

```http
# REST API examples
GET /node/1?_format=json
GET /user/1?_format=json
GET /comment/1?_format=json
POST /entity/node?_format=json

# JSON:API examples
GET /jsonapi/node/article
GET /jsonapi/user/user
GET /jsonapi/comment/comment

# Views REST Export (configured)
GET /views/[view-name].json

# Admin routes
GET /admin/content
GET /admin/structure
GET /admin/modules
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| Generator Header | `X-Generator: Drupal 9.5.3` | Definitive |
| Changelog | `/CHANGELOG.txt` version | High |
| Meta Tag | Generator content | Definitive |
| Core Directory | `/core/CORE_VERSION.txt` | High |
| Database | `{system}` table version | Medium |
| Admin Footer | Admin page footer | High |

## Drupal-Specific Checklist
When Drupal is detected:
- [ ] Identify Drupal 7 vs Drupal 8/9/10
- [ ] Map REST API endpoints
- [ ] Check JSON:API functionality
- [ ] Identify installed modules
- [ ] Check for Views REST exports
- [ ] Identify installed themes
- [ ] Check caching mechanisms
- [ ] Look for e-commerce modules
- [ ] Check for security modules
- [ ] Identify custom modules
- [ ] Check for installation profiles

## Framework-Specific Probes
Check these Drupal-specific endpoints:
```
/
/admin/
/node/1
/jsonapi/
/core/CORE_VERSION.txt
/CHANGELOG.txt
/modules/
/themes/
/cart
/checkout
```

## Technology Stack Integration

### Common Drupal Modules
| Module | Type | Detection Pattern |
|--------|------|--------------------|
| Drupal Commerce | E-commerce | `/modules/commerce/` |
| Ubercart | E-commerce | `/modules/ubercart/` |
| Views | Content | `/modules/views/` |
| CTools | Developer | `/modules/ctools/` |
| Panels | Layout | `/modules/panels/` |
| Token | Utility | `/modules/token/` |
| Pathauto | SEO | `/modules/pathauto/` |
| Paranoia | Security | `/modules/paranoia/` |
| Redis | Caching | Redis configuration |
| Solr | Search | Solr integration |
| JSON:API | API | `/jsonapi/` |
| RESTful Web Services | API | `/node` API endpoints |
| GraphQL | API | GraphQL queries |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Confirm presence of `/core/` directory
- Check Drupal-specific headers and meta tags
- Validate API functionality
- Test authentication requirements
- Check for Drupal-specific route patterns
- Cross-check version consistency across indicators

## Integration with Beacon Skill
- Load this tech pack when Drupal headers or directory patterns detected
- Run Drupal version detection
- Probe REST and JSON:API endpoints
- Check for e-commerce modules
- Document all API surfaces
- Include Drupal in CMS and enterprise site analysis
## 11. GitHub Code Search Patterns

Use these queries on GitHub to find custom endpoints, plugin code, and configuration examples for this framework.

### Framework-Specific Queries

| Search Query | What it finds |
|--------------|---------------|
| `"<pattern>" language:<lang> path:<path>` | <description> |

### Example Queries

```bash
# Search for custom endpoints
site:github.com "<framework>" "api" filetype:<ext>

# Search for auth patterns  
site:github.com "<framework>" "auth" "middleware"

# Search for config files
site:github.com "<framework>" "config" "endpoint"
```

## 12. Framework-Specific Google Dorks

### Discovery Queries

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:<path>` | <description> |

### Complete Dork List

```
# API endpoints
site:{domain} inurl:/api/
site:{domain} inurl:/v1/

# Framework paths
site:{domain} inurl:<specific-path>
```

## 13. Cross-Cutting OSINT Patterns

These patterns apply across frameworks and should be checked for any detected technology.

### Favicon Hashing

Identify technology stack by hashing favicon and searching Shodan/Censys for same stack:

```bash
# Get favicon hash (mmh3 hash of favicon content)
curl -s "https://{domain}/favicon.ico" | python3 -c "
import sys, hashlib
data = sys.stdin.buffer.read()
# Simple mmh3 hash simulation using Python
try:
    import mmh3
    print('Favicon hash:', mmh3.hash(data))
except ImportError:
    print('Install mmh3: pip install mmh3')
"

# Search Shodan for same favicon (indicates shadow IT subdomains)
# site:shodan.io search: icon_hash:{hash}
```

**What it reveals:** Hidden subdomains running same framework stack as main site.

### Source Map Discovery

Check for source maps across all JS bundles:

```bash
# Extract all JS bundle URLs from HTML
curl -s "https://{domain}/" | grep -oP 'src="[^"]+\.js[^"]*"' | grep -oP '"[^"]+"' | tr -d '"' > js_urls.txt

# Check each for .map file
while read url; do
  map_url="${url}.map"
  status=$(curl -s -o /dev/null -w "%{http_code}" "${map_url}")
  [ "$status" = "200" ] && echo "SOURCE MAP: ${map_url}"
done < js_urls.txt
```

**Build tool patterns:**
| Build Tool | Source Map Pattern | Detection |
|------------|-------------------|------------|
| Webpack | `{bundle}.js.map` or `//# sourceMappingURL=` | Check response header `X-SourceMap` |
| Vite | `{name}-[hash].js.map` | Vite manifest `manifest.json` |
| Rollup | `{bundle}.js.map` | Check `sourceMappingURL` comment |
| esbuild | `{bundle}.js.map` | Check `sourceMappingURL` comment |
| Next.js | `/_next/static/chunks/*.js.map` | Only if `productionBrowserSourceMaps: true` |

### Tech Stack → API Pattern Mapping

Auto-map detected frameworks to likely endpoint patterns:

| Framework | Common API Patterns |
|-----------|---------------------|
| Next.js | `/api/*`, `/_next/data/*`, `/api/auth/*`, `/api/trpc/*` |
| WordPress | `/wp-json/*`, `/wp-json/wp/v2/*`, `/wp-admin/admin-ajax.php` |
| Shopify | `/api/2024-10/graphql.json`, `/products.json`, `/collections.json` |
| Rails | `/api/v1/*`, `/assets/*`, `/users/sign_in` |
| Laravel | `/api/*`, `/livewire/message/*`, `/sanctum/csrf-cookie` |
| Strapi | `/api/*`, `/admin/*`, `/api/upload*` |
| Magento | `/rest/V1/*`, `/pub/static/*` |
| Django | `/api/*`, `/admin/*`, `/accounts/*` |
| Express | `/api/*`, `/v1/*`, `/health` |
| Astro | `/_astro/*`, `/api/*` |
| Ghost | `/ghost/api/*`, `/members/api/*` |

When Phase 3 detects a framework, use this table to prioritize Phase 5/6/7 probes.

### Email Naming Convention Analysis

Extract emails from theHarvester/GitHub results to predict internal subdomains:

```bash
# Sample emails found: john.doe@example.com, jane.smith@example.com
# Predicted subdomains: mail.example.com, smtp.example.com, exchange.example.com

# Common patterns:
# first.last@ → internal.example.com, mail.example.com
# firstinitial+last@ → owa.example.com, outlook.example.com
```

**Add to Phase 9 session brief:** Note email patterns and predicted subdomains.
