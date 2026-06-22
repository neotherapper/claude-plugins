# httpbin.org Research

## Summary

| Field | Value |
|-------|-------|
| Site | httpbin.org |
| Framework | Flask (Python) via Gunicorn 19.9.0 |
| Version | N/A (not exposed) |
| CDN | None |
| Auth | None (public API) |
| Bot Protection | None |

## Infrastructure

- **Server**: gunicorn/19.9.0
- **Python WSGI**: Werkzeug/Flask
- **Hosting**: AWS (X-Amzn-Trace-Id header)
- **API Type**: HTTP test service (request/response echo)

## Quick API Reference

| Endpoint | Method | Description |
|----------|--------|------------|
| `/get` | GET | Echo request as JSON |
| `/post` | POST | Echo POST body |
| `/put` | PUT | Echo PUT body |
| `/delete` | DELETE | Echo DELETE |
| `/patch` | PATCH | Echo PATCH body |
| `/status/{code}` | GET | Return specific HTTP status |
| `/headers` | GET | Echo headers |
| `/ip` | GET | Return request origin IP |
| `/uuid` | GET | Return random UUID |
| `/encoding/utf8` | GET | Return UTF-8 demo page |
| `/bytes/{num}` | GET | Return random bytes |
| `/links/{num}` | GET | Return HTML with links |
| `/forms/post` | POST | HTML form posting |

## Notes

- Public HTTP testing and debugging service
- Used by developers for testing HTTP clients and code
- No authentication required
- CORS enabled (`access-control-allow-origin: *`)