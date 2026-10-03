---
framework: symfony
version: "6.x / 7.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# Symfony Framework Detection

## Framework Summary
- **Name**: Symfony
- **Type**: PHP web application framework
- **Language**: PHP 8.1+ (Symfony 6.x), PHP 8.2+ (Symfony 7.x)
- **Popularity**: Most popular enterprise PHP framework; powers Laravel and many other frameworks
- **Website**: [https://symfony.com](https://symfony.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| `sf_redirect` cookie | Flash message cookie | Response Set-Cookie header |
| `sf托` (encoded) cookie | Base64-encoded flash cookie | Response Set-Cookie header |
| `/_profiler/` route | Web Debug Toolbar access | HTTP GET |
| `/_wdt/` route | Web Debug Toolbar data | HTTP GET |
| `vendor/symfony/` in error traces | Composer vendor path | Trigger 404/500 error |
| `templates/*.html.twig` in traces | Twig template paths | Error page inspection |
| `/build/` paths | Webpack Encore assets | HTTP probe (Symfony 4+) |
| `/api/` routes | API Platform endpoints | HTTP probe |
| `X-Debug-Exception` header | Debug mode exception | Response headers |

### Technology Stack
Symfony is commonly paired with:
- PHP 8.1+ (6.x) / PHP 8.2+ (7.x)
- Twig templating engine
- Doctrine ORM for database
- API Platform for REST/GraphQL APIs
- Webpack Encore for asset bundling
- Symfony Security for auth
- LexikJWTAuthenticationBundle for JWT
- Symfony UX (Stimulus, Turbo) for frontend interactivity

## Fingerprint Probes

```bash
# Check for Symfony cookies and headers
curl -I https://target.example.com/ 2>/dev/null | grep -iE 'set-cookie|sf_|x-debug'

# Trigger error for stack trace
curl -s https://target.example.com/does-not-exist/ | grep -oE 'vendor/symfony|src/Kernel|Symfony'

# Probe for Webpack Encore manifest
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/build/manifest.json

# Probe for API Platform docs
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/api/docs.json

# Check for WebProfilerBundle
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/_profiler/
```

## Security Considerations
- `/_profiler/` can expose extremely sensitive data if accessible
- `APP_DEBUG=1` in error pages exposes stack traces and config
- Composer.json or .env exposed via webserver misconfiguration reveals all secrets
- API Platform may expose full data model in OpenAPI spec

## Resources
- [Symfony Official Documentation](https://symfony.com/doc/current/)
- [Symfony GitHub](https://github.com/symfony/symfony)
- [API Platform Documentation](https://api-platform.com/docs/)
- [Symfony Security Guide](https://symfony.com/doc/current/security.html)
- [Symfony Best Practices](https://symfony.com/doc/current/best_practices.html)