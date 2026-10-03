---
framework: storyblok
version: "2.x"
last_updated: "2026-05-11"
author: "@neotherapper"
status: community
---

# Storyblok — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `storyblok.com` in requests | Network | API/asset hostnames | Definitive |
| `a.storyblok.com` or `img2.storyblok.com` in HTML | CDN | Asset and image delivery | Definitive |
| `api.storyblok.com` in requests | API | API endpoint hostname | Definitive |
| `window.Storyblok` | JS global | SDK initialized as global object | Definitive |
| `storyblok-js` in bundles | Package | SDK present in bundle | High |
| `_storyblork` cookie | Cookie | Preview mode active | High |
| `space_id` in request params | API param | Storyblok space identifier | High |
| `version` param in API calls | API param | `published` or `draft` | High |
| `storyblokcdn.com` | CDN | Legacy asset delivery | High |

**Extract space ID from HTML:**

```bash
# Check for Storyblok CDN patterns:
curl -s https://TARGET_DOMAIN/ | grep -oE '(a\.storyblok\.com|img2\.storyblok\.com|api\.storyblok\.com)'

# Extract space ID from SDK initialization:
curl -s https://TARGET_DOMAIN/ | grep -oE '"spaceId"[a-zA-Z": ]+[0-9]+'

# Search for Storyblok config:
curl -s https://TARGET_DOMAIN/ | grep -oE 'storyblok[a-zA-Z"]*\s*[:=]\s*[{"]?[a-zA-Z0-9_-]+'
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://api.storyblok.com/v2/cdn/stories/{SLUG}` | GET | `token` (query) | Single story by slug |
| `https://api.storyblok.com/v2/cdn/story/{SLUG}` | GET | `token` (query) | Single story (alternate) |
| `https://api.storyblok.com/v2/cdn/stories` | GET | `token` (query) | All stories, filterable |
| `https://api.storyblok.com/v2/cdn/datasources/{DATASOURCE}` | GET | `token` (query) | Datasource values |
| `https://api.storyblok.com/v2/cdn/links` | GET | `token` (query) | Story links tree |
| `https://api.storyblok.com/v2/spaces/{SPACE_ID}/stories` | GET/POST | `Bearer {TOKEN}` | Management API |
| `https://api.storyblok.com/v2/spaces/{SPACE_ID}/assets` | GET/POST | `Bearer {TOKEN}` | Asset management |
| `https://api.storyblok.com/v2/spaces/{SPACE_ID}/stories/{ID}` | GET/PUT/DELETE | `Bearer {TOKEN}` | Story CRUD |

**API Versioning:**

| Version | Notes |
|---------|-------|
| `v2` | Current stable API version |
| `v1` | Legacy, no longer actively developed |

**Request examples:**

```
# Get published story
GET /v2/cdn/stories/home?token={PUBLIC_TOKEN}&version=published

# Get draft story
GET /v2/cdn/stories/home?token={PUBLIC_TOKEN}&version=draft

# Get all stories
GET /v2/cdn/stories?token={PUBLIC_TOKEN}&per_page=25&page=1

# Stories with filter
GET /v2/cdn/stories?token={PUBLIC_TOKEN}&starts_with=blog/&sort_by=published_at:desc
```

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.Storyblok` | Browser console | SDK instance, configuration |
| `window.StoryblokBridge` | Browser console | Visual Editor bridge |
| `window.storyblok` | Browser console | Alternative SDK global |
| `data-src` attributes | HTML source | Storyblok asset references |
| `data-blok-uid` attributes | HTML source | Block identifiers |
| `data-blok-c` attributes | HTML source | Component names |
| Inline script config | HTML source | SDK initialization with token |

**Example SDK initialization:**

```javascript
window.storyblok = new window.Storyblok({
  accessToken: '{PUBLIC_TOKEN}',
  cache: { clear: 'auto', type: 'memory' }
})
```

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| `token` query parameter | URL | Public token for Content Delivery API |
| `Authorization: Bearer {token}` | HTTP header | Management API |
| `_storyblork` cookie | Cookie jar | Visual Editor preview session |
| `私人令牌` (private token) | Space settings | Write operations |

**Token discovery from HTML:**

```bash
# Search for public token in script tags:
curl -s https://TARGET_DOMAIN/ | grep -oE 'token["\']?\s*[:=]\s*["\']?[a-zA-Z0-9_-]{20,}'

# Search for Storyblok SDK config:
curl -s https://TARGET_DOMAIN/ | grep -oE 'new Storyblok[a-zA-Z(\s)]*'

# Search for space ID:
curl -s https://TARGET_DOMAIN/ | grep -oE 'spaceId["\']?\s*[:=]\s*["\']?[0-9]+'
```

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `https://app.storyblok.com/f/{VERSION}/storyblok-{BUNDLE}.js` | Storyblok JS SDK |
| `https://a.storyblok.com/{SPACE_ID}/{ASSET_PATH}` | Published assets |
| `https://img2.storyblok.com/{SPACE_ID}/{ASSET_PATH}` | Optimized images |
| `https://yourdomain.com/(storyblok_debugger)` | Visual editor helper |

