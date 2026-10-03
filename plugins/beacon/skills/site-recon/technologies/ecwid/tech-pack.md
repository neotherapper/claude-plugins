# Ecwid E-commerce Tech Pack

## Framework Identification
**Name**: Ecwid
**Type**: Cloud-based Embeddable E-commerce
**Integration**: Website widget/platform integration

## Fingerprinting Rules
```yaml
rules:
  - name: ecwid-storefront-header
    description: Detect Ecwid via storefront ID header
    pattern: "X-Ecwid-Storefront-Id"
    type: header
    confidence: definitive
    
  - name: ecwid-api-version-header
    description: Detect Ecwid via API version header
    pattern: "X-Ecwid-Api-Version"
    type: header
    confidence: high
    
  - name: ecwid-integration-script
    description: Detect Ecwid via integration script
    pattern: "app\\.ecwid\\.com/script\\.js\\?[0-9]+"
    type: body
    confidence: definitive
    
  - name: ecwid-html-container
    description: Detect Ecwid via HTML container
    pattern: 'id="ecwid-store-[0-9]+"'
    type: body
    confidence: high
    
  - name: ecwid-api-endpoints
    description: Detect Ecwid via API endpoints
    pattern: "/api/v3/[0-9]+/"
    type: path
    confidence: high
    
  - name: ecwid-js-globals
    description: Detect Ecwid via JavaScript globals
    pattern: "window\\.(Ecwid|__ecwidStoreData)"
    type: js_global
    confidence: high
    
  - name: ecwid-widget-script
    description: Detect Ecwid via widget script
    pattern: "ecwid-widget\\.js"
    type: path
    confidence: medium
    
  - name: ecwid-class-names
    description: Detect Ecwid via CSS class names
    pattern: "ecwid( |-)(Product|Category|Checkout)"
    type: body
    confidence: medium
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for `X-Ecwid-Storefront-Id` header
- Look for Ecwid integration scripts (`app.ecwid.com/script.js`)
- Search for Ecwid HTML containers (`ecwid-store-[store-id]`)
- Analyze page for `window.Ecwid` global variables
- Check for `/api/v3/[store-id]/products` endpoint

### Phase 4: Directory Enumeration
- Enumerate `/api/v3/` directory for store-specific endpoints
- Check `/widget/` directory for Ecwid widgets
- Look for `/images/` directory for product images
- Probe `/apps/` directory for integrations

### Phase 5: Known Patterns
- Apply Ecwid-specific e-commerce discovery probes
- Check `/cart`, `/checkout` routes
- Probe `/api/v3/[store-id]/orders` for order management
- Check `/search` functionality
- Look for product detail pages

### Phase 6: API Analysis
- Analyze Storefront API (`/api/v3/[store-id]/`)
- Document available endpoints and resources
- Identify authentication requirements
- Check response formats and data structures

## Common Ecwid API Patterns

```http
# Store profile
GET /api/v3/[store-id]/profile

# Product listing
GET /api/v3/[store-id]/products

# Category listing
GET /api/v3/[store-id]/categories

# Order management
GET /api/v3/[store-id]/orders
POST /api/v3/[store-id]/orders

# Cart operations
GET /api/v3/[store-id]/cart
POST /api/v3/[store-id]/cart
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| HTTP Header | `X-Ecwid-Api-Version: 3.2.1` | High |
| API Response | Version in `/api/v3/[store-id]/profile` | High |
| JavaScript | Version in `ecwid-script.js` | Medium |
| Integration Code | Version-specific parameters | Low |

## E-commerce Specific Checklist
When Ecwid is detected, probe:
- [ ] Product catalog functionality
- [ ] Shopping cart operations
- [ ] Checkout process flow
- [ ] Customer account management
- [ ] Order history and management
- [ ] Payment gateway integrations
- [ ] Shipping method configurations
- [ ] Tax calculation settings
- [ ] Discount and coupon codes
- [ ] Product categories
- [ ] Store settings and configuration
- [ ] API authentication methods

## Framework-Specific Probes
Check these Ecwid-specific endpoints:
```
/api/v3/[store-id]/profile
/api/v3/[store-id]/products
/api/v3/[store-id]/orders
/api/v3/[store-id]/cart
/app.ecwid.com/script.js?[store-id]
/ecwid-script.js
/cart
/checkout
```

## Technology Stack Integration

### Common Ecwid Integrations
| Integration | Purpose | Detection Pattern |
|-------------|---------|--------------------|
| WordPress | Website integration | WordPress plugin directory |
| Wix | Website integration | Wix App Market integration |
| Squarespace | Website integration | Squarespace extensions |
| Facebook | Social selling | `/facebook` endpoint |
| Instagram | Social selling | `/instagram` endpoint |
| Payment Gateways | Payments | Payment scripts |
| Shipping APIs | Shipping | Shipping calculation endpoints |
| CDN | Asset delivery | `cdn.ecwid.com` domains |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Confirm presence of Ecwid-specific API endpoints
- Check for Ecwid meta tags and integration scripts
- Validate store functionality exists
- Cross-check store ID consistency across patterns
- Test actual cart/shop workflows

## Integration with Beacon Skill
- Load this tech pack when Ecwid headers, scripts, or API patterns are detected
- Run Ecwid-specific e-commerce discovery probes
- Document all detected API surfaces
- Include Ecwid in e-commerce platform detection
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

