---
framework: nestjs
version: "10.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# NestJS 10.x — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `@nestjs` npm package imports in JS bundles | JS source | `import {.*} from ['"]@nestjs` in source | Definitive — NestJS framework imports in compiled JS |
| `__decorateClass` / `__decorateParam` / `__metadata` | JS runtime helpers | Decorator polyfills in compiled output | Definitive — TypeScript decorators compiled |
| `NestApplication` or `NestFactory` in stack traces | Stack trace | `at NestApplication.init` / `at NestFactory.create` | Definitive — NestJS application bootstrap |
| `__controller_props__` or `__propDecorators__` | JS metadata | TypeScript decorator metadata in compiled output | Definitive |
| `Reflect.metadata` in JS source | JS | Reflect.metadata polyfill | High — TypeScript decorator metadata |
| `/api/` route prefix | URL path | Default global prefix for REST controllers | High — community convention, not enforced |
| `/health` route | URL path | Built-in `TerminusModule` health check | High — health check endpoint |
| `X-Request-Id` custom header | HTTP Header | NestJS default request ID interceptor | Medium — may be configured |
| NestJS error response structure | JSON body | `{statusCode, message, error}` nested format | High — NestJS exception filter format |
| `class-transformer` / `class-validator` in bundles | JS source | TypeScript class transformation imports | High — NestJS DTO validation |
| `app.controller` / `app.module` in source maps | Source maps | Controller and module names in compiled output | Definitive — NestJS bootstrap patterns |

**Version extraction (bash):**

```bash
# Check package.json if accessible (rare but possible)
curl -s https://target.example.com/package.json 2>/dev/null | grep nestjs

# Probe for health endpoint (common in NestJS due to TerminusModule)
curl -s https://target.example.com/health | python3 -m json.tool 2>/dev/null

# Check for NestJS decorator patterns in any exposed JS
curl -s https://target.example.com/main*.js 2>/dev/null | grep -o '@nestjs[^"]*' | head -5

# Check for NestJS in Swagger generated docs
curl -s https://target.example.com/api-docs 2>/dev/null | grep -i 'nestjs\|swagger'

# Try common NestJS Swagger paths
for path in "/api-docs" "/docs" "/swagger" "/swagger-ui" "/api"; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "https://target.example.com$path")
  echo "GET $path → $status"
