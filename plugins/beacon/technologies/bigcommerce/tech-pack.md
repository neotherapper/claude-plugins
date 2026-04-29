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