## 6. Source Map Patterns

```bash
# Check for source maps on Storyblok SDK bundles:
SDK_URL=$(curl -s https://TARGET/ | grep -oE 'app\.storyblok\.com/f/[^"]+\.js' | head -1)
curl -I "${SDK_URL}.map" 2>/dev/null

# Check for source maps on app bundles:
curl -I "https://TARGET/storyblok.js.map" 2>/dev/null
```

## 7. Common Plugins & Extensions

| Integration | API it adds | Detection signal |
|-------------|-------------|------------------|
| `@storyblok/js` | Core SDK | JS bundle contains `storyblok-js` |
| `storyblok-js-client` | Core client | SDK client in bundles |
| `gatsby-source-storyblok` | Gatsby data layer | Gatsby GraphQL nodes |
| `nuxt-storyblok` | Nuxt module | Vue components |
| `@storyblok/react` | React renderer | React component registration |
| `@storyblok/vue` | Vue renderer | Vue component registration |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `GET /v2/cdn/stories` | Story list with metadata | Paginated |
| `GET /v2/cdn/stories/{SLUG}` | Single story with content | Full component tree |
| `GET /v2/cdn/links` | Story navigation tree | Hierarchical structure |
| `GET /v2/cdn/datasources/{KEY}` | Datasource values | Dropdown options |

## 9. Probe Checklist

- [ ] `GET /` — Check HTML for `storyblok.com`, `a.storyblok.com`, `img2.storyblok.com` in script/src tags
- [ ] Extract space ID from SDK initialization or network requests
- [ ] `GET /v2/cdn/stories?token={PUBLIC_TOKEN}&per_page=1` — Test Delivery API access
- [ ] `GET /v2/cdn/stories/home?token={PUBLIC_TOKEN}&version=published` — Fetch homepage story
- [ ] `GET /v2/cdn/links?token={PUBLIC_TOKEN}` — Get story navigation tree
- [ ] `GET /v2/cdn/stories?starts_with=blog/&token={PUBLIC_TOKEN}` — Blog posts
- [ ] Check for preview endpoint: `version=draft` parameter
- [ ] Scan for `window.Storyblok` or `window.storyblok` in JS globals
- [ ] Look for `_storyblork` cookie for Visual Editor presence
- [ ] Check for Storyblok component classes in HTML: `data-blok-uid`, `data-blok-c`
- [ ] `GET /v2/cdn/datasources?token={PUBLIC_TOKEN}` — List datasources
- [ ] Identify if using Visual Editor by checking for `app.storyblok.com` iframe
- [ ] Probe for specific asset URLs at `a.storyblok.com/{SPACE}/`

## 10. Gotchas

- **Space IDs are integers, not UUIDs.** Storyblok space IDs are numeric (e.g., `123456`). This is different from Contentful's UUID-based spaces and Sanity's 32-char hex project IDs.

- **The `version` parameter controls draft vs published.** Use `version=published` for live content and `version=draft` for draft content (requires preview or private token).

- **Stories are fetched by slug, not by ID (in Delivery API).** The Content Delivery API uses slugs like `/v2/cdn/stories/home`. The Management API uses numeric IDs.

- **Component names are visible in the HTML.** Storyblok renders component names in `data-blok-c` attributes in the HTML. This reveals the content model structure.

- **Visual Editor creates a cookie.** The `_storyblork` cookie is set when the Visual Editor is active. It enables draft content viewing.

- **Asset URLs are cached and have specific patterns.** Assets at `a.storyblok.com` follow the pattern `/{SPACE_ID}/{RELATIVE_PATH}`. Image transformations are handled at `img2.storyblok.com`.

## 11. GitHub Code Search Patterns

| Search Query | What it finds |
|--------------|---------------|
| `site:github.com "storyblok" "accessToken" language:javascript` | API token configuration |
| `site:github.com "new Storyblok" language:javascript` | SDK initialization |
| `site:github.com "api.storyblok.com" language:javascript` | API usage |
| `site:github.com "gatsby-source-storyblok" language:javascript` | Gatsby integration |

## 12. Framework-Specific Google Dorks

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:a.storyblok.com` | Storyblok CDN assets |
| `site:{domain} inurl:img2.storyblok.com` | Storyblok images |
| `site:{domain} "storyblok" "token"` | Exposed API tokens |
| `site:{domain} "storyblok" "spaceId"` | Exposed space IDs |

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
| Next.js | `/_storyblok/`, `getStaticProps` |
| Gatsby | `gatsby-source-storyblok`, GraphQL nodes |
| Nuxt | `storyblok-nuxt` module, Vue components |
| SvelteKit | `@storyblok/svelte` integration |