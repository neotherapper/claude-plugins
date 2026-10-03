# Storyblok Framework Fingerprinting Guide

## Discovery Techniques

### 1. Network-Based Detection

Storyblok integrations make requests to specific Storyblok-owned domains. Monitor network requests for:

| Domain | Purpose | Confidence |
|--------|---------|------------|
| `api.storyblok.com` | Content Delivery/Management API | Definitive |
| `a.storyblok.com` | Asset CDN | Definitive |
| `img2.storyblok.com` | Image transformation CDN | Definitive |
| `app.storyblok.com` | Storyblok app and JS SDK | Definitive |
| `app.storyblok.com/f/` | Storyblok JS bundle path | Definitive |

### 2. JavaScript Global Detection

Check browser console for Storyblok SDK objects:

```javascript
// Core SDK
window.Storyblok
window.storyblok

// Visual Editor bridge
window.StoryblokBridge
window.storyblokBridge

// Connection state
window.storyblok?.connecting
window.storyblok?.state
```

### 3. HTML Source Analysis

Look for these patterns in HTML source:

```html
<!-- Storyblok SDK script -->
<script src="//app.storyblok.com/f/{VERSION}/storyblok-{BUNDLE}.js"></script>

<!-- Storyblok asset -->
<img src="//a.storyblok.com/{SPACE_ID}/{PATH}">

<!-- Storyblok image transformation -->
<img src="//img2.storyblok.com/{SPACE_ID}/{PATH}?width=800">

<!-- Block component marker -->
<div data-blok-uid="123" data-blok-c="hero-component">
```

### 4. API Request Pattern Detection

Storyblok API requests follow these patterns:

```
# Story by slug (published)
GET /v2/cdn/stories/home?token={PUBLIC_TOKEN}&version=published

# Story by slug (draft)
GET /v2/cdn/stories/home?token={PUBLIC_TOKEN}&version=draft

# All stories
GET /v2/cdn/stories?token={PUBLIC_TOKEN}&starts_with=blog/

# Links tree
GET /v2/cdn/links?token={PUBLIC_TOKEN}
```

## Version Detection

Storyblok version detection methods:

| Method | Indicator |
|--------|-----------|
| SDK version in bundle URL | `app.storyblok.com/f/{VERSION}/storyblok-{BUNDLE}.js` |
| API version in path | `v2/` in all API paths |
| Feature detection | Visual Editor = v2+ |

**Extract version from HTML:**

```bash
# Get SDK version from bundle URL
curl -s https://TARGET/ | grep -oE 'app\.storyblok\.com/f/[0-9]+/'

# Check for Visual Editor
curl -s https://TARGET/ | grep -oE 'storyblok.*bridge|storyblokBridge'
```

## Confidence Levels

| Confidence | Signal | Action |
|------------|--------|--------|
| Definitive | `api.storyblok.com` or `a.storyblok.com` in requests | Confirm Storyblok |
| Definitive | `window.Storyblok` in JS globals | Confirm Storyblok |
| High | `storyblok-js` in bundles | Confirm Storyblok |
| High | `data-blok-uid` attributes in HTML | Confirm Storyblok |
| Medium | `_storyblork` cookie | Investigate Visual Editor |
| Low | Generic CMS patterns | May be coincidence |

## Fingerprinting Commands

### Basic Detection

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET="https://target.example.com"

echo "=== Storyblok Detection ==="

# Check for Storyblok CDN patterns
echo "CDN patterns:"
curl -s "$TARGET" | grep -oE '(a\.storyblok\.com|img2\.storyblok\.com|api\.storyblok\.com|app\.storyblok\.com)' | sort -u

# Check for Storyblok JS SDK
echo -e "\nSDK patterns:"
curl -s "$TARGET" | grep -oE 'storyblok[a-z_-]*\.js' | sort -u

# Check for component markers
echo -e "\nComponent markers:"
curl -s "$TARGET" | grep -oE 'data-blok-[a-z]+' | sort -u

# Check for token patterns
echo -e "\nPotential API tokens:"
curl -s "$TARGET" | grep -oE 'token["\']?\s*[:=]\s*["\']?[a-zA-Z0-9_-]{20,}' | head -3
```

### Advanced Fingerprinting

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET="https://target.example.com"

echo "=== Advanced Storyblok Fingerprinting ==="

# Extract all unique domains from page
echo "All external domains:"
curl -s "$TARGET" | grep -oE 'https?://[^"'\''> ]+' | awk -F/ '{print $3}' | sort -u

# Check for Visual Editor cookie or iframe
echo -e "\nVisual Editor detection:"
curl -s "$TARGET" | grep -oE 'iframe[^>]+src="[^"]*storyblok[^"]*"' | head -3

# Check for space ID patterns (numeric)
echo -e "\nPotential Space IDs (numeric):"
curl -s "$TARGET" | grep -oE '"spaceId"[^,}]*[0-9]{6,}' | head -3

# Probe the API to confirm
echo -e "\nAPI probe (may need token):"
curl -s "https://api.storyblok.com/v2/cdn/stories?token=test" 2>/dev/null | head -c 200
```

## False Positives

- **Storyblok embed widgets:** Embedded Storyblok content on non-Storyblok sites
- **CDN patterns:** Generic CDN patterns may similar domains
- **Component name collisions:** `data-blok-*` patterns may be used by other systems
- **Visual Editor on staging:** Development environments may have Storyblok in dev mode

## Security Considerations

### Common Security Headers on Storyblok-served Content

```
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Content-Security-Policy: default-src 'self' *.storyblok.com
Strict-Transport-Security: max-age=31536000
```

### Potential Information Disclosure

- **Public tokens in source:** Delivery API tokens visible in client-side code (expected)
- **Space ID exposure:** Numeric space ID in all requests
- **Component names:** `data-blok-c` attributes reveal content model
- **Story slugs:** URL structure reveals content hierarchy
- **Preview mode:** `_storyblork` cookie indicates draft access

## Technology Stack Integration

### Common Storyblok Pairings

| Technology | Purpose | Detection Method |
|------------|---------|------------------|
| React | UI framework | `window.Storyblok` React bridge |
| Next.js | SSR/SSG | `/_storyblok/` routes |
| Vue | UI framework | `@storyblok/vue` |
| Nuxt | Vue SSR | `nuxt-storyblok` module |
| TypeScript | Language | TypeScript SDK available |

### Content Delivery Flow

```
Storyblok Space → Content Delivery API → CDN → Site
      ↓
Visual Editor → Preview iframe → draft content
```

## Fingerprinting Tooling

- **Wappalyzer browser extension** — Detects Storyblok via script patterns
- **BuiltWith** — Technology detection for Storyblok integrations
- **HTTP Archive** — Historical Storyblok usage patterns
- **Shodan** — Search `http.html:storyblok` for Storyblok-powered sites

## Changelog

- 2026-05-11: Initial Storyblok fingerprinting guide
- Future: Add Visual Editor-specific detection patterns