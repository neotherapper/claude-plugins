# Sitecore Detection

This guide covers fingerprinting and API surface mapping for Sitecore applications.

## Framework Summary
- **Name**: Sitecore
- **Type**: Enterprise CMS / Digital Experience Platform
- **Current Versions**: XP 10.4 (on-prem), XM Cloud (cloud), Headless Services 22.x, SitecoreAI
- **Popularity**: Leading enterprise CMS for large organizations
- **Website**: [https://www.sitecore.com](https://www.sitecore.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| Sitecore cookies | Cookie | `SC_ANALYTICS` cookie |
| HTML comment | HTML | `<!-- Sitecore -->` |
| `/sitecore/` path | URL | Sitecore shell and admin |
| `sc_site` query param | Query | Sitecore context site |
| `sc_mode` query param | Query | Experience Editor mode |
| `data-sc-*` attributes | HTML | Component/item IDs |
| `edge.sitecorecloud.io` | Domain | Experience Edge/XM Cloud |
| Layout service | API | `/sitecore/api/layout/render/*` |
| Item API | API | `/sitecore/api/items/*` |
| JSS endpoints | API | `/-/jss/`, `/-/api/items/` |
| Content SDK | HTML | `data-content-sdk-*` attributes |
| __NEXT_DATA__ sitecore | JS | JSS + Next.js inline data |

### Technology Stack
Sitecore is commonly paired with:
- ASP.NET Web Forms / MVC / .NET Core
- .NET Framework (.NET 4.8) / .NET 6/8 (modern)
- SQL Server (on-prem) / Azure SQL (PaaS)
- Solr / Azure Search / SearchStax SolrCloud
- Redis caching (distributed cache)
- Sitecore Experience Platform (XP)
- Sitecore XM Cloud (cloud-native, headless)
- Sitecore Experience Edge (CDN + GraphQL delivery)
- Sitecore Experience Commerce (XC)
- Sitecore Content Hub (DAM, CMP, MRM)
- SitecoreAI (AI-powered content + personalisation)
- Glass.Mapper / TDS / Unicorn (serialization)
- Sitecore JavaScript Services (JSS)
- Sitecore Content SDK (newer App Router)
- Sitecore SXA (Experience Accelerator)
- Docker / Kubernetes (modern deployments)
- Sitecore Identity Server (OAuth/OpenID Connect)
- Helix design principles / modular architecture

## Product Line Detection

### On-prem (XP 10.x)
- Look for `/sitecore/` paths, `SC_ANALYTICS` cookies
- Layout Service at `/sitecore/api/layout/render/`
- Classic Sitecore shell at `/sitecore/shell/`
- Sitecore Identity Server for auth

### XM Cloud (cloud-hosted, 2022+)
- Content managed in cloud portal at `portal.sitecorecloud.io`
- Delivery via Experience Edge GraphQL
- No `/sitecore/shell/` accessible from public CD
- JSS + Next.js is common
- `edge.sitecorecloud.io` in GraphQL endpoint

### Headless Services (22.x)
- Layout Service, Dictionary, Media Handler APIs
- Import Service for JSS app deployment
- GraphQL endpoints (on-prem or Edge)
- ASP.NET Rendering SDK (legacy) or JSS

### SitecoreAI (2025+)
- AI-powered content creation
- Forms with AI assistance
- Personalisation and segmentation
- Integrated with XM Cloud

## API Surface Discovery
Sitecore exposes:
- Layout Service API (REST + GraphQL)
- Item Service API (OData-style)
- Experience Edge APIs (Delivery, Token, Admin)
- Experience Analytics APIs
- Content Testing APIs
- Commerce APIs (if XC)
- Personalization Rules API
- Web API endpoints (custom)
- JSS APIs (dictionary, tracking, forms, import)
- Content Hub APIs (DAM, CMP)
- Media Handler API
- Forms Service API

## Security Considerations
- Sitecore uses `__RequestVerificationToken` for CSRF
- Authentication via Sitecore Identity Server (OAuth/OIDC)
- Virtual users and extranet users
- Role-based access control (RBAC)
- SSL required for admin areas
- IP restrictions possible
- `sc_apikey` header/param for API auth
- JWT for Experience Edge admin APIs
- Deployment secret for JSS import (32+ char shared secret)
- Known CVEs: Remote code execution, SQL injection, path traversal (check CVE database)

## Version Detection
- Check HTML comments for version string (e.g. `Sitecore 10.4.0`)
- Check Sitecore admin pages (`/sitecore/shell`)
- Analyze `/sitecore/shell/sitecore.version.xml`
- Response headers for version hints
- Login page version string
- XM Cloud: check cloud portal or Edge endpoint
- JSS version via `package.json` patterns in bundles
- DLL version from error page paths (Sitecore.Kernel.dll)

## Resources
- [Sitecore Documentation](https://doc.sitecore.com/)
- [Sitecore Developer Portal](https://developers.sitecore.com/)
- [Sitecore XP 10.4 Developer Docs](https://doc.sitecore.com/xp/en/developers/104/)
- [Sitecore Headless Services Docs](https://doc.sitecore.com/xp/en/developers/hd/22/)
- [Sitecore JSS Documentation](https://doc.sitecore.com/xp/en/developers/hd/22/sitecore-headless-development/sitecore-javascript-services-sdk--jss-.html)
- [Sitecore Stack Exchange](https://sitecore.stackexchange.com/)
- [Sitecore MVP Directory](https://mvp.sitecore.com/)
- [Sitecore Downloads](https://developers.sitecore.com/downloads)
- [Sitecore Changelog](https://developers.sitecore.com/changelog)