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