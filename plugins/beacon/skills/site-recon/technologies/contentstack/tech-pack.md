---
framework: contentstack
version: "3.x"
last_updated: "2026-05-11"
author: "@neotherapper"
status: community
---

# Contentstack — Tech Pack

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `contentstack.com` in requests | Network | API/asset hostnames | Definitive |
| `cdn.contentstack.com` in HTML | CDN | Asset delivery hostname | Definitive |
| `api.contentstack.com` in requests | API | API endpoint hostname | Definitive |
| `window.contentstack` | JS global | SDK initialized as global object | Definitive |
| `st-*` class prefixes in HTML | CSS class | Contentstack-rendered elements | High |
| `stack_api_key` in HTML | API param | Contentstack API key | High |
| `contentstack-js` in bundles | Package | SDK present in bundle | High |
| `x-api-key` header | HTTP header | Management API key header | High |
| `blt` prefix in request params | Token | Contentstack token patterns | Medium |

**Extract API key from HTML:**

```bash
# Check for Contentstack CDN patterns:
curl -s https://TARGET_DOMAIN/ | grep -oE '(cdn\.contentstack\.com|api\.contentstack\.com)'

# Extract API key from script tags:
curl -s https://TARGET_DOMAIN/ | grep -oE 'api_key["\']?\s*[:=]\s*["\']?[a-z0-9]{32,}'

# Search for Contentstack SDK initialization:
curl -s https://TARGET_DOMAIN/ | grep -oE 'contentstack[a-zA-Z]?\s*\(\s*[{"]' | head -3

# Search for stack configuration:
curl -s https://TARGET_DOMAIN/ | grep -oE 'stack[^}]*api_key[^}]+' | head -3
```

## 2. Default API Surfaces

| Endpoint | Method | Auth | Notes |
|----------|--------|------|-------|
| `https://cdn.contentstack.com/v3/content_types/{CONTENT_TYPE}/entries` | GET | `access_token` (query) | Delivery API — list entries |
| `https://cdn.contentstack.com/v3/assets` | GET | `access_token` (query) | Asset list |
| `https://cdn.contentstack.com/v3/content_types/{CONTENT_TYPE}/entries/{ENTRY_UID}` | GET | `access_token` (query) | Single entry |
| `https://api.contentstack.com/v3/{API_KEY}/environments` | GET | `api_key` header | Management API |
| `https://api.contentstack.com/v3/{API_KEY}/content_types` | GET/POST | `api_key` + `access_token` header | Content type management |
| `https://api.contentstack.com/v3/{API_KEY}/entries` | GET/POST | `api_key` + `access_token` header | Entry management |
| `https://api.contentstack.com/v3/{API_KEY}/assets` | GET/POST | `api_key` + `access_token` header | Asset management |

**Delivery API patterns:**

```
# Get entries of a content type
GET /v3/content_types/{CONTENT_TYPE}/entries?access_token={TOKEN}&locale=en-us

# Get single entry
GET /v3/content_types/{CONTENT_TYPE}/entries/{ENTRY_UID}?access_token={TOKEN}

# Get all content types
GET /v3/content_types?access_token={TOKEN}

# Query with filters
GET /v3/content_types/{CONTENT_TYPE}/entries?access_token={TOKEN}&query={"field":{"$exists":true}}
```

**Headers:**

```
# Delivery API
access_token: {DELIVERY_TOKEN}

# Management API
api_key: {API_KEY}
access_token: {MANAGEMENT_TOKEN}
```

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `window.contentstack` | Browser console | SDK instance and config |
| `window.Stack` | Browser console | Stack configuration |
| `st-*` CSS classes | HTML source | Contentstack-styled elements |
| `data-cs-label` attributes | HTML source | Contentstack metadata |
| `data-cs-version` attributes | HTML source | Version hints |
| Inline script config | HTML source | SDK initialization with keys |

**Example SDK initialization:**

```javascript
import contentstack from '@contentstack/delivery'
const stack = contentstack.Stack({ api_key: '{API_KEY}', delivery_token: '{TOKEN}', environment: '{ENV}' })
```

## 4. Auth Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| `access_token` query parameter | URL | Delivery API token |
| `access_token` header | HTTP header | Management API |
| `api_key` header | HTTP header | Contentstack API key |
| `stack_api_key` in config | JS config | Content type/API key |
| `delivery_token` | JS config | Delivery API token |

**Token discovery from HTML:**

```bash
# Search for API key patterns (32+ char alphanumeric):
curl -s https://TARGET_DOMAIN/ | grep -oE '[a-z0-9]{32,}'

# Search for Contentstack config:
curl -s https://TARGET_DOMAIN/ | grep -oE '"api_key"[^,}]+' | head -3

# Search for token patterns:
curl -s https://TARGET_DOMAIN/ | grep -oE '"access_token"[^,}]+' | head -3

# Search for delivery token:
curl -s https://TARGET_DOMAIN/ | grep -oE '"delivery_token"[^,}]+' | head -3
```

## 5. JS Bundle Patterns

