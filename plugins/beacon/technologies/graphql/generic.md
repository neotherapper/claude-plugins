---
framework: GraphQL
version: generic
last_updated: "2026-04-14"
author: "@neotherapper"
status: official
---

# GraphQL (generic) — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| POST to `/graphql` returns `{"data":...}` | HTTP response body | JSON with `data` key | High |
| POST to `/api/graphql` | HTTP path | `/api/graphql` | High |
| POST to `/v1/graphql` | HTTP path | `/v1/graphql` | Definitive (Hasura) |
| `__typename` field in response | Response body field | `"__typename"` | High |
| `x-hasura-role` request header | HTTP header | `x-hasura-role` | Definitive (Hasura) |
| `x-hasura-admin-secret` request header | HTTP header | `x-hasura-admin-secret` | Definitive (Hasura) |
| `__APOLLO_STATE__` JS global | JS global | `window.__APOLLO_STATE__` | High (Apollo Client) |
| `__RELAY_STORE__` JS global | JS global | `window.__RELAY_STORE__` | Definitive (Relay) |
| Introspection response contains `__schema` | Response body | `{"data":{"__schema":...}}` | Definitive |

**Endpoint discovery:**
```bash
for path in /graphql /api/graphql /v1/graphql /graphql/v1 /query /api/query; do
  status=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"query":"{__typename}"}' \
    {site}$path)
  echo "$path → $status"
done
```

**Introspection probe:**
```bash
curl -s -X POST {graphql-endpoint} \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { types { name kind } } }"}' | python3 -m json.tool
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `/graphql` | POST | Varies | Standard GraphQL endpoint |
| `/api/graphql` | POST | Varies | Common in Next.js and Express apps |
| `/v1/graphql` | POST | Varies | Hasura standard path |
| `/graphql` | GET | Varies | Some servers support GET with `?query=` param |
| `/graphql` | WebSocket | Varies | Subscriptions via `graphql-ws` or `subscriptions-transport-ws` |

**Type names probe (lightweight — won't trigger complexity limits):**
```json
{"query": "{ __schema { types { name kind } } }"}
```

**Full schema introspection:**
```json
{"query": "{ __schema { queryType { name } mutationType { name } subscriptionType { name } types { name kind fields { name type { name kind ofType { name kind } } } } } }"}
```

## 3. JS Globals

| Global | Library | What it contains |
|--------|---------|-----------------|
| `window.__APOLLO_STATE__` | Apollo Client | Normalised cache — all fetched entity IDs and field values |
| `window.__RELAY_STORE__` | Relay | Record store with all fetched data |
| `window.__URQL_DATA__` | urql | SSR data passed from server to client |

**Extraction (Apollo — reveals all queried types and IDs):**
```javascript
// Run in browser console or via evaluate_script
Object.keys(window.__APOLLO_STATE__ || {}).filter(k => k !== 'ROOT_QUERY')
// → ["User:1", "Post:42", "Comment:7", ...]
```

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| Bearer token | `Authorization: Bearer {token}` header | JWT from login mutation; most common pattern |
| API key | `x-hasura-admin-secret: {secret}` | Hasura only; full admin access — never present in client-side JS |
| Cookie session | `Cookie: session={value}` | Browser-based; check for `credentials: "include"` in fetch calls |
| JWT claims headers | `x-hasura-user-id`, `x-hasura-role` | Hasura JWT claims mode — set manually to impersonate roles |
| Anonymous role | No header | Hasura `anonymous` role grants public query access |

**Auth probe (unauthenticated introspection check):**
```bash
curl -s -X POST {graphql-endpoint} \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { queryType { name } } }"}' | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print('AUTH:OPEN' if 'data' in d else 'AUTH:REQUIRED')"
```

## 5. Rate Limiting

| Mechanism | Description | How to detect |
|-----------|-------------|---------------|
| Query complexity limit | Each field has a cost; request rejected when total exceeds limit | `errors[].extensions.code = "QUERY_TOO_COMPLEX"` |
| Depth limiting | Nested query depth capped (typically 5–10 levels) | `errors[].message` contains "depth" or "nesting" |
| Alias batching block | Multiple aliases for same field rejected | `errors[].message` contains "alias" |
| Persisted query enforcement | Only pre-registered query hashes accepted | `errors[].extensions.code = "PERSISTED_QUERY_NOT_FOUND"` |
| Per-IP request rate | Standard HTTP rate limiting | `HTTP 429` response |

**Depth probe:**
```json
{"query": "{ user { posts { comments { author { posts { comments { id } } } } } } }"}
```

## 6. Caching

| Approach | Description | How to detect |
|----------|-------------|---------------|
| No CDN cache | POST requests bypass CDN by default | Expected — normal GraphQL behaviour |
| Automatic Persisted Queries (APQ) | Hash query → GET with `extensions.persistedQuery` | Try GET with `?extensions={"persistedQuery":{"version":1,"sha256Hash":"..."}}` |
| `@cacheControl` directive | Apollo server-side cache hints in schema | `extensions.cacheControl` in response |
| CDN-over-GET | Some servers accept GET for queries | Try `GET /graphql?query={__typename}` |
| Response `Cache-Control` header | Standard HTTP caching | Check response `Cache-Control` header |

## 7. Versioning

| Approach | Description |
|----------|-------------|
| No URL versioning | GraphQL APIs do not use URL versioning (unlike REST `/v1/`, `/v2/`) |
| Field-level deprecation | Fields marked `@deprecated(reason: "...")` in schema; visible via introspection |
| Additive changes only | New fields added freely; old fields deprecated then removed after a window |
| Breaking change detection | Compare introspection responses across time — removed types or fields = breaking |

**Deprecation check:**
```json
{"query": "{ __schema { types { fields { name isDeprecated deprecationReason } } } }"}
```

## 8. Common Response Patterns

| Pattern | Example | Notes |
|---------|---------|-------|
| Success | `{"data": {"user": {"id": 1}}}` | HTTP 200 |
| Error only | `{"errors": [{"message": "Not found"}]}` | HTTP 200 — not 404 |
| Partial success | `{"data": {"user": null}, "errors": [...]}` | HTTP 200; both keys present — valid GraphQL |
| Extensions | `{"data": {...}, "extensions": {"tracing": {...}}}` | Apollo tracing, cache hints |
| Unauthenticated | `{"errors": [{"extensions": {"code": "UNAUTHENTICATED"}}]}` | HTTP 200 or 401 |

**Correct way to check success (HTTP status alone is not enough):**
```bash
response=$(curl -s -X POST {endpoint} -H "Content-Type: application/json" -d '{"query":"{__typename}"}')
echo "$response" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if 'data' in d and 'errors' not in d:
    print('SUCCESS')
