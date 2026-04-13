# Tool Availability — Detection, Fallbacks, Browser Commands

## Detection Commands (run during Phase 1)

Check each tool and log `[AVAILABLE]` or `[TOOL-UNAVAILABLE:{name}]` in the session brief.

### Wappalyzer MCP
```
Available if: 'lookup_site' appears in the current session's MCP tool list
Fallback: HTTP header grep + HTML pattern grep (see phase-detail.md Phase 3)
```

### Firecrawl
```
MCP available if: 'firecrawl_scrape' in MCP tool list
CLI available if: $(which firecrawl) exits 0
Fallback: curl -s {url} for page content; /sitemap.xml for URL discovery
```

### Chrome DevTools MCP
```
Available if: 'mcp__chrome-devtools__new_page' in MCP tool list
Fallback: check for cmux; if neither, skip Phase 11
```

### cmux browser
```bash
# Check if inside cmux session
[ -n "$CMUX_SURFACE_ID" ] && echo "cmux available"
# Or check if cmux is installed
which cmux && echo "cmux available"
```

### GAU (GetAllURLs)
```bash
which gau && echo "gau available"
# Fallback: Wayback CDX API (no install, always works)
```

---

## Full Fallback Matrix

| Phase | Primary | Fallback | No-tool result |
|-------|---------|---------|----------------|
| 3 Fingerprint | Wappalyzer MCP | Header + HTML grep | Generic signals only |
| 2/6 URL discovery | Firecrawl map | curl /sitemap.xml | Sitemap only |
| 9 OSINT — URL history | GAU | Wayback + CommonCrawl CDX | CDX APIs always work |
| 11 Active browse | cmux browser | Chrome DevTools MCP | [PHASE-11-SKIPPED] |
| Script download | GitHub raw URL | Local .beacon/ cache | [GENERATED-INLINE:path] |

---

## cmux Browser Commands (Phase 11)

Use when `$CMUX_SURFACE_ID` is set or `cmux` is available.

```bash
# Open browser in current pane
cmux browser open-split https://example.com

# Navigate (CMUX_SURFACE_ID is auto-used inside cmux)
cmux browser goto https://example.com/api/docs
cmux browser wait --load-state complete

# Accessibility snapshot (structured text — use for AI reasoning)
cmux browser snapshot --compact

# Screenshot to file
cmux browser screenshot --out docs/research/example-com/browse-snapshots/api-docs.png

# Evaluate JavaScript
cmux browser evaluate "JSON.stringify(window.__NEXT_DATA__?.props, null, 2)"
cmux browser evaluate "Object.keys(window).filter(k => k.startsWith('__'))"

# Interact
cmux browser click "button[data-id=login]"
cmux browser fill "input[name=email]" "test@example.com"
```

Full reference: `docs/guides/cmux-browser.md` (in nikai project)

---

## Chrome DevTools MCP Commands (Phase 11)

Use when `mcp__chrome-devtools__new_page` is in the tool list.

```
# Open page
mcp__chrome-devtools__new_page → returns page_id

# Navigate
mcp__chrome-devtools__navigate_page(url, page_id)
mcp__chrome-devtools__wait_for("networkidle", 5000)

# Capture page content
mcp__chrome-devtools__take_snapshot          → DOM/a11y tree (best for AI)
mcp__chrome-devtools__take_screenshot        → visual PNG

# JavaScript evaluation
mcp__chrome-devtools__evaluate_script("window.__NEXT_DATA__")
mcp__chrome-devtools__evaluate_script("performance.getEntriesByType('resource').map(r=>r.name)")
mcp__chrome-devtools__evaluate_script("Array.from(document.querySelectorAll('script[src]')).map(s=>s.src)")

# Network capture
mcp__chrome-devtools__list_network_requests({ url_filter: "/api/" })
mcp__chrome-devtools__get_network_request(request_id)

# Interact
mcp__chrome-devtools__click(css_selector)
mcp__chrome-devtools__fill(css_selector, value)
mcp__chrome-devtools__press_key("Enter")
```

### Phase 11 execution pattern (Chrome DevTools MCP)

```
1. new_page → page_id
2. For each URL in browse plan:
   a. navigate_page(url, page_id)
   b. wait_for("networkidle", 5000)
   c. evaluate_script(window.__NEXT_DATA__ or similar globals)
   d. list_network_requests({ url_filter: "/api/" })  ← API calls
   e. execute browse plan action (click, fill, etc.)
   f. list_network_requests() again after interaction
   g. take_snapshot for documentation
3. Collect all network requests → reconstruct as HAR entries
4. Run har-to-openapi
```

---

## HAR to OpenAPI (after Phase 11)

```bash
# Install if needed
npm install -g har-to-openapi
# or: bunx har-to-openapi   npx har-to-openapi

# Convert (filter to target domain)
har-to-openapi .beacon/capture.har \
  --include-domains example.com,api.example.com \
  --format yaml \
  > docs/research/example-com/specs/example-com.openapi.yaml
```

If Chrome DevTools MCP captured requests (not a real HAR file), reconstruct minimal HAR:
```python
import json

requests = [...]  # from mcp__chrome-devtools__list_network_requests

har = {
    "log": {
        "version": "1.2",
        "creator": {"name": "beacon-plugin", "version": "0.1.0"},
        "entries": [
            {
                "request": {
                    "method": r["method"],
                    "url": r["url"],
                    "headers": [{"name": k, "value": v} for k, v in (r.get("request_headers") or {}).items()],
                },
                "response": {
                    "status": r.get("status", 0),
                    "headers": [{"name": k, "value": v} for k, v in (r.get("response_headers") or {}).items()],
                    "content": {"text": r.get("response_body", "")}
                }
            }
            for r in requests
        ]
    }
}

with open(".beacon/capture.har", "w") as f:
    json.dump(har, f)
```

---

## Script Download Logic

Scripts live on GitHub and are downloaded on first use to `.beacon/scripts/`.

```bash
VERSION="0.1.0"
SCRIPT="core/probe-passive.sh"
LOCAL=".beacon/scripts/${SCRIPT}"
REMOTE="https://raw.githubusercontent.com/neotherapper/claude-plugins/v${VERSION}/plugins/beacon/scripts/${SCRIPT}"

mkdir -p "$(dirname ${LOCAL})"

if [ ! -f "${LOCAL}" ]; then
    curl -fsSL "${REMOTE}" -o "${LOCAL}" && chmod +x "${LOCAL}"
fi

# Verify SHA256
CHECKSUM_URL="https://raw.githubusercontent.com/neotherapper/claude-plugins/v${VERSION}/plugins/beacon/scripts/checksums.sha256"
curl -fsSL "${CHECKSUM_URL}" -o .beacon/checksums.sha256 2>/dev/null || true

if [ -f .beacon/checksums.sha256 ]; then
    EXPECTED=$(grep "scripts/${SCRIPT}" .beacon/checksums.sha256 | awk '{print $1}')
    ACTUAL=$(shasum -a 256 "${LOCAL}" | awk '{print $1}')
    if [ "${EXPECTED}" != "${ACTUAL}" ]; then
        echo "[ERROR] Checksum mismatch for ${SCRIPT}" >&2
        rm -f "${LOCAL}"
        exit 1
    fi
fi
```

If download fails and no cache: generate inline via Claude and log `[GENERATED-INLINE:${SCRIPT}]`.
