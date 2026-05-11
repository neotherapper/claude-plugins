---
framework: aspnet-core
version: "8.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# ASP.NET Core 8.x — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `Server: Kestrel` response header | HTTP Header | `Kestrel` server name | High — Kestrel is ASP.NET Core's default server |
| `X-SourceFiles` response header | HTTP Header | `X-SourceFiles: <path>` | Definitive — ASP.NET Core development header (absent in prod) |
| `X-AspNet-Version` response header | HTTP Header | `X-AspNet-Version: 4.x` | Definitive for classic ASP.NET; absent in Core (note: no Core version in headers) |
| `__RequestVerificationToken` hidden input | HTML | `<input name="__RequestVerificationToken" type="hidden" value="...">` | Definitive — ASP.NET anti-forgery system |
| `.AspNetCore.Session` cookie | HTTP Cookie | `AspNetCore.Session=<value>` | Definitive — ASP.NET Core session cookie |
| `.AspNetCore.Identity.Application` cookie | HTTP Cookie | Identity cookie name | Definitive — ASP.NET Core Identity |
| `.AspNetCore.OpenIdConnect.*` cookies | HTTP Cookie | OIDC protocol cookies | Definitive — OpenID Connect authentication |
| `Error.razor` or MVC error view in stack trace | HTML/Stack | `Error.cshtml`, `Error.cshtml.cs` | High — Razor Pages error handling |
| `Microsoft.AspNetCore` namespaces in stack traces | Stack trace | Full namespace in exception | Definitive when present |
| `ApplicationInsights` in page source | HTML | `applicationinsights.js` script tag | High — Azure Application Insights SDK |
| `UseDeveloperExceptionPage()` in config | Stack trace | Development-only middleware | High — dev mode detection |
| `dotnet-collect` in traces | Trace/Log | `dotnet-trace` diagnostic patterns | Medium — .NET diagnostic tooling |

**Version extraction (bash):**

```bash
# Version is NOT in HTTP headers for ASP.NET Core — check in other ways:
# Check for .csproj file path hints in error messages
curl -s https://target.example.com/nonexistent-path-abc/ | grep -i 'aspnetcore\|dotnet'

# Check for SDK version hints in swagger docs
curl -s https://target.example.com/swagger/v1/swagger.json | grep -i 'info\|version' | head -10

# Check Program.cs /.csproj if accessible (rare, but sometimes served)
curl -s https://target.example.com/Program.cs 2>/dev/null | head -20
curl -s https://target.example.com/appsettings.json 2>/dev/null | head -20

# .NET version in server header or via OPTIONS request
curl -I https://target.example.com/ 2>/dev/null | grep -i 'server\|kestrel'
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/` | GET | Varies | Application home page |
| `/Health` or `/health` | GET | Usually public | Health check endpoint; built-in `Microsoft.Extensions.Diagnostics.HealthChecks` |
| `/swagger/` | GET | Varies | Swagger UI if Swashbuckle is installed |
| `/swagger/v1/swagger.json` | GET | Varies | OpenAPI 3 spec; full API inventory |
| `/api/` | GET | Varies | API root; convention but not guaranteed at this path |
| `/api/{controller}` | GET/POST | Varies | REST API controllers |
| `/api/{controller}/{id}` | GET/PUT/DELETE | Varies | REST resource endpoints |
| `/Error` | GET | None | Error handler endpoint (when UseExceptionHandler configured) |
| `/Account/Login` | GET/POST | None / Credentials | ASP.NET Core Identity login |
| `/Account/Register` | GET/POST | None / Credentials | ASP.NET Core Identity registration |
| `/Account/Manage` | GET | Authenticated user | Identity account management |
| `/Areas/Identity/` | GET | Varies | Identity UI Razor Pages |
| `/SignalR/hubs` | GET/POST | WebSocket upgrade | SignalR hub endpoint |
| `/hangfire` | GET | Requires dashboard config | Hangfire dashboard if installed |
| `/healthchecks-ui` | GET | Requires config | Health checks UI if AspNetCore.HealthChecks.UI installed |
| `/metrics` | GET | Varies | Prometheus metrics if prometheus-net is installed |
| `.well-known/openid-configuration` | GET | None | OIDC discovery document |
| `/.well-known/jwks` | GET | None | JSON Web Key Set for JWT validation |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `appsettings.json` (server-side) | Not accessible remotely | DB connections, secrets, logging config |
| `appsettings.Development.json` (server-side) | Not accessible remotely | Dev-specific overrides including secrets |
| `Program.cs` (server-side) | Not accessible remotely | DI container, middleware pipeline, `builder.Services` configuration |
| `launchSettings.json` (server-side) | Not accessible remotely | Development profiles, URLs, environment variables |
| `/swagger/v1/swagger.json` | HTTP GET (if public) | Full OpenAPI spec with version info in `info` object |
| `/health` response body | HTTP GET | Health check status, may include component details |
| `/ConfigurationSchema.json` | HTTP GET (if middleware exposes it) | JSON schema for app configuration |
| `.env` file (if served statically) | Direct file access | Environment variables; sometimes exposed on Azure App Service |

