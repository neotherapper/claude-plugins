# Squarespace Framework Detection

This guide covers fingerprinting for Squarespace websites and e-commerce applications.

## Framework Summary
- **Name**: Squarespace
- **Type**: Website builder with e-commerce
- **Hosting**: Cloud-based SaaS
- **Popularity**: 4M+ sites, popular among creatives and small businesses
- **Website**: [https://www.squarespace.com](https://www.squarespace.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| HTTP Headers | `X-Squarespace-Version`, `X-Squarespace-Template` | HTTP response headers |
| Meta Generator | `content="Squarespace"` | HTML source analysis |
| JavaScript Globals | `window.Y.Squarespace`, `window.Squarespace` | Browser console analysis |
| API Endpoints | `/api/commerce/v1/products` | API probing |
| Static Files | `/static/`, `static1.squarespace.com` | Directory enumeration |

### Technology Stack
Squarespace provides:
- Drag-and-drop website builder
- E-commerce and commerce tools
- Blogging and CMS functionality
- Custom domain hosting
- SEO tools and analytics
- Built-in security and compliance

Common integrations:
- Commerce APIs (`/api/commerce/v1/`)
- Payment processing
- Custom JavaScript and CSS
- Marketing tools
- Analytics platforms
- Custom domains

## API Surface Discovery
Squarespace exposes multiple APIs:
- **Commerce API**: Online store functionality (`/api/commerce/v1/`)
- **Site API**: Site management and information (`/api/site/v1/`)
- **Payments API**: Payment processing (`/api/payment/v1/`)
- **Custom integrations**: Via JavaScript and webhooks

## Security Considerations
- Secure API endpoints with proper authentication
- Use Squarespace's built-in security features
- Regularly update payment gateway integrations
- Implement proper access control for sensitive pages
- Secure checkout process with PCI compliance
- Protect against XSS and CSRF vulnerabilities
- Use HTTPS for all pages

## Version Detection
- Check `X-Squarespace-Version` HTTP header
- Query `/api/site/v1/info` endpoint
- Look for Squarespace meta generator tag updates
- Analyze JavaScript globals for version information
- Check template files for version references

## Resources
- [Official Squarespace Developer Documentation](https://developers.squarespace.com)
- [Squarespace API Reference](https://developers.squarespace.com/commerce-apis)
- [Squarespace Custom JavaScript Guide](https://support.squarespace.com/hc/en-us/articles/205815908)
- [Squarespace Commerce APIs](https://developers.squarespace.com/commerce-apis)
- [Squarespace Template Reference](https://developers.squarespace.com/template-guide)
- [Squarespace Support Center](https://support.squarespace.com)