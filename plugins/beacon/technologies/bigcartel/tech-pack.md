# Big Cartel Tech Pack

## Framework Identification
**Name**: Big Cartel
**Type**: Simple E-commerce Platform
**Hosting**: Cloud-based SaaS

## Fingerprinting Rules
```yaml
rules:
  - name: bigcartel-version-header
    description: Detect Big Cartel via version header
    pattern: "X-BigCartel-Version"
    type: header
    confidence: definitive
    
  - name: bigcartel-server-header
    description: Detect Big Cartel via server header
    pattern: "Server: Big Cartel"
    type: header
    confidence: high
    
  - name: bigcartel-generator-meta
    description: Detect Big Cartel via meta generator tag
    pattern: 'content="Big Cartel"'
    type: body
    confidence: definitive
    
  - name: bigcartel-js-file
    description: Detect Big Cartel via JavaScript file
    pattern: "/bigcartel\\.js"
    type: path
    confidence: high
    
  - name: bigcartel-js-globals
    description: Detect Big Cartel via JavaScript globals
    pattern: "window\\.BigCartel"
    type: js_global
    confidence: high
    
  - name: bigcartel-products-json
    description: Detect Big Cartel via products JSON endpoint
    pattern: "/products\\.json"
    type: path
    confidence: high
    
  - name: bigcartel-checkout-route
    description: Detect Big Cartel via checkout route
    pattern: "/checkout"
    type: path
    confidence: medium
    
  - name: bigcartel-products-route
    description: Detect Big Cartel via products route
    pattern: "/product/"
    type: path
    confidence: medium
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for `X-BigCartel-Version` and `Server: Big Cartel` headers
- Look for Big Cartel generator meta tag
- Search for `/bigcartel.js` file
- Analyze page for `window.BigCartel` global variable
- Check for `/products.json` endpoint

### Phase 4: Directory Enumeration
- Enumerate `/products` and `/images` directories
- Check `/assets/`, `/javascripts/`, `/stylesheets/` directories
- Probe `/category/` routes
- Look for theme-specific asset directories

### Phase 5: Known Patterns
- Apply Big Cartel-specific discovery probes
- Check `/cart` and `/checkout` routes
- Probe `/products.json` endpoint
- Look for product detail pages (`/product/[name]`)
- Check `/account` and `/contact` routes

### Phase 6: API Analysis
- Analyze `/products.json` endpoint
- Check `/cart` operations
- Document authentication requirements
- Identify available endpoints and data structures

## Common Big Cartel Patterns

```http
# Product listing
GET /products.json

# Product detail
GET /product/[product-name]

# Cart operations
GET /cart
POST /cart

# Checkout process
GET /checkout
POST /checkout
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| HTTP Header | `X-BigCartel-Version: 3.1.0` | Definitive |
| Server Header | `Server: Big Cartel` | High |
| JavaScript File | Version in `/bigcartel.js` | Medium |
| Meta Tag | Generator content includes version | Low |

## E-commerce Specific Checklist
When Big Cartel is detected, probe:
- [ ] Product catalog functionality
- [ ] Shopping cart operations
- [ ] Checkout process flow
- [ ] Category browsing
- [ ] Product search functionality
- [ ] Customer account management
- [ ] Order history and management
- [ ] Theme customization options
- [ ] Payment gateway integrations
- [ ] Shipping method configurations

## Framework-Specific Probes
Check these Big Cartel-specific endpoints:
```
/
/products.json
/bigcartel.js
/cart
/checkout
/products
/product/[product-name]
/account
/contact
```

## Technology Stack Integration

### Common Big Cartel Integrations
| Integration | Purpose | Detection Pattern |
|-------------|---------|--------------------|
| Custom Domain | Branding | Custom domain mapping |
| Payment Gateways | Payments | `/checkout` payment forms |
| Google Analytics | Tracking | `analytics.js` inclusion |
| Custom CSS | Styling | `/assets/css/custom.css` |
| Custom JS | Functionality | `/assets/js/custom.js` |
| MailChimp | Email marketing | MailChimp form embeds |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Confirm presence of Big Cartel-specific headers
- Check for `/products.json` functionality
- Validate e-commerce store behavior
- Cross-check with meta tag detection
- Test actual product/cart workflows

## Integration with Beacon Skill
- Load this tech pack when Big Cartel headers or meta tags are detected
- Run Big Cartel-specific e-commerce discovery probes
- Document available API surfaces and catalog functionality
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
