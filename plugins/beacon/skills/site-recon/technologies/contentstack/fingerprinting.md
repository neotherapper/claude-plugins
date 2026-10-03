# Contentstack Framework Fingerprinting Guide

## Discovery Techniques

### 1. Network-Based Detection

Contentstack integrations make requests to specific Contentstack-owned domains. Monitor network requests for:

| Domain | Purpose | Confidence |
|--------|---------|------------|
| `cdn.contentstack.com` | Delivery API and asset CDN | Definitive |
| `api.contentstack.com` | Management API | Definitive |
| `app.contentstack.com` | Management dashboard | Definitive |
| `assets.contentstack.com` | Asset delivery | Definitive |

### 2. JavaScript Global Detection

Check browser console for Contentstack SDK objects:

```javascript
// Core SDK
window.contentstack
window.Stack
window.contentstackSdk

// Stack configuration
window.contentstack?.stack

// Delivery client
window.contentstack?.Delivery
```

### 3. HTML Source Analysis

Look for these patterns in HTML source:

```html
<!-- Contentstack SDK script -->
<script src="//cdn.contentstack.com/v3/dist/stack/v3.0.0/stack-sdk.js"></script>

<!-- Contentstack-styled elements -->
<div class="st-*"> or <div class="st-*-wrapper">

<!-- Contentstack metadata -->
<div data-cs-label="..." data-cs-content-type="...">

<!-- Contentstack API config -->
<script>
  var stack = contentstack.Stack({
    api_key: "...",
    delivery_token: "...",
    environment: "..."
  });
</script>
```

### 4. API Request Pattern Detection

Contentstack API requests follow these patterns:

```
# Delivery API (CDN)
GET /v3/content_types/{CONTENT_TYPE}/entries?access_token={TOKEN}

# Management API
GET https://api.contentstack.com/v3/{API_KEY}/content_types

# Assets
GET https://cdn.contentstack.com/v3/assets?access_token={TOKEN}
```

## Version Detection

Contentstack version detection methods:

| Method | Indicator |
|--------|-----------|
| SDK version in CDN URL | `cdn.contentstack.com/v3/dist/stack/{VERSION}/` |
| Header `x-contentstack-version` | API response headers |
| `st-*` CSS class patterns | Stencil-based rendering |
| API version in path | `v3/` is current |

**Extract version from HTML:**

```bash
# Get SDK version from CDN URL
curl -s https://TARGET/ | grep -oE 'cdn\.contentstack\.com/v3/dist/stack/[0-9.]+/'

# Check for version header
curl -I "https://cdn.contentstack.com/v3/content_types" 2>/dev/null | grep -i 'x-contentstack'
```

## Confidence Levels

| Confidence | Signal | Action |
|------------|--------|--------|
| Definitive | `cdn.contentstack.com` or `api.contentstack.com` in requests | Confirm Contentstack |
| Definitive | `window.contentstack` or `window.Stack` in JS globals | Confirm Contentstack |
| High | `cdn.contentstack.com` in script/src | Confirm Contentstack |
| High | `st-*` CSS class prefixes | Confirm Contentstack |
| Medium | `blt` prefix in API keys | Confirm Contentstack |
| Low | Generic CMS patterns | May be coincidence |

## Fingerprinting Commands

### Basic Detection

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET="https://target.example.com"

echo "=== Contentstack Detection ==="

# Check for Contentstack CDN patterns
echo "CDN patterns:"
curl -s "$TARGET" | grep -oE '(cdn\.contentstack\.com|api\.contentstack\.com|app\.contentstack\.com)' | sort -u

# Check for Contentstack SDK
echo -e "\nSDK patterns:"
curl -s "$TARGET" | grep -oE 'contentstack[a-z_-]*\.(js|ts)' | sort -u

# Check for API key patterns (blt prefix + 32+ chars)
echo -e "\nPotential API keys:"
curl -s "$TARGET" | grep -oE 'blt[a-f0-9]{24,}' | sort -u | head -3

# Check for CSS class patterns
echo -e "\nContentstack CSS classes:"
curl -s "$TARGET" | grep -oE 'class="st-[^"]*"' | sort -u | head -5
```

### Advanced Fingerprinting

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET="https://target.example.com"

echo "=== Advanced Contentstack Fingerprinting ==="

# Extract all unique domains from page
echo "All external domains:"
curl -s "$TARGET" | grep -oE 'https?://[^"'\''> ]+' | awk -F/ '{print $3}' | sort -u

# Check for stack configuration
echo -e "\nStack configuration:"
curl -s "$TARGET" | grep -oE 'contentstack\.Stack\([^)]+\)' | head -3

# Check for version headers
echo -e "\nVersion headers:"
curl -I -s "https://cdn.contentstack.com/v3/content_types" 2>/dev/null | grep -i 'x-contentstack'

# Probe for content types (may need token)
echo -e "\nAPI probe:"
curl -s "https://cdn.contentstack.com/v3/content_types" 2>/dev/null | head -c 200
```

## False Positives

- **Third-party Contentstack widgets:** Embedded Contentstack content on non-Contentstack sites
- **CDN patterns:** Some CDNs may use similar domain structures
- **CSS class collisions:** `st-*` prefix may be used by other systems
- **API key format:** `blt` prefix is distinctive but not exclusive

## Security Considerations

### Common Security Headers on Contentstack-served Content

```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Content-Security-Policy: default-src 'self' *.contentstack.com
Strict-Transport-Security: max-age=31536000
```

### Potential Information Disclosure

- **Public tokens in source:** Delivery API tokens visible in client-side code (expected)
- **API key exposure:** Contentstack API key in client-side code
- **Content type names:** API reveals content model structure
- **Entry UIDs:** System-generated UIDs expose entry IDs
- **Locale patterns:** Reveals localization configuration

## Technology Stack Integration

### Common Contentstack Pairings

| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| React | UI framework | `@contentstack/delivery` React bindings |
| Next.js | SSR/SSG | Next.js SDK integration |
| Vue | UI framework | Vue SDK |
| Nuxt | Vue SSR | Nuxt 3 module |
| TypeScript | Language | TypeScript SDK available |

### Content Delivery Flow

```
Contentstack Dashboard → Management API → Content Stack
         ↓
Delivery API → CDN → Site
```

## Fingerprinting Tooling

- **Wappalyzer browser extension** — Detects Contentstack via script patterns
- **BuiltWith** — Technology detection for Contentstack integrations
- **HTTP Archive** — Historical Contentstack usage patterns
- **Shodan** — Search `http.html:contentstack` for Contentstack-powered sites

## Changelog

- 2026-05-11: Initial Contentstack fingerprinting guide
- Future: Add Webhook-specific detection patterns