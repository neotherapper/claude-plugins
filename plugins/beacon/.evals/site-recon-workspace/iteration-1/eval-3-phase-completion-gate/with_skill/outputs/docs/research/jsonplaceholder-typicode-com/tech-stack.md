# Tech Stack — jsonplaceholder.typicode.com

## Framework & Runtime

| Component | Value | Source |
|-----------|-------|--------|
| Runtime | Node.js | x-powered-by: Express header |
| Framework | Express | x-powered-by: Express header |
| Base Library | json-server | GitHub OSINT (typicode/jsonplaceholder) |
| Frontend | Tailwind CSS v2.1.4 | style.css |
| CDN | Cloudflare | cf-ray, cf-cache-status headers |
| Hosting | Heroku | via: 2.0 heroku-router |

## Version Information

- Express version: Unknown (not exposed in headers)
- Tailwind CSS: 2.1.4 (from style.css comment)
- Node.js: Unknown

## Authentication

- **None** — Public API, no authentication required

## Bot Protection

- Cloudflare detected but allows curl/automated access

## Tool Availability Matrix

| Tool | Status |
|------|--------|
| wappalyzer | [TOOL-UNAVAILABLE] |
| firecrawl | [TOOL-UNAVAILABLE] |
| chrome-devtools-mcp | [AVAILABLE] |
| cmux | [TOOL-UNAVAILABLE] |
| gau | [TOOL-UNAVAILABLE] |

## Graceful Degradation

- [TECH-PACK-UNAVAILABLE:express:unknown] — No Express tech pack in repository