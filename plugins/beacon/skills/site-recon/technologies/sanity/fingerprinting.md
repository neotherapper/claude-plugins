# Sanity Framework Fingerprinting Guide

## Discovery Techniques

### 1. Network-Based Detection

Sanity integrations make requests to specific Sanity-owned domains. Monitor network requests for:

| Domain | Purpose | Confidence |
|--------|---------|------------|
| `api.sanity.io` | Content Lake API | Definitive |
| `cdn.sanity.io` | Asset and JS delivery | Definitive |
| `sanitycdn.com` | Legacy CDN | Definitive |
| `sanity.studio` | Studio domain | Definitive |
| `sanity.io` | Documentation and login | Definitive |
| `_ `_` route in Next.js | Embedded Studio | Definitive |

### 2. JavaScript Global Detection

Check browser console for Sanity SDK objects:

```javascript
// Studio initialization (embedded)
window.__SANITY__
window.__SANITY_DATA__
window.__INITIAL_STATE__

// Client initialization
window.__NEXT_DATA__.props.pageProps.sanityData

// Sanity image URL builder
window.__SANITY_IMAGE_BUILDER__
```

### 3. HTML Source Analysis

Look for these patterns in HTML source:

```html
<!-- Sanity CDN scripts -->
<script src="//cdn.sanity.io/sanity.@VERSION.js"></script>

<!-- Sanity image -->
<img src="//cdn.sanity.io/images/{PROJECT}/{DATASET}/{FILE}">

<!-- Embedded Studio -->
<link rel="stylesheet" href="/_/studio.css">

<!-- Data attributes -->
<div data-project-id="..." data-dataset="...">
```

### 4. API Request Pattern Detection

Sanity API requests follow these patterns:

```bash
# GROQ query (POST to data endpoint)
POST /v2024-01-01/data/query/{DATASET}
{"query":"*[_type == 'post']{title}"}

# Image URL pattern
https://cdn.sanity.io/images/{PROJECT_ID}/{DATASET}/{FILENAME}?w=800

# GraphQL (if enabled)
POST /v1/graphql/{DATASET}/default
```

## Version Detection

Sanity version detection methods:

| Method | Indicator |
|--------|-----------|
| SDK version in CDN URL | `cdn.sanity.io/sanity@VERSION/js/...` |
| `X-Sanity-Version` header | May appear in API responses |
| Bundle filename patterns | `sanity.@MAJOR.min.js` |
| API version in path | `v2024-01-01` is current, `v1` is older |

**Extract version from HTML:**

```bash
# Get SDK version from CDN URL
curl -s https://TARGET/ | grep -oE 'cdn\.sanity\.io/sanity@[0-9]+\.[0-9]+\.[0-9]+/'

# Check API version in requests
curl -s https://TARGET/ | grep -oE 'v2024-01-01|v1'
```

## Confidence Levels

| Confidence | Signal | Action |
|------------|--------|--------|
| Definitive | `api.sanity.io` or `cdn.sanity.io` in requests | Confirm Sanity |
| High | `@sanity/client` in bundle, GROQ queries | Confirm Sanity |
| High | `/_` route with Studio content | Confirm embedded Studio |
| Medium | `projectId` in HTML attributes | Investigate further |
| Low | `sanity` in generic analytics | May be coincidence |

## Fingerprinting Commands

### Basic Detection

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET="https://target.example.com"

echo "=== Sanity Detection ==="

# Check for Sanity CDN patterns
echo "CDN patterns:"
curl -s "$TARGET" | grep -oE '(cdn\.sanity\.io|sanitycdn\.com|sanity\.io)' | sort -u

# Check for embedded Studio
echo -e "\nEmbedded Studio routes:"
curl -s "$TARGET" | grep -oE '/_[/]?(?:studio|index)?' | sort -u

# Check for project ID patterns (32-char hex)
echo -e "\nPotential Project IDs:"
curl -s "$TARGET" | grep -oE '[a-f0-9]{32}' | sort -u | head -3

# Check for dataset patterns
echo -e "\nDataset names:"
curl -s "$TARGET" | grep -oE '"dataset"[a-zA-Z": ]+[a-z_]+' | head -5
```

### Advanced Fingerprinting

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET="https://target.example.com"

echo "=== Advanced Sanity Fingerprinting ==="

# Extract all unique hostnames from page
echo "All external domains:"
curl -s "$TARGET" | grep -oE 'https?://[^"'\''> ]+' | awk -F/ '{print $3}' | sort -u

# Check for GROQ query patterns in bundles
echo -e "\nGROQ patterns in bundles:"
curl -s "$TARGET" | grep -oE '\*\[_[a-z_ ==!\]]+' | sort -u | head -10

# Check for Sanity-specific route patterns
echo -e "\nSanity-specific routes:"
curl -s "$TARGET" | grep -oE '"/_[^"]+"|"/studio[^"]*"' | sort -u

# Probe embedded Studio if present
echo -e "\nProbing embedded Studio:"
STUDIO_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/_/")
echo "Studio status: $STUDIO_STATUS"

# Check for source maps
echo -e "\nSource map check:"
curl -s "$TARGET" | grep -oE 'cdn\.sanity\.io/[^"]+\.js' | while read js; do
  map_status=$(curl -s -o /dev/null -w "%{http_code}" "https://${js}.map")
  [ "$map_status" = "200" ] && echo "  FOUND: ${js}.map"
done
```

## False Positives

- **Third-party Sanity widgets:** Embedded Sanity content on non-Sanity sites
- **CDN aliases:** Some CDNs may use similar domain patterns
- **Project ID collision:** 32-char hex patterns could match other systems
- **GROQ-like syntax:** Other systems may use similar bracket notation

## Security Considerations

### Common Security Headers on Sanity-served Content

```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Content-Security-Policy: default-src 'self' *.sanity.io
Strict-Transport-Security: max-age=31536000
```

### Potential Information Disclosure

- **Project ID exposure:** Publicly visible in all requests and HTML
- **Dataset name:** Often `production` — reveals data architecture
- **Content type names:** Schema reveals content model structure
- **GROQ queries in logs:** Query strings may expose content patterns
- **API tokens:** Write tokens should never appear in client-side code

## Technology Stack Integration

### Common Sanity Pairings

| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| React | UI framework | React DevTools, `window.__REACT_DEVTOOLS_GLOBAL_HOOK__` |
| Next.js | SSR/SSG | `/_` routes, `/_next/` paths |
| TypeScript | Language | `.ts` in bundle names, type annotations |
| GROQ | Query language | POST body queries |
| GraphQL | Alternative API | `/v1/graphql/` endpoint (if enabled) |

### Content Delivery Flow

```
Sanity Studio → Content Lake → API → CDN → Site
                      ↓
              GraphQL (optional)
```

## Fingerprinting Tooling

- **Wappalyzer browser extension** — Detects Sanity via package.json or meta tags
- **BuiltWith** — Technology detection for Sanity integrations
- **HTTP Archive** — Historical Sanity usage patterns
- **Shodan** — Search `http.html:sanity` for Sanity-powered sites

## Changelog

- 2026-05-11: Initial Sanity fingerprinting guide
- Future: Add GROQ-specific detection patterns