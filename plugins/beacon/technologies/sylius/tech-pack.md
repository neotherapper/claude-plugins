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