done
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/` | GET | Varies | Application root (may serve Swagger or redirect) |
| `/health` | GET | Usually public | TerminusModule health check endpoint |
| `/api` | GET | Varies | Default global prefix if `setGlobalPrefix('api')` configured |
| `/api/{controller-route}` | REST | Varies | REST controllers at global prefix |
| `/api-docs` | GET | Varies | Swagger/OpenAPI docs (via `@nestjs/swagger`) |
| `/api-docs.json` | GET | Varies | OpenAPI spec JSON |
| `/api/admin/` | GET/POST | Requires admin | Admin-scoped routes |
| `/graphql` | POST/GET | Varies | GraphQL endpoint if `@nestjs/graphql` + Apollo/CodeFirst |
| `/graphql/schema.graphql` | GET | Varies | GraphQL SDL schema export |
| `/subscriptions` | GET | WebSocket | GraphQL subscriptions endpoint |
| `/_nestioc` | GET | Varies | Swagger endpoints at root |
| `/api/swagger.json` | GET | Varies | Alternative OpenAPI spec path |
| `/:version/api/*` | REST | Varies | Versioned API (common pattern) |

**GraphQL-specific endpoints (when NestJS GraphQL is configured):**

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/graphql` | POST | Varies | Primary GraphQL endpoint |
| `/graphql` | GET | Varies | GraphiQL IDE if enabled |
| `/schemas/:type` | GET | Varies | SDL schema export |
| `/_graphql` | GET | Varies | GraphQL playground |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `main.ts` (server-side) | Not accessible remotely | Bootstrap, global prefix, Swagger config, guards |
| `app.module.ts` (server-side) | Not accessible remotely | All imported modules |
| `package.json` (server-side) | Not accessible remotely | NestJS version, dependencies |
| `*.entity.ts` files (server-side) | Not accessible remotely | TypeORM entities; may be extractable if served |
| `/health` response body | HTTP GET | Health check details from TerminusModule |
| `/api-docs` response body | HTTP GET | OpenAPI spec; version in `info.version` |
| Environment variables in error traces | Stack traces (dev only) | May expose `NODE_ENV`, `DATABASE_URL` hints |
| `application.properties` (if Spring co-hosted) | Direct file access | Spring Boot config; different framework |

**Extract OpenAPI version:**
```bash
curl -s https://target.example.com/api-docs | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('API Version:', d.get('info', {}).get('version', 'not found'))
print('Title:', d.get('info', {}).get('title', 'not found'))
"
```

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| JWT Bearer token | `Authorization: Bearer <token>` header | `@nestjs/jwt` + `@nestjs/passport` |
| Passport.js strategies | `Authorization: Bearer <token>` or `X-API-Key` | Multiple strategies via passport |
| Session cookie | `connect.sid` or custom session cookie | express-session; NestJS passport integrated |
| GraphQL auth header | `Authorization: Bearer <token>` in GraphQL context | Sent in GraphQL request body |
| `@Public()` decorator | Marks endpoint as public | SkipAuth guard pattern |
| `@Roles('admin')` decorator | Role-based guard | Custom guard checking roles |
| CASL permissions | Ability guard | Dynamic permissions via CASL |

**JWT token acquisition pattern:**

```bash
# Step 1: find login endpoint (common paths)
LOGIN_RESP=$(curl -s -X POST https://target.example.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user","password":"pass"}')

# Step 2: extract JWT from response
TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

# Step 3: use token in subsequent requests
curl -H "Authorization: Bearer $TOKEN" https://target.example.com/api/protected-resource
```

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `/dist/*.js` | Compiled TypeScript output (ts-node or webpack) |
| `/node_modules/.package-lock.json` | Package lock (Node.js ecosystem) |
| `/assets/*.js` | Front-end bundled assets (if separate SPA) |
| `/_next/static/chunks/*.js` | Next.js front-end; NestJS may be backend |
| `/_nuxt/**/*.js` | Nuxt.js front-end; similar pattern |
| `/main*.js` | Compiled NestJS entry point |
| `/src/**/*.js` | Compiled TypeScript source (if served) |
| `webpack:/` in source maps | Webpack build detected |
| `webpack://NestJS/` in bundles | Webpack bundle for NestJS app |
| `__webpack_exports__` | Webpack module exports |

**Check for NestJS in bundle metadata:**

```bash
# Check compiled main.js for NestJS signatures
curl -s https://target.example.com/main*.js 2>/dev/null | grep -oE 'NestApplication|NestFactory|@nestjs' | head -5

# Check for TypeScript decorator metadata
curl -s https://target.example.com/main*.js 2>/dev/null | grep -o '__decorate|__metadata|__param' | head -5
```

## 6. Source Map Patterns

NestJS apps compiled with Webpack emit source maps by default in development. Production builds may also include them if not explicitly disabled.

**Where to look:**

```bash
# Check for source maps next to known JS files
curl -I https://target.example.com/dist/main.js.map 2>/dev/null

# Check webpack stats if accessible
curl -s https://target.example.com/dist/stats.json 2>/dev/null | python3 -m json.tool

# Check manifest
curl -s https://target.example.com/dist/manifest.json 2>/dev/null

# Extract all JS URLs from HTML and check each for .map
curl -s https://target.example.com/ | grep -oP 'src="[^"]+\.js[^"]*"' | sed 's/src="//;s/"$//' | while read -r url; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "${url}.map")
  [ "$status" = "200" ] && echo "SOURCE MAP: ${url}.map"
done
```

## 7. Common Plugins & Extensions