| Path | Content |
|------|---------|
| `https://cdn.contentstack.com/javascripts/stencil/{VERSION}/main.js` | Stencil SDK (legacy) |
| `https://cdn.contentstack.com/v3/dist/stack/v3.0.0/stack-sdk.js` | Delivery SDK |
| `https://cdn.contentstack.com/static/.../contentstack-{BUNDLE}.js` | Modern SDK bundles |
| `https://assets.contentstack.com/{API_KEY}/{ASSET_PATH}` | Published assets |

## 6. Source Map Patterns

```bash
# Check for source maps on Contentstack SDK bundles:
SDK_URL=$(curl -s https://TARGET/ | grep -oE 'cdn\.contentstack\.com/[^"]+\.js' | head -1)
curl -I "${SDK_URL}.map" 2>/dev/null

# Check for source maps on app bundles:
curl -I "https://TARGET/contentstack.js.map" 2>/dev/null
```

## 7. Common Plugins & Extensions

| Integration | API it adds | Detection signal |
|-------------|-------------|------------------|
| `@contentstack/delivery` | Content delivery SDK | Bundle contains `contentstack-delivery` |
| `@contentstack/stack` | Core stack SDK | SDK initialization |
| `@contentstack-labs/plugins` | Labs plugins | Extension-specific bundles |
| `gatsby-source-contentstack` | Gatsby data layer | Gatsby GraphQL nodes |
| `contentstack-nuxt3` | Nuxt module | Vue components |

## 8. Known Public Data

| Endpoint | Data | Notes |
|----------|------|-------|
| `GET /v3/content_types?access_token={TOKEN}` | Content type definitions | Field schemas |
| `GET /v3/content_types/{TYPE}/entries?access_token={TOKEN}` | Published entries | Paginated |
| `GET /v3/assets?access_token={TOKEN}` | Asset list | Images, files |

## 9. Probe Checklist

- [ ] `GET /` — Check HTML for `cdn.contentstack.com`, `contentstack.com` in script/src tags
- [ ] Extract API key from SDK initialization or data attributes
- [ ] `GET /v3/content_types?access_token={TOKEN}` — List content types
- [ ] `GET /v3/content_types/{TYPE}/entries?access_token={TOKEN}&limit=1` — List entries of a type
- [ ] `GET /v3/content_types/{TYPE}/entries/{UID}?access_token={TOKEN}` — Single entry
- [ ] `GET /v3/assets?access_token={TOKEN}&limit=10` — List assets
- [ ] Check for `st-*` CSS class prefixes in HTML
- [ ] Look for `window.contentstack` or `window.Stack` globals
- [ ] Check for Contentstack-specific headers: `x-api-key`, `x-header`
- [ ] Identify environment (usually `development`, `staging`, or `production`)
- [ ] Probe for GraphQL endpoint if available: `POST /v3/graphql/{API_KEY}`
- [ ] Check for `data-cs-*` HTML attributes for version hints
- [ ] Verify locale patterns — Contentstack uses `en-us` format

## 10. Gotchas

- **API keys are 32+ character alphanumeric strings.** Contentstack API keys look like `blt1234567890abcdef1234567890abcdef`. The `blt` prefix helps identify them.

- **Delivery API uses query parameter, Management API uses headers.** The Delivery API passes `access_token` as a URL query parameter. The Management API passes `api_key` and `access_token` as HTTP headers.

- **Content types have UIDs, not just names.** When querying entries, use the content type UID (not the display name): `/v3/content_types/{CONTENT_TYPE_UID}/entries`.

- **Locales use underscore format.** Contentstack uses `en-us` (underscore) not `en-US` (hyphen). Wrong locale format returns no results.

- **CDN endpoint is `cdn.contentstack.com`, not `api.contentstack.com`.** The Delivery API is served from `cdn.contentstack.com` for performance. The Management API uses `api.contentstack.com`.

- **Entries have UIDs separate from their slugs.** Entry UIDs are system-generated and used in API calls. Custom slugs are separate fields in the entry data.

## 11. GitHub Code Search Patterns

| Search Query | What it finds |
|--------------|---------------|
| `site:github.com "contentstack" "api_key" language:javascript` | API key configuration |
| `site:github.com "cdn.contentstack.com" language:javascript` | CDN endpoint usage |
| `site:github.com "@contentstack" language:javascript` | NPM SDK usage |
| `site:github.com "contentstack" "access_token" language:javascript` | Token configuration |

## 12. Framework-Specific Google Dorks

| Search Query | What it finds |
|--------------|---------------|
| `site:{domain} inurl:cdn.contentstack.com` | Contentstack CDN assets |
| `site:{domain} inurl:api.contentstack.com` | Contentstack API requests |
| `site:{domain} "contentstack" "api_key"` | Exposed API keys |
| `site:{domain} "contentstack" "access_token"` | Exposed access tokens |

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
| Next.js | `getStaticProps`, `getServerSideProps` with Contentstack SDK |
| Gatsby | `gatsby-source-contentstack`, GraphQL nodes |
| Nuxt | `contentstack-nuxt3` module |
| SvelteKit | `@contentstack/svelte` integration |