---
framework: symfony
version: "6.x / 7.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# Symfony 6.x / 7.x — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `sf_redirect` cookie | HTTP Cookie | `sf_redirect=<value>` | High — Symfony flash messages and redirects |
| `sf托` cookie (encoded name) | HTTP Cookie | Base64 or URL-encoded cookie name | High — Symfony 4+ flash message encoding |
| `PHPSESSID` cookie | HTTP Cookie | Standard PHP session | Medium — may indicate PHP session auth |
| `APP_ENV` / `APP_DEBUG` in error pages | HTML / Stack trace | `APP_ENV=prod` or `APP_DEBUG=1` | Definitive — Symfony environment exposed in debug |
| `Symfony` in stack traces | Stack trace | `vendor/symfony/*` in error output | Definitive — Symfony component paths |
| `src/` directory structure hints | URL paths | `/main.css`, `/runtime.js` | High — Symfony 4+ web dir structure |
| `_profiler` in error pages | HTML | Profiler toolbar in error pages | Definitive — Symfony WebProfilerBundle |
| `_wdt` in HTML | HTML | Web Debug Toolbar injection | Definitive — WebProfilerBundle active |
| `X-Debug-Exception` header | HTTP Header | Raw exception in header (debug mode) | Definitive |
| Twig template path in errors | Stack trace | `templates/*.html.twig` in trace | Definitive — Twig templating |
| API Platform in HTML | HTML | `<jsonld>` schema tags, Hydra API documentation | Definitive — API Platform on Symfony |
| `/_profiler/` route | URL path | Symfony profiler access point | Definitive — WebProfilerBundle |
| `/_wdt/` route | URL path | Web Debug Toolbar endpoint | Definitive |
| `SymfonySession` or similar session namespace | PHP session data | `PHPSESSID` with `sf_` prefixed cookies | High |
| `kernel.root_dir` in error traces | Stack trace | References `/app/` or `/var/` as root | High |

**Version extraction (bash):**

```bash
# Check for Symfony version in composer.json if served
curl -s https://target.example.com/composer.json 2>/dev/null | grep -i 'symfony/symfony'
curl -s https://target.example.com/composer.lock 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); [print(p['name'], p['version']) for p in d.get('packages',[]) if 'symfony' in p.get('name','')]" 2>/dev/null | head -10

# Check error page for Symfony version in debug mode
curl -s https://target.example.com/nonexistent-path-abc/ | grep -oP 'Symfony \d+\.\d+\.\d+' | head -1

# Check for Symfony profiler / debug toolbar
curl -s https://target.example.com/ | grep -o '_profiler\|_wdt\|sf_redirect' | head -3

# Check X-Debug-Exception header (debug mode only)
curl -I https://target.example.com/ 2>/dev/null | grep -i 'x-debug'
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/api/` | GET | Varies | API Platform root entry point |
| `/api/docs` | GET | Varies | Swagger/OpenAPI docs (NelmioApiDocBundle) |
| `/api/docs.json` | GET | Varies | OpenAPI JSON spec |
| `/api/{resource}` | GET/POST/PUT/DELETE | Varies | API Platform REST resources |
| `/api/{resource}/{id}` | GET/PUT/DELETE | Varies | API Platform item operations |
| `/api/graphql` | POST/GET | Varies | API Platform GraphQL endpoint |
| `/api/graphql/playground` | GET | Varies | GraphQL Playground (dev) |
| `/_profiler/` | GET | Requires token | Web Debug Profiler — extremely sensitive |
| `/_profiler/<token>` | GET | Requires token | Individual profiler snapshot |
| `/_wdt/<token>` | GET | Requires token | Web Debug Toolbar data |
| `/translations/` | GET | Varies | Translation file downloads (if not protected) |
| `/{_locale}/` | GET | Varies | Internationalized routes with locale prefix |
| `/bundles/` | GET | None | Asset bundles served from `/var/bundles/` (Symfony 4+) |
| `/main.css` | GET | None | Compiled CSS entry (Symfony 4+ web directory) |
| `/runtime.js` | GET | None | Webpack-encore compiled JS entry (Symfony 4+) |
| `/build/` | GET | None | Webpack-encore build artifacts (Symfony 4+) |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `.env` file (server-side) | Not accessible remotely | `APP_ENV`, `APP_SECRET`, `DATABASE_URL` |
| `.env.local` (server-side) | Not accessible remotely | Local overrides; may contain real secrets |
| `config/packages/*.yaml` (server-side) | Not accessible remotely | Framework, security, doctrine, messenger config |
| `services.yaml` (server-side) | Not accessible remotely | Service container definitions |
| `composer.json` (if served) | Direct file access | Symfony version, installed bundles |
| `vendor/composer/installed.json` (if served) | Direct file access | Full dependency tree |
| `/api/docs.json` response | HTTP GET (if public) | API Platform OpenAPI spec |
| `/api/docs` HTML | HTTP GET (if public) | Swagger UI for API |
| Error page stack trace (dev) | HTTP GET | Full config, env vars, bundle list |