| Package | API it adds | Detection signal |
|---------|-------------|------------------|
| `@nestjs/swagger` | `/api-docs`, `/api-docs.json` | Swagger/OpenAPI documentation |
| `@nestjs/graphql` + Apollo | `/graphql` | GraphQL endpoint + schema |
| `@nestjs/typeorm` | No HTTP surface | Database ORM; no direct detection |
| `@nestjs/mongoose` | No HTTP surface | MongoDB ODM |
| `@nestjs/passport` | Auth via passport | Various auth mechanisms |
| `@nestjs/jwt` | JWT generation | JWT Bearer token auth |
| `@nestjs/terminus` | `/health` | Health check endpoint with details |
| `@nestjs/bull` | `/queues` (if dashboard) | Background job queue |
| `@nestjs/schedule` | No HTTP surface | Cron job scheduling |
| `@nestjs/websockets` | WebSocket gateway | `socket.io` or `ws` protocol |
| `@nestjs/config` | No HTTP surface | Configuration module |
| class-validator | No HTTP surface | DTO validation decorators |
| class-transformer | No HTTP surface | Object transformation |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `/api-docs` | Full OpenAPI spec | All routes, schemas, parameters — API inventory |
| `/api-docs.json` | OpenAPI JSON spec | Machine-readable API schema |
| `/health` | Health status with component details | Only if TerminusModule with detailed health is configured |
| `/graphql` | GraphQL schema introspection | If introspection enabled |
| `/graphql/schema.graphql` | SDL schema export | If schema is exported |
| `/main.js` | Compiled entry point | May expose bootstrap config, guards, interceptors |
| Error responses | NestJS error format | `{statusCode, message, error}` exception structure |

## 9. Probe Checklist

- [ ] `GET /` — Check application root for NestJS signals (Swagger redirect, API info)
- [ ] `GET /health` — Is TerminusModule health check present? (200 with JSON health = Terminus installed)
- [ ] `GET /api-docs` — Is NestJS Swagger present? (200 = @nestjs/swagger installed; shows full API)
- [ ] `GET /api-docs.json` — Retrieve OpenAPI spec; check version in `info` object
- [ ] `GET /graphql` — Is GraphQL endpoint present? (200 with introspection = @nestjs/graphql installed)
- [ ] `GET /graphql/schema.graphql` — Is SDL schema export available?
- [ ] Check response for NestJS error format — `{statusCode, message, error}` = NestJS exception filter
- [ ] Scan HTML/JS for `@nestjs` imports in compiled output — definitive for NestJS framework
- [ ] Look for TypeScript decorator metadata (`__decorateClass`, `__metadata`) in JS bundles
- [ ] `GET /swagger` or `GET /api/swagger.json` — Try alternative Swagger paths
- [ ] `GET /main*.js` — Probe for compiled NestJS entry point; may expose bootstrap config
- [ ] Check for `webpack://NestJS/` or `webpack://` in bundle references — NestJS webpack build
- [ ] Probe for GraphQL Playground or GraphiQL — `GET /graphql` may serve interactive IDE
- [ ] `GET /api/admin/` — Is admin module present? (sensitive — may require auth)
- [ ] Check for Bull queue dashboard — `GET /queues` or similar if bull-board installed

## 10. Gotchas

- **NestJS is built on Express or Fastify.** By default it uses Express. If Fastify is configured (via `@nestjs/platform-fastify`), the `X-Powered-By` header changes from `Express` to `fastify`. Don't rely solely on the Express fingerprint.

- **Decorators are compiled away in production.** TypeScript decorators (`@Controller`, `@Get`, `@Injectable`) become JavaScript class metadata or direct function calls in compiled output. Look for `__decorateClass`, `__decorateParam`, and `__metadata` in bundles as the definitive NestJS signature.

- **NestJS Swagger path varies.** `@nestjs/swagger` v5+ uses `/api-docs` by default, but older versions used `/swagger` or `/api/swagger`. Always probe multiple paths.

- **GraphQL and REST coexist.** A single NestJS application may expose both REST controllers and a GraphQL schema simultaneously. If `/graphql` is found, always probe `/api-docs` as well — the REST surface may be documented there.

- **JWT guards don't expose themselves in responses.** A missing `401` on a protected endpoint could mean no auth or a misconfigured guard. Always look at the controller source (via source maps or bundle inspection) to confirm guard usage.

## 11. GitHub Code Search Patterns

### Framework-Specific Queries

