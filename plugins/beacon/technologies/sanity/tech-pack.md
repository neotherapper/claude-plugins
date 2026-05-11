---
framework: sanity
version: "3.x"
last_updated: "2026-05-11"
author: "@neotherapper"
status: community
---

# Sanity — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `sanity.io` or `sanitycdn.com` in requests | Network | API/asset hostnames | Definitive |
| `cdn.sanity.io` in HTML | CDN | Script src or img src | Definitive |
| `/_` route in URL | Route | Sanity Studio embedded | Definitive |
| `window.__SANITY__` or `window.SANITY_DATA` | JS global | Studio initialization | Definitive |
| `@sanity/client` in JS bundles | Package | SDK present in bundle | High |
| `projectId` in request params | API param | Sanity project identifier | High |
| `dataset` in request params | API param | Dataset name (usually `production`) | High |
| GROQ query string in request body | API | `{"query":"*[_type == '...']"}` | High |
| `sanity-io` in bundle filenames | Bundle | Sanity SDK bundles | High |
| `cdn.sanity.io/images/` in HTML | Image CDN | Image asset delivery | Definitive |

**Extract project ID from HTML:**

```bash
# Check for Sanity CDN patterns in page source:
curl -s https://TARGET_DOMAIN/ | grep -oE '(cdn\.sanity\.io|sanitycdn\.com)'

# Extract project ID from bundle or config:
curl -s https://TARGET_DOMAIN/ | grep -oE 'projectId[a-zA-Z": ]+[a-f0-9-]{32,}'

# Extract dataset name:
curl -s https://TARGET_DOMAIN/ | grep -oE 'dataset[a-zA-Z": ]+[a-z]+'
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://{PROJECT_ID}.api.sanity.io/v2024-01-01/data/query/{DATASET}` | POST | `Authorization: Bearer {TOKEN}` | GROQ query endpoint |
| `https://{PROJECT_ID}.api.sanity.io/v2024-01-01/assets/{DATASET}` | GET/POST | `Authorization: Bearer {TOKEN}` | Asset operations |
| `https://cdn.sanity.io/files/{PROJECT_ID}/{DATASET}/{FILENAME}` | GET | Public (usually) | Static asset delivery |
| `https://cdn.sanity.io/images/{PROJECT_ID}/{DATASET}/{FILENAME}` | GET | Public | Image transformation CDN |
| `https://{PROJECT_ID}.api.sanity.io/v1/graphql/{DATASET}/default` | POST | Public or token | GraphQL API (if enabled) |
| `https://{PROJECT_ID}.sanity.studio/` | GET | Auth (Studio) | Embedded Studio |
| `https://api.sanity.io/v2024-01-01/projects/{PROJECT_ID}` | GET | Token | Project metadata |

**GROQ Query Examples:**

```
# Query all documents of a type
POST /v2024-01-01/data/query/production
{"query":"*[_type == 'post']{_id, title, slug}"}

# Query with filters
{"query":"*[_type == 'post' && defined(slug.current)] | order(_createdAt desc)[0...10]"}

# Single document by ID
{"query":"*[_id == 'drafts.{ID}'][0]"}
```

**Image URL patterns:**

```
# Basic image
https://cdn.sanity.io/images/{PROJECT_ID}/{DATASET}/{FILENAME}

# With transformations
https://cdn.sanity.io/images/{PROJECT_ID}/{DATASET}/{FILENAME}?w=800&h=600&fit=crop
```

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.__SANITY__` | Browser console | Project ID, dataset, config |
| `window.SANITY_DATA` | Browser console | Embedded studio data |
| `window.__INITIAL_STATE__` | Browser console | Sanity Studio initial state |
| `data-project-id` attribute | HTML source | Project ID in DOM |
| `data-dataset` attribute | HTML source | Dataset name in DOM |
| `sanity.json` in bundles | JS bundle content | SDK configuration |
| `/_` route HTML | `/_` page source | Embedded Studio config |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| `Authorization: Bearer {token}` | HTTP header | API token for Management API |
| `X-Sanity-Client` header | HTTP header | Client identification |
| `projectId` + `dataset` | Public config | No auth for read operations |
| API token in client config | JS bundle or env | Write operations require token |
| Sanity account OAuth | `sanity.login` domain | Studio authentication |

**Token discovery from HTML:**

```bash
# Search for project ID patterns:
curl -s https://TARGET_DOMAIN/ | grep -oE '[a-f0-9]{32}' | head -5

# Search for Sanity config in scripts:
curl -s https://TARGET_DOMAIN/ | grep -oE '"projectId"[^,}]+' | head -3

# Search for token patterns (may be in write-enabled configs):
curl -s https://TARGET_DOMAIN/ | grep -oE 'sanity[A-Za-z0-9_-]*token[^,}]+' | head -3
```

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `https://cdn.sanity.io/{VERSION}/js/{BUNDLE}.js` | Sanity Studio core bundles |
| `https://cdn.sanity.io/{VERSION}/css/{BUNDLE}.css` | Studio styles |
| `https://cdn.sanity.io/images/{PROJECT}/{DATASET}/{FILE}` | Image assets |
| `https://cdn.sanity.io/files/{PROJECT}/{DATASET}/{FILE}` | File assets |
| `/_/{BUNDLE}.js` | Embedded Studio JS |
| `/_/{BUNDLE}.css` | Embedded Studio CSS |

**Sanity Studio embedded in Next.js:**

```
/_/index.js — Studio entry point
/_/vendor.js — Third-party deps
/_/studio.js — Studio app bundle
```

