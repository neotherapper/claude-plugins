# httpbin.org — Research Index

## Summary
HTTP Request & Response Service - A simple HTTP request/response testing service.

## Infrastructure

| Component | Value | Evidence |
|-----------|-------|----------|
| Framework | Flask (Python) | HTML contains Flasgger (Swagger UI) |
| Server | gunicorn/19.9.0 | Server: gunicorn/19.9.0 header |
| Hosting | Unknown | No clear hosting signals |
| CDN | None detected | No CDN headers |

## API Endpoints

| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| / | GET | 200 | Main page with Swagger UI |
| /get | GET | 200 | Echo request as JSON |
| /anything | GET | 200 | Echo request with full details |
| /headers | GET | 200 | Echo request headers |
| /ip | GET | 200 | Return origin IP |
| /uuid | GET | 200 | Return random UUID |
| /post | POST | 405 | POST endpoint (needs data) |
| /put | PUT | 405 | PUT endpoint (needs data) |
| /delete | DELETE | 405 | DELETE endpoint |

## Discovered Files

- tech-stack.md — Framework and server details
- site-map.md — All discovered URLs
- constants.md — API taxonomy

## Notes

Phase 1 used `touch` to scaffold output files (0-byte placeholder files).