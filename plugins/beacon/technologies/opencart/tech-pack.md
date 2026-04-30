# OpenCart E-commerce Tech Pack

## Framework Identification
**Name**: OpenCart
**Type**: E-commerce Platform
**Language**: PHP

## Fingerprinting Rules
```yaml
rules:
  - name: opencart-static-files
    description: Detect OpenCart via static file patterns
    pattern: "/catalog/view/theme/[^/]+/stylesheet/stylesheet.css"
    type: path
    confidence: high
    
  - name: opencart-route-pattern
    description: Detect OpenCart via route pattern
    pattern: "index\\.php\\?route=product/(product|category)"
    type: path
    confidence: high
    
  - name: opencart-cookie
    description: Detect OpenCart via session cookie
    pattern: "OCSESSID=[a-f0-9]{32}"
    type: cookie
    confidence: high
    
  - name: opencart-admin-files
    description: Detect OpenCart via admin files
    pattern: "/admin/view/javascript/common.js"
    type: path
    confidence: high
    
  - name: opencart-image-cache
    description: Detect OpenCart via image cache
    pattern: "/image/cache/"
    type: path
    confidence: medium
    
  - name: opencart-error-page
    description: Detect OpenCart via error pages
    pattern: "(The page you requested cannot be found|We are currently performing maintenance)"
    type: body
    confidence: medium
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for OpenCart static file patterns
- Look for `OCSESSID` cookie
- Analyze URL patterns for `index.php?route=`
- Probe admin interface files
- Check HTTP response headers

### Phase 4: Directory Enumeration
- Enumerate `/catalog/`, `/admin/`, `/system/` directories
- Check `/image/cache/` and `/download/` directories
- Probe `/vqmod/` or `/storage/modification/` directories
- Look for theme directories in `/catalog/view/theme/`
- Check for extension directories

### Phase 5: Known Patterns
- Apply OpenCart-specific e-commerce discovery probes
- Check `/cart`, `/checkout`, `/account` routes
- Probe product and category pages
- Look for `/admin/index.php` login page
- Check maintenance mode response

### Phase 6: API Analysis
- Analyze front controller routes (`index.php?route=`)
- Check for REST API extensions if available
- Document available endpoints and parameters
- Test authentication requirements
- Identify version-specific patterns

## Common OpenCart API Patterns

```http
# Product listing
GET /index.php?route=product/category&path=20

# Product details
GET /index.php?route=product/product&product_id=43

# Search
GET /index.php?route=product/search&search=test

# Add to cart
POST /index.php?route=checkout/cart/add
product_id=43&quantity=1

# Customer account
GET /index.php?route=account/account

# Admin login
POST /admin/index.php?route=common/login
username=admin&password=*****&redirect=common/dashboard
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| Admin JS | "OpenCart 3.0.3.8" in `/admin/view/javascript/common.js` | High |
| Database | `oc_setting` table contains version info | High |
| Admin Footer | Version in admin login footer | High |
| File Patterns | Directory structure differences | Medium |
| Template Engine | Twig vs traditional PHP templates | Medium |

## E-commerce Specific Checklist
When OpenCart is detected, probe:
- [ ] Product catalog functionality
- [ ] Shopping cart operations
- [ ] Checkout process flow
- [ ] Customer account endpoints
- [ ] Payment gateway integrations
- [ ] Shipping method configurations
- [ ] Order management
- [ ] Search functionality
- [ ] Content pages
- [ ] Image and media handling
- [ ] Extension/module endpoints

## Framework-Specific Probes
Check these OpenCart-specific endpoints:
```
/
/index.php?route=product/category
/index.php?route=product/product&product_id=1
/index.php?route=account/login
/index.php?route=checkout/cart
/admin/index.php
/image/cache/
/catalog/view/theme/[theme_name]/stylesheet/stylesheet.css
/vqmod/
```

## Technology Stack Integration

### Common OpenCart Extensions
| Extension Type | Purpose | Detection Pattern |
|----------------|---------|--------------------|
| Payment | Payments | `/extension/payment/` directory |
| Shipping | Shipping | `/extension/shipping/` directory |
| Theme | Design | `/catalog/view/theme/[theme_name]/` |
| Analytics | Tracking | `/extension/analytics/` |
| Marketing | Promotions | `/extension/module/` |
| VQMod | Modifications | `/vqmod/xml/` files |
| OCMod | Modifications | `/system/modification/` |
| Captcha | Security | `/extension/captcha/` |
| Feed | Exports | `/extension/feed/` |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Confirm presence of OpenCart-specific routes
- Check for distinctive static file patterns
- Validate e-commerce functionality exists
- Cross-check with PHP application detection
- Test actual product/cart workflows

## Integration with Beacon Skill
- Load this tech pack when OpenCart patterns detected
- Run OpenCart-specific e-commerce discovery probes
- Include OpenCart in e-commerce analysis phases
- Document all front controller routes and endpoints
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
