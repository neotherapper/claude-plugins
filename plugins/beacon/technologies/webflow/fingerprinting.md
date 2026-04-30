# Webflow Framework Fingerprinting Guide

## Framework Overview
Webflow is a visual web design platform that allows users to design, build, and launch responsive websites without writing code. It combines design tools with CMS and hosting capabilities, making it popular among designers, agencies, and businesses who want to create professional websites without traditional development.

## Fingerprinting Patterns

### 1. HTTP Headers
Webflow sites have distinctive headers:
```
X-Webflow-Route: [route-id]
Server: Webflow
X-Webflow-Site: [site-id]
X-Wf-Route: [route-info]
X-Wf-Site: [site-id]
```

### 2. Static File Patterns
Webflow has distinctive static asset patterns:
- `/js/webflow.js` - Webflow core JavaScript
- `/css/norm.css` - Webflow normalization CSS
- `/css/webflow.css` - Webflow core CSS
- `/[site-id].webflow.io/` - Default Webflow subdomain
- `/images/[filename].[hash].jpg` - Hashed image assets
- `/css/[site-name].css` - Site-specific CSS
- `/js/[site-name].js` - Site-specific JavaScript

### 3. HTML Meta Tags
Webflow sites typically include these meta tags:
```html
<meta property="webflow" content="[site-id]">
<meta name="generator" content="Webflow">
<meta name="theme-color" content="#[color]">
```

### 4. JavaScript Globals
Webflow exposes these global variables:
```javascript
window.Webflow = {
  site: {
    id: "[site-id]",
    name: "[site-name]"
  },
  env: "production",
  version: "[version]"
};
window.__wf_debug_config = [[...]];
Webflow.require('ix').then(function(ix) {...});
```

### 5. Common Routes
Webflow standard routes:
- `/` - Homepage
- `/[page-slug]` - Content pages
- `/collections/[collection-name]` - CMS collection pages
- `/collections/[collection-name]/[item-slug]` - Collection items
- `/api/v1/sites/[site-id]` - Webflow API
- `/api/v1/form/[form-id]` - Form submission API

### 6. API Endpoints
Webflow exposes multiple APIs:

**Webflow CMS API:**
- `/api/v1/sites/[site-id]/collections`
- `/api/v1/sites/[site-id]/collections/[collection-id]/items`
- `/api/v1/sites/[site-id]/forms`

**Site Management API:**
- `/api/v1/sites/[site-id]`
- `/api/v1/sites/[site-id]/publish`

**Form Submission API:**
- `/api/v1/form/[form-id]/submission`

### 7. Error Pages
Webflow error pages:
- **404**: Customizable 404 page with Webflow branding
- **500**: Server error page
- **502**: Bad gateway (CDN issues)
- **403**: Access denied

### 8. Version Fingerprinting
Detect Webflow version through:
- `webflow.js` file version
- `window.Webflow.version` global variable
- `/api/v1/sites/[site-id]` endpoint response
- Webflow dashboard version indicators
- Error pages may reveal version

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/js/
/css/
/images/
```

### 2. Common File Discovery
Look for these files:
```
/js/webflow.js
/css/webflow.css
/images/placeholder.img
```

### 3. Framework-Specific Endpoints
Check these Webflow-specific endpoints:
```
/js/webflow.js
/api/v1/sites/[site-id]
/collections/
```

## Security Considerations

### Common Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self' *.webflow.com
```

### Vulnerable Patterns
- Exposed API keys in client-side code
- Unprotected CMS API endpoints
- Missing security headers
- Insecure form submissions
- Unrestricted collection access
- Hardcoded site IDs in JavaScript
- Missing rate limiting on API endpoints
- Unsecured Webflow dashboard

## Technology Stack Integration

### Common Webflow Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| Webflow Designer | Visual design | Webflow-specific HTML classes |
| Webflow CMS | Content management | `/collections/` routes |
| Webflow Hosting | Website hosting | Webflow CDN patterns |
| Zapier/Zoho | Automation | Integration scripts |
| Google Analytics | Analytics | Tracking scripts |
| Custom Code | Functionality | Embedded JavaScript |
| Memberstack | Membership | Memberstack JS files |
| Foxy/Stripe | Payments | Payment scripts |

## Example Fingerprinting Commands

```bash
# Check Webflow headers
curl -I https://example.com

# Check Webflow JavaScript
curl -I https://example.com/js/webflow.js

# Extract site ID from meta tag
curl https://example.com | grep -oP 'content=\"\\K[a-zA-Z0-9]{8}'

# Check Webflow CMS API
curl -H "Authorization: Bearer [api-key]" https://api.webflow.com/sites/[site-id]

# Check for Webflow CSS
curl -I https://example.com/css/webflow.css
```

## False Positives
- Websites using similar visual builders
- Custom websites with similar asset patterns
- Websites using Webflow-like CDN patterns
- Sites that previously used Webflow but migrated
- Webflow templates used on other platforms

## Fingerprinting Tooling
- HTTP header analysis for Webflow-specific headers
- JavaScript global detection
- Meta tag analysis
- Static file pattern recognition
- API endpoint discovery
- CDN pattern recognition
- Collection route analysis

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns