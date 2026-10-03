# Big Cartel Framework Detection

This guide covers fingerprinting for Big Cartel e-commerce stores.

## Framework Summary
- **Name**: Big Cartel
- **Type**: Simple e-commerce platform
- **Target Audience**: Artists, musicians, small creators
- **Popularity**: 100K+ stores
- **Website**: [https://www.bigcartel.com](https://www.bigcartel.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| HTTP Header | `X-BigCartel-Version` | HTTP response headers |
| Meta Generator | `content="Big Cartel"` | HTML source analysis |
| JavaScript File | `/bigcartel.js` | File enumeration |
| JavaScript Global | `window.BigCartel` | Browser console analysis |
| Product API | `/products.json` | API probing |
| Checkout Route | `/checkout` | Route analysis |

### Technology Stack
Big Cartel provides:
- Simple product management
- Shopping cart and checkout
- Customizable store themes
- Order management
- Inventory tracking
- Payment processing
- Email marketing integration

Common integrations:
- Custom domains
- Payment gateways (Stripe, PayPal)
- Google Analytics
- MailChimp
- Custom CSS/JavaScript
- Social media selling

## API Surface Discovery
Big Cartel exposes:
- Product API (`/products.json`)
- Cart and checkout routes
- Theme customization APIs

## Security Considerations
- Secure checkout process with HTTPS
- Use reputable payment gateway integrations
- Regularly update store settings
- Secure admin interface with strong credentials
- Protect customer data according to regulations
- Monitor for suspicious activity

## Version Detection
- Check `X-BigCartel-Version` HTTP header
- Analyze `/bigcartel.js` file version
- Look for version hints in meta tags
- Check theme and template patterns
- Review admin dashboard for version information

## Resources
- [Official Big Cartel Documentation](https://help.bigcartel.com)
- [Big Cartel Theme Development](https://help.bigcartel.com/developers/themes)
- [Big Cartel Developer Guide](https://help.bigcartel.com/developers)
- [Big Cartel API Reference](https://help.bigcartel.com/developers/api)
- [Big Cartel Support Center](https://help.bigcartel.com)
- [Big Cartel Community Forum](https://community.bigcartel.com)