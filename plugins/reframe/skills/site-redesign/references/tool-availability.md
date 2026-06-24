# Copied and trimmed from beacon site-recon (intentional duplication; N=2 skills, no shared lib).

## Content-Extraction Preference Order

For fetching a page's **rendered content** (text/markdown), especially JS-rendered SPAs, use this order:

1. **Jina Reader** — `curl -s https://r.jina.ai/<FULL_URL>` — renders JS server-side, returns clean markdown, zero install, no key. **DEFAULT for SPA/empty-HTML content.**
2. **Firecrawl** — if MCP (`firecrawl_scrape`) or CLI (`firecrawl`) is available; renders + returns markdown; bypasses many WAF configs.
3. **Crawl4AI** — if installed (`command -v crwl` exits 0); local Playwright crawler, no key, renders SPAs.
4. **Chrome DevTools MCP** — **RESERVED.** Use ONLY for: authenticated/interactive flows (login/session walls, clicking through gated content) and specific-element screenshots the crawlers cannot produce. Not the default for content extraction.

For **screenshots** (visual track): prefer Jina pageshot (`X-Respond-With: pageshot`), Firecrawl `formats:["screenshot"]`, or Crawl4AI (Python `CrawlerRunConfig(screenshot=True)` → base64 PNG); fall back to Chrome MCP `take_screenshot` only if none available.

---

## Detection Commands (run during Phase 1)

Check each tool and log `[AVAILABLE]` or `[TOOL-UNAVAILABLE:{name}]` in the session brief.

### Firecrawl
```
MCP available if: 'firecrawl_scrape' in MCP tool list
CLI available if: $(which firecrawl) exits 0
Fallback: curl -s {url} for page content; /sitemap.xml for URL discovery
```

**Extended Firecrawl usage:**
- When curl 403s: `firecrawl_scrape(url, formats=["markdown"])` — bypasses many Cloudflare configs; returns clean content
- Sitemap: `firecrawl_crawl(site, maxDepth=1)` — structured URL tree without manual XML parsing
- JS links: `firecrawl_scrape(url, formats=["links"])` — all hrefs/scripts without browser
- Screenshot: `firecrawl_scrape(url, formats=["screenshot"])` — page screenshot without browser

### Jina Reader
```
No install required. Zero-config URL-prefix API.
Available if: HTTP 200 from https://r.jina.ai/https://httpbin.org/get
  curl -s -o /dev/null -w "%{http_code}" https://r.jina.ai/https://httpbin.org/get
MCP: community server 'mcp-jina-reader' (check MCP tool list for 'jina_reader')
Fallback: Firecrawl or Crawl4AI
```

**Usage pattern:**
```bash
# Fetch any URL as clean LLM-ready markdown (JS rendered, ads removed):
curl -s "https://r.jina.ai/{target_url}"

# JSON output with structured fields:
curl -s -H "Accept: application/json" "https://r.jina.ai/{target_url}"

# Force crawl past cached version:
curl -s -H "X-No-Cache: true" "https://r.jina.ai/{target_url}"

# Screenshot (pageshot):
curl -s -H "X-Respond-With: pageshot" "https://r.jina.ai/{target_url}"
```

- Renders JS server-side — handles SPAs; returns rendered markdown without a browser
- Free: 1M tokens/month, no API key required for basic use
- Limit: not a Cloudflare bypass tool — heavy bot-protected sites still block it; use Firecrawl for those

### Crawl4AI
```
Local Playwright-based crawler. No API key. Renders SPAs.
Presence test: command -v crwl >/dev/null 2>&1
  (Note: crawl4ai-doctor is a diagnostic tool, NOT a presence test)
One-time install is moderately heavy (~hundreds-MB Chromium download).
Use only if already installed.
```

**Usage pattern:**
```bash
# Fetch rendered fit-markdown to a file:
crwl <URL> -o md-fit -O out.md

# Screenshot (Python — CLI has no screenshot flag):
python3 -c "
import asyncio
from crawl4ai import AsyncWebCrawler, CrawlerRunConfig
async def main():
    async with AsyncWebCrawler() as c:
        r = await c.arun('<URL>', config=CrawlerRunConfig(screenshot=True))
        # r.screenshot is a base64 PNG string
        import base64, pathlib
        pathlib.Path('screenshot.png').write_bytes(base64.b64decode(r.screenshot))
asyncio.run(main())
"
```

### WebFetch
```
Available if: 'WebFetch' appears in the current session's tool list
Fallback: curl -s {url}
```

**Usage pattern:**
```
# Built-in Claude Code tool — no install required:
WebFetch(url="{target_url}", prompt="Return the full page content")
```

- Use for: initial homepage fetch, robots.txt, sitemap.xml retrieval
- Limit: may not render JavaScript — if returned body text is near-empty, escalate using the content-extraction preference order above (Jina → Firecrawl → Crawl4AI)

### Chrome DevTools MCP

Two namespaces exist depending on how the MCP server is registered. Test BOTH in Phase 1
and record which one responds. Use ONLY the recorded namespace for all subsequent phases.

```
# Plugin-level (preferred — registered via plugin system):
Test: attempt mcp__plugin_chrome-devtools-mcp_chrome-devtools__list_pages
  → If it returns a list (even empty): log [CHROME-NAMESPACE:plugin]

# Project-level (fallback — registered in project .mcp.json):
Test: attempt mcp__chrome-devtools__list_pages
  → If it returns a list: log [CHROME-NAMESPACE:project]

# Neither responds:
  → log [TOOL-UNAVAILABLE:chrome-devtools-mcp]
```

**Important:** If list_pages returns a timeout or "Network.enable timed out", the Chrome
process may have a stale CDP connection. Ask the user to: restart Chrome, run
`pkill -f chrome-devtools-mcp`, then retry before giving up on Chrome MCP entirely.

---

## WAF Escalation Chain

When the homepage returns 403 or a bot-challenge response, try in order:

**Firecrawl → Jina → browser-fetch**

- **Firecrawl** — bypasses many Cloudflare configurations; try first
- **Jina Reader** — zero-config URL-prefix fallback; does not bypass heavy bot protection
- **browser-fetch** — Chrome DevTools MCP `navigate_page` + `take_snapshot`; most reliable but requires Chrome MCP to be available

If all three fail: log `[WAF-BLOCKED]` and proceed with whatever partial content was retrieved, plus a coverage note. Do not hard-stop.
