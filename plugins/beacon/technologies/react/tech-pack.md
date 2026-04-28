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
- Error page analysis for React-specific errors