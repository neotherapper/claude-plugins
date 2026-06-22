# Constants & Configuration — jsonplaceholder.typicode.com

## Rate Limiting

| Header | Value |
|--------|-------|
| x-ratelimit-limit | 1000 |
| x-ratelimit-remaining | 999 |
| x-ratelimit-reset | Unix timestamp |

## CORS

- `access-control-allow-credentials: true`
- Supports cross-domain requests

## HTTP Methods Supported

- GET
- POST
- PUT
- PATCH
- DELETE
- OPTIONS

## Data Counts

| Resource | Count |
|----------|-------|
| Users | 10 |
| Posts | 100 |
| Comments | 500 |
| Albums | 100 |
| Photos | 5000 |
| Todos | 200 |

## Relationships (Has Many)

- User → Posts, Albums, Todos
- Post → Comments
- Album → Photos

## Query Parameters

- `_limit` — Limit results
- `_page` — Pagination
- `userId=X` — Filter by user
- `postId=X` — Filter by post
- `albumId=X` — Filter by album

## Response Format

- JSON only
- No XML/CSV support