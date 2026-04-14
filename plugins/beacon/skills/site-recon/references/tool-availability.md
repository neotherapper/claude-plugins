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

# Network request capture
cmux browser surface:N network requests        ← list all captured requests since page load
cmux browser surface:N network route "*/api/*" --body '{"mock":true}'  ← intercept/mock

# Interact
cmux browser click "button[data-id=login]"
cmux browser fill "input[name=email]" "test@example.com"
```

Full reference: `docs/guides/cmux-browser.md` (in nikai project)

---

## Chrome DevTools MCP Commands (Phase 11)

Use when `mcp__chrome-devtools__new_page` is in the tool list.

**Corrected v0.21.0 signatures:**
- `navigate_page(url, type="url", timeout=10000)` — no `page_id` parameter; call `select_page(page_id)` first
- `wait_for` checks text presence only — use `evaluate_script(() => document.readyState)` polling instead of networkidle
- `list_network_requests({resourceTypes: ["xhr","fetch"]})` — no `url_filter` param; filter URLs client-side

```
# Open page
mcp__chrome-devtools__new_page → returns {page_id: "..."}
mcp__chrome-devtools__select_page(page_id)

# Navigate + wait for load
mcp__chrome-devtools__navigate_page(url, type="url", timeout=10000)
# Poll until complete (retry 3× with 2s delay):
mcp__chrome-devtools__evaluate_script(() => document.readyState)

# Capture page content
mcp__chrome-devtools__take_snapshot          → DOM/a11y tree (best for AI)
mcp__chrome-devtools__take_screenshot        → visual PNG

# JavaScript evaluation
mcp__chrome-devtools__evaluate_script(() => JSON.stringify(window.__NEXT_DATA__))
mcp__chrome-devtools__evaluate_script(() => Object.keys(window).filter(k => k.startsWith('__')))

# Network capture (filter client-side — no url_filter param)
mcp__chrome-devtools__list_network_requests({resourceTypes: ["xhr", "fetch"]})
  → keep entries where url contains target domain
mcp__chrome-devtools__get_network_request(reqid)   ← response body

# Interact
mcp__chrome-devtools__click(css_selector)
mcp__chrome-devtools__fill(css_selector, value)
mcp__chrome-devtools__press_key("Enter")
```

### Phase 11 execution pattern (Chrome DevTools MCP)

For full auth setup and per-URL execution loop, see `references/phase-11-browser.md`.

```
1. Detect mode: list_pages → real URLs? auto-connect : new-instance
2. Auth setup if new-instance (see phase-11-browser.md Phase 11a)
3. new_page → page_id
4. For each URL in browse plan:
   a. select_page(page_id)
   b. navigate_page(url, type="url", timeout=10000)
   c. Poll: evaluate_script(() => document.readyState) until "complete"
   d. evaluate_script for JS globals
   e. list_network_requests({resourceTypes: ["xhr","fetch"]}) — filter client-side
   f. get_network_request(reqid) per matching request
   g. Execute browse plan actions (click, fill, etc.)
   h. list_network_requests again after interactions
   i. take_snapshot for documentation
5. Write collected requests to .beacon/chrome-requests.json
6. Run har-reconstruct.py → .beacon/capture.har
7. Run npx har-to-openapi (see phase-11-browser.md Phase 11d)
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

If Chrome DevTools MCP captured requests, reconstruct a valid HAR 1.2 using `har-reconstruct.py`:

```bash
python3 scripts/core/har-reconstruct.py \
  --input .beacon/chrome-requests.json \
  --output .beacon/capture.har \
  --domain {target-domain}
```

See `references/phase-11-browser.md` Phase 11c for full instructions.

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
