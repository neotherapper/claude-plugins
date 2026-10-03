---
framework: nestjs
version: "10.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# NestJS 10.x — Fingerprinting Guide

## Framework Overview

NestJS is a progressive Node.js framework for building efficient, scalable server-side applications. Built on top of Express (default) or Fastify, it uses TypeScript natively, applies Angular-inspired modular architecture, and employs decorators extensively for routing, dependency injection, and validation. This guide covers fingerprinting techniques for NestJS 10.x applications.

## Fingerprinting Patterns

### 1. HTTP Response Headers

| Header | Value Example | Confidence | Notes |
|--------|--------------|------------|-------|
| `X-Powered-By` | `Express` or `fastify` | Medium | Base platform; NestJS uses Express by default, Fastify if platform-fastify |
| `Server` | Framework-specific | Low | Generic; varies by deployment |
| `X-Request-Id` | UUID or custom string | Medium | NestJS default request ID interceptor |
| `Content-Type` | `application/json` | Low | Generic API response |

**Probe:**
```bash
curl -I https://target.example.com/ 2>/dev/null | grep -iE 'x-powered-by|x-request-id|server'
```

### 2. Response Body Structure

| Signal | Pattern | Confidence | Notes |
|--------|---------|------------|-------|
| NestJS exception filter format | `{"statusCode":500,"message":"...","error":"..."}` | Definitive | NestJS default `ExceptionFilter` response structure |
| Validation error format | `{"statusCode":400,"message":["field must be a string"],"error":"Bad Request"}` | Definitive | class-validator + class-transformer error format |
| Swagger API response | OpenAPI spec in `/api-docs` JSON | Definitive | @nestjs/swagger plugin |
| Swagger UI HTML | `<title>Swagger UI</title>` with NestJS branding | Definitive | @nestjs/swagger rendered UI |

**Probe:**
```bash
# Trigger 400 error to see NestJS validation format
curl -s -X POST https://target.example.com/api/resource \
  -H "Content-Type: application/json" \
  -d '{"invalid_field": 123}' | python3 -m json.tool
```

### 3. Decorator Signatures in Bundles

| Signal | Pattern in JS | Confidence | Notes |
|--------|-------------|------------|-------|
| TypeScript decorator metadata | `__decorateClass`, `__decorateParam`, `__param` | Definitive | Compiled from `@Controller`, `@Get`, etc. |
| Reflect metadata | `Reflect.metadata("design:paramtypes", ...)` | Definitive | TypeScript DI metadata |
| NestJS module imports | `@nestjs/common` in bundle imports | Definitive | NestJS framework imports |
| Guard metadata | `__guard__` or `roles` metadata | High | Custom guard decorators |
| Pipe/Interceptor metadata | `__pipe__`, `__interceptor__` | High | NestJS built-in decorators |

**Probe:**
```bash
# Fetch main bundle and look for NestJS decorator patterns
curl -s https://target.example.com/main*.js 2>/dev/null | grep -oE '__decorate|__metadata|@nestjs|__param' | sort -u
```

### 4. Route/Controller Patterns

| Signal | Pattern | Confidence | Notes |
|--------|---------|------------|-------|
| Global prefix `/api` | Routes start with `/api/` | High | Community convention for REST APIs |
| Versioned routes | `/v1/`, `/v2/` prefix | High | Common NestJS versioning pattern |
| Health endpoint | `/health` returning `{status:"ok"}` | High | TerminusModule default response |
| Swagger base path | `/api-docs` | Definitive | @nestjs/swagger default path |
| GraphQL path | `/graphql` | Definitive | NestJS GraphQL module default |

### 5. Module and Service Signatures

| Signal | Pattern | Confidence | Notes |
|--------|---------|------------|-------|
| `app.module` in bundle | `app.module` string in compiled output | Definitive | Default root module name |
| `app.controller` in bundle | `app.controller` string | Definitive | Default root controller name |
| TypeORM entities | `entity:` references in DI | High | @nestjs/typeorm usage |
| Mongoose schemas | `Schema` and `Document` in bundle | High | @nestjs/mongoose usage |

