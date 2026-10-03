# Adobe Experience Manager (AEM) Detection

This guide covers fingerprinting and API surface mapping for Adobe Experience Manager (AEM) applications.

## Framework Summary
- **Name**: Adobe Experience Manager (AEM)
- **Type**: Enterprise CMS / Digital Asset Management
- **Popularity**: Leading enterprise CMS with large market presence
- **Website**: [https://business.adobe.com/products/experience-manager/adobe-experience-manager.html](https://business.adobe.com/products/experience-manager/adobe-experience-manager.html)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| AEM HTML comment | HTML comment | `<!-- CQ -->`, `<!-- DAM -->`, `<!-- AEM -->` |
| AEM selectors | URL patterns | `.html`, `.json`, `.infinity`, `.model.json` |
| CRXDE Lite | Path discovery | `/crx/de/index.jsp` |
| AEM login page | URL pattern | `/libs/granite/core/content/login.html` |
| Sling Servlets | Response headers | `Sling` or `Adobe` in headers |
| AEM assets | Path patterns | `/content/dam/`, `/assets/` |
| AEM version signature | HTML | Version-specific signatures in HTML comments |

### Technology Stack
AEM is commonly paired with:
- Apache Sling (content framework)
- Jackrabbit (JCR repository)
- Oak (modern content repository)
- Sightly / HTL (templating)
- Java servlets and OSGi bundles
- Dispatcher (Apache mod_cache)
- AEM Forms, AEM Assets, AEM Sites

## API Surface Discovery
AEM exposes:
- Sling API (`/api/assets`, `/api/resources`)
- AEM Forms API
- AEM Workflow APIs
- DAM API (`/api/assets`)
- Replication APIs
- User Management APIs
- Content Fragments API

## Security Considerations
- AEM authentication uses Adobe IMS or local accounts
- CSRF protection via tokens
- CORS configuration required
- Dispatcher caching for performance
- IP allowlisting for admin access
- SSL/TLS required for production

## Version Detection
- Check HTML comments for version
- Check `/system/console/about` for AEM version
- Analyze response headers for `Sling` and `Adobe` signatures
- Look for version-specific endpoints

## Resources
- [AEM Documentation](https://experienceleague.adobe.com/docs/experience-manager-65.html)
- [AEM Developer Documentation](https://experienceleague.adobe.com/docs/experience-manager-65/developing/home.html)
- [Sling API Documentation](https://sling.apache.org/documentation.html)
- [AEM Assets API](https://experienceleague.adobe.com/docs/experience-manager-65/assets/extending/mac-api-assets.html)