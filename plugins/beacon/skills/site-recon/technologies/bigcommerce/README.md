# BigCommerce Framework Detection

This guide covers fingerprinting for BigCommerce e-commerce applications.

## Framework Summary
- **Name**: BigCommerce
- **Type**: Cloud-based e-commerce platform
- **Hosting**: SaaS (fully hosted)
- **Popularity**: #3 e-commerce platform, 100K+ stores
- **Website**: [https://www.bigcommerce.com](https://www.bigcommerce.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| HTTP Headers | `X-Bc-Api-Version`, `X-Bc-Store-Version` | HTTP response headers |
| Static Files | `/bc-static/`, `/product-images/` | Directory enumeration |
| Meta Generator | `content="BigCommerce"` | HTML source analysis |
| API Endpoints | `/api/storefront/cart` | API probing |
| JavaScript Globals | `window.bigcommerce`, `window.store_hash` | Browser console analysis |

### Technology Stack
BigCommerce is a SaaS platform providing:
- Storefront hosting
- Product management
- Checkout processing
- Payment integration
- Multi-channel selling
- SEO and marketing tools

Common integrations:
- Stencil theme engine
- REST API and GraphQL
- Payment gateways (PayPal, Stripe, etc.)
- Shipping providers
- Tax calculation services
- ERP systems
- POS systems

## API Surface Discovery
BigCommerce exposes multiple APIs:

- **Storefront API**: Public-facing API for store interactions (`/api/storefront/`)
- **REST API**: Back-office management API (`/api/v2/`)
- **GraphQL**: Modern query API (`/graphql`)
- **Checkout SDK**: Embedded checkout integration

## Security Considerations
- Secure Storefront API with proper authentication
- Restrict REST API access with IP whitelisting
- Use OAuth 2.0 for API authentication
- Regularly rotate API tokens
- Secure checkout process with PCI compliance
- Disable unused API endpoints
- Implement proper access control for store admin

## Version Detection
- Check `X-Bc-Api-Version` and `X-Bc-Store-Version` headers
- Query `/api/v2/store` endpoint
- Look for `stencil-version` meta tag
- Check JavaScript globals for version information
- Analyze theme files for version references

## Resources
- [Official BigCommerce Documentation](https://developer.bigcommerce.com)
- [BigCommerce Storefront API Reference](https://developer.bigcommerce.com/api-docs/storefront)
- [BigCommerce REST API Reference](https://developer.bigcommerce.com/api-reference)
- [BigCommerce GraphQL Reference](https://developer.bigcommerce.com/api-reference/storefront/graphql/graphql)
- [BigCommerce Developer Portal](https://developer.bigcommerce.com)
- [BigCommerce Community Forum](https://support.bigcommerce.com)