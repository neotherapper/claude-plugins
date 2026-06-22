# Copied and trimmed from beacon site-recon (intentional duplication; N=2 skills, no shared lib).

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
- Limit: not a Cloudflare bypass tool — heavy bot-protected sites still block it; use Firecrawl or browser fetch for those

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
- Limit: may not render JavaScript — if returned body text is near-empty, escalate to Chrome DevTools MCP

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
