# JS Bundle & Source Map Analysis — Research Reference

> Techniques for extracting API endpoints from JavaScript bundles, source maps, and network captures. Beacon applies these in Phase 7 and optionally in Phase 11 (active browse with HAR capture).

## Overview

JavaScript-heavy sites (Next.js, Nuxt, React SPAs) embed API calls, auth patterns, and endpoint strings inside their JS bundles. Even without source code access, you can recover significant API surface by:

1. Grepping downloaded bundles for URL patterns
2. Recovering original source via source maps
3. Capturing network traffic in a HAR file and converting to OpenAPI

## Phase 7 — Static JS Analysis

### Step 1: Find all JS bundle URLs

From the page HTML:
```bash
curl -s https://example.com | grep -oP 'src="[^"]+\.js[^"]*"' | sed 's/src="//;s/"//'
```

For Next.js — check the build manifest:
```bash
curl -s https://example.com/_next/static/chunks/ 2>/dev/null || true
curl -s https://example.com/_next/static/chunks/pages/_app.js
# Also check: /_next/static/chunks/main.js, /_next/static/chunks/webpack.js
```

For Nuxt:
```bash
curl -s https://example.com/_nuxt/
# Or read window.__NUXT__ from the page
```

### Step 2: Download bundles and grep for API patterns

```bash
# Download a bundle
curl -s "https://example.com/_next/static/chunks/pages/_app-abc123.js" -o bundle.js

# Grep patterns (order by specificity)
grep -oP '"/api/[^"]+' bundle.js          # Absolute API paths
grep -oP '"https?://[^"]+/api/[^"]+' bundle.js  # Full URLs
grep -oP 'fetch\("[^"]+' bundle.js        # fetch() calls
grep -oP 'axios\.[a-z]+\("[^"]+' bundle.js  # axios calls
grep -oP '`[^`]*\$\{[^}]+\}[^`]*`' bundle.js | head -20  # Template literals

# WebSocket patterns
grep -oP 'new WebSocket\("[^"]+' bundle.js
grep -oP 'wss?://[^"]+' bundle.js

# SSE patterns
grep -oP 'new EventSource\("[^"]+' bundle.js

# GraphQL
grep -oP '"graphql[^"]*"' bundle.js
grep -oP '/__graphql[^"]*"' bundle.js

# Auth patterns
grep -oP '"Bearer [^"]+' bundle.js
grep -oP '"Authorization[^"]+' bundle.js
grep -oP 'nonce[^;]{0,50}' bundle.js | head -5
```

### Step 3: Check for source maps

For each bundle URL, try appending `.map`:
```bash
BUNDLE_URL="https://example.com/_next/static/chunks/pages/_app-abc123.js"
MAP_URL="${BUNDLE_URL}.map"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${MAP_URL}")
if [ "${HTTP_STATUS}" = "200" ]; then
  echo "Source map available: ${MAP_URL}"
  curl -s "${MAP_URL}" -o sourcemap.json
fi
```

### Step 4: Parse source maps

Source maps contain `sources` (original file paths) and `sourcesContent` (original source code).

```bash
# Extract original file paths
python3 -c "
import json, sys
data = json.load(open('sourcemap.json'))
for src in data.get('sources', []):
    print(src)
"
```

This reveals project structure: component names, API client files, service layer, utility modules.

```python
# Extract all source content and grep for API paths
import json

data = json.load(open('sourcemap.json'))
sources = data.get('sources', [])
contents = data.get('sourcesContent', [])

for path, content in zip(sources, contents):
    if content and '/api/' in content:
        print(f"\n=== {path} ===")
        for line in content.split('\n'):
            if '/api/' in line:
                print(f"  {line.strip()}")
```

## har-to-openapi

Converts a HAR (HTTP Archive) file captured during active browsing into an OpenAPI specification.

### Installation

```bash
npm install -g har-to-openapi
# or use without installing:
bunx har-to-openapi
npx har-to-openapi
```

### Basic Usage

```bash
# Convert HAR to OpenAPI YAML
har-to-openapi capture.har > openapi.yaml

# JSON output
har-to-openapi capture.har --format json > openapi.json

# Filter to specific domain
har-to-openapi capture.har --include-domains api.example.com > openapi.yaml

# Multiple output files (one per base URL)
har-to-openapi capture.har --multi-spec --output-dir ./specs/
```

