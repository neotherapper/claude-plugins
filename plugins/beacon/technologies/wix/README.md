# Wix Framework Detection

This guide covers fingerprinting for Wix websites and e-commerce applications.

## Framework Summary
- **Name**: Wix
- **Type**: Website builder with e-commerce capabilities
- **Hosting**: Cloud-based (SaaS)
- **Popularity**: 200M+ users, #1 website builder
- **Website**: [https://www.wix.com](https://www.wix.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| HTTP Headers | `X-Wix-Request-Id`, `X-Wix-Website` | HTTP response headers |
| Meta Tags | `content="Wix.com Website Builder"` | HTML source analysis |
| JavaScript Globals | `window.Wix`, `window.__WIX_BUILD_IDENTIFIER__` | Browser console analysis |
| API Endpoints | `/_api/wix-site/v1/site` | API probing |
| Static Files | `/static.parastorage.com/`, `/_partials/` | Directory enumeration |

### Technology Stack
Wix provides:
- Drag-and-drop website builder
- E-commerce functionality
- Booking and scheduling
- Blogging and CMS
- Payment processing
- SEO tools
- Custom domain hosting

Common integrations:
- Wix APIs (Site, E-commerce, Bookings)
- Wix Apps Marketplace
- Payment gateways
- Marketing tools
- Analytics platforms
- Custom React components

## API Surface Discovery
Wix exposes multiple APIs:
- **Site API**: Site information and management (`/_api/wix-site/v1/`)
- **E-commerce API**: Store functionality (`/_api/wix-ecom/v1/`)
- **Bookings API**: Appointment scheduling (`/_api/wix-bookings/v1/`)
- **Members API**: User management
- **Stores API**: Product management

## Security Considerations
- Secure API endpoints with proper authentication
- Use Wix's built-in security features
- Regularly update apps and integrations
- Secure payment processing with PCI compliance
- Implement proper access control for admin areas
- Protect against XSS and CSRF vulnerabilities
- Use HTTPS for all pages

## Version Detection
- Check `X-Wix-Render-Version` HTTP header
- Look for `window.__WIX_BUILD_IDENTIFIER__` global
- Query `/_api/wix-site/v1/site` endpoint
- Analyze Wix meta generator tag
- Check `X-Wix-Cache-Hit` header patterns

## Resources
- [Official Wix Developer Documentation](https://dev.wix.com)
- [Wix API Reference](https://dev.wix.com/api/rest)
- [Wix Velo Reference (JS API)](https://www.wix.com/velo/reference)
- [Wix CLI Documentation](https://support.wix.com/en/article/wix-cli-installation)
- [Wix App Marketplace](https://www.wix.com/app-market)
- [Wix Support Center](https://support.wix.com)