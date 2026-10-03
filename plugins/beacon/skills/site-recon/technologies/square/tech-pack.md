# Square Online E-commerce Tech Pack

## Framework Identification
**Name**: Square Online
**Type**: E-commerce and Website Platform
**Hosting**: Cloud-based SaaS

## Fingerprinting Rules
```yaml
rules:
  - name: square-store-header
    description: Detect Square via store ID header
    pattern: "X-Square-Store-Id"
    type: header
    confidence: definitive
    
  - name: square-site-header
    description: Detect Square via site ID header
    pattern: "X-Square-Site-Id"
    type: header
    confidence: definitive
    
  - name: square-generator-meta
    description: Detect Square via meta generator tag
    pattern: 'content="Square Online"'
    type: body
    confidence: definitive
    
  - name: square-site-meta
    description: Detect Square via site ID meta tag
    pattern: 'name="square-site-id"'
    type: body
    confidence: high
    
  - name: square-api-endpoints
    description: Detect Square via API endpoints
    pattern: "/api/(site|store)/v1/"
    type: path
    confidence: high
    
  - name: square-js-globals
    description: Detect Square via JavaScript globals
    pattern: "window\\.(SQUARE|WEEBLY)"
    type: js_global
    confidence: high
    
  - name: square-checkout-route
    description: Detect Square via checkout route
    pattern: "/checkout"
    type: path
    confidence: medium
    
  - name: square-static-files
    description: Detect Square via Weebly static files
    pattern: "/static/weebly/"
    type: path
    confidence: medium
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for `X-Square-Store-Id` and `X-Square-Site-Id` headers
- Look for Square meta generator tag
- Search for `/api/site/v1/info` endpoint
- Analyze page for `window.SQUARE` global variable
- Check for Weebly legacy static files

### Phase 4: Directory Enumeration
- Enumerate `/api/`, `/shop/`, `/cart/` directories
- Check `/static/`, `/themes/`, `/files/` directories
- Probe `/assets/` and `/scripts/` directories
- Look for `/static/weebly/` legacy files

### Phase 5: Known Patterns
- Apply Square-specific e-commerce discovery probes
- Check `/cart` and `/checkout` routes
- Probe `/api/store/v1/products` endpoint
- Check `/shop` catalog functionality
- Look for `/account` customer area

### Phase 6: API Analysis
- Analyze Site API (`/api/site/v1/`)
- Check Store API (`/api/store/v1/`) for e-commerce functionality
- Identify authentication requirements
- Document available endpoints and resources

## Common Square API Patterns

```http
# Site information
GET /api/site/v1/info

# Product listing
GET /api/store/v1/products

# Cart management
GET /api/store/v1/cart
POST /api/store/v1/cart

# Checkout process
GET /api/store/v1/checkout
POST /api/store/v1/checkout

# Order management
GET /api/store/v1/orders
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| HTTP Header | `X-Square-Version: 2.4.1` | Definitive |
| API Response | Version in `/api/site/v1/info` | High |
| Meta Tag | Generator content includes version | Medium |
| JavaScript | Version in `window.SQUARE.version` | High |

## E-commerce Specific Checklist
When Square Online is detected, probe:
- [ ] Product catalog functionality
- [ ] Shopping cart operations
- [ ] Checkout flow analysis
- [ ] Payment gateway integration
- [ ] Order management endpoints
- [ ] Customer account management
- [ ] Shipping method configurations
- [ ] Tax calculation settings
- [ ] Inventory management
- [ ] Product search functionality
- [ ] Content management pages
- [ ] Restaurant/retail specific functionality

## Framework-Specific Probes
Check these Square Online-specific endpoints:
```
/
/api/site/v1/info
/api/store/v1/products
/api/store/v1/cart
/shop
/checkout
/cart
/static/weebly/
```

## Technology Stack Integration

### Common Square Online Integrations
| Integration | Purpose | Detection Pattern |
|-------------|---------|--------------------|
| Square Payments | Payment processing | `/payment` endpoints, `square.js` |
| Weebly Legacy | Site building | `/static/weebly/` files |
| Square POS | Retail integration | POS hardware references |
| CDN | Asset delivery | `*.squarecdn.com` domains |
| Theme Engine | Design | `/themes/` directory |
| MailChimp | Email marketing | MailChimp form embeds |
| Google Analytics | Tracking | `analytics.js` inclusion |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Confirm presence of Square-specific headers
- Check for `/api/site/v1/info` functionality
- Validate Weebly legacy file patterns
- Cross-check with Square payment integration
- Test actual cart/shop workflows

## Integration with Beacon Skill
- Load this tech pack when Square headers or meta tags are detected
- Run Square-specific e-commerce discovery probes
- Focus on Square API endpoints
- Include Square in e-commerce platform detection
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

