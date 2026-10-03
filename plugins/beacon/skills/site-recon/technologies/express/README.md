# Express Framework Detection

This guide covers fingerprinting and API surface mapping for Express.js applications.

## Framework Summary
- **Name**: Express
- **Type**: Web application framework
- **Language**: JavaScript/Node.js
- **Popularity**: 19.28% (Stack Overflow 2023 survey)
- **Website**: [https://expressjs.com](https://expressjs.com)

## Key Characteristics

### Fingerprinting Indicators
| Indicator | Pattern | Detection Method |
|------------|---------|------------------|
| HTTP Header | `X-Powered-By: Express` | HTTP response headers |
| Static Files | `/public/` directory | Directory enumeration |
| Error Pages | "Cannot GET /path" | 404 error page |
| Common Routes | `/api/*`, `/auth/*` | Directory enumeration |

### Technology Stack
Express is commonly paired with:
- Node.js runtime
- MongoDB, PostgreSQL, or MySQL databases
- React, Vue.js, or Angular frontends
- Redis for caching

## API Surface Discovery
See [fingerprinting.md](./fingerprinting.md) for detailed API surface mapping techniques.

## Security Considerations
- Always use `helmet` middleware
- Disable `X-Powered-By` header in production
- Implement CORS properly
- Use rate limiting on public endpoints

## Version Detection
- Check error pages (development mode)
- Look for `package.json` exposure
- Analyze JavaScript source code

## Resources
- [Official Express Documentation](https://expressjs.com/en/4x/api.html)
- [Express GitHub Repository](https://github.com/expressjs/express)