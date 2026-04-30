# BigCommerce E-commerce Tech Pack

## Framework Identification
**Name**: BigCommerce
**Type**: Cloud-based E-commerce Platform
**Hosting**: SaaS (Fully hosted)

## Fingerprinting Rules
```yaml
rules:
  - name: bigcommerce-api-headers
    description: Detect BigCommerce via API version headers
    pattern: "X-Bc-Api-Version"
    type: header
    confidence: definitive
    
  - name: bigcommerce-store-header
    description: Detect BigCommerce via store version header
    pattern: "X-Bc-Store-Version"
    type: header
    confidence: definitive
    
  - name: bigcommerce-static-files
    description: Detect BigCommerce via static file patterns
    pattern: "/bc-static/"
    type: path
    confidence: high
    
  - name: bigcommerce-generator-meta
    description: Detect BigCommerce via meta generator tag
    pattern: 'content="BigCommerce"'
    type: body
    confidence: high
    
  - name: bigcommerce-storefront-api
    description: Detect BigCommerce via Storefront API endpoints
    pattern: "/api/storefront/(cart|products|categories)"
    type: path
    confidence: high
    
  - name: bigcommerce-js-globals
    description: Detect BigCommerce via JavaScript globals
    pattern: "window\\.(store_hash|bigcommerce)"
    type: js_global
    confidence: high
    
  - name: bigcommerce-rest-api
    description: Detect BigCommerce via REST API endpoints
    pattern: "/api/v2/(products|orders|customers)"
    type: path
    confidence: medium
    
  - name: bigcommerce-graphql
    description: Detect BigCommerce via GraphQL endpoint
    pattern: "/graphql"
    type: path
    confidence: medium
    
  - name: bigcommerce-server-header
    description: Detect BigCommerce via server header
    pattern: "BC/ocst-"
    type: header
    confidence: high
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for `X-Bc-Api-Version` and `X-Bc-Store-Version` headers
- Look for `/bc-static/` directory patterns
- Search HTML for BigCommerce meta generator tag
- Check for `/api/storefront/cart` endpoint
- Analyze JavaScript for BigCommerce globals

### Phase 4: Directory Enumeration
- Enumerate `/bc-static/`, `/product-images/`, `/content/` directories
- Check `/stencil/` and `/theme/` directories
- Probe `/assets/js/` and `/assets/css/` directories
- Look for `/pages/` content directory

### Phase 5: Known Patterns
- Apply BigCommerce-specific e-commerce discovery probes
- Check `/cart`, `/checkout` routes
- Probe `/account.php`, `/login.php` authentication routes
- Check `/search.php` search functionality
- Look for `/wishlist.php` wishlist functionality

### Phase 6: API Analysis
- Analyze Storefront API (`/api/storefront/`)
- Check REST API endpoints (`/api/v2/`) for auth requirements
- Test GraphQL endpoint at `/graphql`
- Identify authentication methods
- Document available resources and endpoints

## Common BigCommerce API Patterns

```http
# Storefront API examples
GET /api/storefront/cart
GET /api/storefront/products?include_fields=name,price
GET /api/storefront/categories
POST /api/storefront/cart/items

# REST API examples
GET /api/v2/products
GET /api/v2/orders?limit=5
POST /api/v2/customers
PUT /api/v2/products/{id}

# GraphQL example
POST /graphql
{
  products {
    edges {
      node {
        entityId
        name
        prices {
          price {
            value
            currencyCode
          }
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
| HTTP Headers | `X-Bc-Api-Version: 3` | Definitive |
| REST API | `/api/v2/store` returns version | High |
| Meta Tag | `generator` content includes version | Medium |
| JavaScript | `window.stencil_version` global | High |
| Server Header | `Server: BC/ocst-6.1.0` | High |

## E-commerce Specific Checklist
When BigCommerce is detected, probe:
- [ ] Product catalog functionality
- [ ] Shopping cart operations
- [ ] Checkout process flow
- [ ] Customer account endpoints
- [ ] Payment gateway configurations
- [ ] Shipping method options
- [ ] Order management endpoints
- [ ] Search functionality
- [ ] Multi-channel selling endpoints
- [ ] API authentication methods
- [ ] Content management pages
- [ ] Theme customization files

## Framework-Specific Probes
Check these BigCommerce-specific endpoints:
```
/
/api/storefront/cart
/api/storefront/products
/api/v2/store
/graphql
/.well-known/bigcommerce/
/bc-static/
/stencil/config.js
/account.php
/login.php
/cart
/checkout
```

## Technology Stack Integration

### Common BigCommerce Integrations
| Integration | Purpose | Detection Pattern |
|-------------|---------|--------------------|
| Stencil | Theme engine | `/stencil/` directory |
| Handlebars | Templating | `{{...}}` syntax in templates |
| Payment Processors | Payments | `/payment_methods` API |
| Shipping Providers | Shipping | `/shipping_methods` API |
| ERP Systems | Enterprise | REST API usage |
| POS Systems | Retail | `/orders` API usage |
| Analytics | Tracking | Tracking scripts in HTML |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Confirm presence of BigCommerce-specific headers
- Check for `/api/storefront/` endpoints
- Validate e-commerce functionality exists
- Cross-check with CDN patterns
- Test actual product/cart workflows

## Integration with Beacon Skill
- Load this tech pack when BigCommerce headers or file patterns are detected
- Run extended e-commerce discovery probes
- Include BigCommerce API endpoints in discovery phases
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