**Extract API Platform schema:**
```bash
# Get full OpenAPI spec from API Platform
curl -s https://target.example.com/api/docs.json | python3 -m json.tool | head -50

# Check version in API spec info
curl -s https://target.example.com/api/docs.json | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('Version:', d.get('info', {}).get('version', 'not found'))
print('Title:', d.get('info', {}).get('title', 'not found'))
"
```

## 4. Auth Patterns

| Pattern | Location | Notes |
|--------|----------|-------|
| Session cookie | `PHPSESSID` (default) or custom named | PHP native sessions; HttpOnly + Secure |
| Symfony Security firewall | `BEARER` or custom token header | `json_login`, `form_login`, or stateless token |
| JWT with LexikJWTAuthenticationBundle | `Authorization: Bearer <jwt>` header | Most common Symfony JWT pattern |
| API Platform OAuth | `Authorization: Bearer <token>` header | API Platform built-in OIDC support |
| Remember-me cookie | `REMEMBERME=<value>` cookie | Symfony Security remember-me feature |
| Login form action | `POST /login` to `/login` | Standard form login flow |
| CSRF token | `_csrf_token` form field or `_csrf_token` cookie | Symfony CSRF protection; form submissions |
| Guard authenticator | Custom guard in security.yaml | Route-level auth via `access_control` |

**CSRF token acquisition for form submissions:**

```bash
# Step 1: GET the form page to extract CSRF token
curl -sc /tmp/sf_cookies.txt https://target.example.com/form-page

# Step 2: extract _csrf_token from response (usually in hidden input)
TOKEN=$(curl -sb /tmp/sf_cookies.txt -s https://target.example.com/form-page \
  | grep -oP '_csrf_token[^>]*value="[^"]*"' \
  | grep -oP 'value="\K[^"]+')

# Step 3: POST with CSRF token and session cookie
curl -sb /tmp/sf_cookies.txt \
  -X POST https://target.example.com/submit-form \
  -d "_csrf_token=$TOKEN&field1=value1&field2=value2"
```

## 5. JS/CSS Bundle Patterns

| Path | Content |
|------|---------|
| `/build/*.js` | Webpack Encore compiled JavaScript (Symfony 4+) |
| `/build/*.css` | Webpack Encore compiled stylesheets |
| `/build/entrypoints.json` | Webpack Encore entrypoints manifest |
| `/build/manifest.json` | Asset filename-to-hashed filename mapping |
| `/bundles/*/` | WebProfilerBundle, WebDebugToolbar assets |
| `/main.css` | Default CSS entry point (Symfony 4+ web/) |
| `/runtime.js` | Webpack Encore runtime bundle |
| `/node_modules/.package-lock.json` | Node.js package manager lock |
| `/assets/` | Source assets (Vue, React, or Stimulus) |
| `/vendor/` | Composer PHP dependencies (NOT served by default) |

**Webpack Encore manifest probe:**
```bash
# Check for Symfony Encore asset manifest
curl -s https://target.example.com/build/manifest.json 2>/dev/null | python3 -m json.tool | head -30
```

## 6. Source Map Patterns

Symfony does not generate source maps natively. Source maps only appear if Webpack Encore (or custom webpack) is configured to emit them.

**Where to look:**

```bash
# Check for source maps next to known JS files
curl -I https://target.example.com/build/app.js.map 2>/dev/null

# Check Webpack manifest for hashed filenames, then check for maps
curl -s https://target.example.com/build/manifest.json 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for k, v in d.items():
        if k.endswith('.js'):
            print(f'{k} -> {v}')
except: pass
" | head -10

# Extract all JS URLs from HTML and check each for .map
curl -s https://target.example.com/ | grep -oP 'src=\"[^\"]+\.js[^\"]*\"' | sed 's/src=\"//;s/\"$//' | while read -r url; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "${url}.map")
  [ "$status" = "200" ] && echo "SOURCE MAP: ${url}.map"
done
```

## 7. Common Plugins & Extensions

