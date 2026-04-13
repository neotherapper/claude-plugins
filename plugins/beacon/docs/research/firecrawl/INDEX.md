# Firecrawl — Research Reference

> Firecrawl scrapes and crawls websites, returning clean markdown/structured data. Beacon uses it as an optional enhancement for content extraction and site mapping. All Firecrawl usage is conditional — probe with curl first, reach for Firecrawl when you need cleaner content.

## Installation

### CLI (primary for scripts)

```bash
npm install -g firecrawl-cli
```

Requires `FIRECRAWL_API_KEY` environment variable.

### MCP Server (for Claude Code integration)

```json
{
  "mcpServers": {
    "firecrawl": {
      "command": "npx",
      "args": ["-y", "firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_KEY": "${FIRECRAWL_API_KEY}"
      }
    }
  }
}
```

## CLI Commands

### `scrape` — Single page

```bash
firecrawl scrape https://example.com
firecrawl scrape https://example.com --format markdown
firecrawl scrape https://example.com --format json        # includes metadata
firecrawl scrape https://example.com --format links       # extract all links
```

Returns: clean markdown of the page (JS rendered, ads stripped).

### `crawl` — Entire site

```bash
firecrawl crawl https://example.com
firecrawl crawl https://example.com --limit 50            # max pages
firecrawl crawl https://example.com --depth 3             # max crawl depth
firecrawl crawl https://example.com --include-paths "/api/*,/docs/*"
firecrawl crawl https://example.com --exclude-paths "/blog/*"
```

Returns: all pages as markdown files. Good for building site maps.

### `map` — URL discovery only (fast, no content)

```bash
firecrawl map https://example.com
firecrawl map https://example.com --limit 200
```

Returns: list of all URLs on the site. Much faster than crawl. Use this for site mapping in Phase 2.

### `search` — Web search

```bash
firecrawl search "wordpress REST API endpoints"
firecrawl search "site:example.com api" --limit 10
```

### `agent` — AI-guided interaction (expensive, use sparingly)

```bash
firecrawl agent "Find all API endpoints and return them as JSON" --url https://example.com
```

## MCP Tools (when Firecrawl MCP is installed)

### `firecrawl_scrape`

```
Input:
  url: string (required)
  formats: ["markdown"] | ["html"] | ["links"] | ["extract"] (default: markdown)
  onlyMainContent: boolean (default: true — strips nav/footer/ads)
  waitFor: number (ms to wait for JS rendering, default 0)
  mobile: boolean (default false)
  includeTags: string[] (CSS selectors to include)
  excludeTags: string[] (CSS selectors to exclude)
  actions: Action[] (click, wait, scroll before scraping — for dynamic content)

Output:
  markdown: string
  html: string (if requested)
  links: string[] (if requested)
  metadata: { title, description, statusCode, ... }
```

### `firecrawl_batch_scrape`

```
Input:
  urls: string[] (required)
  formats: string[]
  options: same as firecrawl_scrape

Output:
  results: Array<{ url, markdown, metadata }>
```

### `firecrawl_map`

```
Input:
  url: string (required)
  limit: number (default 5000)
  search: string (filter URLs containing this string)
  ignoreSitemap: boolean (default false)
  includeSubdomains: boolean (default false)

Output:
  links: string[]
```

### `firecrawl_crawl`

```
Input:
  url: string (required)
  maxDepth: number (default 2)
  limit: number (default 10)
  includePaths: string[] (glob patterns)
  excludePaths: string[] (glob patterns)
  ignoreSitemap: boolean

Output:
  data: Array<{ url, markdown, metadata }>
```

### `firecrawl_search`

```
Input:
  query: string (required)
  limit: number (default 5)
  lang: string (default "en")
  country: string (default "us")
  scrapeOptions: { formats, onlyMainContent }

Output:
  data: Array<{ url, markdown, metadata }>
```

### `firecrawl_extract`

```
Input:
  urls: string[] (required)
  prompt: string (what to extract — natural language)
  schema: object (JSON Schema for structured extraction)
  systemPrompt: string

Output:
  data: object (matches schema if provided)
```

### `firecrawl_interact` (beta)

For clicking, form filling, and JS-heavy interaction. Use Chrome DevTools MCP instead when available.

## Beacon Usage Patterns

### Phase 2 — Site map via `map`

```bash
# Fast URL inventory — no content needed
firecrawl map https://example.com --limit 500
```

Fallback (no Firecrawl): fetch `/sitemap.xml` and `/sitemap_index.xml` directly.

### Phase 5 — Apply tech pack patterns

```bash
# Scrape a known API endpoint for schema hints
firecrawl scrape https://example.com/wp-json/wp/v2/posts --format json
```

### Phase 6 — Extract structured data

Use `firecrawl_extract` with a JSON Schema to pull product listings, schema.org data, etc.

### Phase 7 — Link extraction for JS bundles

```bash
firecrawl scrape https://example.com --format links | grep "\.js$"
```

## Tool Availability Check

Before using Firecrawl in a Beacon skill:

```markdown
Check if firecrawl CLI is available:
  $ which firecrawl || echo "not installed"

Check if Firecrawl MCP is available:
  Look for 'firecrawl_scrape' in the available MCP tools list.

If neither available: log [TOOL-UNAVAILABLE:firecrawl] in session brief.
Fall back to: curl + grep for content, /sitemap.xml for URL discovery.
```

## Rate Limits and Cost

- Free tier: 500 credits/month
- Each scrape = 1 credit; crawl = 1 credit/page
- `map` is cheap — use it for URL discovery
- `agent` is expensive (multiple requests) — avoid in automated scripts
- `firecrawl_interact` is beta and credit-intensive

## Fallbacks (no Firecrawl)

| Firecrawl operation | Fallback |
|---------------------|---------|
| `map` | Fetch sitemap.xml → parse URLs |
| `scrape` | `curl -s URL \| cat` |
| `crawl` | Not directly replaceable; use sitemap |
| `extract` | Grep HTML for JSON-LD / OpenGraph |

## Source

Research consolidated from:
- Firecrawl official docs: https://docs.firecrawl.dev
- Firecrawl MCP npm package: `firecrawl-mcp`
- nikai research notes (AI tools knowledge vault)
