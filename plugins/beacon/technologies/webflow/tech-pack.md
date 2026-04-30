# Webflow Tech Pack

## Framework Identification
**Name**: Webflow
**Type**: Visual Website Builder
**Hosting**: Cloud-based SaaS

## Fingerprinting Rules
```yaml
rules:
  - name: webflow-site-header
    description: Detect Webflow via site ID header
    pattern: "X-Webflow-Site|X-Wf-Site"
    type: header
    confidence: definitive
    
  - name: webflow-core-js
    description: Detect Webflow via core JavaScript file
    pattern: "/js/webflow\\.js$"
    type: path
    confidence: definitive
    
  - name: webflow-generator-meta
    description: Detect Webflow via meta generator tag
    pattern: 'content="Webflow"'
    type: body
    confidence: definitive
    
  - name: webflow-js-globals
    description: Detect Webflow via JavaScript globals
    pattern: "window\\.Webflow"
    type: js_global
    confidence: high
    
  - name: webflow-api-endpoints
    description: Detect Webflow via API endpoints
    pattern: "/api/v1/sites/[a-zA-Z0-9]+"
    type: path
    confidence: high
    
  - name: webflow-collection-routes
    description: Detect Webflow via CMS collection routes
    pattern: "/collections/"
    type: path
    confidence: medium
    
  - name: webflow-core-css
    description: Detect Webflow via core CSS file
    pattern: "/css/webflow\\.css$"
    type: path
    confidence: high
    
  - name: webflow-image-patterns
    description: Detect Webflow via image asset patterns
    pattern: "\\.[a-f0-9]{20}\\.jpg$"
    type: path
    confidence: medium
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for `X-Webflow-Site` or `X-Wf-Site` headers
- Look for `/js/webflow.js` file
- Search for Webflow generator meta tag
- Analyze page for `window.Webflow` global variable
- Check for Webflow-specific CSS files
- Look for API endpoints (`/api/v1/sites`)

### Phase 4: Directory Enumeration
- Enumerate `/js/`, `/css/`, `/images/` directories
- Check for `/collections/` routes
- Look for Webflow CMS indicators
- Probe for e-commerce routes (`/products/`, `/cart/`)
- Check for form API endpoints

### Phase 5: Known Patterns
- Apply Webflow-specific discovery probes
- Check CMS collection routes (`/collections/`)
- Probe Webflow API endpoints
- Look for e-commerce functionality indicators
- Check for form submission endpoints
- Look for Webflow Designer-generated classes

### Phase 6: API Analysis
- Test Webflow CMS API (`/api/v1/sites/[site-id]/collections`)
- Check form submission API (`/api/v1/form/[form-id]`)
- Identify site management API (`/api/v1/sites/[site-id]`)
- Document available endpoints and authentication requirements
- Check for collection item routes

## Common Webflow Patterns

```http
# Site information
GET /api/v1/sites/[site-id]
Headers: Authorization: Bearer [api-key]

# Collection listing
GET /api/v1/sites/[site-id]/collections

# Collection items
GET /api/v1/sites/[site-id]/collections/[collection-id]/items

# Form submission
POST /api/v1/form/[form-id]/submission

# Collection page
GET /collections/[collection-name]/[item-slug]
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| JavaScript Global | `window.Webflow.version` | High |
| Core JS File | Version in `/js/webflow.js` | Medium |
| API Response | Version in `/api/v1/sites/[site-id]` | High |
| Meta Tag | Generator tag content | Low |

## Webflow-Specific Checklist
When Webflow is detected, probe:
- [ ] CMS collection functionality
- [ ] Form submission endpoints
- [ ] E-commerce capabilities
- [ ] Custom code integration
- [ ] Hosted asset patterns
- [ ] API authentication methods
- [ ] Collection content types
- [ ] Designer-generated classes
- [ ] Static page generation
- [ ] API rate limiting

## Framework-Specific Probes
Check these Webflow-specific endpoints:
```
/js/webflow.js
/css/webflow.css
/api/v1/sites/[site-id]
/collections/
/products/
/cart/
/checkout/
```

## Technology Stack Integration

### Common Webflow Integrations
| Integration | Purpose | Detection Pattern |
|-------------|---------|--------------------|
| Webflow CMS | Content | `/collections/` routes |
| Webflow Ecommerce | Online store | `/products/`, `/cart/` |
| Memberstack | Membership | `memberstack.js`, user flows |
| Zapier/Zoho | Automation | Integration scripts |
| Google Analytics | Tracking | `analytics.js` |
| Stripe/PayPal | Payments | Payment scripts |
| Lottie | Animations | `lottie.js`, animation assets |
| Typeform | Forms | `typeform.js`, embedded forms |
| Hotjar | Analytics | `hotjar.js` |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Confirm presence of Webflow core files
- Validate Webflow API functionality
- Check for CMS collection routes
- Cross-check Webflow header patterns
- Test actual form submission functionality

## Integration with Beacon Skill
- Load this tech pack when Webflow headers or core files detected
- Run Webflow API discovery
- Probe CMS collection routes
- Check for form submission endpoints
- Document all detected API surfaces
- Include Webflow in CMS/e-commerce analysis