| Package | API it adds | Detection signal |
|---------|-------------|------------------|
| API Platform | `/api/`, `/api/docs`, `/api/graphql` | Comprehensive REST/GraphQL API surface |
| NelmioApiDocBundle | `/api/docs` | Swagger/OpenAPI documentation |
| NelmioCorsBundle | CORS headers on API responses | `Access-Control-Allow-*` headers |
| LexikJWTAuthenticationBundle | JWT Bearer token auth | `Authorization: Bearer` pattern |
| FOSUserBundle | `/register`, `/login`, `/profile` | User management routes |
| Doctrine ORM | No HTTP surface | Database ORM; entity classes in vendor |
| Propel | No HTTP surface | Alternative ORM |
| Messenger | No HTTP surface (queues) | Async message handling |
| EasyAdmin | `/admin` | Admin dashboard (customizable) |
| Sonata Project | `/admin` | Admin bundle collection |
| WebProfilerBundle | `/_profiler/`, `/_wdt/` | Debug toolbar and profiler |
| Twig | No HTTP surface | Templating engine |
| Symfony UX (Stimulus, Turbo) | `/assets/` | Front-end interactivity |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `/api/docs.json` | Full OpenAPI spec | API Platform + NelmioApiDocBundle |
| `/api/docs` | Interactive Swagger UI | May be public or require auth |
| `/api/graphql` | GraphQL endpoint | API Platform GraphQL |
| `/translations/` | Translation file downloads | May expose internal keys if not protected |
| `/_profiler/` | Profiler redirect or 403 | Access-controlled; reveals internal data if accessible |
| `/.env` | Environment variables | Exposed if web server misconfiguration serves root files |
| `/build/manifest.json` | Asset mapping | May expose internal build structure |
| Error pages | Stack traces, config values | Only in dev (`APP_DEBUG=1`) |

## 9. Probe Checklist

- [ ] `GET /` — Check for Symfony 4+ webpack-encore assets (`/build/` paths) and flash cookies
- [ ] `GET /api/` — Is API Platform present? (200 = API Platform installed)
- [ ] `GET /api/docs` — Is API documentation exposed? (200 = NelmioApiDocBundle or API Platform docs)
- [ ] `GET /api/docs.json` — Retrieve OpenAPI spec; full API inventory and version
- [ ] `GET /api/graphql` — Is API Platform GraphQL present? (probe introspection query)
- [ ] Check response headers and cookies for `sf_redirect`, `PHPSESSID` — Symfony session/flash system
- [ ] `GET /nonexistent-path-abc/` — Trigger error; check for Symfony debug output, version in stack trace, Twig template paths
- [ ] `GET /_profiler/` — Is WebProfilerBundle present? (redirects or 200 = installed; extremely sensitive)
- [ ] `GET /_wdt/<token>` — Is Web Debug Toolbar data endpoint accessible?
- [ ] Check for `sf_` prefixed cookies — `sf_redirect`, `sf托` (encoded) confirm Symfony flash messages
- [ ] Scan HTML source for `_profiler` or `_wdt` references — profiler toolbar injection in HTML
- [ ] `GET /build/manifest.json` — Is Webpack Encore manifest accessible? (Symfony 4+ build fingerprinting)
- [ ] `GET /api/{resource}` — Probe for API Platform REST resources
- [ ] Check for `APP_ENV` or `APP_DEBUG` in error pages — environment exposure (debug mode)
- [ ] `GET /translations/` — Is translation file serving exposed?
- [ ] Probe for EasyAdmin or Sonata admin routes at `/admin`
- [ ] Check for API Platform JSON-LD / Hydra signatures in API responses

## 10. Gotchas

- **Symfony 4+ changed the web directory structure.** Classic Symfony (≤3.x) served from `web/` with `app.php` entry point. Symfony 4+ uses `/build/` for webpack-encore assets, `/public/` as the web root, and `/main.css` / `/runtime.js` as common entry points. Older tech packs may describe the old structure.

- **Flash messages use encoded cookie names.** `sf_redirect` is the primary flash message cookie but Symfony 4+ uses base64 or URL-encoded names (`sf托` where `托` is a Chinese character encoding). If `sf_redirect` is absent, check for any cookie starting with `sf`.

- **The profiler is access-controlled but sometimes misconfigured.** `/_profiler/` requires a token by default. A successful probe (200 with profiler data) is a critical finding. Even a 403 indicates the WebProfilerBundle is installed and potentially accessible.

- **API Platform uses Hydra and JSON-LD.** Standard OpenAPI tooling may not fully parse API Platform's output. Look for `<jsonld>` schema tags in HTML responses and `_embedded` / `_links` HATEOAS patterns in JSON responses.

- **Composer dependencies are NOT served by default.** The `vendor/` directory is outside the web root. Only misconfigured servers expose `composer.json` or `vendor/composer/installed.json`. If found, they reveal the full Symfony version and bundle dependency tree.