**Extract config hints from swagger.json:**

```bash
# Get full API inventory and version from OpenAPI spec
curl -s https://target.example.com/swagger/v1/swagger.json | python3 -m json.tool | head -50

# Look for version in the info object
curl -s https://target.example.com/swagger/v1/swagger.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('info',{}).get('version','not found'))"
```

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| ASP.NET Core Identity cookie | `.AspNetCore.Identity.Application` cookie | Default cookie name for Identity; HttpOnly + Secure |
| Session cookie | `.AspNetCore.Session` cookie | Distributed session; may be Redis, SQL, or in-memory |
| JWT Bearer token | `Authorization: Bearer <jwt>` header | `AddAuthentication().AddJwtBearer()` configured |
| API Key | `X-Api-Key` header or query param | Custom middleware or `AddApiKey()` |
| Windows Auth (Kerberos/NTLM) | `Negotiate` or `NTLM` in headers | `AddNegotiate()` on Windows/IIS |
| OAuth2 / OIDC | `.AspNetCore.OpenIdConnect.*` cookies | `AddOpenIdConnect()` social login |
| Azure AD | `Bearer` token + `login.microsoftonline.com` | `AddMicrosoftIdentityWebApi()` |
| Antiforgery token | `__RequestVerificationToken` form field | Required for all non-GET form posts; `X-XSRF-TOKEN` header alternative |

**Obtaining antiforgery token for write operations:**

