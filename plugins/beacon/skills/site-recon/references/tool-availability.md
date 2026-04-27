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

**Extended Firecrawl usage (beyond URL discovery):**
- Phase 2/6 when curl 403s: `firecrawl_scrape(url, formats=["markdown"])` — bypasses many Cloudflare configs; returns clean content
- Phase 6 sitemap: `firecrawl_crawl(site, maxDepth=1)` — structured URL tree without manual XML parsing
- Phase 7 JS links: `firecrawl_scrape(url, formats=["links"])` — all hrefs/scripts without browser

### Jina Reader
```
No install required. Zero-config URL-prefix API.
Available if: HTTP 200 from https://r.jina.ai/https://httpbin.org/get
  curl -s -o /dev/null -w "%{http_code}" https://r.jina.ai/https://httpbin.org/get
MCP: community server 'mcp-jina-reader' (check MCP tool list for 'jina_reader')
Fallback: Firecrawl or browser fetch
```

**Usage pattern:**
```bash
# Fetch any URL as clean LLM-ready markdown (JS rendered, ads removed):
curl -s "https://r.jina.ai/{target_url}"

# JSON output with structured fields:
curl -s -H "Accept: application/json" "https://r.jina.ai/{target_url}"

# Force crawl past cached version:
curl -s -H "X-No-Cache: true" "https://r.jina.ai/{target_url}"
```

- Free: 1M tokens/month, no API key required for basic use
- Use for: Phase 2 fallback when curl 403s, Phase 6 feed/sitemap extraction, Phase 9 OSINT URL content
- Limit: not a Cloudflare bypass tool — heavy bot-protected sites still block it; use Firecrawl or browser fetch for those

### Crawl4AI
```
Available if: python3 -c "import crawl4ai" exits 0
MCP: check MCP tool list for 'crawl4ai'
Fallback: Jina Reader → Firecrawl → browser fetch
```

**Usage (Python async — Phase 6 deep crawl):**
```python
from crawl4ai import AsyncWebCrawler
import asyncio
async def crawl(url):
    async with AsyncWebCrawler() as c:
        r = await c.arun(url=url)
        return r.markdown  # 67% fewer tokens than raw HTML
asyncio.run(crawl("{target_url}"))
```

- Free, self-hosted OSS (Apache 2.0), 58k+ stars — no external API calls
- Use when data sovereignty required or Firecrawl quota exhausted

### Spider
```
MCP available if: 'spider_scrape' or 'spider_crawl' in MCP tool list
API available if: SPIDER_API_KEY env var set
```

**Usage pattern:**
```bash
# Via API (rotates fingerprints per request — strong Cloudflare/Akamai bypass):
curl -H "Authorization: Bearer {SPIDER_API_KEY}" \
     -H "Content-Type: application/json" \
     -d '{"url":"{target_url}","return_format":"markdown"}' \
     https://api.spider.cloud/crawl
```

- Free tier available; per-request pricing from $0.01
- Key advantage: **fingerprint rotation on every request** — different from Firecrawl's static bypass
- Use when: Firecrawl blocked, Akamai-protected sites, need fresh fingerprint per probe

### Scrapfly
```
API available if: SCRAPFLY_API_KEY env var set
SDK available if: $(python3 -c "import scrapfly" 2>/dev/null) exits 0
```

**Usage pattern (asp=true for anti-bot bypass):**
```bash
# 98% bypass success on Cloudflare, DataDome, PerimeterX, Akamai:
curl "https://api.scrapfly.io/scrape?key={API_KEY}&url={target_url}&asp=true&render_js=true"
```

- Free tier: 1000 credits/month
- **Best-in-class for DataDome/PerimeterX** — different threat model from Cloudflare
- `asp=true` activates Anti-Scraping Protection bypass (Curlium + Scrapium engines)
- Use when: site uses DataDome/PerimeterX (detectable from response headers), all other methods blocked

### Steel (self-hosted headless browser)
```
Available if: steel server running locally or STEEL_API_KEY env var set
  curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health → 200
MCP: community MCP server available
```

**Usage pattern:**
```python
# Open-source, self-hosted (Apache 2.0), 100 hrs/month free on Steel Cloud:
from steel import Steel
client = Steel(steel_api_key="{key}")  # or omit for local
session = client.sessions.create()
# Use CDP URL with existing browser automation tools
cdp_url = session.cdp_url
```

- Phase 11 alternative to Chrome DevTools MCP — persistent sessions, stealth included
- Self-hostable: `docker run -p 3000:3000 steel/steel`
- Use when: Chrome DevTools MCP unavailable, need persistent authenticated session

### Chrome DevTools MCP

Two namespaces exist depending on how the MCP server is registered. Test BOTH in Phase 1
and record which one responds. Use ONLY the recorded namespace for all of Phase 11.

```
# Plugin-level (preferred — registered via plugin system):
Test: attempt mcp__plugin_chrome-devtools-mcp_chrome-devtools__list_pages
  → If it returns a list (even empty): log [CHROME-NAMESPACE:plugin]

# Project-level (fallback — registered in project .mcp.json):
Test: attempt mcp__chrome-devtools__list_pages
  → If it returns a list: log [CHROME-NAMESPACE:project]

# Neither responds:
  → Check cmux; if neither: log [TOOL-UNAVAILABLE:chrome-devtools-mcp]
```

