# Shopify Framework Fingerprinting Guide (Part 3)

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/cdn/shopifycloud/
/assets/
/collections/
/products/
```

### 2. Common File Discovery
Look for these files:
```
/cdn/shopifycloud/shopify.js
/assets/theme.js
/assets/theme.css
```

### 3. Framework-Specific Endpoints
Check these Shopify-specific endpoints:
```
/cart.js
/api/2023-07/graphql.json
/checkout
/collections/
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self' *.shopify.com; frame-ancestors 'none'
```

### Vulnerable Patterns
- Exposed admin API credentials
- Unsecured app proxy endpoints
- Missing admin area protection
- Unsecured checkout customizations
- Exposed storefront API tokens
- Unprotected theme editor
- Missing content security policies
- Unsecured Webhook endpoints
- Payment information leaks

## Technology Stack Integration

### Common Shopify Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| Liquid | Templating | `.liquid` theme files |
| React | Frontend | Shopify Hydrogen framework |
| GraphQL | API | Storefront API |
| CDN | Asset delivery | `cdn.shopify.com` domains |
| Payment Gateways | Payments | Payment processing endpoints |
| Shipping APIs | Shipping | Shipping calculation endpoints |
| Analytics | Tracking | Google Analytics, Shopify analytics |

## Example Fingerprinting Commands

```bash
# Check Shopify headers
curl -I https://example.com

# Check Shopify JavaScript
curl -I https://example.com/cdn/shopifycloud/shopify.js

# Check Shopify cart API
curl -I https://example.com/cart.js

# Check for Shopify meta tags
curl https://example.com | grep -i "shopify"
```

## False Positives
- Sites using Shopify Buy Button
- Custom storefronts using Hydrogen/Remix
- Sites using Shopify CDN but not Shopify platform
- WordPress sites with Shopify plugins
- Other e-commerce platforms using similar CDNs

## Fingerprinting Tooling
- HTTP header analysis for Shopify-specific headers
- JavaScript global detection
- Theme asset pattern recognition
- API endpoint discovery
- Route pattern analysis
- CDN pattern detection

## Changelog
- 2026-04-30: Initial guide creation
- Future: Add version-specific fingerprinting patterns