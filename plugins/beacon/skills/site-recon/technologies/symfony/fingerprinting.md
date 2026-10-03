---
framework: symfony
version: "6.x / 7.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# Symfony 6.x / 7.x — Fingerprinting Guide

## Framework Overview

Symfony is a mature, component-based PHP framework with a robust ecosystem. Version 6.x requires PHP 8.1+ and version 7.x requires PHP 8.2+. It uses a service container architecture, with config driven by YAML or PHP attributes, and Twig as its default templating engine. This guide covers fingerprinting techniques for Symfony 6.x/7.x applications.

## Fingerprinting Patterns

### 1. HTTP Response Headers

| Header | Value Example | Confidence | Notes |
|--------|--------------|------------|-------|
| `X-Debug-Exception` | Raw PHP exception | Definitive (dev only) | Debug mode exposes exception in header |
| `X-Debug-Exception-File` | File path + line number | Definitive (dev only) | Source location of exception |
| `X-Generator` | `Symfony` | High | Default PHP session/cache headers |
| `Set-Cookie` with `sf_redirect` | `sf_redirect=<value>` | High | Flash message cookie |
| `Set-Cookie` with `sf托` | Base64/URL-encoded name | High | Encoded Symfony flash cookie |
| `Set-Cookie` with `PHPSESSID` | Standard PHP session | Medium | Generic PHP session |

**Probe:**
```bash
curl -I https://target.example.com/ 2>/dev/null | grep -iE 'sf_redirect|x-debug|set-cookie'
```

### 2. Cookie Signatures

| Cookie Name | Confidence | Notes |
|-------------|------------|-------|
| `sf_redirect` | High | Flash message redirect cookie |
| `sf托` (base64/encoded) | High | Symfony 4+ encoded flash message |
| `PHPSESSID` | Medium | PHP native session; common across PHP apps |
| `REMEMBERME` | High | Symfony Security remember-me feature |
| `BEARER` | High | LexikJWTAuthenticationBundle token |
| `_csrf_token` | High | CSRF token cookie |

### 3. Error Page Signatures

| Signal | Pattern | Confidence | Notes |
|--------|---------|------------|-------|
| `vendor/symfony/` in stack trace | `vendor/symfony/<package>/` | Definitive | Composer vendor path in error trace |
| `templates/` directory reference | `templates/*.html.twig` in trace | Definitive | Twig template engine |
| `at Symfony\\` namespace | Full class namespace in trace | Definitive | Symfony component classes |
| `App\\` namespace | Application namespace in trace | High | Symfony default application namespace |
| `src/Kernel.php` | Kernel bootstrap reference | Definitive | Symfony 4+ kernel entry point |
| `_profiler` URL parameter | `?_profiler` or `/_profiler/` | Definitive | WebProfilerBundle active |
| `_wdt` URL path | `/_wdt/<token>` | Definitive | Web Debug Toolbar endpoint |
| `X-Debug-Exception` header | Dev-mode header | Definitive | Debug exception exposed in header |
| `Twig\\Error` in trace | Twig template errors | Definitive | Twig engine in use |

**Probe:**
```bash
# Trigger error and look for Symfony fingerprints
curl -s https://target.example.com/nonexistent-path-abc/ 2>/dev/null | grep -oE 'vendor/symfony|src/Kernel|templates/|at Symfony\\' | head -5
```

### 4. URL Path Signatures

| Signal | Pattern | Confidence | Notes |
|--------|---------|------------|-------|
| `/_profiler/` | Route prefix | Definitive | WebProfilerBundle |
| `/_wdt/` | Route prefix | Definitive | Web Debug Toolbar |
| `/build/` | Asset path | High | Webpack Encore on Symfony 4+ |
| `/translations/` | Route prefix | High | Translation file serving |
| `/{_locale}/` | Locale routing | High | Symfony internationalization |
| `/api/` | API Platform prefix | Definitive | API Platform installed |
| `/.env` | Environment file | Definitive (misconfig) | Exposed env file; critical finding |

### 5. HTML Source Signatures

| Signal | Pattern | Confidence | Notes |
|--------|---------|------------|-------|
| `_profiler` injected in HTML | Comments or hidden elements | Definitive | Web Debug Toolbar present |
| `_wdt` references | Script or link tags | Definitive | Web Debug Toolbar assets |
| `<html lang="...">` with locale | `lang="en">` in `<html>` | Medium | Symfony default locale output |
| `<div class="sf-toolbar">` | HTML class | Definitive | Symfony Web Debug Toolbar rendered |
| API Platform JSON-LD | `<jsonld>` script tags | Definitive | API Platform JSON-LD context |
| `data-turbo="true"` | Turbo Drive attribute | High | Symfony UX Turbo |
| `data-controller` attributes | Stimulus attributes | High | Symfony UX Stimulus |
| `<link rel="stylesheet" href="/build/` | CSS from webpack-encore | High | Symfony 4+ with Encore |

### 6. Version Detection

