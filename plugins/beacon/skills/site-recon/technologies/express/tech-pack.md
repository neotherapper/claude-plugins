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
## 11. GitHub Code Search Patterns

Use these queries on GitHub to find custom endpoints, plugin code, and configuration examples for this framework.

### Framework-Specific Queries

| Search Query | What it finds |
|--------------|---------------|
| `"<pattern>" language:<lang> path:<path>` | <description> |

### Example Queries

```bash
# Search for custom endpoints
site:github.com "<framework>" "api" filetype:<ext>

# Search for auth patterns  
site:github.com "<framework>" "auth" "middleware"

# Search for config files
site:github.com "<framework>" "config" "endpoint"
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