else:
    print('ERROR:', d.get('errors', 'unknown'))
"
```

## 9. Probe Checklist

Run these probes and record results (✓ success / ✗ error / – not applicable):

- [ ] `POST /graphql {"query":"{__typename}"}` — basic connectivity, unauthenticated
- [ ] `POST /graphql {"query":"{ __schema { types { name } } }"}` — introspection enabled?
- [ ] `POST /graphql {"query":"{ __schema { mutationType { name } } }"}` — mutations available?
- [ ] `GET /graphql?query={__typename}` — GET queries supported? (enables CDN caching)
- [ ] WebSocket handshake to `/graphql` with `graphql-ws` subprotocol — subscriptions available?
- [ ] Deep nesting probe (6+ levels) — depth limiting in effect?
- [ ] `POST /graphql` with `extensions.persistedQuery` hash — APQ enforced?
- [ ] Unauthenticated introspection — returns full schema or auth error?

## 10. Gotchas

- **HTTP 200 ≠ success.** GraphQL always returns HTTP 200 even for errors. Always check the `errors` array — not the status code.
- **Introspection is often disabled in production.** If `__schema` returns an error, probe for specific type names you suspect exist using `{ __type(name: "User") { fields { name } } }`.
- **Alias batching bypasses rate limits.** `{ a: user(id:1) { id } b: user(id:2) { id } }` fires two resolvers in one HTTP request. Some servers cap the alias count per query.
- **Subscriptions need WebSocket, not HTTP.** A 404 or 400 on a WebSocket upgrade for `/graphql` doesn't mean subscriptions are absent — the server may route WebSocket and HTTP to different handlers on different ports or paths.
- **`__APOLLO_STATE__` is a goldmine.** The Apollo cache serialises every entity with its ID and all fetched fields. Read `window.__APOLLO_STATE__` in the browser to see all data the app has ever fetched — type names, IDs, field values — without making a single API call.
- **Partial success is valid.** A response with both `data` and `errors` is not a failure — it means some resolvers succeeded and others failed. Treat each resolver result independently.
- **Hasura JWT claims are in headers, not in the token itself.** Hasura reads user identity from `x-hasura-user-id`, `x-hasura-role`, `x-hasura-org-id` headers (extracted from JWT or set directly). If you have a valid session token, you can set these headers manually to test different roles.
