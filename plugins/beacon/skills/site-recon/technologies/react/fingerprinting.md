# React Framework Fingerprinting Guide

## Framework Overview
React is a JavaScript library for building user interfaces, primarily used for frontend development. With 40.58% popularity according to the Stack Overflow 2023 survey, it's the most widely used frontend framework. React applications often pair with backend frameworks like Express, Next.js, or custom APIs.

## Fingerprinting Patterns

### 1. Static File Patterns
React applications have distinctive static file patterns:
- `/static/js/main.[hash].js` - Main React bundle
- `/static/js/vendor.[hash].js` - Vendor libraries bundle
- `/static/js/[name].[hash].chunk.js` - Code-split chunks
- `/static/css/main.[hash].css` - Main stylesheet
- `/favicon.ico` - React default favicon

### 2. HTML Meta Tags
React apps often include specific meta tags in the HTML:
```html
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#000000">
<meta name="description" content="Web site created using create-react-app">
```

### 3. JavaScript Globals
Look for React-specific global variables in browser console:
- `React` - React library global
- `ReactDOM` - React DOM library
- `ReactDOMClient` - React 18+ client API
- `window.__REACT_DEVTOOLS_GLOBAL_HOOK__` - React DevTools hook

### 4. Common Routes
- `/` - Main application entry point
- `/static/` - Static assets directory
- `/manifest.json` - Web app manifest
- `/asset-manifest.json` - React asset manifest (create-react-app)
- `/precache-manifest.[hash].js` - Workbox precache manifest

### 5. Next.js Specific Patterns (if applicable)
If the app uses Next.js:
- `/_next/` - Next.js specific directory
- `/_next/static/chunks/` - Next.js code chunks
- `/_next/data/[buildId]/` - Next.js data fetching
- `/_app.js` - Custom Next.js app component
- `/_document.js` - Custom Next.js document

### 6. Error Pages
React applications typically show:
- 404: "This page could not be found" (Next.js)
- Development errors: "React Error Boundary" with stack traces
- Production errors: Generic "Sorry, something went wrong" messages

### 7. Version Fingerprinting
Check these sources for React version:
- In JavaScript bundles: `"react": "^18.2.0"`
- Browser console: `React.version`
- `asset-manifest.json`: structure differences between versions
- Next.js apps: `/.next/BUILD_ID` or `/_next/static/chunks/webpack-*.js`

## API Surface Mapping

### Common React API Integration Patterns
| Endpoint Pattern | Purpose | Method |
|------------------|---------|--------|
| `/api/*` | Backend API endpoints | GET, POST, PUT, DELETE |
| `/graphql` | GraphQL endpoint | POST |
| `/auth/*` | Authentication endpoints | POST |
| `/upload` | File uploads | POST |

### Next.js API Routes (if applicable)
| Route Pattern | Purpose | Method |
|---------------|---------|--------|
| `/api/auth/*` | Authentication | POST |
| `/api/posts` | Content management | GET, POST |
| `/api/posts/:id` | Single post operations | GET, PUT, DELETE |
| `/api/search` | Search functionality | GET |
| `/api/webhook` | Webhook handlers | POST |

## Discovery Techniques

### 1. Directory Enumeration
Focus on these directories:
```
/static/
/assets/
/_next/
/public/
/api/
```

### 2. Common File Discovery
Look for these files:
```
package.json
asset-manifest.json
sw.js
precache-manifest.[hash].js
next.config.js
```

### 3. Framework-Specific Endpoints
Check for these React/Next.js specific endpoints:
```
/_next/webpack-hmr
/_next/data/[buildId].json
/_next/on-demand-entries-ping
/_next/static/chunks/pages/[page].js
```

## Security Considerations

### Common React Security Headers
```
Content-Security-Policy: script-src 'self' 'unsafe-eval' https://cdn.jsdelivr.net
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

### Vulnerable Patterns
- Exposed environment variables in client-side code
- Missing CSP for inline scripts
- Unprotected API routes in Next.js
- Version information in error pages
- Missing CSRF protection on forms
- Hardcoded API keys in JavaScript bundles
- Missing input validation on user-generated content

## Technology Stack Integration

### Common React Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| Next.js | Full-stack framework | `/_next/` directory, `/_app.js` |
| Express | Backend API | `api/` routes, `X-Powered-By: Express` |
| GraphQL | API queries | `/graphql` endpoint, Apollo client |
| Redux | State management | `redux` in `package.json`, `__REDUX_DEVTOOLS_EXTENSION__` |
| Tailwind | CSS framework | `@tailwind` in CSS files |
| Firebase | Backend services | `firebase` in `package.json` |
| AWS Amplify | Hosting/deployment | `aws-amplify` in `package.json` |
| Workbox | PWA capabilities | `workbox` in service worker files |

## Example Fingerprinting Commands

```bash
# Check for React static files
curl -I https://example.com/static/js/main.*.js

# Check for React meta tags
curl https://example.com | grep -i "react\|create-react-app"

# Check for Next.js patterns
curl -I https://example.com/_next/

# Check React version via console
echo "React.version" | chrome-devtools_evaluate_script

# Check for common React API routes
curl -I https://example.com/api/
```

## False Positives
- Some CDNs serve similar static file patterns
- JavaScript-heavy apps might resemble React
- Next.js patterns might conflict with other frameworks
- Generic `/api/` routes could be from any backend
- Some React-specific global variables might be polyfilled

## Fingerprinting Tooling
For automated fingerprinting of React applications:
- Static file pattern matching
- HTML meta tag analysis
- JavaScript bundle analysis for React imports
- Error page analysis
- Asset manifest structure analysis

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns