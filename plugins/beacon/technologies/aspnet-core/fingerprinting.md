---
framework: aspnet-core
version: "8.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# ASP.NET Core 8.x — Fingerprinting Guide

## Framework Overview

ASP.NET Core is a cross-platform, high-performance framework for building modern web applications and APIs using C#. It is the evolution of classic ASP.NET, rebuilt from the ground up to be modular, cloud-ready, and runnable on Windows, Linux, and macOS. This guide covers fingerprinting techniques for ASP.NET Core 8.x applications.

## Fingerprinting Patterns

### 1. HTTP Response Headers

| Header | Value Example | Confidence | Notes |
|--------|--------------|------------|-------|
| `Server` | `Kestrel` | High | Default ASP.NET Core server; may be hidden behind reverse proxy |
| `X-SourceFiles` | `X-SourceFiles: <path>` | Definitive (dev only) | Development-only header; absent in production |
| `X-AspNet-Version` | `4.8` | Definitive (Classic ONLY) | NOT present in ASP.NET Core — signals classic .NET Framework |
| `X-AspNetMvc-Version` | `5.x` | Definitive (Classic ONLY) | NOT present in Core |
| `X-Powered-By` | `ASP.NET` | Low | Generic; may be suppressed |
| `Cache-Control` | `no-cache, no-store` | Low | Generic; common across many frameworks |

**Probe:**
```bash
curl -I https://target.example.com/ 2>/dev/null | grep -iE 'server|x-|kestrel|aspnet'
```

### 2. Cookie Signatures

| Cookie Name | Value Pattern | Confidence | Notes |
|-------------|--------------|------------|-------|
| `.AspNetCore.Session` | Base64-encoded session data | Definitive | ASP.NET Core distributed session |
| `.AspNetCore.Identity.Application` | Encrypted identity data | Definitive | ASP.NET Core Identity authentication |
| `.AspNetCore.OpenIdConnect.Nonce.*` |Nonce for OIDC flow | Definitive | OpenID Connect authentication |
| `.AspNetCore.OpenIdConnect.Correlation.*` | OIDC correlation cookie | Definitive | OpenID Connect correlation |
| `ARRAffinity` / `ARRAffinitySameSite` | Azure App Service cookie | Medium | Azure hosting indicator; not framework-specific |
| `ApplicationRequestId` | Request correlation ID | Medium | May appear in Azure front-door |

**Probe:**
```bash
curl -Is https://target.example.com/ 2>/dev/null | grep -i 'set-cookie' | grep -iE 'aspnetcore|requestverification'
```

### 3. Anti-Forgery Token

| Signal | Pattern | Confidence | Notes |
|--------|---------|------------|-------|
| `__RequestVerificationToken` | Hidden input with base64 token value | Definitive | Present in ALL forms posting to MVC or Razor Pages endpoints |
| `X-XSRF-TOKEN` | Request header with token | Definitive (SPA context) | Angular/Vue sends via header instead of form field |

**Probe:**
```bash
# Fetch a form page and look for the token
curl -s https://target.example.com/ | grep -o '__RequestVerificationToken[^>]*'
```

### 4. Error Page Signatures

| Error Type | Content | Confidence | Notes |
|------------|---------|------------|-------|
| 404 with StatusCode page | `StatusCode: 404` in HTML | High | ASP.NET Core default status code page |
| 500 with Exception details | `Microsoft.AspNetCore` namespaces in stack trace | Definitive | Development error page; `UseDeveloperExceptionPage()` |
| 404 with Endpoint information | `No matching route` message | High | ASP.NET Core routing failure |
| Error.razor | `Error.cshtml` / `Error.cshtml.cs` references | Definitive | Razor Pages error handling |
| System.Exception | Full exception type name in HTML | Definitive | Unhandled exception in dev mode |

### 5. Blazor-Specific Fingerprints

| Signal | Pattern | Confidence | Notes |
|--------|---------|------------|-------|
| `/_framework/` path | WebAssembly framework assemblies served | Definitive | Blazor WebAssembly deployment |
| `/_content/` path | Blazor component library static assets | Definitive | Blazor component library (RCL) |
| `/_blazor` WebSocket | Blazor Server real-time connection | Definitive | Blazor Server (WebSocket upgrade) |
| `blazor.webassembly.js` in HTML | Script tag for WASM boot | Definitive | Blazor WebAssembly |
| `blazor.server.js` in HTML | Script tag for Server connection | Definitive | Blazor Server |

