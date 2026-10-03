---
framework: contentful
version: "current"
last_updated: "2026-05-11"
author: "@neotherapper"
status: community
---

# Contentful — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `cdn.contentful.com` in HTML/requests | CDN hostname | Script src or XHR to cdn.contentful.com | Definitive |
| `images.ctfassets.net` in HTML | CDN hostname | Image src pointing to Contentful image CDN | Definitive |
| `ctfl.io` in network requests | Domain | Preview or assets served via ctfl.io | Definitive |
| `contentful` in JS bundle names | Bundle | SDK bundle named `contentful.*.js` | High |
| `window.contentful` | JS global | SDK initialized as global object | High |
| `space_id` in request params | API param | Contentful space identifier | High |
| `access_token` query param | API param | Delivery or preview API token | High |
| `X-Contentful-Token` header | HTTP Header | Auth token in API requests | High |
| `_ga` cookie with Contentful analytics | Analytics | `/_ct` token in cookie | Medium |

**Extract space ID and content from HTML:**

```bash
# Check for Contentful CDN patterns in page source:
curl -s https://TARGET_DOMAIN/ | grep -oE '(cdn\.contentful\.com|images\.ctfassets\.net|ctfl\.io)'

# Extract space_id from Contentful API requests:
curl -s https://TARGET_DOMAIN/ | grep -oE 'space_id=[a-zA-Z0-9]+'

# Check for Contentful SDK initialization:
curl -s https://TARGET_DOMAIN/ | grep -oE 'contentful\.delivery|contentful\.preview|window\.contentful'
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://cdn.contentful.com/spaces/{SPACE}/environments/{ENV}/entries` | GET | `access_token` (query) | Content Delivery API — published entries |
| `https://cdn.contentful.com/spaces/{SPACE}/environments/{ENV}/assets` | GET | `access_token` (query) | Content Delivery API — assets |
| `https://cdn.contentful.com/spaces/{SPACE}/environments/{ENV}/tags` | GET | `access_token` (query) | Content Delivery API — tags |
| `https://preview.contentful.com/spaces/{SPACE}/environments/{ENV}/entries` | GET | `access_token` (query) | Content Preview API — draft content |
| `https://graphql.contentful.com/content/v1/spaces/{SPACE}` | POST | `access_token` (header) | GraphQL Content API |
| `https://api.contentful.com/spaces/{SPACE}/environments/{ENV}/entries` | GET/POST/PUT/DELETE | `access_token` (header) | Content Management API |
| `https://api.contentful.com/spaces/{SPACE}/environments/{ENV}/assets` | GET/POST/PUT/DELETE | `access_token` (header) | Asset management |
| `https://api.contentful.com/spaces/{SPACE}/environments/{ENV}/content_types` | GET | `access_token` (header) | Content type definitions |
| `https://api.contentful.com/spaces/{SPACE}/environments/{ENV}/locales` | GET | `access_token` (header) | Locale configuration |

**Delivery API pagination:**

```
https://cdn.contentful.com/spaces/{SPACE}/environments/{ENV}/entries?access_token={TOKEN}&limit=25&skip=0&order=-sys.createdAt
```

**GraphQL endpoint example:**

```bash
# Query published content via GraphQL:
curl -s -X POST https://graphql.contentful.com/content/v1/spaces/{SPACE} \
  -H "Authorization: Bearer {ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ entryCollection { items { sys { id } fields } } }"}'
```

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.contentful` | Browser console | SDK instance with client, space, environment |
| `window.__CONTEXTFUL__` | Browser console | Space ID, environment, locale config |
| `data-ctfl` attributes | HTML source | Inline content references |
| `<script src="cdn.contentful.com/...>` | HTML source | SDK initialization script |
| `contentful.json` in bundles | JS bundle content | SDK config and endpoints |
| `srcset` with `ctfassets.net` | HTML img tags | Contentful-hosted images |

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| `access_token` query parameter | URL | Delivery/Preview API token in URL params |
| `Authorization: Bearer {token}` | HTTP header | GraphQL and Management API |
| `X-Contentful-Token: {token}` | HTTP header | Alternative auth header format |
| `ContentfulToken` env var | Server config | CLI and build-time token |
| `CONTENTFUL_SPACE_ID` | Environment | Space identifier |

**API key discovery from HTML:**

```bash
# Search for delivery token in page source:
curl -s https://TARGET_DOMAIN/ | grep -oE 'access_token=[a-zA-Z0-9_-]+'

# Search for space ID patterns:
curl -s https://TARGET_DOMAIN/ | grep -oE 'space/[a-zA-Z0-9_-]+'

# Extract Contentful SDK initialization config:
curl -s https://TARGET_DOMAIN/ | grep -oE '{ "spaceId"[^}]+|"spaceId"[^,}]+|"accessToken"[^,}]+'
```

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `https://cdn.contentful.com/javascripts/contentful-{VERSION}.js` | Contentful Delivery SDK |
| `https://cdn.contentful.com/javascripts/contentful-preview.{VERSION}.js` | Contentful Preview SDK |
| `https://assets.ctfassets.net/{SPACE}/{ASSET_ID}/{FILENAME}` | Published asset files |
| `https://images.ctfassets.net/{SPACE}/{ASSET_ID}/{FILENAME}` | Optimized images |
| `https://downloads.ctfassets.net/{SPACE}/{ASSET_ID}/{FILENAME}` | Downloadable assets |

**Asset URL patterns:**

```
# Images with transformations:
https://images.ctfassets.net/{space}/{asset_id}/{filename}?w=800&h=600&fit=fill&f=center

# Generic assets:
https://assets.ctfassets.net/{space}/{asset_id}/{filename}
```

