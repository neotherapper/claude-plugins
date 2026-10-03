# Express Framework Fingerprinting Guide

## Framework Overview
Express is a minimal and flexible Node.js web application framework that provides a robust set of features for web and mobile applications. It's the most popular backend framework for Node.js with 19.28% popularity according to Stack Overflow 2023 survey.

## Fingerprinting Patterns

### 1. HTTP Headers
```
X-Powered-By: Express
Server: Express
```

### 2. Static File Patterns
- `/robots.txt` - Often customized in Express apps
- `/favicon.ico` - Default location
- `/public/` - Default static assets directory
- `/static/` - Common alternative static assets directory

### 3. Error Pages
Express has distinctive error pages:
- **404**: "Cannot GET /nonexistent-path"
- **500**: "Internal Server Error" with stack traces in development

### 4. Common Routes
- `/api/*` - REST API endpoints
- `/auth/*` - Authentication routes
- `/health` or `/status` - Health check endpoints

### 5. Common Middleware Indicators
- `body-parser` usage: `Content-Type: application/json` accepted
- `cookie-parser` usage: `Set-Cookie` headers
- `cors` usage: CORS headers like `Access-Control-Allow-Origin`

### 6. Version Fingerprinting
Check these files for version information:
- `package.json` - Direct access might be exposed
- `/version` - Some apps expose version info
- Error pages often show Express version in development

## API Surface Mapping

### Common Express API Patterns
| Endpoint Pattern | Purpose | Method |
|------------------|---------|--------|
| `/api/users` | User management | GET, POST |
| `/api/users/:id` | Single user operations | GET, PUT, DELETE |
| `/api/posts` | Post/content management | GET, POST |
| `/api/posts/:id` | Single post operations | GET, PUT, DELETE |
| `/api/auth/login` | Authentication | POST |
| `/api/auth/register` | User registration | POST |
| `/api/auth/refresh` | Token refresh | POST |

### Common Middleware Endpoints
| Middleware | Endpoint | Purpose |
|------------|----------|---------|
| `express.static` | `/static/*` | Static file serving |
| `express.json` | All routes | JSON body parsing |
| `express.urlencoded` | All routes | Form data parsing |
| `cookie-parser` | All routes | Cookie handling |
| `express-session` | All routes | Session management |

## Discovery Techniques

### 1. Directory Bruteforcing
Focus on these directories:
```
/api
/auth
/public
/static
/assets
/uploads
/routes
/views
```

### 2. Common File Discovery
Look for these files:
```
package.json
app.js
server.js
index.js
server/index.js
src/index.js
src/server.js
```

### 3. Framework-Specific Endpoints
Check for these framework-specific endpoints:
```
/health
/status
/version
/.well-known/express/server
```

## Security Considerations

### Common Express Security Headers
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

### Vulnerable Patterns
- Missing `helmet` middleware
- Exposed `package.json` files
- Directory listing enabled
- Version information in error pages
- No rate limiting on authentication endpoints

## Technology Stack Integration

### Common Express Pairings
| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| MongoDB | Database | `mongodb://` URLs in JS files |
| PostgreSQL | Database | `pg` package in `package.json` |
| React | Frontend | `_next/` directory, `react-dom.js` |
| Vue.js | Frontend | `vue.js` files, `#app` element |
| Redis | Caching | `redis` package in `package.json` |
| Socket.IO | Realtime | `socket.io.js` files |

## Example Fingerprinting Commands

```bash
# Check headers for Express
curl -I https://example.com

# Check for common Express files
curl https://example.com/package.json

# Check error pages for version info
curl -i https://example.com/nonexistent-path
```

## False Positives
- Some CDNs add `X-Powered-By: Express` header
- Generic Node.js apps might have similar routes
- Some static site generators produce similar directory structures

## Fingerprinting Tooling
For automated fingerprinting, consider these techniques:
- HTTP header analysis
- Error page content matching
- Static file pattern detection
- JavaScript source analysis for Express imports

## Changelog
- 2026-04-28: Initial guide creation
- Future: Add version-specific fingerprinting patterns