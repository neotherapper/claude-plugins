# OpenCart Framework Detection

This guide covers fingerprinting for OpenCart e-commerce applications.

## Framework Summary
- **Name**: OpenCart
- **Type**: E-commerce platform
- **Language**: PHP
- **Popularity**: Widely used open-source e-commerce solution
- **Website**: [https://www.opencart.com](https://www.opencart.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| Static Files | `/catalog/view/theme/default/stylesheet/stylesheet.css` | File enumeration |
| Route Pattern | `index.php?route=product/product` | URL analysis |
| Admin Interface | `/admin/index.php` | Directory enumeration |
| Cookie Pattern | `OCSESSID` cookie | Cookie analysis |
| JavaScript Files | `/admin/view/javascript/common.js` | File analysis |

### Technology Stack
OpenCart is built on:
- PHP (backend logic)
- MySQL (database)
- Twig template engine (versions 3.0+)
- jQuery (frontend JavaScript)
- Bootstrap (frontend CSS framework)

Common integrations:
- Payment gateways (PayPal, Stripe, etc.)
- Shipping methods
- Tax calculation services
- Themes and templates
- Marketplace extensions

## API Surface Discovery
OpenCart exposes:
- Frontend catalog routes (`index.php?route=product/*`)
- Customer account endpoints (`index.php?route=account/*`)
- Checkout process routes (`index.php?route=checkout/*`)
- Admin REST API (in some versions/extensions)
- Payment gateway integration points

## Security Considerations
- Secure `config.php` and `admin/config.php` files
- Restrict admin directory access
- Use strong admin credentials
- Regularly update OpenCart core
- Secure payment processing
- Disable directory listing
- Protect against SQL injection
- Implement CSRF protection
- Use HTTPS for all pages
- Secure file uploads

## Version Detection
- Check `/admin/view/javascript/common.js` for version info
- Look at admin login page footer
- Analyze version-specific file patterns
- Check `system/startup.php` for version markers
- Database - `oc_setting` table contains version info

## Resources
- [Official OpenCart Documentation](https://docs.opencart.com)
- [OpenCart Developer Guide](https://www.opencart.com/index.php?route=developer)
- [OpenCart GitHub](https://github.com/opencart/opencart)
- [OpenCart Marketplace](https://www.opencart.com/index.php?route=marketplace/extension)
- [OpenCart Forum](https://forum.opencart.com)