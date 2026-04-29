# Express Technology Pack

## Framework Identification
**Name**: Express
**Type**: Web Application Framework
**Language**: JavaScript/Node.js

## Fingerprinting Rules
```yaml
rules:
  - name: express-x-powered-by-header
    description: Detect Express via X-Powered-By header
    pattern: "X-Powered-By: Express"
    type: header
    confidence: high
    
  - name: express-error-page
    description: Detect Express via 404 error page
    pattern: "Cannot GET /"
    type: body
    confidence: high
    
  - name: express-static-files
    description: Detect Express via static file directories
    pattern: "/public/|/static/|/assets/"
    type: path
    confidence: medium
    
  - name: express-package-json
    description: Detect Express via package.json
    pattern: '"express": "\\d+\\.\\d+\\.\\d+"'
    type: file
    confidence: high
```

## Discovery Phases

### Phase 3: Initial HTTP Probe
- Check for `X-Powered-By: Express` header
- Check for `/robots.txt` with Express-specific paths
- Check for `/favicon.ico` existence

### Phase 4: Error Page Analysis
- Trigger 404 errors to check for "Cannot GET" messages
- Check error page structure for Express signatures

### Phase 5: Directory Enumeration
- Check for `/public/`, `/static/`, `/assets/` directories
- Check for `/api/`, `/auth/` route prefixes
- Check for `/health`, `/status`, `/version` endpoints

### Phase 7: API Surface Mapping
- Analyze discovered endpoints for REST patterns
- Check for GraphQL endpoints if applicable
- Identify authentication mechanisms

## Common API Patterns

```javascript
// REST API example
app.get('/api/users', (req, res) => {...});
app.post('/api/users', (req, res) => {...});
app.get('/api/users/:id', (req, res) => {...});

// Authentication example
app.post('/auth/login', (req, res) => {...});
app.post('/auth/register', (req, res) => {...});
```

## Version Fingerprinting

### Version Detection Methods
| Method | Example | Confidence |
|--------|---------|------------|
| Package.json | `"express": "4.18.2"` | High |
| Error Page | Express 4.x.y in development | High |
| HTTP Header | `X-Powered-By: Express` | Medium |

## False Positive Mitigation
- Verify multiple fingerprinting rules
- Cross-check with other Node.js frameworks
- Analyze error page structure
- Check for presence of `node_modules/express/` in paths

## Integration with Beacon Skill
- This tech pack should be loaded when beacon detects Node.js applications
- Activate when any Express fingerprinting rule matches
- Run Express-specific discovery phases

## 12. Framework-Specific Google Dorks

Use these Google search queries to discover exposed endpoints, configuration files, and documentation for this framework.

### Discovery Queries

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:/api/` | Express API routes and endpoints |
| `site:{domain} inurl:/routes/` | Express route definition files |
| `site:{domain} "express" "router"` | Express router endpoint references |
| `site:{domain} inurl:express-session` | Express session middleware paths |

### Complete Dork List for Express

```
# API endpoints
site:{domain} inurl:/api/
site:{domain} inurl:/auth/login
site:{domain} inurl:/health

# Framework-specific paths
site:{domain} inurl:/routes/
site:{domain} inurl:/public/

# Configuration files
site:{domain} filetype:js "express"
site:{domain} filetype:json "package.json"

# Documentation/leaks
site:{domain} "Express" "api" "endpoint"
site:{domain} "express-session" "secret"

# Admin/debug paths
site:{domain} inurl:/api/
site:{domain} inurl:/debug/
```