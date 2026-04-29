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