# Joomla Framework Detection

This guide covers fingerprinting for Joomla CMS websites.

## Framework Summary
- **Name**: Joomla
- **Type**: Content Management System (CMS)
- **Language**: PHP
- **Database**: MySQL
- **Popularity**: 1.3% of all websites, 1.8% of CMS sites
- **Website**: [https://www.joomla.org](https://www.joomla.org)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| Meta Generator | `content="Joomla!"` | HTML source analysis |
| Admin Directory | `/administrator/` | Directory enumeration |
| Core JavaScript | `/media/system/js/core.js` | File enumeration |
| Option Parameter | `option=com_` | URL analysis |
| Component Structure | `/components/com_[name]/` | Directory enumeration |
| Cookie Pattern | `jos_[hash]` or session cookie | Cookie analysis |

### Technology Stack
Joomla is built on:
- PHP (server-side scripting)
- MySQL (database)
- MVC architecture
- Template engine
- Extensible component system

Common integrations:
- Template frameworks (Gantry, Helix)
- E-commerce extensions (VirtueMart, HikaShop, J2Store)
- SEO extensions
- Caching systems (Redis, Memcached)
- Analytics platforms
- Marketing tools
- Payment gateways

## API Surface Discovery
Joomla exposes these APIs:
- **Legacy component system**: `index.php?option=com_[component]`
- **Joomla 4+ REST API**: `/api/index.php/v1/`
- **Extension-specific APIs**: Component-specific endpoints
- **Template APIs**: Template parameter access

## Security Considerations
- Secure `/administrator/` with strong credentials
- Remove `/installation/` directory after setup
- Use `.htaccess` restrictions for sensitive directories
- Regularly update Joomla core and extensions
- Use security extensions like Admin Tools or RSFirewall
- Secure `/configuration.php` file permissions
- Use HTTPS for all pages
- Implement proper file permissions
- Protect against SQL injection and XSS

## Version Detection
- Check `/administrator/manifests/files/joomla.xml`
- Look at admin login page footer
- Analyze `/media/system/js/core.js`
- Check `/language/en-GB/en-GB.xml`
- Query `#__schemas` table in MySQL
- Look for template-specific version indicators

## Resources
- [Official Joomla Documentation](https://docs.joomla.org)
- [Joomla Developer Network](https://developer.joomla.org)
- [Joomla Extensions Directory](https://extensions.joomla.org)
- [Joomla GitHub Repository](https://github.com/joomla/joomla-cms)
- [Joomla Forum](https://forum.joomla.org)
- [Joomla API Reference](https://api.joomla.org)

## E-commerce Extensions
Common Joomla e-commerce extensions:
- **VirtueMart**: `/components/com_virtuemart/`
- **HikaShop**: `/components/com_hikashop/`
- **J2Store**: `/components/com_j2store/`
- **Eshop**: `/components/com_eshop/`
- **MijoShop**: `/components/com_mijoshop/`
- **RedSHOP**: `/components/com_redshop/`