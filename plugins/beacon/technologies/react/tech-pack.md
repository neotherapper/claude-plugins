# React Technology Pack

## Framework Identification
**Name**: React
**Type**: Frontend JavaScript Library/Framework
**Language**: JavaScript/TypeScript

## Fingerprinting Rules
```yaml
rules:
  - name: react-static-js-files
    description: Detect React via static JavaScript files
    pattern: "/static/js/main.[a-f0-9]{8,}.js"
    type: path
    confidence: high
    
  - name: react-meta-tag
    description: Detect React via HTML meta tag
    pattern: 'content="create-react-app|React App"'
    type: body
    confidence: high
    
  - name: react-js-global
    description: Detect React via JavaScript global
    pattern: "React|ReactDOM|window.__REACT_DEVTOOLS_GLOBAL_HOOK__"
    type: js_global
    confidence: high
    
  - name: nextjs-static-files
    description: Detect Next.js via static files
    pattern: "/_next/static/chunks/"
    type: path
    confidence: high
    
  - name: react-asset-manifest
    description: Detect React via asset manifest
    pattern: "asset-manifest.json"
    type: file
    confidence: medium
    
  - name: react-error-boundary
    description: Detect React via error pages
    pattern: "React Error Boundary|Minified React error #"
    type: body
    confidence: medium
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for React static files (`/static/js/main.*.js`)
- Look for Next.js patterns (`/_next/` directory)
- Search HTML for React meta tags
- Check for manifest files (`asset-manifest.json`)

### Phase 4: JavaScript Analysis
- Analyze JavaScript bundles for React imports
- Check for React-specific global variables
- Detect version-specific code patterns
- Look for state management libraries (Redux, Zustand)

### Phase 5: Error Page Analysis
- Trigger 404 errors to check for React error boundaries
- Look for Next.js error messages
- Analyze error page structure for version clues

### Phase 7: API Surface Mapping
- Probe `/api/` routes (React apps often use backend APIs)
- Check for GraphQL endpoints (`/graphql`)
- Test authentication endpoints (`/auth/login`, `/auth/register`)
- Look for Next.js API routes in `/api/*`

## Common API Patterns

```javascript
// REST API example
fetch('/api/users')
  .then(response => response.json())
  .then(data => console.log(data));

// GraphQL example
fetch('/graphql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  body: JSON.stringify({query: "{ users { id name } }"})
})

// Next.js API route example
export default function handler(req, res) {
  res.status(200).json({ name: 'John Doe' })
}
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| JS Global | `React.version` → "18.2.0" | High |
| Asset Manifest | `asset-manifest.json` structure | Medium |
| Bundle Analysis | Code patterns in main.*.js | High |
| Next.js Files | `/.next/BUILD_ID` or chunk filenames | High |
| Error Messages | "Minified React error #88" | Medium |

## Framework-Specific Probes

Check these paths when React is detected:
```
# React application files
/static/js/*.js
/static/css/*.css

# Next.js specific paths
/_next/data/
/_next/static/chunks/
/_next/static/css/
/_next/static/media/

# Common React assets
/manifest.json
/favicon.ico
/logo*.png

# API surfaces (when paired with backend)
/api/*
/graphql
/auth/*
```

## Integration Patterns

### Common React Integration Points
| Library | Purpose | Detection Pattern |
|---------|---------|--------------------|
| Redux | State management | `__REDUX_DEVTOOLS_EXTENSION__`, `import { createStore }` |
| React Router | Client-side routing | `import { BrowserRouter }`, `/static/js/5.*.chunk.js` |
| Apollo Client | GraphQL | `@apollo/client` in bundles, `/graphql` endpoint |
| Next.js | Full-stack | `/_next/`, `next.config.js` |
| Tailwind CSS | Styling | `@tailwind` in CSS, `tailwind.config.js` |
| styled-components | CSS-in-JS | `styled-components` in bundles, dynamic classnames |

## React Ecosystem Checklist
When React is detected, probe for these ecosystem technologies:
- [ ] State management (Redux, Zustand, Context API)
- [ ] Routing (React Router, Next.js File System Routing)
- [ ] Styling (CSS Modules, Tailwind, styled-components, Emotion)
- [ ] Form handling (Formik, React Hook Form)
- [ ] Internationalization (react-i18next, FormatJS)
- [ ] Testing (Jest, React Testing Library, Cypress)
- [ ] Build tools (Webpack, Vite, esbuild)
- [ ] Server-side rendering (Next.js, Remix)
- [ ] API clients (axios, fetch, Apollo)

## False Positive Mitigation
- Verify multiple React fingerprinting rules
- Check for React-specific code patterns in JavaScript bundles
- Confirm React error boundaries or next.js error pages
- Cross-reference asset manifest files when available
- Test for React global variables in the browser console

## Integration with Beacon Skill
- This tech pack loads when React or Next.js static files are detected
- React version probing activates during JS bundle analysis phase
- API surface mapping focuses on `/api/` and `/graphql` endpoints
- Additional discovery of related technologies (state management, styling)

## 11. GitHub Code Search Patterns

Use these queries on GitHub to find custom endpoints, plugin code, and configuration examples for this framework.

### Framework-Specific Queries

| Search Query | What it finds |
|--------------|---------------|
| `"useEffect(" language:javascript` | React useEffect hook usage |
| `"useState(" language:javascript` | React useState hook usage |
| `"createContext(" language:javascript` | React context creation |
| `"React.Component" language:javascript` | Class component definitions |

### Example Queries for React

```bash
# Search for custom API routes/endpoints
site:github.com "React" "api" filetype:js "fetch"

# Search for authentication patterns
site:github.com "React" "auth" "context" language:javascript

# Search for configuration files with endpoint definitions
site:github.com "React" "package" "endpoint" language:javascript

# Search for custom post types, taxonomies, or extensions
site:github.com "React" "component" "custom" language:javascript
```

## 12. Framework-Specific Google Dorks

Use these Google search queries to discover exposed endpoints, configuration files, and documentation for this framework.

### Discovery Queries

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:/static/js/` | React compiled JS bundles |
| `site:{domain} inurl:/api/` | React app API calls |
| `site:{domain} "react" "api" "fetch"` | React API fetch call references |
| `site:{domain} inurl:__react` | React dev tools or global objects |

### Complete Dork List for React

```
# API endpoints
site:{domain} inurl:/api/
site:{domain} inurl:/graphql
site:{domain} inurl:/auth/login

# Framework-specific paths
site:{domain} inurl:/static/js/
site:{domain} inurl:/asset-manifest.json

# Configuration files
site:{domain} filetype:js "react"
site:{domain} filetype:json "package.json"

# Documentation/leaks
site:{domain} "React" "api" "endpoint"
site:{domain} "useEffect" "fetch" "api"

# Admin/debug paths
site:{domain} inurl:/api/
site:{domain} inurl:/__react/devtools
```
## 13. Cross-Cutting OSINT Patterns

These patterns apply across frameworks and should be checked for any detected technology.

### Favicon Hashing

Identify technology stack by hashing favicon and searching Shodan/Censys for same stack:

```bash
# Get favicon hash (mmh3 hash of favicon content)
curl -s "https://{domain}/favicon.ico" | python3 -c "
import sys, hashlib, base64
data = sys.stdin.buffer.read()
# Simple mmh3 hash simulation using Python
import mmh3 2>/dev/null || pip install mmh3
# Or use: python3 -c "import mmh3; print(mmh3.hash(data))"
print('Favicon hash needed for Shodan search: icon_hash')
"

# Search Shodan for same favicon (indicates shadow IT subdomains)
# site:shodan.io search: icon_hash:{hash}
```

**What it reveals:** Hidden subdomains running same framework stack as main site.

### Source Map Discovery

Check for source maps across all JS bundles:

```bash
# Extract all JS bundle URLs from HTML
curl -s "https://{domain}/" | grep -oP 'src="[^"]+\.js[^"]*"' | grep -oP '"[^"]+' | tr -d '"' > js_urls.txt

# Check each for .map file
while read url; do
  map_url="${url}.map"
  status=$(curl -s -o /dev/null -w "%{http_code}" "${map_url}")
  [ "$status" = "200" ] && echo "SOURCE MAP: ${map_url}"
done < js_urls.txt
```

**Build tool patterns:**
| Build Tool | Source Map Pattern | Detection |
|------------|-------------------|------------|
| Webpack | `{bundle}.js.map` or `//# sourceMappingURL=` | Check response header `X-SourceMap` |
| Vite | `{name}-[hash].js.map` | Vite manifest `manifest.json` |
| Rollup | `{bundle}.js.map` | Check `sourceMappingURL` comment |
| esbuild | `{bundle}.js.map` | Check `sourceMappingURL` comment |
| Next.js | `/_next/static/chunks/*.js.map` | Only if `productionBrowserSourceMaps: true` |

### Tech Stack → API Pattern Mapping

Auto-map detected frameworks to likely endpoint patterns:

| Framework | Common API Patterns |
|-----------|---------------------|
| Next.js | `/api/*`, `/_next/data/*`, `/api/auth/*`, `/api/trpc/*` |
| WordPress | `/wp-json/*`, `/wp-json/wp/v2/*`, `/wp-admin/admin-ajax.php` |
| Shopify | `/api/2024-10/graphql.json`, `/products.json`, `/collections.json` |
| Rails | `/api/v1/*`, `/assets/*`, `/users/sign_in` |
| Laravel | `/api/*`, `/livewire/message/*`, `/sanctum/csrf-cookie` |
| Strapi | `/api/*`, `/admin/*`, `/api/upload*` |
| Magento | `/rest/V1/*`, `/pub/static/*` |
| Django | `/api/*`, `/admin/*`, `/accounts/*` |

When Phase 3 detects a framework, use this table to prioritize Phase 5/6/7 probes.

### Email Naming Convention Analysis

Extract emails from theHarvester/GitHub results to predict internal subdomains:

```bash
# Sample emails found: john.doe@example.com, jane.smith@example.com
# Predicted subdomains: mail.example.com, smtp.example.com, exchange.example.com

# Common patterns:
# first.last@ → internal.example.com, mail.example.com
# firstinitial+last@ → owa.example.com, outlook.example.com
```

**Add to Phase 9 session brief:** Note email patterns and predicted subdomains.