### 6. Version Detection

**Method 1: OpenAPI spec info object**
```bash
curl -s https://target.example.com/api-docs | python3 -c "
import sys, json
d = json.load(sys.stdin)
info = d.get('info', {})
print('Version:', info.get('version', 'not found'))
print('Title:', info.get('title', 'not found'))
"
```

**Method 2: package.json dependencies**
```bash
# package.json is rarely accessible but worth trying
curl -s https://target.example.com/package.json | python3 -c "
import sys, json
d = json.load(sys.stdin)
deps = d.get('dependencies', {})
print('@nestjs/core:', deps.get('@nestjs/core', 'not found'))
"
```

**Method 3: Compiled bundle inspection**
```bash
# NestJS compiler may include version hints in bundle
curl -s https://target.example.com/main*.js 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' | grep '10\.' | head -3
```

## Confidence Level Definitions

| Level | Meaning | When to use |
|-------|---------|-------------|
| **Definitive** | Cannot be produced by any other framework | Use as primary confirmation |
| **High** | Very strong signal; unlikely false positive | Use as strong evidence |
| **Medium** | Present in many frameworks or common configuration | Use as supporting evidence |
| **Low** | Generic signal; many possible explanations | Use as hint only |

## Quick Fingerprinting Commands

```bash
# Quick check: headers
curl -I https://target.example.com/ 2>/dev/null | grep -iE 'x-powered-by|x-request-id'

# Quick check: NestJS Swagger
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/api-docs

# Quick check: health endpoint
curl -s https://target.example.com/health | python3 -m json.tool 2>/dev/null

# Quick check: error format
curl -s https://target.example.com/nonexistent-path-abc/ | python3 -m json.tool 2>/dev/null | head -20

# Full OpenAPI spec
curl -s https://target.example.com/api-docs | python3 -m json.tool | head -50

# Probe GraphQL
curl -s -X POST https://target.example.com/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{__schema{types{name}}}"}' | python3 -m json.tool 2>/dev/null | head -20

# Check for decorator patterns in compiled JS
curl -s https://target.example.com/main*.js 2>/dev/null | grep -oE '@nestjs[^"'\'']*' | head -10
```

## False Positive Mitigation

- **`X-Powered-By: Express` alone does not mean NestJS.** Express alone produces this header. Combine with decorator patterns, NestJS error format, or Swagger endpoints before concluding.
- **TypeScript decorator metadata (`__decorate*`, `__metadata`)** is the most definitive signal. No other mainstream Node.js framework compiles to this pattern. If present, it is almost certainly NestJS (or a custom Angular/Ionic backend).
- **NestJS Swagger at `/api-docs`** is the default, but older versions or custom configurations may use `/swagger`. Always probe both.
- **Error response format `{statusCode, message, error}`** matches NestJS exception filter but could theoretically match other Express middleware. Combine with other signals.
- **`/health` alone could indicate many frameworks.** NestJS Terminus returns a structured JSON with status details. Probe the actual response body.

## Technology Stack Pairings

| Technology | Detection Method | Confidence |
|------------|-----------------|------------|
| Express (default platform) | `X-Powered-By: Express` | Medium |
| Fastify (platform-fastify) | `X-Powered-By: fastify` | High |
| @nestjs/swagger | `/api-docs`, `/api-docs.json` | Definitive |
| @nestjs/graphql + Apollo | `/graphql`, introspection query | Definitive |
| @nestjs/typeorm | TypeORM entity references in DI | High |
| @nestjs/mongoose | Mongoose model references | High |
| @nestjs/passport | Auth guard patterns | High |
| @nestjs/jwt | JWT module references | High |
| @nestjs/terminus | `/health` structured response | Definitive |
| class-validator | Validation error format | Definitive |

## Changelog

- 2026-05-11: Initial NestJS 10.x tech pack with decorator-based fingerprinting, GraphQL coverage, and module detection