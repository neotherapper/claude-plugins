---
framework: nestjs
version: "10.x"
last_updated: "2026-05-11"
author: "@georgios"
status: community
---

# NestJS Framework Detection

## Framework Summary
- **Name**: NestJS
- **Type**: Progressive Node.js web application framework
- **Language**: TypeScript (compiled to JavaScript)
- **Popularity**: Rapidly growing; Angular-inspired architecture on Node.js
- **Website**: [https://nestjs.com](https://nestjs.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|-----------|---------|------------------|
| Decorator metadata in bundles | `__decorateClass`, `__metadata` in JS | Bundle inspection |
| NestJS imports in JS | `@nestjs/common` in source | Bundle content analysis |
| NestJS Swagger | `/api-docs` or `/api-docs.json` | HTTP probe |
| Terminus health check | `/health` with JSON status | HTTP GET |
| GraphQL endpoint | `/graphql` | HTTP probe |
| Error response format | `{statusCode, message, error}` | JSON response inspection |
| Global prefix `/api` | Routes start with `/api/` | URL enumeration |

### Technology Stack
NestJS is commonly paired with:
- Node.js runtime (v18+ for NestJS 10)
- Express (default) or Fastify (platform-fastify)
- TypeScript with decorators
- GraphQL with Apollo (CodeFirst or Schema First)
- TypeORM, Mongoose, Prisma for database
- Passport.js for authentication
- class-validator / class-transformer for DTO validation

## Fingerprint Probes

```bash
# Check for NestJS Swagger
curl -s -o /dev/null -w "%{http_code}" https://target.example.com/api-docs

# Probe health endpoint
curl -s https://target.example.com/health | python3 -m json.tool 2>/dev/null

# Trigger error to see NestJS exception format
curl -s https://target.example.com/nonexistent/ | python3 -m json.tool 2>/dev/null

# Probe GraphQL
curl -s -X POST https://target.example.com/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{__typename}"}'

# Check for NestJS in compiled bundles
curl -s https://target.example.com/main*.js 2>/dev/null | grep -o '@nestjs[^"'\'']*' | head -5
```

## Security Considerations
- NestJS Swagger often exposes full API schema
- GraphQL introspection may reveal data model
- Guards must be explicitly applied — unprotected endpoints common
- Validation pipes (class-validator) leave specific error signatures

## Resources
- [NestJS Official Documentation](https://docs.nestjs.com)
- [NestJS GitHub](https://github.com/nestjs/nest)
- [@nestjs/swagger](https://github.com/nestjs/swagger)
- [@nestjs/graphql](https://github.com/nestjs/graphql)
- [NestJS Official Blog](https://trilon.io/blog)