## 6. Source Map Patterns

```bash
# Check for source maps on Contentful SDK bundles:
SDK_URL=$(curl -s https://TARGET_DOMAIN/ | grep -oE 'cdn\.contentful\.com/javascripts/contentful[^"]+\.js' | head -1)
curl -I "${SDK_URL}.map"

# Check for source maps on app-specific bundles:
APP_BUNDLES=$(curl -s https://TARGET_DOMAIN/ | grep -oE 'https://[^"]+\.js' | grep -v contentful | head -10)
```

## 7. Common Plugins & Extensions

| Integration | API it adds | Detection signal |
|-------------|-------------|------------------|
| `@contentful/rich-text-*` | Rich text rendering | Bundle contains `rich-text` renderer |
| `contentful-import/export` | Content migration | CLI tools with specific API calls |
| Contentful UI Extensions | Custom editors | `ctf()` API in extension iframes |
| `gatsby-source-contentful` | Gatsby data layer | GraphQL nodes from Contentful |
| `next-contentful` | Next.js integration | API routes with Contentful SDK |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `GET /spaces/{SPACE}/environments/{ENV}/entries?access_token={TOKEN}` | Published content entries | Paginated, filterable by content type |
| `GET /spaces/{SPACE}/environments/{ENV}/assets?access_token={TOKEN}` | Media assets | Images, files, downloads |
| `GET /spaces/{SPACE}/environments/{ENV}/content_types?access_token={TOKEN}` | Content type schemas | Field definitions, entry structure |

## 9. Probe Checklist

- [ ] `GET /` — Check HTML for `cdn.contentful.com`, `images.ctfassets.net`, `ctfl.io` in script/src tags
- [ ] Extract space ID from network requests or bundle config
- [ ] `GET /spaces/{SPACE}/environments/master/entries?access_token={TOKEN}&limit=1` — Test Delivery API access
- [ ] `GET /spaces/{SPACE}/environments/master/content_types?access_token={TOKEN}` — Enumerate content types
- [ ] `GET /spaces/{SPACE}/environments/master/assets?access_token={TOKEN}&limit=10` — List media assets
- [ ] `POST /graphql/content/v1/spaces/{SPACE}` — Test GraphQL API (with token in header)
- [ ] Check for Preview API at `preview.contentful.com` — requires preview token
- [ ] Scan bundle JS for Contentful SDK initialization
- [ ] Look for `X-Contentful-*` headers on API responses
- [ ] Check response headers for `X-Contentful-Version` — indicates API version
- [ ] `GET /assets.ctfassets.net/{SPACE}/*` — Probe for specific asset patterns
- [ ] Identify if using Gatsby/Next.js wrapper by checking bundle patterns

## 10. Gotchas

- **Content Delivery API requires token but it's often public.** The delivery API token is meant for client-side use and is not treated as a secret. Many Contentful implementations embed it directly in JavaScript or HTML source. Finding it does not constitute a misconfiguration.

- **Space IDs are UUIDs.** Contentful space IDs look like `abc123def456789...` — long alphanumeric strings. Unlike other CMS platforms that use readable slugs, Contentful uses UUIDs that cannot be guessed easily.

- **Multiple environments exist by default.** Every Contentful space has at least a `master` environment (production). Additional environments like `staging`, `development` are common and use the same space ID with different environment IDs.

- **Preview API is separate from Delivery API.** Preview content requires a separate token and the `preview.contentful.com` hostname. Do not confuse the two — they have different endpoints and different auth requirements.

- **GraphQL and REST APIs have different schemas.** The GraphQL API (`graphql.contentful.com`) exposes content in a GraphQL-shaped schema, while the REST Delivery API returns a different structure. Be aware which you're querying.

## 11. GitHub Code Search Patterns

| Search Query | What it finds |
|--------------|---------------|
| `site:github.com "cdn.contentful.com" language:javascript` | Contentful SDK usage examples |
| `site:github.com "space_id" "contentful" language:javascript` | Space ID configuration patterns |
| `site:github.com "contentful" "access_token" language:javascript` | API token usage |
| `site:github.com "gatsby-source-contentful" language:javascript` | Gatsby + Contentful integrations |

## 12. Framework-Specific Google Dorks

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:cdn.contentful.com` | Contentful CDN assets |
| `site:{domain} inurl:ctfassets.net` | Contentful image assets |
| `site:{domain} "contentful" "access_token"` | Exposed API tokens |
| `site:{domain} "contentful" "space_id"` | Exposed space identifiers |

## 13. Cross-Cutting OSINT Patterns

### Favicon Hashing

```bash
# Get favicon hash for Shodan/Censys:
curl -s "https://{domain}/favicon.ico" | python3 -c "
import sys
data = sys.stdin.buffer.read()
import mmh3
print(mmh3.hash(data))
"
```

### Source Map Discovery

```bash
# Extract all JS bundle URLs:
curl -s "https://{domain}/" | grep -oP 'src=\"[^\"]+\.js[^\"]*\"' | grep -oP '"[^\"]+' | tr -d '"' > js_urls.txt

# Check each for .map file:
while read url; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "${url}.map")
  [ "$status" = "200" ] && echo "SOURCE MAP: ${url}.map"
done < js_urls.txt
```

### Tech Stack → CMS Pattern Mapping

| Framework | Common CMS Patterns |
|-----------|---------------------|
| Next.js | `/api/contentful/*`, `getStaticProps`, `getServerSideProps` |
| Gatsby | `gatsby-source-contentful`, GraphQL nodes |
| Nuxt | `@nuxt/contentful` module |
| Astro | `@astro/content` integration |