| Search Query | What it finds |
|--------------|---------------|
| `@Controller()` `language:typescript` `path:*.ts` | NestJS controller definitions |
| `@Injectable()` `path:*.module.ts` | NestJS service and module definitions |
| `@nestjs/swagger` `language:typescript` | Swagger decorator usage |
| `@nestjs/graphql` `language:typescript` | GraphQL resolver definitions |
| `@UseGuards(AuthGuard` | NestJS authentication guard patterns |
| `NestFactory.create` | NestJS application bootstrap |

### Example Queries for NestJS

```bash
# Search for NestJS controller patterns
site:github.com "NestJS" "@Controller()" "@Get()" language:typescript

# Search for GraphQL resolvers
site:github.com "@nestjs/graphql" "@Resolver()" language:typescript

# Search for Swagger configuration
site:github.com "@nestjs/swagger" "SwaggerModule.setup" language:typescript

# Search for authentication patterns
site:github.com "@nestjs/jwt" "JwtModule" language:typescript

# Search for TypeORM entities in NestJS
site:github.com "NestJS" "@Entity()" "TypeOrmModule" language:typescript
```

## 12. Framework-Specific Google Dorks

### Discovery Queries

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:/api-docs` | NestJS Swagger API documentation |
| `site:{domain} inurl:/graphql` | NestJS GraphQL endpoint |
| `site:{domain} inurl:/health` | NestJS Terminus health check |
| `site:{domain} inurl:/dist/` | Compiled TypeScript output |
| `site:{domain} inurl:/src/` | Source directory exposed |

### Complete Dork List for NestJS

```
# API endpoints
site:{domain} inurl:/api-docs
site:{domain} inurl:/graphql
site:{domain} inurl:/api/
site:{domain} inurl:/health

# Framework-specific paths
site:{domain} inurl:/dist/
site:{domain} inurl:/swagger
site:{domain} inurl:/api-docs.json

# Configuration files (if served)
site:{domain} filetype:ts "main.ts"
site:{domain} filetype:json "package.json" "nestjs"
site:{domain} filetype:json "package.json" "@nestjs"

# Documentation/leaks
site:{domain} "NestJS" "@Controller" "@Get"
site:{domain} "nestjs" "swagger" "ApiProperty"

# Admin/debug paths
site:{domain} inurl:/api/admin
site:{domain} inurl:/swagger
site:{domain} inurl:/api-docs
```

## 13. Cross-Cutting OSINT Patterns

### Favicon Hashing

```bash
# Get favicon hash for Shodan/Censys cross-referencing
curl -s "https://{domain}/favicon.ico" | python3 -c "
import sys
data = sys.stdin.buffer.read()
import mmh3 2>/dev/null || pip install mmh3
print(mmh3.hash(data))
"
```

### Source Map Discovery

```bash
# Extract all JS bundle URLs from HTML
curl -s "https://{domain}/" | grep -oP 'src=\"[^\"]+\.js[^\"]*\"' | sed 's/src=\"//;s/\"$//' > js_urls.txt

# Check each for .map file
while read -r url; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "${url}.map")
  [ "$status" = "200" ] && echo "SOURCE MAP: ${url}.map"
done < js_urls.txt
```

**Build tool patterns:**
| Build Tool | Source Map Pattern | Detection |
|------------|-------------------|------------|
| Webpack | `dist/*.js.map` | NestJS default tsconfig build |
| esbuild | `{name}.js.map` | Fastify platform build |
| TypeScript (tsc) | `src/*.js.map` | Without bundler |

### Tech Stack → API Pattern Mapping

| Framework | Common API Patterns |
|-----------|---------------------|
| NestJS | `/api-docs`, `/graphql`, `/health`, `/api/*` |
| Spring Boot | `/actuator/*`, `/api/*`, `/swagger-ui/` |
| ASP.NET Core | `/api/*`, `/swagger/*`, `/health` |
| Django | `/api/*`, `/admin/*`, `/accounts/*` |
| Laravel | `/api/*`, `/livewire/*`, `/sanctum/csrf-cookie` |
| Express | `/api/*`, `/auth/*`, `/health` |

### Email Naming Convention Analysis

```bash
# Predict internal subdomains from email patterns:
# john.doe@example.com → mail.example.com, smtp.example.com
# first.last@ → internal.example.com
# firstinitial+last@ → owa.example.com
```