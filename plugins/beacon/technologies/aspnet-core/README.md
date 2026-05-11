---
framework: aspnet-core
version: "8.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# ASP.NET Core Framework Detection

## Framework Summary
- **Name**: ASP.NET Core
- **Type**: Web application framework / Web API framework
- **Language**: C# (.NET 8)
- **Popularity**: Dominant enterprise framework on Windows; growing on Linux
- **Website**: [https://dotnet.microsoft.com/apps/aspnet](https://dotnet.microsoft.com/apps/aspnet)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| `Server: Kestrel` header | HTTP response | `curl -I` |
| `.AspNetCore.Session` cookie | HTTP cookie | Response Set-Cookie header |
| `.AspNetCore.Identity.Application` cookie | HTTP cookie | ASP.NET Core Identity auth |
| `__RequestVerificationToken` hidden input | HTML form field | Page source |
| `X-SourceFiles` header | HTTP response | Dev-only; absent in prod |
| `/_framework/` path | Blazor WASM assets | HTTP probe |
| `/_blazor` WebSocket | Blazor Server | Upgrade header probe |
| `/swagger/` routes | API documentation | HTTP probe |

### Technology Stack
ASP.NET Core is commonly paired with:
- .NET 8 runtime (LTS)
- Entity Framework Core for ORM
- ASP.NET Core Identity for authentication
- Razor Pages or MVC controllers for web UI
- Blazor WebAssembly or Blazor Server for SPAs
- Azure App Service, IIS, or Kestrel behind reverse proxy
- Azure AD / Entra ID for cloud authentication

## Fingerprint Probes

```bash
# Check for Kestrel server and ASP.NET Core cookies
curl -I https://target.example.com/ 2>/dev/null | grep -iE 'server|kestrel|aspnetcore|set-cookie'

# Trigger error page
curl -s https://target.example.com/does-not-exist/ | grep -iE 'statuscode|aspnetcore|kestrel|exception'

# Check for antiforgery token
curl -s https://target.example.com/ | grep -o '__RequestVerificationToken[^"]*"'

# Probe Swagger
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/swagger/v1/swagger.json

# Check Blazor paths
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/_framework/wasm/dotnet.wasm
```

## Security Considerations
- `UseDeveloperExceptionPage()` leaks stack traces in dev
- Hangfire dashboard often exposed without auth
- Swagger may expose full API schema publicly
- Anti-forgery tokens required for all form posts

## Resources
- [ASP.NET Core Official Documentation](https://docs.microsoft.com/aspnet/core/)
- [ASP.NET Core GitHub](https://github.com/dotnet/aspnetcore)
- [Swashbuckle / Swagger for ASP.NET Core](https://github.com/domaindrivendev/Swashbuckle.AspNetCore)
- [ASP.NET Core Identity](https://docs.microsoft.com/aspnet/core/security/authentication/identity)
- [.NET Official Site](https://dotnet.microsoft.com/)