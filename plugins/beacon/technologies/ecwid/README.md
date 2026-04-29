# Ecwid Framework Detection

This guide covers fingerprinting for Ecwid e-commerce applications.

## Framework Summary
- **Name**: Ecwid
- **Type**: Cloud-based e-commerce platform
- **Integration**: Embeddable store widget
- **Popularity**: 100K+ stores, popular integration option
- **Website**: [https://www.ecwid.com](https://www.ecwid.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| Ecwid Header | `X-Ecwid-Storefront-Id` | HTTP response headers |
| Integration Script | `app.ecwid.com/script.js` | JavaScript analysis |
| HTML Container | `<div id="ecwid-store-[store-id]">` | HTML source analysis |
| API Endpoints | `/api/v3/[store-id]/products` | API probing |
| JavaScript Global | `window.Ecwid` | Browser console analysis |

### Technology Stack
Ecwid provides:
- Embeddable store widgets
- Cloud-based inventory management
- Multi-channel selling
- Payment processing
- Order management
- SEO tools
- Mobile-responsive design

Common integrations:
- WordPress plugins
- Wix store integrations
- Squarespace extensions
- Facebook and Instagram stores
- Amazon and eBay marketplaces
- Custom website integrations

## API Surface Discovery
Ecwid exposes multiple APIs:
- **Storefront API**: Product, category, and order management (`/api/v3/`)
- **Widget API**: Store embedding and initialization
- **Ecwid Payments API**: Payment processing
- **Mobile API**: iOS and Android SDKs

## Security Considerations
- Secure API endpoints with proper storefront IDs
- Use HTTPS for all widget integrations
- Restrict access to management endpoints
- Regularly update integration scripts
- Secure payment processing with PCI compliance
- Protect storefront IDs from exposure
- Use secure token-based authentication for API access

## Version Detection
- Check `X-Ecwid-Api-Version` HTTP header
- Analyze Ecwid JavaScript file versions
- Query `/api/v3/[store-id]/profile` endpoint
- Check integration script patterns for version clues
- Analyze Ecwid dashboard for version information

## Resources
- [Official Ecwid API Documentation](https://developers.ecwid.com/api-documentation)
- [Ecwid Integration Guide](https://developers.ecwid.com/integration-guides)
- [Ecwid WordPress Plugin](https://wordpress.org/plugins/ecwid-shopping-cart/)
- [Ecwid API Reference](https://api-docs.ecwid.com)
- [Ecwid Developer Center](https://developers.ecwid.com/)
- [Ecwid Help Center](https://support.ecwid.com)