## 11. GitHub Code Search Patterns

### Framework-Specific Queries

| Search Query | What it finds |
|--------------|---------------|
| `language:php #[Route(]` | Symfony route attribute definitions |
| `#[ORM\Entity]` | Doctrine entity class definitions |
| `#[AsDoctrine]` | PHP 8 attribute-based Doctrine mapping |
| `security.yml` path:config | Symfony security firewall configuration |
| `services.yaml` path:config | Symfony service container configuration |
| `doctrine.orm` `language:yaml` | Doctrine ORM configuration |

### Example Queries for Symfony

```bash
# Search for Symfony route patterns
site:github.com "Symfony" "#[Route(" language:php "#[\Route"

# Search for API Platform resources
site:github.com "ApiResource" "#[ApiResource]" language:php

# Search for Doctrine entities
site:github.com "#[ORM\Entity]" "#[ORM\Column]" language:php

# Search for Twig templates
site:github.com "twig" "extends(" path:templates

# Search for Symfony security configuration
site:github.com "access_control" "ROLE_" path:security.yaml language:yaml
```

## 12. Framework-Specific Google Dorks

### Discovery Queries

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:/api/` | API Platform endpoints |
| `site:{domain} inurl:/api/docs` | Symfony API documentation |
| `site:{domain} inurl:/_profiler` | Symfony WebProfilerBundle |
| `site:{domain} inurl:/_wdt` | Symfony Web Debug Toolbar |
| `site:{domain} inurl:/build/` | Symfony 4+ webpack-encore build artifacts |
| `site:{domain} "sf_redirect"` | Symfony flash message cookies |
| `site:{domain} inurl:/admin` | EasyAdmin or Sonata admin panel |
| `site:{domain} inurl:/login` | Symfony form login |

### Complete Dork List for Symfony

```
# API endpoints
site:{domain} inurl:/api/
site:{domain} inurl:/api/docs
site:{domain} inurl:/api/graphql

# Framework-specific paths
site:{domain} inurl:/_profiler
site:{domain} inurl:/_wdt
site:{domain} inurl:/build/
site:{domain} inurl:/vendor/

# Configuration files (if served)
site:{domain} filetype:php "symfony"
site:{domain} filetype:yaml "doctrine.orm"
site:{domain} filetype:json "composer.lock" "symfony"

# Documentation/leaks
site:{domain} "Symfony" "ApiPlatform"
site:{domain} "sf_redirect" "flash"

# Admin/debug paths
site:{domain} inurl:/_profiler
site:{domain} inurl:/admin
site:{domain} inurl:/login
```

## 13. Cross-Cutting OSINT Patterns

### Favicon Hashing

```bash
# Get favicon hash for Shodan/Censys cross-referencing
curl -s "https://{domain}/favicon.ico" | python3 -c "
import sys
data = sys.stdin.buffer.read()
import mmh3 2>/dev/null || pip install mmh3
print(mmh3.hash(data))
"
```

### Source Map Discovery

```bash
# Extract all JS bundle URLs from HTML
curl -s "https://{domain}/" | grep -oP 'src=\"[^\"]+\.js[^\"]*\"' | sed 's/src=\"//;s/\"$//' > js_urls.txt

# Check each for .map file
while read -r url; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "${url}.map")
  [ "$status" = "200" ] && echo "SOURCE MAP: ${url}.map"
done < js_urls.txt
```

**Build tool patterns:**
| Build Tool | Source Map Pattern | Detection |
|------------|-------------------|------------|
| Webpack Encore | `{name}.js.map` in `/build/` | Symfony standard bundler |
| Webpack (custom) | `{hash}.js.map` | Check `/build/manifest.json` |
| Vite | `{name}.js.map` | Alternative to Encore |
| esbuild | `{name}.js.map` | Check `sourceMappingURL` |

### Tech Stack → API Pattern Mapping

| Framework | Common API Patterns |
|-----------|---------------------|
| Symfony | `/api/*`, `/api/docs`, `/_profiler/*`, `/_wdt/*` |
| Laravel | `/api/*`, `/livewire/*`, `/sanctum/csrf-cookie` |
| Spring Boot | `/actuator/*`, `/api/*`, `/swagger-ui/` |
| Django | `/api/*`, `/admin/*`, `/accounts/*` |
| NestJS | `/api-docs`, `/graphql`, `/health` |
| API Platform (on Symfony) | `/api/`, `/api/docs`, `/api/graphql` |

### Email Naming Convention Analysis

```bash
# Predict internal subdomains from email patterns:
# john.doe@example.com → mail.example.com, smtp.example.com
# first.last@ → internal.example.com
# firstinitial+last@ → owa.example.com
```