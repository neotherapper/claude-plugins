# JSONPlaceholder — Research Summary

**URL:** https://jsonplaceholder.typicode.com
**Slug:** jsonplaceholder-typicode-com
**Date:** 2026-04-27

## Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Express (Node.js) |
| **Version** | Unknown (X-Powered-By: Express) |
| **CDN** | Cloudflare |
| **Hosting** | Heroku (via: 2.0 heroku-router) |
| **Auth** | None (public API) |
| **Bot Protection** | None detected |

## Tool Availability

| Tool | Status |
|------|--------|
| wappalyzer | Not checked (manual fingerprint) |
| firecrawl | Not available |
| chrome-devtools-mcp | Not available |
| cmux-browser | Not available |
| gau | Not available |

## Tech Pack

No tech pack loaded (simple static + API site).

## Discovered Endpoints

| Endpoint | Method | Auth | Phase | Notes |
|----------|--------|------|-------|-------|
| `/posts` | GET | None | P5 | Returns 100 posts |
| `/posts/{id}` | GET | None | P5 | Single post |
| `/posts` | POST | None | P5 | Create post (returns id: 101) |
| `/posts/{id}` | PUT | None | P5 | Update post |
| `/posts/{id}` | DELETE | None | P5 | Delete post |
| `/users` | GET | None | P5 | Returns 10 users |
| `/users/{id}` | GET | None | P5 | Single user |
| `/comments` | GET | None | P5 | Returns 500 comments |
| `/comments/{id}` | GET | None | P5 | Single comment |
| `/albums` | GET | None | P5 | Returns 100 albums |
| `/photos` | GET | None | P5 | Returns 5000 photos |
| `/todos` | GET | None | P5 | Returns 200 todos |
| `/posts/{id}/comments` | GET | None | P5 | Nested resource |
| `/users/{id}/posts` | GET | None | P5 | Nested resource |
| `/posts?userId={id}` | GET | None | P5 | Filtering |
| `/comments?postId={id}` | GET | None | P5 | Filtering |

## OpenAPI Status

No OpenAPI spec found (Phase 8: not found).
Phase 11 skipped (no browser tool available).

## Phase Execution Summary

| Phase | Status | Notes |
|-------|--------|-------|
| P1: Scaffold | ✓ | Output directory created |
| P2: Passive recon | ✓ | robots.txt found, no sitemap |
| P3: Fingerprint | ✓ | Express detected via X-Powered-By |
| P4: Tech pack | SKIPPED | Simple API, no tech pack needed |
| P5: Known patterns | ✓ | All CRUD endpoints tested |
| P6: Feeds/structure | ✓ | REST API structure documented |
| P7: JS/source maps | ✓ | Tailwind CSS detected |
| P8: OpenAPI detect | ✓ | No OpenAPI spec found |
| P9: OSINT | SKIPPED | No additional OSINT needed |
| P10: Browse plan | SKIPPED | No browser for active browse |
| P11: Active browse | SKIPPED | No browser tool available |
| P12: Document | ✓ | Output files written |

## Files Generated

- `INDEX.md` — This summary
- `tech-stack.md` — Framework and hosting details
- `site-map.md` — All discovered URLs
- `api-surfaces/rest-api.md` — REST API documentation