### 6. Version Detection

ASP.NET Core does NOT expose version information in HTTP response headers. Use these methods:

**Method 1: Swagger/OpenAPI spec**
```bash
# Version is in the OpenAPI info object
curl -s https://target.example.com/swagger/v1/swagger.json | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('Version:', d.get('info', {}).get('version', 'not found'))
print('Title:', d.get('info', {}).get('title', 'not found'))
"
```

**Method 2: Blazor .dll version**
```bash
# If Blazor WebAssembly, check dotnet.wasm version
curl -sI https://target.example.com/_framework/wasm/dotnet.wasm 2>/dev/null | grep -i 'etag\|last-modified'
```

**Method 3: Error page stack traces**
```bash
# Force an error in development mode
curl -s https://target.example.com/?param=%7B%7D | grep -oP 'ASP.NET Core \d+\.\d+'
```

**Method 4: HTML source inspection**
```bash
# Look for versioned script tags or links
curl -s https://target.example.com/ | grep -oP '/js/[^\.]+\.js' | head -5
curl -s https://target.example.com/ | grep -oP '/css/[^\.]+\.css' | head -5
```

## Confidence Level Definitions

| Level | Meaning | When to use |
|-------|---------|-------------|
| **Definitive** | Cannot be produced by any other framework | Use as primary confirmation |
| **High** | Very strong signal; unlikely false positive | Use as strong evidence |
| **Medium** | Present in many frameworks or common configuration | Use as supporting evidence |
| **Low** | Generic signal; many possible explanations | Use as hint only |

## Quick Fingerprinting Commands

```bash
# Quick check: headers
curl -I https://target.example.com/ 2>/dev/null

# Quick check: cookies and Kestrel header
curl -Is https://target.example.com/ 2>/dev/null | grep -iE 'server|aspnetcore|set-cookie'

# Trigger 404 error
curl -s https://target.example.com/does-not-exist-abc/ | grep -iE 'statuscode|aspnetcore|kestrel'

# Check for antiforgery token in home page
curl -s https://target.example.com/ | grep -o '__RequestVerificationToken[^>]*'

# Probe Swagger
for path in "/swagger/" "/swagger/v1/swagger.json" "/swagger/v2/swagger.json"; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "https://target.example.com$path")
  echo "GET $path → $status"
done

# Check Blazor paths
for path in "/_framework/wasm/dotnet.wasm" "/_blazor" "/_content/"; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "https://target.example.com$path")
  echo "GET $path → $status"
done
```

## False Positive Mitigation

- **`Server: Kestrel` is strong but not exclusive.** Kestrel is ASP.NET Core's default, but some reverse proxy setups strip or modify the Server header. Always combine with cookie patterns or antiforgery tokens before concluding.
- **`__RequestVerificationToken` is definitive for MVC or Razor Pages** but may be absent in pure Web API applications that don't use view rendering. Check for cookies instead.
- **ASP.NET Core Identity cookie names are definitive** but a site may use custom authentication without Identity, making the Identity-specific cookies absent. Check for `.AspNetCore.Session` instead.
- **Classic ASP.NET (4.x) vs Core:** Classic ASP.NET produces `X-AspNet-Version` and `X-AspNetMvc-Version` headers, which are NEVER present in Core. If those headers appear, the target is NOT ASP.NET Core.

## Technology Stack Pairings

| Technology | Detection Method | Confidence |
|------------|-----------------|------------|
| ASP.NET Core Identity | `.AspNetCore.Identity.Application` cookie | Definitive |
| Razor Pages | `__RequestVerificationToken` in forms | Definitive |
| Entity Framework Core | `/swagger/` may show EF models | Medium |
| Azure AD authentication | `login.microsoftonline.com` in OpenID config | Definitive |
| Blazor WebAssembly | `/_framework/` paths | Definitive |
| Blazor Server | `/_blazor` WebSocket | Definitive |
| Swashbuckle (Swagger) | `/swagger/` routes | Definitive |
| Hangfire | `/hangfire` dashboard | Definitive |
| Serilog | No HTTP surface | N/A |
| Polly | No HTTP surface | N/A |

## Changelog

- 2026-05-11: Initial ASP.NET Core 8.x tech pack with comprehensive API surface, authentication patterns, and Blazor detection