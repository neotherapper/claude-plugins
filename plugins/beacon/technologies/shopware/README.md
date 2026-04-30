# Shopware Framework Detection

This guide covers fingerprinting and analysis for Shopware e-commerce applications.

## Framework Summary
- **Name**: Shopware
- **Type**: E-commerce platform
- **Language**: PHP
- **Base Framework**: Symfony
- **Popularity**: Market leader in DACH region (Germany, Austria, Switzerland)
- **Website**: [https://www.shopware.com](https://www.shopware.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| HTTP Header | `sw-version` | HTTP response headers |
| Cookies | `sw-context-token`, `sw-currency`, `sw-language` | Cookie analysis |
| API Endpoints | `/store-api/context` | API probing |
| Meta Generator | `content="Shopware"` | HTML source analysis |
| JavaScript Globals | `window.__sw`, `window.sw` | Browser console analysis |
| File Patterns | `/theme/[hash]/js/all.js` | Directory enumeration |

### Technology Stack
Shopware is built on Symfony and integrates with:
- Doctrine ORM for database
- Twig template engine
- Vue.js for storefront JavaScript
- Webpack for asset compilation
- Elasticsearch for product search
- MySQL for data storage

Common integrations:
- Payment gateways (PayPal, Stripe, Mollie)
- Shipping providers
- Tax calculation services
- ERP systems
- Marketplace extensions

## API Surface Discovery
Shopware exposes multiple API surfaces:
- **Store API**: Public-facing API for storefront interactions
- **Admin API**: Back-office API for management
- **Sync API**: Bulk operations API
- **Plugin APIs**: Extension-specific endpoints

Store API paths:
- `/store-api/product`
- `/store-api/product-listing`
- `/store-api/search`
- `/store-api/search-suggest`
- `/store-api/cart`

Admin API paths:
- `/api/product`
- `/api/category`
- `/api/order`
- `/api/_info/version`

## Security Considerations
- Restrict admin interface access by IP
- Protect `/api/_info/openapi3.json` endpoint
- Use strong authentication for Admin API
- Regularly update Shopware core and plugins
- Secure payment processing
- Use HTTPS for all API communications
- Disable Symfony debug toolbar in production
- Secure media file uploads
- Implement proper access control
- Monitor for exposed access keys

## Version Detection
- Check `sw-version` HTTP header
- Query `/store-api/info` endpoint
- Check `/api/_info/version` endpoint
- Look for version in meta generator tag
- Analyze `/api/_info/config` response
- Check `/composer.lock` for shopware/core version
- Look for version-specific file patterns

## Resources
- [Official Shopware Documentation](https://docs.shopware.com)
- [Shopware Store API Reference](https://shopware.stoplight.io)
- [Shopware Admin API Documentation](https://shopware.github.io/admin-api-docs)
- [Shopware Developer Guide](https://developer.shopware.com)
- [Shopware GitHub](https://github.com/shopware/shopware)
- [Shopware Community Forum](https://forum.shopware.com)