### Options

```
--format json|yaml           Output format (default: yaml)
--multi-spec                 Create separate spec per base URL
--include-domains <list>     Comma-separated domains to include
--exclude-domains <list>     Comma-separated domains to exclude
--output-dir <path>          Directory for multi-spec output
--filter-status <codes>      Only include responses with these status codes
--include-response-body      Include response body schemas (default: false)
```

### Capturing a HAR file

**Via Chrome DevTools MCP:**
```
1. Open browser: mcp__chrome-devtools__new_page
2. Navigate: mcp__chrome-devtools__navigate_page
3. Interact with the site to trigger API calls
4. Get network requests: mcp__chrome-devtools__list_network_requests
   → Export as HAR
```

**Via Chrome DevTools (manual):**
1. Open DevTools → Network tab
2. Reload the page and interact
3. Right-click any request → "Save all as HAR with content"

**Via Playwright/Puppeteer script:**
```javascript
const { chromium } = require('playwright');
const fs = require('fs');

const browser = await chromium.launch();
const context = await browser.newContext({ recordHar: { path: 'capture.har' } });
const page = await context.newPage();
await page.goto('https://example.com');
// ... interact ...
await context.close();  // HAR is written on context close
await browser.close();
```

### Output Example

```yaml
openapi: 3.0.0
info:
  title: API from HAR capture
  version: 1.0.0
paths:
  /api/v1/users:
    get:
      summary: GET /api/v1/users
      parameters:
        - name: page
          in: query
          schema:
            type: string
      responses:
        '200':
          description: OK
  /api/v1/posts:
    post:
      summary: POST /api/v1/posts
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                title:
                  type: string
```

### Beacon Integration

Phase 11 (active browse) generates a HAR file, then runs `har-to-openapi` to produce the OpenAPI spec:

```bash
# After active browsing session
har-to-openapi .beacon/capture.har \
  --include-domains example.com,api.example.com \
  --format yaml \
  > docs/research/example-com/specs/example-com.openapi.yaml
```

Mark the spec source in INDEX.md:
```markdown
| OpenAPI spec | source: har-capture (Phase 11) |
```

## Asset Manifests

Some frameworks publish a complete asset inventory:

```bash
# Next.js
curl -s https://example.com/_next/static/chunks/manifest.json

# Create React App (older pattern)
curl -s https://example.com/asset-manifest.json

# Vite
curl -s https://example.com/manifest.json
```

These reveal ALL JS/CSS chunk URLs — use them instead of grepping HTML for `<script>` tags.

## Tool Availability Matrix

| Analysis type | With Chrome DevTools MCP | Without MCP |
|--------------|--------------------------|-------------|
| Find JS bundles | `list_network_requests` after page load | Grep `<script>` tags from curl |
| Get full asset list | `evaluate_script('performance.getEntriesByType("resource")')` | Fetch asset manifest |
| Download and grep bundle | `evaluate_script` + file system | curl + bash grep |
| Check source maps | Automatic via DevTools | Try `.map` suffix on each bundle URL |
| Capture network traffic | `get_network_request` for each request | Static analysis only (no live capture) |
| HAR to OpenAPI | Export HAR from DevTools → har-to-openapi | Not available without active browsing |

## Session Brief Format

```markdown
## Phase 7 — JS & Source Map Analysis

### Bundles Found
- /_next/static/chunks/main-abc123.js (142KB)
- /_next/static/chunks/pages/_app-def456.js (89KB)
- /_next/static/chunks/pages/index-ghi789.js (34KB)

### API Endpoints Extracted (from bundles)
- /api/v1/users (from main-abc123.js:fetch)
- /api/v1/posts (from pages/index:axios.get)
- /api/v2/search (from pages/_app:fetch)

### Source Maps
- main-abc123.js.map: AVAILABLE
  - Reveals: src/api/client.ts, src/services/userService.ts
- pages/_app-def456.js.map: 404

### Auth Patterns Found
- Bearer token in Authorization header (line 4892)
- CSRF nonce variable: `csrfToken` (injected from window.__NEXT_DATA__)
```

## Source

- har-to-openapi: https://www.npmjs.com/package/har-to-openapi
- Source map spec: https://sourcemaps.info/spec.html
- Design spec Phase 7 detail section
- Elevate Greece analysis (nikai) — practical JS analysis applied
