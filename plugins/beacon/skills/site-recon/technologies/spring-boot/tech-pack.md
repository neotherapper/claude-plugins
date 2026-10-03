---
framework: spring-boot
version: "3.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# Spring Boot 3.x — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `X-Application-Context` header | HTTP Response | `application=<name>:<profile>:<version>` | High — Spring Boot default header |
| `spring-boot-starter` in JS/CSS paths | HTML source | `/webjars/spring-boot/` or `/static/js/*.js` with Spring context | Medium |
| `Whitelabel Error Page` title in HTML | HTML error | Error page with "Whitelabel Error Page" title | Definitive — default error page |
| `status` query param in error URLs | URL param | `/error?status=404&message=Not+Found` | High — Spring MVC error handler |
| `org.springframework.web.servlet.view` in stack traces | Stack trace | Spring class packages in error output | Definitive — when DEBUG=True |
| `Spring Boot Web` title in actuator info | HTML | `/actuator/info` endpoint returns Spring Boot info | Definitive — actuator enabled |
| `application/json` accepted without charset | HTTP Content-Type | `Content-Type: application/json` without `charset` parameter | Medium — common Spring default |
| `X-Content-Type-Options: nosniff` header | HTTP Header | Spring Security default headers | Medium — Spring Security present |

**Version extraction (bash):**

```bash
# Check actuator info endpoint for version details
curl -s https://target.example.com/actuator/info | python3 -m json.tool 2>/dev/null || curl -s https://target.example.com/actuator/info

# Trigger error page for version (Spring Boot 2.x shows version in error)
curl -s https://target.example.com/nonexistent-path-abc123/ | grep -i 'spring'

# Check X-Application-Context header
curl -I https://target.example.com/ 2>/dev/null | grep -i 'application-context'

# Check for Spring Boot JAR fingerprint in response headers
curl -I https://target.example.com/ 2>/dev/null | grep -iE 'server|x-application'
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/actuator/` | GET | Varies (often public) | Spring Boot Actuator root; lists available endpoints |
| `/actuator/health` | GET | Usually public | Health check endpoint; may show component status |
| `/actuator/info` | GET | Usually public | Application info; may expose git commit, build info |
| `/actuator/env` | GET | Requires admin | Environment variables — sensitive; often protected |
| `/actuator/beans` | GET | Requires admin | All Spring beans — very sensitive |
| `/actuator/mappings` | GET | Requires admin | All URL → handler mappings — API inventory |
| `/actuator/configprops` | GET | Requires admin | Configuration properties — may expose secrets |
| `/actuator/heapdump` | GET | Requires admin | Heap dump download — highly sensitive |
| `/api/` | GET | Varies | REST API root if using `/api` prefix; not guaranteed |
| `/v1/api/` | GET | Varies | Versioned API root |
| `/error` | GET | None | Spring MVC error handler; accessible for all errors |
| `/favicon.ico` | GET | None | Static resource |
| `/webjars/**` | GET | None | WebJars resources if configured |
| `/swagger-ui/` | GET | Varies | Swagger UI if springdoc-openapi is installed |
| `/v3/api-docs` | GET | Varies | OpenAPI 3 spec if springdoc-openapi is installed |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `application.properties` (server-side) | Not accessible remotely | DB credentials, server port, context path, actuator config |
| `application.yml` (server-side) | Not accessible remotely | Same as properties in YAML format |
| `/actuator/env` | HTTP GET (if not protected) | Environment variables including `spring.config.location` hints |
| `/actuator/configprops` | HTTP GET (if not protected) | Configuration property values — may expose secrets |
| `/actuator/beans` | HTTP GET (if not protected) | All Spring bean names and types |
| `/actuator/mappings` | HTTP GET (if not protected) | Complete URL-to-handler mapping table |
| `MANIFEST.MF` inside JAR | If JAR is served statically | Build info, `Implementation-Version`, git commit (if git-commit-id-plugin used) |
| `BOOT-INF/classes/application.properties` | Inside deployed JAR | Same as server-side config file; may be extractable from JAR |

**Extract config from JAR (if accessible):**

```bash
# If the application JAR is accessible (e.g., via /webjars or a file endpoint)
curl -sO https://target.example.com/static/app.jar 2>/dev/null && unzip -p app.jar BOOT-INF/classes/application.properties 2>/dev/null | head -50
```

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| Spring Security session | `JSESSIONID` cookie | Default servlet session; HttpOnly + Secure in production |
| OAuth2 / OIDC | `Authorization: Bearer <token>` header | Spring Security OAuth2 Resource Server |
| JWT (access token) | `Authorization: Bearer <jwt>` header | Spring Security JWT; often with jjwt library |
| Basic Auth | `Authorization: Basic <base64>` header | HTTP Basic auth; common for actuator endpoints |
| CSRF token | `csrf` cookie or request parameter | Spring Security CSRF protection; send as `_csrf` parameter or `X-CSRF-TOKEN` header |
| Actuator basic auth | `Authorization: Basic` header | Often protected via `management.endpoints.web.exposure.include` and `spring.security.user.name`/`password` |

