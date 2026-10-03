# Umbraco Detection

This guide covers fingerprinting and API surface mapping for Umbraco applications.

## Framework Summary
- **Name**: Umbraco
- **Type**: Open-source CMS / .NET CMS
- **Popularity**: Popular open-source CMS especially in Europe
- **Website**: [https://umbraco.com](https://umbraco.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| Umbraco cookies | Cookie | `UMB_UPDCHK` or `UMB_SESSION` |
| HTML comment | HTML | `<!--Umbraco-->` |
| `/umbraco/` path | URL | Umbraco backoffice |
| Umbraco JavaScript | JS | `umb` global or `Umbraco` object |
| Request verification | Form | `__CallBack` parameter |
| Content node IDs | HTML | `data-umb-` attributes |

### Technology Stack
Umbraco is commonly paired with:
- ASP.NET Web Forms / Razor
- .NET Framework / .NET Core
- SQL Server / SQLite / PostgreSQL
- MVC pattern
- Umbraco Forms
- Umbraco Deploy
- Umbraco Cloud

## API Surface Discovery
Umbraco exposes:
- Umbraco API (backoffice)
- Content Delivery API
- Member API
- Forms API
- Media API
- Surface Controllers

## Security Considerations
- Umbraco uses `__CallBack` and `__RequestVerificationToken`
- Backoffice authentication via Umbraco identity
- Member authentication with members area
- HTTPS required for admin areas
- IP allowlisting possible

## Resources
- [Umbraco Documentation](https://docs.umbraco.com/)
- [Umbraco API Reference](https://apidoc.umbraco.com/)
- [Umbraco Developer Documentation](https://docs.umbraco.com/developer/)
- [Umbraco Cloud Documentation](https://docs.umbraco.com/umbraco-cloud/)