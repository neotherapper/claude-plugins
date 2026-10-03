# Sylius Framework Detection

This guide covers fingerprinting for Sylius e-commerce applications.

## Framework Summary
- **Name**: Sylius
- **Type**: E-commerce framework
- **Language**: PHP
- **Framework**: Symfony
- **Website**: [https://sylius.com](https://sylius.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| Admin Route | `/admin/` | Directory enumeration |
| Static Files | `/bundles/` | Directory enumeration |
| Meta Generator | `content="Sylius"` | HTML source analysis |
| API Routes | `/api/products` | API probing |
| HTTP Headers | `X-Generator: Sylius` | HTTP header analysis |

### Technology Stack
Sylius is built on Symfony and commonly integrates with:
- Doctrine ORM for database
- Twig templating engine
- API Platform for modern API
- Webpack/Vite for asset management
- Elasticsearch for product search
- Payment gateways (Stripe, PayPal, PayU)
- Redis for caching

## API Surface Discovery
Sylius provides multiple API surfaces:
- REST API at `/api/`
- API Platform at `/api/v2/`
- GraphQL at `/api/v2/graphql`
- Customer storefront endpoints (`/shop/`)
- Admin REST API (`/admin/api/`)

## Security Considerations
- Secure admin interface with strong authentication
- Protect API endpoints with appropriate permissions
- Disable debug mode in production
- Regularly update dependencies
- Secure payment gateway integrations
- Implement proper access control
- Secure sensitive configuration files

## Version Detection
- Check `composer.json` or `composer.lock` (if exposed)
- Look for version information in admin footer
- Analyze API responses for version headers
- Version-specific code patterns
- Frontend asset versions

## Resources
- [Official Sylius Documentation](https://docs.sylius.com)
- [Sylius GitHub Repository](https://github.com/Sylius/Sylius)
- [Sylius Demo](https://demo.sylius.com)
- [API Reference](https://api.sylius.com)