# JSONPlaceholder — Site Recon Report

**Target:** https://jsonplaceholder.typicode.com  
**Date:** 2026-04-27  
**Framework:** Express (Node.js)  
**Source:** x-powered-by: Express header

## Infrastructure

| Component | Value | Source |
|-----------|-------|--------|
| Framework | Express (Node.js) | HTTP header |
| Version | Unknown | Not exposed |
| CDN | Cloudflare | cf-ray, cf-cache-status |
| Hosting | Heroku | via: heroku-router |
| Auth | None | Public API |
| Bot Protection | Cloudflare (permissive) | Headers present but curl works |

## Tool Availability

| Tool | Status |
|------|--------|
| wappalyzer | [TOOL-UNAVAILABLE] |
| firecrawl | [TOOL-UNAVAILABLE] |
| chrome-devtools-mcp | [AVAILABLE] |
| cmux | [TOOL-UNAVAILABLE] |
| gau | [TOOL-UNAVAILABLE] |

## Tech Pack

- [TECH-PACK-UNAVAILABLE:express:unknown]

## Quick API Reference

| Endpoint | Method | Notes |
|----------|--------|-------|
| /posts | GET/POST | 100 posts |
| /comments | GET | 500 comments |
| /users | GET | 10 users |
| /albums | GET | 100 albums |
| /photos | GET | 5000 photos |
| /todos | GET | 200 todos |

Supports: GET, POST, PUT, PATCH, DELETE

## Discovered Endpoints

All 6 resources fully mapped with CRUD operations.

## Source

- GitHub: [typicode/jsonplaceholder](https://github.com/typicode/jsonplaceholder)
- Stars: 5220
- Powered by: json-server