**Method 1: composer.json or composer.lock (if accessible)**
```bash
curl -s https://target.example.com/composer.json | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('Require:', d.get('require', {}).get('symfony/symfony', 'not found'))
"

curl -s https://target.example.com/composer.lock | python3 -c "
import sys, json
d = json.load(sys.stdin)
for p in d.get('packages', []):
    n = p.get('name', '')
    if 'symfony/symfony' in n or 'framework-bundle' in n:
        print(n, p.get('version', ''))
" 2>/dev/null | head -5
```

**Method 2: Error page stack trace**
```bash
curl -s https://target.example.com/nonexistent-path-abc/ | grep -oP 'Symfony \d+\.\d+\.\d+' | head -1
```

**Method 3: API Platform OpenAPI spec**
```bash
curl -s https://target.example.com/api/docs.json | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('API Version:', d.get('info', {}).get('version', 'not found'))
"
```

**Method 4: Kernel version constant**
```bash
# If main entry point is accessible
curl -s https://target.example.com/index.php 2>/dev/null | grep -oP 'SYMFONY_\d+_\d+_VERSION|SymfonyVersion'
```

## Version Comparison Table

| Symfony Version | PHP Required | Config Format | Key Changes |
|-----------------|---------------|---------------|-------------|
| 4.x | 7.1+ | YAML + attributes | Flex, recipe system, web directory restructure |
| 5.x | 7.2+ | Attributes + YAML | PHP 8 support, Mailer, UX |
| 6.x | 8.1+ | Attributes primarily | PHP 8.1 required,Uid component |
| 7.x | 8.2+ | Attributes primarily | PHP 8.2 required, new features |

## Confidence Level Definitions

| Level | Meaning | When to use |
|-------|---------|-------------|
| **Definitive** | Cannot be produced by any other framework | Use as primary confirmation |
| **High** | Very strong signal; unlikely false positive | Use as strong evidence |
| **Medium** | Present in many frameworks or common configuration | Use as supporting evidence |
| **Low** | Generic signal; many possible explanations | Use as hint only |

## Quick Fingerprinting Commands

```bash
# Quick check: headers + cookies
curl -I https://target.example.com/ 2>/dev/null | grep -iE 'set-cookie|sf_redirect|x-debug'

# Quick check: flash cookie presence
curl -Is https://target.example.com/ 2>/dev/null | grep -iE 'sf_|PHPSESSID'

# Quick check: Symfony 4+ webpack-encore assets
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/build/manifest.json

# Quick check: API Platform
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/api/docs.json

# Quick check: profiler
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/_profiler/

# Trigger error for version and stack trace
curl -s https://target.example.com/does-not-exist-xyz/ | grep -oE 'vendor/symfony|src/Kernel|Symfony \d+\.\d+' | head -5

# Check for encoded flash cookie
curl -Is https://target.example.com/ 2>/dev/null | grep 'set-cookie' | grep -i 'sf'
```

## False Positive Mitigation

- **`PHPSESSID` alone only means PHP.** Any PHP application uses this default session cookie. Combine with `sf_redirect`, `sf_` prefix, or error trace with `vendor/symfony/` before concluding Symfony.
- **`/_profiler/` may return 403 even when installed.** A 403 means WebProfilerBundle is present but correctly access-controlled. Do not rule out Symfony based on a 403 from the profiler.
- **The `/_wdt/` endpoint requires a token** and is not accessible without the profiler. Its presence in HTML source (even as a comment) definitively confirms Symfony's WebProfilerBundle.
- **Flash cookies (`sf_redirect` and encoded variants) are transient** — they appear after a redirect, not on every request. To detect them, follow a chain: visit a page that issues a redirect, then check cookies on the destination.
- **API Platform requires both Symfony AND the API Platform library.** `/api/` path alone is not definitive — many Symfony apps have a controller named "Api" with routes there. The presence of `/api/docs` or `/api/docs.json` is more definitive.

## Technology Stack Pairings

| Technology | Detection Method | Confidence |
|------------|-----------------|------------|
| Twig templating | `templates/*.html.twig` in error traces | Definitive |
| API Platform | `/api/`, `/api/docs`, JSON-LD signatures | Definitive |
| Doctrine ORM | Entity classes referenced in error traces | High |
| WebProfilerBundle | `/_profiler/`, `/_wdt/`, toolbar in HTML | Definitive |
| Webpack Encore | `/build/` paths, manifest.json | High |
| LexikJWTAuthenticationBundle | `BEARER` cookie or header | High |
| FOSUserBundle | `/register`, `/login` routes | High |
| Symfony UX (Stimulus/Turbo) | `data-controller`, `data-turbo` attributes | High |
| PHP 8 attributes | `#[Route]`, `#[ORM\Column]` in source | Definitive |

## Changelog

- 2026-05-11: Initial Symfony 6.x/7.x tech pack with comprehensive coverage of flash cookies, WebProfilerBundle, API Platform, and Webpack Encore detection