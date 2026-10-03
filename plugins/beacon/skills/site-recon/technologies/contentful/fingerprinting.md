# Contentful Framework Fingerprinting Guide

## Discovery Techniques

### 1. Network-Based Detection

Contentful integrations make requests to specific Contentful-owned domains. Monitor network requests for:

| Domain | Purpose | Confidence |
|--------|---------|------------|
| `cdn.contentful.com` | SDK and asset delivery | Definitive |
| `images.ctfassets.net` | Image transformation CDN | Definitive |
| `assets.ctfassets.net` | Binary asset delivery | Definitive |
| `ctfl.io` | Preview and live preview | Definitive |
| `preview.contentful.com` | Preview API endpoint | Definitive |
| `graphql.contentful.com` | GraphQL API endpoint | Definitive |
| `api.contentful.com` | Management API endpoint | Definitive |

### 2. JavaScript Global Detection

Check browser console for Contentful SDK objects:

```javascript
// Contentful SDK instance
window.contentful

// Delivery client initialization
window.contentfulDelivery

// Preview client initialization
window.contentfulPreview

// Space context
window.__CONTEXTFUL__
```

### 3. HTML Source Analysis

Look for these patterns in HTML source:

```html
<!-- Contentful SDK script -->
<script src="//cdn.contentful.com/javascripts/contentful-*.js"></script>

<!-- Contentful image -->
<img src="//images.ctfassets.net/...">

<!-- Contentful asset -->
<link href="//assets.ctfassets.net/...">

<!-- Inline config -->
<div data-contentful-space-id="..."></div>
```

### 4. API Request Pattern Detection

Contentful API requests follow these patterns:

```
# Delivery API
GET /spaces/{SPACE}/environments/{ENV}/entries?access_token={TOKEN}

# GraphQL
POST /content/v1/spaces/{SPACE}

# Asset URLs
https://images.ctfassets.net/{SPACE}/{ASSET_ID}/{FILENAME}
```

## Version Detection

Contentful doesn't expose version in standard headers. Detect version via:

| Method | Indicator |
|--------|-----------|
| SDK version in bundle filename | `contentful-{VERSION}.js` |
| API version header | `X-Contentful-Version` in responses |
| Feature detection | GraphQL support = newer, Preview API = v3+ |

**Extract SDK version from HTML:**

```bash
# Get SDK version from bundle URL
curl -s https://TARGET/ | grep -oE 'contentful-[0-9]+\.[0-9]+\.[0-9]+\.js' | head -1

# Check response headers for version
curl -I https://cdn.contentful.com/spaces/{SPACE}/environments/master/entries 2>/dev/null | grep -i 'x-contentful'
```

## Confidence Levels

| Confidence | Signal | Action |
|------------|--------|--------|
| Definitive | `cdn.contentful.com` or `images.ctfassets.net` in requests | Confirm Contentful |
| High | `contentful` SDK in JS bundles | Likely Contentful |
| Medium | `space_id` or `access_token` in params | Investigate further |
| Low | Generic analytics cookies | May be coincidence |

## Fingerprinting Commands

### Basic Detection

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET="https://target.example.com"

echo "=== Contentful Detection ==="

# Check for Contentful CDN patterns
echo "CDN patterns:"
curl -s "$TARGET" | grep -oE '(cdn\.contentful\.com|images\.ctfassets\.net|ctfl\.io)' | sort -u

# Check for Contentful SDK
echo -e "\nSDK patterns:"
curl -s "$TARGET" | grep -oE 'contentful[a-z_-]*\.(js|ts)' | sort -u

# Check for API tokens
echo -e "\nAPI tokens:"
curl -s "$TARGET" | grep -oE 'access_token=[a-zA-Z0-9_-]+' | sort -u

# Check for space IDs
echo -e "\nSpace IDs:"
curl -s "$TARGET" | grep -oE 'space[a-z_/]*[a-f0-9-]{36}' | sort -u
```

### Advanced Fingerprinting

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET="https://target.example.com"
echo "=== Advanced Contentful Fingerprinting ==="

# Get all unique domains from page
echo "All external domains:"
curl -s "$TARGET" | grep -oE 'https?://[^"'\''> ]+' | awk -F/ '{print $3}' | sort -u

# Check for Contentful-specific headers
echo -e "\nContentful headers (if proxied):"
curl -I -s "$TARGET" 2>/dev/null | grep -i 'contentful'

# Extract bundle URLs and analyze
echo -e "\nJS bundle analysis:"
BUNDLES=$(curl -s "$TARGET" | grep -oE 'src="[^"]+\.js[^"]*"' | grep -oE '"[^"]+' | tr -d '"')
for bundle in $BUNDLES; do
  if echo "$bundle" | grep -q 'contentful'; then
    echo "CONTENTFUL BUNDLE: $bundle"
    # Check for source map
    curl -s -o /dev/null -w "%{http_code}" "${bundle}.map" | xargs -I{} echo "  .map status: {}"
  fi
done
```

## False Positives

- **CDN aliases:** Some CDNs serve Contentful assets but aren't Contentful sites
- **Third-party embeds:** Embedded Contentful content widgets on non-Contentful sites
- **CDN pattern matches:** Generic CDN patterns may false-match on similar domain structures

## Security Considerations

### Common Security Headers on Contentful-served Content

```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Content-Security-Policy: default-src 'self' *.contentful.com
Strict-Transport-Security: max-age=31536000
```

### Potential Information Disclosure

- **API tokens in source:** Delivery tokens visible in HTML/JS (expected, not a bug)
- **Content preview:** Draft content accessible via Preview API if token leaked
- **Content type schemas:** Content model structure reveals data architecture
- **Asset URLs:** Predictable URL patterns may leak asset inventory

## Technology Stack Integration

### Common Contentful Pairings

| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| React | UI framework | React DevTools, `window.__REACT_DEVTOOLS_GLOBAL_HOOK__` |
| Next.js | SSR/SSG | `/_next/` paths, `next.js` in bundles |
| Gatsby | Static generation | `gatsby-*` bundles, `/static/` builds |
| TypeScript | Language | `.ts` in bundle names or source maps |
| GraphQL | Query layer | `graphql.contentful.com` requests |

### Content Delivery Flow

```
Contentful Space → Delivery API → [Gatsby/Next.js Build] → Static Files → CDN
                                      ↓
                              Preview API → Preview Server
```

## Fingerprinting Tooling

- **Wappalyzer browser extension** — Detects Contentful via package.json or meta tags
- **BuiltWith** — Detects Contentful integrations via technology fingerprinting
- **HTTP Archive** — Historical Contentful usage patterns
- **Shodan** — Search `http.html:contentful` for Contentful-powered sites

## Changelog

- 2026-05-11: Initial Contentful fingerprinting guide
- Future: Add GraphQL-specific detection patterns