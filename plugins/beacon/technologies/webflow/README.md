# Webflow Framework Detection

This guide covers fingerprinting for Webflow websites.

## Framework Summary
- **Name**: Webflow
- **Type**: Visual Web Design Platform
- **Hosting**: Cloud-based SaaS
- **Popularity**: 0.9% of all websites, 1.2% of CMS sites
- **Website**: [https://webflow.com](https://webflow.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| HTTP Headers | `X-Webflow-Site`, `X-Wf-Site` | HTTP response headers |
| Meta Generator | `content="Webflow"` | HTML source analysis |
| JavaScript File | `/js/webflow.js` | File enumeration |
| JavaScript Global | `window.Webflow` | Browser console analysis |
| API Endpoints | `/api/v1/sites/[site-id]` | API probing |
| Static Files | `/css/webflow.css` | File enumeration |
| Collection Routes | `/collections/[name]` | Route analysis |

### Technology Stack
Webflow combines:
- Visual design tools (drag-and-drop editor)
- Content management system (CMS)
- Hosting infrastructure
- Exportable static sites
- Webflow Designer (professional tool)
- E-commerce capabilities (Webflow Ecommerce)

Common integrations:
- CMS collections for dynamic content
- E-commerce product catalogs
- Form submission handling
- Memberstack for membership sites
- Zapier/Zoho for automation
- Analytics platforms (Google Analytics)
- Payment processors (Stripe, PayPal)
- Custom code embeds

## API Surface Discovery
Webflow exposes multiple APIs:
- **CMS API**: Content management endpoints (`/api/v1/sites/[site-id]/collections`)
- **Form API**: Form submission handling (`/api/v1/form/[form-id]`)
- **Site API**: Site management (`/api/v1/sites/[site-id]`)
- **Designer API**: Integration with Webflow Designer
- **Collection Pages**: Dynamic content routes (`/collections/`)

## Security Considerations
- Secure CMS API endpoints with proper authentication
- Use HTTPS for all pages and API requests
- Protect API keys and site IDs
- Secure form submissions against spam
- Implement proper access control for collections
- Use Webflow's built-in security features
- Secure payment processing with PCI compliance
- Regularly update API keys and credentials

## Version Detection
- Check `webflow.js` file version
- Look for `window.Webflow.version` global variable
- Query `/api/v1/sites/[site-id]` endpoint
- Analyze error pages for version hints
- Check Webflow dashboard for version information
- Look for version-specific features in HTML/classes

## Resources
- [Official Webflow Developer Documentation](https://developers.webflow.com)
- [Webflow API Reference](https://developers.webflow.com/api)
- [Webflow CMS API Documentation](https://developers.webflow.com/cms-api)
- [Webflow Designer API](https://developers.webflow.com/designer-api)
- [Webflow University](https://university.webflow.com)
- [Webflow Community Forum](https://forum.webflow.com)
- [Webflow E-commerce Guide](https://webflow.com/ecommerce)

## E-commerce Indicators
Webflow e-commerce sites show:
- `/products/` routes
- `/checkout` endpoint
- `/cart` functionality
- Payment processor integration (Stripe, PayPal)
- Product collection pages (`/collections/products`)
- Shopping cart functionality
- Order management endpoints