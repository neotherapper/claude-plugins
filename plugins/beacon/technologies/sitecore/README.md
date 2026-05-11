# Sitecore Detection

This guide covers fingerprinting and API surface mapping for Sitecore applications.

## Framework Summary
- **Name**: Sitecore
- **Type**: Enterprise CMS / Digital Experience Platform
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
| Sitecore device detectors | HTML | `sc_device` patterns |
| Layout service | API | `/sitecore/api/layout/render/*` |
| Item API | API | `/sitecore/api/items/*` |

### Technology Stack
Sitecore is commonly paired with:
- ASP.NET Web Forms / MVC
- .NET Framework / .NET Core
- SQL Server / NoSQL
- Solr / Azure Search
- Sitecore Experience Platform (XP)
- Sitecore Experience Commerce (XC)
- Glass.Mapper / TDS
- Sitecore JavaScript Services (JSS)

## API Surface Discovery
Sitecore exposes:
- Layout Service API
- Item Service API
- Experience Analytics APIs
- Content Testing APIs
- Commerce APIs (if XC)
- Personalization Rules API
- Web API endpoints

## Security Considerations
- Sitecore uses `__RequestVerificationToken` for CSRF
- Authentication via Sitecore Identity Server
- Virtual users and extranet users
- Role-based access control
- SSL required for admin areas
- IP restrictions possible

## Version Detection
- Check HTML comments for version
- Check Sitecore admin pages
- Analyze `sitecore` root path responses
- Look for version-specific endpoints

## Resources
- [Sitecore Documentation](https://doc.sitecore.com/)
- [Sitecore Developer Network](https://developers.sitecore.com/)
- [Sitecore API Reference](https://doc.sitecore.com/xp/en/developer/)
- [Sitecore JSS Documentation](https://doc.sitecore.com/xp/en/developer/tools/sitecore-javascript-services.html)