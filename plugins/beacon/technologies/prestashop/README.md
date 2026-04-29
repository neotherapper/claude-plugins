# PrestaShop Framework Detection

This guide covers fingerprinting for PrestaShop e-commerce applications.

## Framework Summary
- **Name**: PrestaShop
- **Type**: E-commerce platform
- **Language**: PHP
- **Popularity**: One of the top 5 e-commerce platforms globally
- **Website**: [https://www.prestashop.com](https://www.prestashop.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| Meta Generator | `content="PrestaShop"` | HTML source analysis |
| Static Files | `/themes/default-bootstrap/` | Directory enumeration |
| Admin Directory | `/admin[random]/` | Directory brute-forcing |
| API Routes | `/api/products` | API probing |
| HTTP Headers | `X-Generator: PrestaShop` | HTTP header analysis |
| Cookie Pattern | `PrestaShop-[hash]` | Cookie analysis |

### Technology Stack
PrestaShop is built on:
- PHP (backend logic)
- MySQL (database)
- Smarty (templating engine)
- jQuery (frontend JavaScript)
- REST API (modern versions)

Common integrations:
- Payment gateways (Stripe, PayPal, local providers)
- Shipping providers (FedEx, UPS, etc.)
- Tax calculation services
- Analytics platforms
- Marketing tools

## API Surface Discovery
PrestaShop exposes multiple API surfaces:
- REST API at `/api/` (modern versions)
- Legacy front controller endpoints
- Module-specific endpoints
- Customer account endpoints
- Checkout process endpoints

## Security Considerations
- Secure admin interface with strong passwords
- Restrict access to admin directory
- Protect configuration files
- Regularly update PrestaShop core and modules
- Use HTTPS for all pages
- Secure payment gateway integrations
- Disable directory listing
- Hide version information
- Implement IP restrictions for admin access

## Version Detection
- Check `/config/settings.inc.php` for `_PS_VERSION_` constant
- Look for version information in admin footer
- Analyze specific module versions
- Version-specific file structures and paths
- Pattern differences in template files

## Resources
- [Official PrestaShop Documentation](https://doc.prestashop.com)
- [PrestaShop Developer Guide](https://devdocs.prestashop.com)
- [PrestaShop GitHub](https://github.com/PrestaShop)
- [PrestaShop Addons Marketplace](https://addons.prestashop.com)
- [PrestaShop API Reference](https://devdocs.prestashop.com/1.7/webservice)