**Important:** If list_pages returns a timeout or "Network.enable timed out", the Chrome
process may have a stale CDP connection. Ask the user to: restart Chrome, run
`pkill -f chrome-devtools-mcp`, then retry before giving up on Chrome MCP entirely.
```

### cmux browser
```bash
# Check if inside cmux session
[ -n "$CMUX_SURFACE_ID" ] && echo "cmux available"
# Or check if cmux is installed
which cmux && echo "cmux available"
```

### context7 MCP
```
Available if: 'resolve-library-docs' appears in the current session's MCP tool list
Fallback: Web search for "{framework} {major}.x API routes endpoints file structure"
Log: [AVAILABLE] context7  OR  [TOOL-UNAVAILABLE:context7]
```

### GAU (GetAllURLs)
```bash
# 'which gau' is NOT sufficient — gau may be aliased to 'git add --update'
# Confirm the binary is the URL extractor before marking available:
GAU_CHECK=$(gau --version 2>&1 || gau --help 2>&1 || true)
if echo "$GAU_CHECK" | grep -qi "getallurls\|gau.*version"; then
  echo "[AVAILABLE] gau"
else
  echo "[TOOL-UNAVAILABLE:gau:aliased-or-not-found]"
fi
# Fallback: Wayback CDX API (no install, always works — see phase-detail.md Phase 9)
```

---

## Full Fallback Matrix

| Phase | Primary | Fallback 1 | Fallback 2 | Fallback 3 (specialist) | No-tool result |
|-------|---------|-----------|-----------|------------------------|----------------|
| 3 Fingerprint | Wappalyzer MCP | Header + HTML grep | — | — | Generic signals only |
| 2/6 URL discovery | Firecrawl crawl | Spider | Jina Reader | curl /sitemap.xml | Sitemap only |
| 2/5 CF-blocked probes | Firecrawl scrape | Spider (fingerprint rotation) | Jina Reader | Scrapfly `asp=true` | [CF-BLOCKED:all] |
| 2/5 DataDome/PerimeterX | Scrapfly `asp=true` | Firecrawl | Browser fetch | — | [CF-BLOCKED:all] |
| 4 Tech pack | GitHub raw URL | context7 MCP | Web search | — | [TECH-PACK-UNAVAILABLE] |
| 6 Feed/content extraction | Firecrawl scrape | Jina Reader | Crawl4AI | Spider | curl RSS/Atom |
| 9 OSINT — URL history | GAU | Wayback + CommonCrawl CDX | — | — | CDX APIs always work |
| 9 OSINT — page content | Jina Reader | Firecrawl | Spider | curl | Skip if none |
| 11 Active browse | Chrome DevTools MCP | cmux browser | Steel (self-hosted) | — | [PHASE-11-SKIPPED] |
| Script download | GitHub raw URL | Local .beacon/ cache | — | — | [GENERATED-INLINE:path] |

**Bot protection detection matrix** — identify the WAF before choosing the bypass tool:

| WAF Signal | How to detect | Best bypass |
|------------|--------------|-------------|
| Cloudflare | `cf-ray` response header; 403 with `cloudflare` in body | Firecrawl → Spider → browser fetch |
| DataDome | `x-datadome-*` headers; JSON `{"type":"DataDome"}` body | Scrapfly `asp=true` |
| PerimeterX | `_px*` cookies; `403 Access Denied by PerimeterX` body | Scrapfly `asp=true` |
| Akamai | `AkamaiGHost` in `Server` header; `x-akamai-*` headers | Spider (fingerprint rotation) |
| Generic 403 | No WAF header signal | Try all in order |

---

## cmux Browser Commands (Phase 11) — CORRECTED SIGNATURES

Use when `$CMUX_SURFACE_ID` is set or `cmux` is available.

`cmux browser wait --load-state complete` is NOT a valid command — remove it if encountered.

```bash
# Open a new browser tab and get its surface ID
cmux browser open https://example.com
# Returns output like: "surface:83" or a UUID string

# All subsequent commands require --surface {id}
SURF="surface:83"   # replace with actual ID from open

# Navigate to URL
cmux browser --surface $SURF goto https://example.com/products

# Get current URL (useful to confirm navigation succeeded)
cmux browser --surface $SURF get url

# Evaluate JavaScript — ALWAYS wrap return value in JSON.stringify
cmux browser --surface $SURF eval "JSON.stringify(window.__NEXT_DATA__)"
cmux browser --surface $SURF eval "JSON.stringify(Object.keys(window).filter(k=>k.startsWith('wc')))"

# Get HTML of element — CSS selector is REQUIRED (bare 'get html' fails)
cmux browser --surface $SURF get html "body"
cmux browser --surface $SURF get html "#product-list"

# Take screenshot
cmux browser --surface $SURF screenshot --out docs/research/example-com/screenshot.png

# List network requests captured since page load
cmux browser --surface $SURF list network

# Common failure modes:
#   'Error: Unsupported browser subcommand: --load-state'  → remove --load-state
#   'Error: browser requires a subcommand'                 → add a subcommand
#   'Error: Invalid surface handle: get'                   → add --surface flag
#   '(eval):1: bad math expression: illegal character: \'  → JSON.stringify the return value
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

For full auth setup and per-URL execution loop, see `references/browser-recon.md`.

```
1. Detect mode: list_pages → real URLs? auto-connect : new-instance
2. Auth setup if new-instance (see browser-recon.md Phase 11a)
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
7. Run npx har-to-openapi (see browser-recon.md Phase 11d)
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

See `references/browser-recon.md` Phase 11c for full instructions.

---

## Script Download Logic

Scripts live on GitHub and are downloaded on first use to `.beacon/scripts/`.

```bash
VERSION="0.2.0"
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