```bash
# Step 1: GET the page to retrieve the token
curl -sc /tmp/cookies.txt https://target.example.com/api/resource/form-page

# Step 2: extract the token from the response
TOKEN=$(curl -sb /tmp/cookies.txt -s https://target.example.com/api/resource/form-page \
  | grep -oP '__RequestVerificationToken[^>]*value="[^"]*"' \
  | grep -oP 'value="\K[^"]+')

# Step 3: POST with token in header and cookie
curl -sb /tmp/cookies.txt \
  -H "RequestVerificationToken: $TOKEN" \
  -X POST https://target.example.com/api/resource \
  -H "Content-Type: application/json" \
  -d '{"field":"value"}'
```

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `/js/site.js` | Default ASP.NET Core Razor site JavaScript |
| `/lib/jquery/dist/jquery.js` | jQuery from built-in libman packages |
| `/lib/bootstrap/dist/js/bootstrap.js` | Bootstrap JS from libman |
| `/js/{bundle}.js` | Custom bundled JS (Vite, Webpack, or ASP.NET's built-in bundler) |
| `/css/{bundle}.css` | Bundled stylesheets |
| `/node_modules/.package-lock.json` | Node.js package manager lock file (if Vite/Webpack used) |
| `/wwwroot/_content/` | Razor class library (RCL) static assets |
| `/dist/{hash}.js` | Vite production build output |
| `/build/{hash}.js` | Webpack production build output |
| `/_framework/` | Blazor WebAssembly framework assemblies |
| `/_content/` | Blazor component library static assets |
| `/_blazor` | Blazor Server WebSocket connection |

## 6. Source Map Patterns

ASP.NET Core does not generate source maps natively. Source maps appear only if a front-end build tool (Vite, Webpack, esbuild) is configured.

**Where to look:**

```bash
# Check for source maps alongside known JS files
curl -I https://target.example.com/js/site.js.map 2>/dev/null

# Check Vite manifest
curl -s https://target.example.com/distmanifest.json 2>/dev/null

# Check webpack manifest
curl -s https://target.example.com/build/manifest.json 2>/dev/null

# Check Blazor WASM source maps (if applicable)
curl -I https://target.example.com/_framework/wasm/dotnet.js.map 2>/dev/null
```

## 7. Common Plugins & Extensions

| Package | API it adds | Detection signal |
|---------|-------------|------------------|
| Swashbuckle.AspNetCore | `/swagger/`, `/swagger/v1/swagger.json` | Swagger UI and OpenAPI spec |
| NSwag | `/swagger/`, `/swagger/v2/swagger.json` | Alternative Swagger/OpenAPI generation |
| ASP.NET Core Identity | `/Account/Login`, `/Account/Register`, `.AspNetCore.Identity.Application` cookie | Identity UI routes and cookie |
| IdentityServer / Duende IdentityServer | `/connect/authorize`, `/.well-known/openid-configuration` | OAuth2/OIDC server endpoints |
| Hangfire | `/hangfire` dashboard | Background job processing dashboard |
| Polly | No HTTP surface | Resilience patterns; no direct detection |
| Serilog | No HTTP surface (logs) | Structured logging library; no surface |
| FluentValidation | No HTTP surface | Validation; no surface |
| AutoMapper | No HTTP surface | Object mapping; no surface |
| MediatR | No HTTP surface | Mediator pattern; no surface |
| prometheus-net.AspNetCore | `/metrics` | Prometheus metrics endpoint |
| AspNetCore.HealthChecks.UI | `/healthchecks-ui` | Health checks visual dashboard |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `/swagger/v1/swagger.json` | Full OpenAPI spec — all routes, models, parameters | Public if Swashbuckle is not locked down |
| `/swagger/` | Interactive Swagger UI | Public if auth not configured on Swagger |
| `/health` | Health check status | Often public; shows component-level health |
| `/healthchecks-ui` | Visual health dashboard | Only if health checks UI package is installed |
| `/metrics` | Prometheus-format metrics | Only if prometheus-net installed and exposed |
| `/.well-known/openid-configuration` | OIDC discovery document | Only if OpenID Connect is configured |
| `/.well-known/jwks` | JSON Web Key Set | Public JWT signing keys |
| `/Error` | Error details | May expose stack trace in Development env |
| `web.config` (IIS deployments) | IIS configuration | Sometimes accessible; may expose handler mappings |

## 9. Probe Checklist

- [ ] `GET /` — Retrieve home page; check for ASP.NET Core signals (razor views, antiforgery tokens, identity links)
- [ ] `GET /Health` — Is health check endpoint present? (200 = health checks configured)
- [ ] `GET /swagger/` — Is Swagger UI present? (200 = Swashbuckle or NSwag installed; may require auth)
- [ ] `GET /swagger/v1/swagger.json` — Retrieve OpenAPI spec; full API inventory with routes, models, versions
- [ ] `GET /Error` — Check error handler; may expose stack trace in Development environment
- [ ] Check response headers for `Server: Kestrel` — confirms ASP.NET Core with Kestrel server
- [ ] Check for `__RequestVerificationToken` in any HTML form — confirms anti-forgery (MVC or Razor Pages)
- [ ] Check cookies for `.AspNetCore.Session`, `.AspNetCore.Identity.Application`, or `.AspNetCore.OpenIdConnect.*` — confirms authentication mechanism
- [ ] `GET /hangfire` — Is Hangfire dashboard exposed? (may require auth — try without credentials first)
- [ ] `GET /healthchecks-ui` — Is health checks UI present?
- [ ] `GET /metrics` — Is Prometheus metrics endpoint exposed?
- [ ] `GET /.well-known/openid-configuration` — Is OIDC discovery endpoint present? (OAuth2/OIDC server)
- [ ] `GET /.well-known/jwks` — Is JWKS endpoint present? (JWT validation public keys)
- [ ] `GET /SignalR/hubs` — Probe for SignalR WebSocket endpoint
- [ ] Check for `X-SourceFiles` header — development mode indicator
- [ ] Scan HTML source for `applicationinsights.js` — Azure Application Insights integration
- [ ] Look for `/_framework/` paths — Blazor WebAssembly detection
- [ ] `GET /api/` — Probe for API root; may be 404 or return API JSON root

## 10. Gotchas

- **No version header in production.** ASP.NET Core does NOT expose its version in HTTP headers. Unlike classic ASP.NET (`X-AspNet-Version`), Core omits version headers. Version must be inferred from Swagger/OpenAPI spec, error traces, or `package` references in the deployed application.

- **Kestrel is the default server but not exclusive.** Applications may run behind IIS (via IISModule for AspNetCoreModuleV2), Nginx, or Apache. A missing `Server: Kestrel` header does not mean absence of ASP.NET Core — the app could be behind a reverse proxy. Check for `X-SourceFiles` (dev-only) or look for `__RequestVerificationToken` in forms.

- **Anti-forgery token is definitive but may be absent.** `__RequestVerificationToken` appears in all forms POSTed to MVC or Razor Pages endpoints. SPAs using `fetch` with AJAX may or may not include it depending on implementation. Its absence does not rule out ASP.NET Core — check cookies and headers instead.

- **Razor Pages and MVC controllers coexist.** A single application may use both `@page` Razor Pages and `[ApiController]` MVC controllers. API endpoints live under `/api/` by convention (and `[Route("api/...")]`), while Razor Pages use `/Pages/` or root paths.

- **Blazor adds distinct paths.** Blazor WebAssembly served from `/wwwroot/` adds `/_framework/` and `/_content/` paths. Blazor Server uses `/_blazor` WebSocket endpoint. If either is detected, the full Blazor component library becomes relevant.

## 11. GitHub Code Search Patterns

### Framework-Specific Queries

| Search Query | What it finds |
|--------------|---------------|
| `language:c# [ApiController]` | ASP.NET Core Web API controller definitions |
| `[Route("api/` language:c# | API route attribute definitions |
| `AddSwaggerGen` language:c# | Swashbuckle/Swagger configuration |
| `AddAuthentication` language:c# | Authentication configuration |
| `AddDbContext` language:c# | Entity Framework Core context registration |

### Example Queries for ASP.NET Core

```bash
# Search for Web API controller patterns
site:github.com "ASP.NET Core" "[ApiController]" "[Route" language:c#

# Search for Swagger configuration
site:github.com "AddSwaggerGen" "SwaggerInfo" language:c#

# Search for authentication patterns
site:github.com "AddAuthentication" "AddJwtBearer" language:c#

# Search for Entity Framework Core patterns
site:github.com "AddDbContext" "OnConfiguring" language:c#

# Search for health check configuration
site:github.com "AddHealthChecks" language:c#
```

## 12. Framework-Specific Google Dorks

### Discovery Queries

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:/swagger/` | ASP.NET Core API documentation |
| `site:{domain} inurl:/api/` | ASP.NET Core REST API endpoints |
| `site:{domain} inurl:/Account/Login` | ASP.NET Core Identity login pages |
| `site:{domain} inurl:/hangfire` | Hangfire dashboard exposed |
| `site:{domain} inurl:.well-known/openid-configuration` | OpenID Connect server |

### Complete Dork List for ASP.NET Core

```
# API endpoints
site:{domain} inurl:/api/
site:{domain} inurl:/swagger/
site:{domain} inurl:/swagger/v1/swagger.json

# Framework-specific paths
site:{domain} inurl:/Account/Login
site:{domain} inurl:/Account/Register
site:{domain} inurl:/hangfire
site:{domain} inurl:/healthchecks-ui

# Configuration files (if served)
site:{domain} filetype:json "appsettings"
site:{domain} filetype:xml "web.config"

# Documentation/leaks
site:{domain} "AspNetCore" "swagger"
site:{domain} "openid-configuration" ".well-known"

# Admin/debug paths
site:{domain} inurl:/swagger/
site:{domain} inurl:/health
site:{domain} inurl:/hangfire
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
| Vite | `{name}-[hash].js.map` | Vite manifest `vite-manifest.json` |
| Webpack | `{name}-[hash].js.map` | Check `sourceMappingURL` comment |
| esbuild | `{name}.js.map` | Check `sourceMappingURL` comment |
| Blazor WASM | `/_framework/wasm/*.wasm.map` | If Blazor WASM is used |

### Tech Stack → API Pattern Mapping

| Framework | Common API Patterns |
|-----------|---------------------|
| ASP.NET Core | `/api/*`, `/swagger/*`, `/health`, `/.well-known/*` |
| Spring Boot | `/actuator/*`, `/api/*`, `/swagger-ui/` |
| Django | `/api/*`, `/admin/*`, `/accounts/*` |
| Laravel | `/api/*`, `/livewire/*`, `/sanctum/csrf-cookie` |
| Next.js | `/api/*`, `/_next/data/*` |
| Express | `/api/*`, `/auth/*`, `/health` |

### Email Naming Convention Analysis

```bash
# Predict internal subdomains from email patterns:
# john.doe@example.com → mail.example.com, smtp.example.com
# first.last@ → internal.example.com
# firstinitial+last@ → owa.example.com
```