**CSRF token acquisition for write operations:**

```bash
# Step 1: fetch a page to get CSRF token from cookie
curl -sc /tmp/sb_cookies.txt https://target.example.com/actuator/heapdump 2>/dev/null

# Step 2: extract CSRF token from cookie
CSRF=$(grep 'csrf' /tmp/sb_cookies.txt | cut -f7)
# or from cookie file directly:
CSRF=$(cat /tmp/sb_cookies.txt | grep 'csrf' | awk '{print $7}')

# Step 3: POST with CSRF token
curl -sb /tmp/sb_cookies.txt \
  -H "X-CSRF-TOKEN: $CSRF" \
  -X POST https://target.example.com/api/resource \
  -d '{"key":"value"}'
```

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `/webjars/bootstrap/` | Bootstrap CSS/JS via WebJars |
| `/webjars/jquery/` | jQuery via WebJars |
| `/static/js/*.js` | Static JS files (standard Maven resource layout) |
| `/static/css/*.css` | Static CSS files |
| `/assets/**/*.js` | Thymeleaf or other template engine assets |
| `/dist/*.js` | Build tool output (Webpack, Vite) |
| `/webapp/dist/*.js` | Front-end build artifacts (rare, more common in 2.x legacy) |
| `/_assets/**` | Svelte, Vue, or React build output (if front-end in same WAR) |

Spring Boot does not bundle JavaScript natively. Static files are served via `spring.web.resources.static-locations`. A separate front-end build (Node.js/Vite) is common for modern SPA front-ends, which will have their own bundle patterns.

## 6. Source Map Patterns

Spring Boot does not generate source maps natively. Source maps are only present if a front-end build tool is explicitly configured.

**Where to look:**

```bash
# Check for source maps alongside known JS files (if static resources are on same origin)
curl -I https://target.example.com/static/js/main.js.map

# Check manifest-based builds
curl -s https://target.example.com/static/manifest.json

# Extract all JS bundle URLs from HTML and check each for .map
curl -s https://target.example.com/ | grep -oP 'src="[^"]+\.js[^"]*"' | while read -r url; do
  map_url="${url}.map"
  status=$(curl -s -o /dev/null -w "%{http_code}" "$map_url")
  [ "$status" = "200" ] && echo "SOURCE MAP: $map_url"
done
```

## 7. Common Plugins & Extensions

| Package | API it adds | Detection signal |
|---------|-------------|------------------|
| springdoc-openapi | `/swagger-ui/`, `/v3/api-docs/` | Swagger UI at `/swagger-ui/`; OpenAPI JSON at `/v3/api-docs` |
| Spring Security OAuth2 | `/oauth2/`, `/login/oauth2/` | OAuth2 authorization endpoints |
| Spring Data REST | `/api/` root with HATEOAS | Exported REST repositories at `/api/*` |
| Spring Admin (Codecentric) | `/admin/` | Spring Boot Admin dashboard; specific UI |
| Micrometer | `/actuator/prometheus` | Prometheus metrics endpoint |
| Spring Boot Actuator | `/actuator/*` | All actuator endpoints |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `/actuator/health` | Application health status, component health | Often public; shows disk space, DB connectivity |
| `/actuator/info` | Application name, description, git commit, build version | Public if `spring.config.location` exposes info; use git-commit-id-plugin for version |
| `/error` | Error details | May expose stack trace if `server.error.include-stacktrace=always` |
| `/swagger-ui/` | Interactive API documentation | Public if springdoc-openapi is used without auth |
| `/v3/api-docs` | Full OpenAPI 3 spec | All routes, models, parameters |
| `/actuator/mappings` | All registered URL mappings | Complete API inventory |
| `/actuator/beans` | All Spring bean names | Component inventory |
| `MANIFEST.MF` in JAR | Build metadata, git commit, timestamp | Extractable from deployed JAR |

## 9. Probe Checklist

- [ ] `GET /actuator/health` — Is actuator present? (200 with JSON health = Spring Boot Actuator active; public by default in Spring Boot 2.x, may require auth in 3.x)
- [ ] `GET /actuator/info` — Retrieve application info; check for git commit, build version in response
- [ ] `GET /actuator/mappings` — Is the full URL-to-handler mapping table accessible? (sensitive — full API inventory)
- [ ] `GET /actuator/beans` — Are Spring beans exposed? (highly sensitive)
- [ ] `GET /actuator/env` — Is the environment accessible? (sensitive — may expose credentials)
- [ ] `GET /swagger-ui/` — Is springdoc-openapi Swagger UI present? (200 = springdoc installed)
- [ ] `GET /v3/api-docs` — Is OpenAPI 3 spec public? (200 = full API schema available)
- [ ] `GET /error` — Trigger error page; check for "Whitelabel Error Page" or stack trace with Spring classes
- [ ] Check response headers for `X-Application-Context` — reveals application name, profile, version
- [ ] `GET /actuator/configprops` — Is configprops exposed? (may reveal configured passwords/secrets)
- [ ] `GET /api/` or `GET /v1/api/` — Probe for REST API root; check for Spring Data REST exports
- [ ] `GET /actuator/heapdump` — Attempt heap dump download (requires auth in prod; if 200 = unprotected)
- [ ] Probe for Spring Security login: `GET /login` — check if OAuth2 or form login is present
- [ ] `GET /actuator/prometheus` — Is Micrometer/Prometheus metrics endpoint exposed?
- [ ] Check for `/webjars/` paths — presence indicates WebJars usage

