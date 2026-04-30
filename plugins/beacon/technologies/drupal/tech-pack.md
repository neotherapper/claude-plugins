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