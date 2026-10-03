# Optimizely (Episerver) Detection

This guide covers fingerprinting and API surface mapping for Optimizely (formerly Episerver) applications.

## Framework Summary
- **Name**: Optimizely (formerly Episerver)
- **Type**: Enterprise CMS / Digital Experience Platform
- **Popularity**: Leading enterprise CMS in Nordics and globally
- **Website**: [https://www.optimizely.com](https://www.optimizely.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| Episerver/Optimizely cookies | Cookie | `EPiServer` cookie |
| HTML comment | HTML | `<!--.episerver-->` |
| `/episerver/` path | URL | Episerver admin |
| Optimizely CMS path | URL | `/Util/` or `//episerver/` |
| Content Delivery API | API | `/api/episerver/v3/` |
| Content Management API | API | `/episerverapi/` |
| DXP indicators | Response | `.optimizely.com` or Azure |

### Technology Stack
Optimizely is commonly paired with:
- ASP.NET MVC / Razor Pages
- .NET Framework / .NET Core
- SQL Server / Azure SQL
- Azure App Service / DXP
- Elasticsearch
- OWIN authentication
- Find (Optimizely Search)

## API Surface Discovery
Optimizely exposes:
- Content Delivery API (CDA)
- Content Management API (CMA)
- Commerce API
- Forms API
- Personalization API
- Scheduled Content API

## Security Considerations
- Forms authentication with roles
- OAuth for API access
- CORS configuration required
- IP restrictions on DXP
- HTTPS enforced

## Resources
- [Optimizely Documentation](https://docs.optimizely.com/)
- [Optimizely Developer Documentation](https://docs.optimizely.com/developer)
- [Content Delivery API](https://docs.optimizely.com/content-cloud/v1.3.0/extending-the-ui/content-delivery-api)
- [Episerver API Reference](https://world.episerver.com/documentation/developer-guides/)