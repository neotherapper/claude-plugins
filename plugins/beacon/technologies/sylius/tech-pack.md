# Sylius E-commerce Tech Pack

## Framework Identification
**Name**: Sylius
**Type**: E-commerce Framework
**Language**: PHP
**Base Framework**: Symfony

## Fingerprinting Rules
```yaml
rules:
  - name: sylius-admin-route
    description: Detect Sylius via admin route
    pattern: "/admin/"
    type: path
    confidence: high
    
  - name: sylius-meta-generator
    description: Detect Sylius via meta generator tag
    pattern: 'content="Sylius"'
    type: body
    confidence: high
    
  - name: sylius-x-generator-header
    description: Detect Sylius via X-Generator header
    pattern: "X-Generator: Sylius"
    type: header
    confidence: high
    
  - name: sylius-api-routes
    description: Detect Sylius via API routes
    pattern: "/api/(products|taxons|orders)"
    type: path
    confidence: high
    
  - name: sylius-assets
    description: Detect Sylius via static assets
    pattern: "/bundles/syliusshop/"
    type: path
    confidence: medium
    
  - name: sylius-error-page
    description: Detect Sylius via error pages
    pattern: "The requested URL was not found.*Sylius"
    type: body
    confidence: medium
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for Sylius `/admin/` route
- Look for Sylius meta generator tag
- Probe API endpoints (`/api/products`)
- Check for Symfony profiler (`/_profiler`)
- Analyze HTTP headers for `X-Generator: Sylius`

### Phase 4: Directory Enumeration
- Enumerate `/admin/`, `/api/`, `/shop/` directories
- Check for `/bundles/` directory structure
- Probe `/themes/` directory for custom themes
- Check `/build/` directory for frontend assets

### Phase 5: Known Patterns
- Apply Sylius-specific e-commerce probes
- Check `/cart/`, `/checkout/`, `/account/` routes
- Probe `/products/` for product listings
- Check `/api/v2/graphql` for GraphQL endpoint
- Look for `/login` and `/register` authentication routes

### Phase 6: API Analysis
- Analyze REST API at `/api/`
- Check API Platform at `/api/v2/`
- Test GraphQL endpoint at `/api/v2/graphql`
- Identify authentication requirements
- Document available resources and methods

## Common E-commerce Patterns

```http
# Product listing
GET /api/products?page=1&limit=10

# Single product
GET /api/products/{code}

# Cart operations
GET /api/carts/{id}
POST /api/carts/{id}/items

# Checkout steps
POST /api/checkouts/{id}/address
POST /api/checkouts/{id}/ship
POST /api/checkouts/{id}/pay

# GraphQL example
POST /api/v2/graphql
query {
  products(first: 5) {
    edges {
      node {
        name
        code
        variants {
          price
        }
      }
    }
  }
}
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| Composer File | `"sylius/sylius": "1.13.*"` | High |
| Admin Footer | "Sylius v1.13" | High |
| API Version | "sylius_version: 1.13.0" in headers | High |
| Error Pages | "Sylius 1.13" in development errors | Medium |
| Asset Files | `/build/app-1.13.0.js` | Medium |

## E-commerce Specific Checklist
When Sylius is detected, probe for:
- [ ] Product catalog endpoints
- [ ] Shopping cart functionality
- [ ] Checkout process endpoints
- [ ] Customer authentication flows
- [ ] Payment gateway integrations
- [ ] Shipping method configurations
- [ ] Promotion and discount systems
- [ ] Order management APIs
- [ ] Search functionality
- [ ] Media asset management

## Framework-Specific Probes

Check these Sylius-specific endpoints:
```
/admin/
/admin/dashboard
/admin/login
/api/doc
/api/v2/graphql
/shop/
/products/
/cart/
/checkout/
/api/products
/api/taxons
/api/orders
/api/customers
```

## Technology Stack Integration

### Common Sylius Integration Points
| Technology | Purpose | Detection Pattern |
|------------|---------|--------------------|
| Symfony | PHP Framework | `_profiler`, `symfony` in headers |
| Doctrine | ORM | `_profiler/doctrine`, database queries |
| API Platform | API Framework | `/api/v2/`, GraphQL endpoint |
| Webpack | Asset Build | `/build/manifest.json`, Encore |
| Elasticsearch | Search | `/api/_search`, search endpoints |
| Redis | Caching | `Redis` cache headers |
| Twig | Templating | `.twig` files, Twig error pages |
| Stripe/PayU | Payments | Payment method references, secrets |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Cross-check Symfony framework detection
- Confirm presence of e-commerce functionality
- Check for Sylius-specific API endpoints
- Verify e-commerce specific directory structure (`/shop/`, `/admin/`)
- Test actual e-commerce endpoints (products, cart, checkout)

## Integration with Beacon Skill
- Load this tech pack when Sylius/Symfony patterns are detected
- Focus discovery on e-commerce specific endpoints
- Include Sylius in e-commerce probe checklist
- Run extended e-commerce analysis phases
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

