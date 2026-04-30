# Drupal Framework Detection

This guide covers fingerprinting for Drupal CMS websites.

## Framework Summary
- **Name**: Drupal
- **Type**: Enterprise Content Management System (CMS)
- **Language**: PHP
- **Database**: MySQL, PostgreSQL, SQLite
- **Popularity**: 0.7% of all websites, 1.0% of CMS sites
- **Website**: [https://www.drupal.org](https://www.drupal.org)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| HTTP Header | `X-Generator: Drupal` | HTTP response headers |
| Meta Generator | `content="Drupal"` | HTML source analysis |
| Core Directory | `/core/` | Directory enumeration |
| Version Files | `/CHANGELOG.txt` | File enumeration |
| Modules Structure | `/modules/[module-name]/` | Directory enumeration |
| Admin Path | `/admin/` | Route analysis |
| REST API | `/jsonapi/` | API probing |

### Technology Stack
Drupal is built on:
- PHP (server-side scripting)
- Symfony components (Drupal 8+)
- Twig templating engine (Drupal 8+)
- Database abstraction layer
- Modular architecture
- Theme system

Common integrations:
- Database systems (MySQL, PostgreSQL, SQLite)
- Caching systems (Redis, Memcached)
- Search engines (Solr, Elasticsearch)
- E-commerce modules (Drupal Commerce, Ubercart)
- Multilingual support
- Web services (REST, JSON:API)
- CI/CD pipelines
- Varnish caching

## API Surface Discovery
Drupal exposes multiple APIs:

- **REST API**: Comprehensive content entity API (`/node`, `/user`, `/comments`)
- **JSON:API**: Modern JSON:API implementation (`/jsonapi/`)
- **Views REST Export**: JSON/XML exports from Views
- **GraphQL**: Supported via GraphQL module
- **Web Services**: SOAP, XML-RPC (legacy)

## Security Considerations
- Secure `/admin/` with strong authentication
- Remove or protect `/install.php` and `/update.php`
- Use security-focused hosting
- Keep Drupal core and modules updated
- Secure file permissions (especially `/sites/default/files/`)
- Use security modules (Paranoia, Security Kit)
- Implement proper caching headers
- Secure database configuration
- Protect against SQL injection and XSS
- Use HTTPS for all pages

## Version Detection
- Check `X-Generator` HTTP header
- Look at meta generator tag
- Analyze `/CHANGELOG.txt`
- Check `/core/CORE_VERSION.txt`
- Look for version in `/core/lib/Drupal.php`
- Query `{system}` table in database
- Check admin footer version information
- Look for version-specific module structures

## Resources
- [Official Drupal Documentation](https://www.drupal.org/docs)
- [Drupal API Reference](https://api.drupal.org)
- [Drupal REST API Documentation](https://www.drupal.org/docs/8/api/rest-api)
- [Drupal JSON:API Documentation](https://www.drupal.org/docs/8/modules/jsonapi)
- [Drupal GitHub Repository](https://github.com/drupal/drupal)
- [Drupal Commerce Documentation](https://docs.drupalcommerce.org)
- [Drupal Security Team](https://www.drupal.org/security)

## E-commerce Modules
Common Drupal e-commerce modules:

- **Drupal Commerce**: `/modules/commerce/`, `/cart`, `/checkout`
- **Ubercart**: `/modules/ubercart/`, `/cart`, `/checkout`
- **Commerce Kickstart**: Drupal Commerce distribution

Indicators of e-commerce:
- `/cart` route
- `/checkout` process
- Payment gateway integration
- Product catalog pages
- Order management interfaces