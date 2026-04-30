# PrestaShop E-commerce Tech Pack

## Framework Identification
**Name**: PrestaShop
**Type**: E-commerce Platform
**Language**: PHP

## Fingerprinting Rules
```yaml
rules:
  - name: prestashop-meta-generator
    description: Detect PrestaShop via meta generator tag
    pattern: 'content="PrestaShop"'
    type: body
    confidence: high
    
  - name: prestashop-x-generator-header
    description: Detect PrestaShop via X-Generator header
    pattern: "X-Generator: PrestaShop"
    type: header
    confidence: high
    
  - name: prestashop-admin-directory
    description: Detect PrestaShop via admin directory pattern
    pattern: "/admin[a-zA-Z0-9]{4,}/"
    type: path
    confidence: high
    
  - name: prestashop-api-routes
    description: Detect PrestaShop via API routes
    pattern: "/api/(products|categories|orders|customers)"
    type: path
    confidence: high
    
  - name: prestashop-cookie
    description: Detect PrestaShop via cookie pattern
    pattern: "PrestaShop-[a-f0-9]{32}"
    type: cookie
    confidence: high
    
  - name: prestashop-file-patterns
    description: Detect PrestaShop via file patterns
    pattern: "/themes/[^/]+/css/global.css"
    type: path
    confidence: medium
    
  - name: prestashop-error-page
    description: Detect PrestaShop via error pages
    pattern: "(This store is currently undergoing maintenance|PrestaShop\\.com)"
    type: body
    confidence: medium
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for `X-Generator: PrestaShop` header
- Look for PrestaShop meta tag
- Probe known PrestaShop files (`/config/settings.inc.php`)
- Check for randomized admin directory pattern
- Analyze cookies for PrestaShop pattern

### Phase 4: Directory Enumeration
- Enumerate `/themes/`, `/modules/`, `/admin*/` directories
- Check `/override/`, `/upload/`, `/cache/` directories
- Probe `/api/` for REST API availability
- Check for legacy module endpoints

### Phase 5: Known Patterns
- Apply PrestaShop-specific probes from e-commerce checklist
- Check `/cart`, `/order`, `/my-account` routes
- Probe API endpoints for authentication requirements
- Check `/search` for search functionality
- Look for `/modules/` directory structure

### Phase 6: API Analysis
- Analyze REST API if available (`/api/`)
- Test CRUD operations on products, categories, orders
- Document authentication requirements
- Identify version-specific API differences

## Common PrestaShop API Patterns

```http
# Product listing
GET /api/products?display=[full|id|name]

# Single product
GET /api/products/{id}

# Product categories
GET /api/categories?display=full

# Create order
POST /api/orders
{
  "order": {
    "id_customer": 1,
    "id_cart": 1,
    "id_currency": 1,
    "id_lang": 1
  }
}

# Customer management
GET /api/customers/{id}
POST /api/customers
PUT /api/customers/{id}

# Cart operations
GET /api/carts/{id}?display=full
POST /api/carts
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| settings.inc.php | `_PS_VERSION_ = '1.7.8.5'` | High |
| Admin Footer | "PrestaShop™ 1.7.8.5" | High |
| Database | `ps_configuration` table | Medium |
| File Patterns | `/themes/core.js` vs `/js/theme.js` | Medium |
| Error Pages | Maintenance mode message format | Low |

## E-commerce Specific Checklist
When PrestaShop is detected, probe:
- [ ] Product catalog endpoints
- [ ] Shopping cart functionality
- [ ] Checkout process endpoints
- [ ] Payment gateway modules
- [ ] Shipping method configurations
- [ ] Order status workflows
- [ ] Customer authentication flows
- [ ] Search functionality
- [ ] Content management pages
- [ ] Module-specific endpoints
- [ ] Admin REST API endpoints

## Framework-Specific Probes
Check these PrestaShop-specific endpoints:
```
/
/admin*/index.php
/api/
/api/products
/api/categories
/api/orders
/modules/[module_name]/[action]
/themes/[theme_name]/css/global.css
/js/jquery/jquery.js
/cart
/order
/my-account
```

## Technology Stack Integration

### Common PrestaShop Modules
| Module | Purpose | Detection Pattern |
|--------|---------|--------------------|
| MailChimp | Email marketing | `/modules/mailchimp/` |
| PayPal | Payments | `/modules/paypal/` |
| Stripe | Payments | `/modules/stripe/` |
| Google Analytics | Analytics | `/modules/ganalytics/` |
| SEO Expert | SEO | `/modules/seoexpert/` |
| Page Cache | Caching | `/modules/pagecache/` |
| Advanced Search | Search | `/modules/blocksearch/` |
| Loyalty Program | Loyalty | `/modules/loyalty/` |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Confirm presence of `/admin*/` directory pattern
- Check for PrestaShop-specific API endpoints
- Validate e-commerce functionality
- Cross-check with PHP/Smarty detection
- Test actual product/cart/checkout workflows

## Integration with Beacon Skill
- Load this tech pack when PrestaShop patterns detected
- Run extended e-commerce discovery probes
- Include PrestaShop in e-commerce-specific analysis
- Document all API surfaces and endpoints
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
import sys
try:
    import mmh3
    data = sys.stdin.buffer.read()
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

