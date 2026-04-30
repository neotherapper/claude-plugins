# Wix E-commerce Tech Pack

## Framework Identification
**Name**: Wix
**Type**: Website Builder with E-commerce
**Hosting**: Cloud-based SaaS

## Fingerprinting Rules
```yaml
rules:
  - name: wix-request-header
    description: Detect Wix via request ID header
    pattern: "X-Wix-Request-Id"
    type: header
    confidence: high
    
  - name: wix-site-header
    description: Detect Wix via website ID header
    pattern: "X-Wix-Website"
    type: header
    confidence: high
    
  - name: wix-meta-generator
    description: Detect Wix via meta generator tag
    pattern: 'content="Wix\\.com Website Builder"'
    type: body
    confidence: definitive
    
  - name: wix-api-endpoints
    description: Detect Wix via API endpoints
    pattern: "_api/wix-(site|ecom|bookings)/v1/"
    type: path
    confidence: high
    
  - name: wix-js-globals
    description: Detect Wix via JavaScript globals
    pattern: "window\\.(Wix|__WIX_)"
    type: js_global
    confidence: high
    
  - name: wix-cdn-patterns
    description: Detect Wix via CDN patterns
    pattern: "static\\.parastorage\\.com"
    type: body
    confidence: high
    
  - name: wix-partial-components
    description: Detect Wix via partial components
    pattern: "/_partials/"
    type: path
    confidence: medium
    
  - name: wix-app-patterns
    description: Detect Wix via app patterns
    pattern: "/_apps/"
    type: path
    confidence: medium
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for `X-Wix-Request-Id` and `X-Wix-Website` headers
- Look for Wix meta generator tag
- Search for `/_api/wix-site/v1/site` API endpoint
- Analyze JavaScript for Wix global variables
- Check for Wix CDN patterns (`static.parastorage.com`)

### Phase 4: Directory Enumeration
- Enumerate `/_api/`, `/_partials/`, `/_apps/` directories
- Check `/assets/` and `/files/` directories
- Probe `/store`, `/blog`, `/account` routes
- Look for `/static.parastorage.com/` CDN files

### Phase 5: Known Patterns
- Apply Wix-specific discovery probes
- Check `/_api/wix-ecom/v1/cart` for e-commerce
- Probe `/_api/wix-bookings/v1/calendar` for bookings
- Check `/account` and `/search` routes
- Look for dynamic page routes (`/_pages/`)

### Phase 6: API Analysis
- Analyze Site API (`/_api/wix-site/v1/`)
- Check E-commerce API (`/_api/wix-ecom/v1/`) for store functionality
- Test Bookings API (`/_api/wix-bookings/v1/`) if available
- Identify authentication requirements
- Document available endpoints and resources

## Common Wix API Patterns

```http
# Site information
GET /_api/wix-site/v1/site

# Pages listing
GET /_api/wix-site/v1/pages

# E-commerce cart
GET /_api/wix-ecom/v1/cart
POST /_api/wix-ecom/v1/cart/items

# Product data
GET /_api/wix-ecom/v1/products
GET /_api/wix-ecom/v1/products/{product-id}

# Booking calendar
GET /_api/wix-bookings/v1/calendar
GET /_api/wix-bookings/v1/services

# Dynamic page content
GET /_pages/{page-id}
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| HTTP Header | `X-Wix-Render-Version: 2.1234` | High |
| JS Global | `__WIX_BUILD_IDENTIFIER__: "1.2.3"` | High |
| API Response | Version in `/_api/wix-site/v1/site` | Medium |
| Meta Tag | Generator tag includes version | Low |

## E-commerce Specific Checklist
When Wix e-commerce is detected, probe:
- [ ] Shopping cart functionality
- [ ] Product listing and details
- [ ] Checkout process flow
- [ ] Payment gateway integrations
- [ ] Customer account management
- [ ] Order history and management
- [ ] Inventory management
- [ ] Discount and coupon codes
- [ ] Shipping method configurations
- [ ] Tax calculation settings
- [ ] Product categories
- [ ] Search functionality

## Framework-Specific Probes
Check these Wix-specific endpoints:
```
/_api/wix-site/v1/site
/_api/wix-ecom/v1/cart
/_api/wix-ecom/v1/products
/_api/wix-ecom/v1/categories
/_api/wix-bookings/v1/calendar
/_pages/[page-id]
/_partials/
/static.parastorage.com/
```

## Technology Stack Integration

### Common Wix Integrations
| Integration | Purpose | Detection Pattern |
|-------------|---------|--------------------|
| Wix E-commerce | Online store | `/_api/wix-ecom/v1/` endpoints |
| Wix Bookings | Appointment scheduling | `/_api/wix-bookings/v1/` endpoints |
| Wix Blog | Blog functionality | `/_api/wix-blog/v1/` endpoints |
| Wix Members | User accounts | `/account`, `/login` routes |
| Payment Gateways | Payments | `/checkout`, payment API calls |
| Marketing Tools | Email marketing | Third-party script tags |
| Analytics | Tracking | Google Analytics, etc. |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Confirm presence of Wix API endpoints
- Check for Wix meta generator tag
- Validate dynamic page behavior
- Cross-check with CDN patterns
- Test site editing functionality

## Integration with Beacon Skill
- Load this tech pack when Wix headers, meta tags, or API patterns are detected
- Focus discovery on Wix-specific APIs
- Include Wix in e-commerce detection phases when applicable
- Document available API surfaces and endpoints
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
