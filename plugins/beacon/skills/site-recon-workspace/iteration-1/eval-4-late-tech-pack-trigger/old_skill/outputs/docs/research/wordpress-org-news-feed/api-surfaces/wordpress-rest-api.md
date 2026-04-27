# WordPress REST API — API Surface

**Site:** wordpress.org/news
**Analysed:** 2026-04-27
**Base URL:** https://wordpress.org/news/wp-json/
**Auth required:** No (all observed endpoints are public read)

## Discovery Phase
Phase 5 (WITHOUT tech pack — OLD skill did not load tech pack for this run)

## Endpoints Observed

| Method | Path | Auth | Shape | Notes |
|--------|------|------|-------|-------|
| GET | /wp-json/ | No | 21 namespaces | Full REST API root |
| GET | /wp-json/wp/v2/posts | No | array | Public post listing |
| GET | /wp-json/wp/v2/users | No | array | Public user data (enumeration) |
| GET | /wp-json/wp/v2/types | No | object | Post type registry |
| GET | /wp-json/wp/v2/taxonomies | No | object | Taxonomy registry |

## Auth Detail
No authentication required for any observed read endpoint. POST/DELETE/PUT endpoints may require auth but were not tested.

## Rate Limits
Not detected on public endpoints.

## Surface Notes
- Full WordPress REST API v2 with 21 namespaces including WordPress.org specific endpoints
- Public user enumeration via `/wp-json/wp/v2/users` exposes usernames
- Custom namespaces: `wporg/v1`, `global-header-footer/v1`, `wporg-two-factor/1.0`, `ssp/v1` (Simple Subscribe Pro)
- Jetpack namespace includes stats, blaze, explat, video and other Automattic services
- No XML-RPC write access (returns 405)

## Example Request
```bash
curl -s "https://wordpress.org/news/wp-json/wp/v2/posts?per_page=5&_fields=id,slug,date,title" | python3 -m json.tool
```

## Example Response Shape
```json
[
  {
    "id": 20385,
    "slug": "celebrating-wcasia-2026",
    "date": "2026-04-11T18:21:14",
    "title": { "rendered": "Celebrating Community at WordCamp Asia 2026" }
  }
]
```