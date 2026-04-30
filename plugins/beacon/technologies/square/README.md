# Square Online Framework Detection

This guide covers fingerprinting for Square Online websites and e-commerce stores.

## Framework Summary
- **Name**: Square Online
- **Type**: E-commerce and website platform
- **Formerly**: Weebly
- **Integration**: Square payments and POS
- **Popularity**: Growing platform for small businesses and restaurants
- **Website**: [https://squareup.com/online-store](https://squareup.com/online-store)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| HTTP Headers | `X-Square-Store-Id`, `X-Square-Site-Id` | HTTP response headers |
| Meta Generator | `content="Square Online"` | HTML source analysis |
| API Endpoints | `/api/store/v1/products` | API probing |
| JavaScript Globals | `window.SQUARE`, `window.WEEBLY` | Browser console analysis |
| Static Files | `/static/weebly/` | File enumeration |
| Square JS | `square.js`, `web.squarecdn.com` | JavaScript analysis |

### Technology Stack
Square Online integrates:
- Website building tools
- E-commerce functionality
- Square payment processing
- Inventory management
- Order processing
- Customer accounts
- Marketing tools
- Restaurant-specific features

Common integrations:
- Square POS system
- Payment gateways
- Email marketing tools
- Custom domains
- CDNs for asset delivery
- Analytics platforms

## API Surface Discovery
Square Online exposes multiple APIs:
- **Site API**: Site information and management (`/api/site/v1/`)
- **Store API**: E-commerce functionality (`/api/store/v1/`)
- **Payment API**: Square payment processing
- **Legacy Weebly APIs**: Site building functionality

## Security Considerations
- Secure payment processing with PCI compliance
- Protect sensitive API endpoints
- Use HTTPS for all pages
- Secure customer data properly
- Regularly update integration scripts
- Protect against SQL injection and XSS
- Implement proper access control
- Secure file uploads

## Version Detection
- Check `X-Square-Version` HTTP header
- Query `/api/site/v1/info` endpoint
- Look for version in meta tags
- Analyze Square JavaScript files
- Review integration script versions
- Check admin dashboard for version info

## Resources
- [Square Online Documentation](https://developer.squareup.com/docs/online-store)
- [Square Developer Platform](https://developer.squareup.com)
- [Square API Reference](https://developer.squareup.com/reference)
- [Square Online Help Center](https://squareup.com/help/us/en)
- [Weebly Developer Documentation](https://developers.weebly.com)
- [Square Community Forum](https://community.squareup.com)