## 10. Gotchas

- **Actuator security changed significantly in Spring Boot 3.x.** In 2.x, actuator endpoints were public by default; in 3.x, most are protected by default and require explicit exposure via `management.endpoints.web.exposure.include`. Finding `/actuator/health` alone no longer means full actuator is accessible — always probe `/actuator/env`, `/actuator/beans`, and `/actuator/mappings` individually.

- **Error pages reveal application structure.** The default Whitelabel Error Page is definitive for Spring Boot. If `server.error.include-stacktrace=always` is set (common in dev), error pages expose the full stack trace including package names, class names, and configuration hints. Trigger a 404 intentionally to probe.

- **Spring Security has a default deny-all posture in 3.x.** If Spring Security is on the classpath, almost everything requires authentication by default. A publicly accessible API suggests either `permitAll()` was explicitly configured or security is intentionally relaxed.

- **JWT and session auth coexist.** Spring Security OAuth2 Resource Server uses JWT (`Authorization: Bearer`) while traditional form login uses session cookies. A site may use both simultaneously — don't assume one excludes the other.

- **Version information hides in multiple places.** Version may be in `/actuator/info` (if git-commit-id-plugin configured), in `MANIFEST.MF` inside the JAR, in error page stack traces (DEBUG mode), or in the `X-Application-Context` response header.

## 11. GitHub Code Search Patterns

### Framework-Specific Queries

| Search Query | What it finds |
|--------------|---------------|
| `language:java @GetMapping @PostMapping` | Spring MVC REST controller definitions |
| `@RestController @RequestMapping` | REST controller with base path |
| `@Service @Repository` | Spring service and repository layer patterns |
| `spring-boot-starter-web` | Maven/Gradle dependencies |
| `spring.security` | Spring Security configuration examples |

### Example Queries for Spring Boot

```bash
# Search for REST controller patterns
site:github.com "Spring Boot" "RestController" "GetMapping" language:java

# Search for actuator configuration
site:github.com "spring boot" "actuator" "expose" language:java

# Search for security configuration
site:github.com "Spring Security" "configure" "HttpSecurity" language:java

# Search for application.properties/yml
site:github.com "application.yml" "spring:" "server:" language:yaml
```

## 12. Framework-Specific Google Dorks

### Discovery Queries

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:/actuator/` | Spring Boot Actuator endpoints |
| `site:{domain} inurl:/swagger-ui` | Spring Boot API documentation |
| `site:{domain} "Whitelabel Error Page"` | Spring Boot error pages |
| `site:{domain} inurl:/error?status=` | Spring MVC error handler |

### Complete Dork List for Spring Boot

```
# API endpoints
site:{domain} inurl:/actuator/
site:{domain} inurl:/api/
site:{domain} inurl:/v1/

# Framework-specific paths
site:{domain} inurl:/swagger-ui/
site:{domain} inurl:/v3/api-docs
site:{domain} inurl:/webjars/

# Configuration files (if served statically)
site:{domain} filetype:properties "spring"
site:{domain} filetype:yml "spring.boot"

# Documentation/leaks
site:{domain} "Spring Boot" "RestController"
site:{domain} "Whitelabel Error Page"

# Admin/debug paths
site:{domain} inurl:/actuator/env
site:{domain} inurl:/actuator/beans
site:{domain} inurl:/actuator/mappings
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
| Webpack | `{bundle}.js.map` | Check response header `X-SourceMap` |
| Vite | `{name}-[hash].js.map` | Vite manifest `manifest.json` |
| Rollup | `{bundle}.js.map` | Check `sourceMappingURL` comment |

### Tech Stack → API Pattern Mapping

| Framework | Common API Patterns |
|-----------|---------------------|
| Spring Boot | `/actuator/*`, `/api/*`, `/v1/*`, `/swagger-ui/` |
| Django | `/api/*`, `/admin/*`, `/accounts/*` |
| Rails | `/api/v1/*`, `/assets/*`, `/users/sign_in` |
| Laravel | `/api/*`, `/livewire/message/*`, `/sanctum/csrf-cookie` |
| Next.js | `/api/*`, `/_next/data/*`, `/api/auth/*` |
| Shopify | `/api/2024-10/graphql.json`, `/products.json` |

### Email Naming Convention Analysis

```bash
# Predict internal subdomains from email patterns:
# john.doe@example.com → mail.example.com, smtp.example.com
# first.last@ → internal.example.com
# firstinitial+last@ → owa.example.com, outlook.example.com
```