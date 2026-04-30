# Squarespace E-commerce Tech Pack

## Framework Identification
**Name**: Squarespace
**Type**: Website Builder with E-commerce
**Hosting**: Cloud-based SaaS

## Fingerprinting Rules
```yaml
rules:
  - name: squarespace-version-header
    description: Detect Squarespace via version header
    pattern: "X-Squarespace-Version"
    type: header
    confidence: definitive
    
  - name: squarespace-layout-header
    description: Detect Squarespace via layout header
    pattern: "X-Squarespace-Layout"
    type: header
    confidence: high
    
  - name: squarespace-meta-generator
    description: Detect Squarespace via meta generator tag
    pattern: 'content="Squarespace"'
    type: body
    confidence: definitive
    
  - name: squarespace-static-files
    description: Detect Squarespace via static file patterns
    pattern: "/static/"
    type: path
    confidence: high
    
  - name: squarespace-api-endpoints
    description: Detect Squarespace via commerce API endpoints
    pattern: "/api/commerce/v1/"
    type: path
    confidence: high
    
  - name: squarespace-js-globals
    description: Detect Squarespace via JavaScript globals
    pattern: "window\\.(Squarespace|Y\\.Squarespace)"
    type: js_global
    confidence: high
    
  - name: squarespace-cdn-patterns
    description: Detect Squarespace via CDN patterns
    pattern: "static1\\.squarespace\\.com"
    type: body
    confidence: medium
    
  - name: squarespace-template-header
    description: Detect Squarespace via template header
    pattern: "X-Squarespace-Template"
    type: header
    confidence: high
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for `X-Squarespace-Version` and `X-Squarespace-Template` headers
- Look for Squarespace meta generator tag
- Search for `/api/commerce/v1/products` endpoint
- Analyze JavaScript for Squarespace globals
- Check for `/static/` directory and CDN patterns

### Phase 4: Directory Enumeration
- Enumerate `/static/`, `/assets/`, `/scripts/` directories
- Check `/api/` for available endpoints
- Probe `/commerce`, `/checkout`, `/account` routes
- Look for template-specific asset directories

### Phase 5: Known Patterns
- Apply Squarespace-specific discovery probes
- Check `/api/commerce/v1/cart` for e-commerce functionality
- Probe `/checkout` for checkout process
- Check `/products/`, `/category/` routes
- Look for Squarespace template identifiers

### Phase 6: API Analysis
- Analyze Commerce API (`/api/commerce/v1/`)
- Test Site API (`/api/site/v1/`) for site information
- Identify authentication requirements
- Document available endpoints and resources
- Check for payment processing endpoints

## Common Squarespace API Patterns

```http
# Commerce API examples
GET /api/commerce/v1/products
GET /api/commerce/v1/products/{id}
GET /api/commerce/v1/orders
POST /api/commerce/v1/cart/add

# Site API examples
GET /api/site/v1/info
GET /api/site/v1/pages
GET /api/site/v1/collections

# Product pages
GET /products/{product-name}
GET /category/{category-name}
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| HTTP Header | `X-Squarespace-Version: 7.1` | Definitive |
| Site API | `/api/site/v1/info` returns version | High |
| Meta Tag | Generator tag includes version | Medium |
| JS Global | `window.Squarespace.templateVersion` | High |
| Template Files | Version-specific asset patterns | Medium |

## E-commerce Specific Checklist
When Squarespace e-commerce is detected, probe:
- [ ] Product catalog functionality
- [ ] Shopping cart operations
- [ ] Checkout flow analysis
- [ ] Payment gateway integration
- [ ] Order management endpoints
- [ ] Customer account management
- [ ] Shipping method configurations
- [ ] Tax calculation settings
- [ ] Discount and promotion codes
- [ ] Product categories
- [ ] Inventory management
- [ ] Search functionality

## Framework-Specific Probes
Check these Squarespace-specific endpoints:
```
/
/api/commerce/v1/products
/api/commerce/v1/cart
/api/site/v1/info
/commerce
/checkout
/account
/static/
/static1.squarespace.com/
/products/
```

## Technology Stack Integration

### Common Squarespace Integrations
| Integration | Purpose | Detection Pattern |
|-------------|---------|--------------------|
| Squarespace Commerce | Online store | `/api/commerce/v1/` endpoints |
| Payment Processors | Payments | `/api/payment/v1/`, `/checkout` |
| Stripe | Payments | `/api/stripe/` endpoints |
| Custom CSS | Styling | `/assets/css/custom.css` |
| Custom JS | Functionality | `/assets/js/custom.js` |
| Analytics | Tracking | Google Analytics, Squarespace analytics |
| Marketing | Email marketing | MailChimp, Constant Contact scripts |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Confirm presence of Squarespace API endpoints
- Check for Squarespace meta generator tag
- Validate template and layout headers
- Cross-check with CDN patterns
- Test Commerce API functionality

## Integration with Beacon Skill
- Load this tech pack when Squarespace headers or meta tags are detected
- Focus discovery on Squarespace Commerce API
- Include Squarespace in e-commerce detection phases
- Document all Commerce API surfaces and endpoints
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