## 6. Source Map Patterns

```bash
# Check for source maps on Sanity CDN bundles:
SANITY_JS=$(curl -s https://TARGET/ | grep -oE 'cdn\.sanity\.io/[^"]+\.js' | head -1)
curl -I "${SANITY_JS}.map" 2>/dev/null

# Check for source maps on embedded Studio:
curl -I "https://TARGET/_.js.map" 2>/dev/null

# Check for studio maps:
curl -I "https://TARGET/studio.js.map" 2>/dev/null
```

## 7. Common Plugins & Extensions

| Integration | API it adds | Detection signal |
|-------------|-------------|------------------|
| `@sanity/client` | API client | Bundle contains `sanity-client` |
| `sanity-plugin-*` | Studio plugins | `sanity.io/plugins/` route |
| `@sanity/image-url` | Image URL builder | Image URL transforms |
| `GROQ` queries | Content retrieval | POST bodies with GROQ syntax |
| `sanity-plugin-portable-text` | Rich text | Portable Text rendering |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `POST /v2024-01-01/data/query/{DATASET}?query=*[_type == '...']` | Published content | Read operations don't require token |
| `GET /v2024-01-01/assets/{DATASET}/{ASSET_ID}` | Asset metadata | Asset operations |
| `https://cdn.sanity.io/images/{PROJECT}/{DATASET}/{FILE}` | Image files | Public image delivery |

## 9. Probe Checklist

- [ ] `GET /` — Check HTML for `cdn.sanity.io` in script/src tags
- [ ] Extract project ID from network requests or HTML data attributes
- [ ] `POST /v2024-01-01/data/query/{DATASET}` with `{"query":"*[_type == 'post'][0...5]{_type,_id}"}` — List document types
- [ ] `POST /v2024-01-01/data/query/{DATASET}` with `{"query":"*[_type in path('**')]{_type} | unique"}` — Enumerate all document types
- [ ] `POST /v2024-01-01/data/query/{DATASET}` with `{"query":"count(*[_type == '...'])"}` — Count documents per type
- [ ] `GET /v2024-01-01/assets/{DATASET}` — List assets
- [ ] Check for GraphQL endpoint at `/v1/graphql/{DATASET}/default`
- [ ] Scan JS bundles for `@sanity/client` and SDK initialization
- [ ] Check `/_` route for embedded Sanity Studio
- [ ] Look for `window.__SANITY__` or `window.SANITY_DATA` globals
- [ ] Probe image CDN: `GET /images/{PROJECT}/{DATASET}/{FILENAME}?w=100`
- [ ] Identify dataset name (usually `production` but may be custom)
- [ ] Check for GROQ query strings in browser network tab

## 10. Gotchas

- **Project IDs are 32-character hex strings.** Sanity project IDs look like `abc123def456789012345678901234` — exactly 32 hex characters. This makes them distinctive and easier to identify than UUIDs.

- **GROQ queries are POST bodies, not URL params.** Unlike most APIs that use GET with query strings, Sanity's API sends GROQ queries as JSON in the POST body: `{"query": "*[_type == 'post']"}`.

- **The dataset is separate from the project.** The same project can have multiple datasets (e.g., `production`, `staging`, `test`). The default is usually `production`.

- **Sanity Studio is often embedded at `/_` in Next.js.** Many Next.js + Sanity sites embed the Studio at the `/_` route. This route returns HTML containing the full Studio configuration and can be probed for project metadata.

- **Images use a separate CDN with transformation API.** Image URLs at `cdn.sanity.io/images/` support on-the-fly transformations via URL parameters (`?w=800&h=600&fit=crop`). This is different from the API endpoint.

- **Read operations on the Content Lake API are often public.** The `api.sanity.io` endpoint for queries does not always require authentication for read operations. However, write operations require a token.

## 11. GitHub Code Search Patterns

| Search Query | What it finds |
|--------------|---------------|
| `site:github.com "@sanity/client" language:javascript` | Sanity client usage |
| `site:github.com "projectId" "sanity" language:javascript` | Project ID configuration |
| `site:github.com "GROQ" "sanity" language:javascript` | GROQ query examples |
| `site:github.com "cdn.sanity.io" language:javascript` | CDN asset patterns |

## 12. Framework-Specific Google Dorks

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:cdn.sanity.io` | Sanity CDN assets |
| `site:{domain} inurl:sanity.io` | Sanity API requests |
| `site:{domain} "projectId" "sanity"` | Exposed project IDs |
| `site:{domain} "sanity" "groq"` | GROQ query examples |

## 13. Cross-Cutting OSINT Patterns

### Favicon Hashing

```bash
curl -s "https://{domain}/favicon.ico" | python3 -c "
import sys
data = sys.stdin.buffer.read()
import mmh3
print(mmh3.hash(data))
"
```

### Source Map Discovery

```bash
curl -s "https://{domain}/" | grep -oP 'src=\"[^\"]+\.js[^\"]*\"' | grep -oP '"[^\"]+' | tr -d '"' > js_urls.txt
while read url; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "${url}.map")
  [ "$status" = "200" ] && echo "SOURCE MAP: ${url}.map"
done < js_urls.txt
```

### Tech Stack → CMS Pattern Mapping

| Framework | Common CMS Patterns |
|-----------|---------------------|
| Next.js | `/_/`, `getStaticProps`, `getServerSideProps` |
| Gatsby | `gatsby-source-sanity`, GraphQL nodes |
| Nuxt | `@nuxtjs/sanity` module |
| SvelteKit | `@sanity/client` in SvelteKit endpoints |