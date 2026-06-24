# Crawl and Coverage — Phases 2–4 Detail

Covers structure discovery, render and content-sufficiency gates, the coverage manifest, and the crawl budget. Signal-emission conditions are defined verbatim — executors must not invent alternative triggers.

---

## Phase 2 — Structure Discovery

1. Fetch `robots.txt` — parse for `Sitemap:` directive(s).
2. Fetch `sitemap.xml` (and follow sitemap-index child sitemaps to enumerate all leaf URLs).
3. If no sitemap is found, parse the homepage `<nav>` and `<a href>` links to build the URL list.
4. Enumerate ALL discovered URLs.
5. Cluster URLs by path template using prefix patterns:
   - `/` — homepage
   - `/blog/*` — blog posts / articles
   - `/services/*` — service pages
   - `/products/*` — product pages
   - `/about` — about page
   - `/contact` — contact page
   - Legal paths (`/privacy`, `/terms`, `/cookies`, etc.)
   - Any additional recurring prefix patterns found in the URL list

### Signal Emission — Structure

- `[NO-SITEMAP]` — no `sitemap.xml` and no `Sitemap:` line in `robots.txt`; fall back to homepage-nav crawl.
- `[SINGLE-PAGE]` — ≤2 enumerated URLs after discovery; replace the page table with a section-anchor map.
- `[MULTI-LOCALE:canonical=x]` — `hreflang` alternates OR locale-path/subdomain branching (`/en`, `/de`, `de.`) detected; pick the canonical locale `x` (default the site root / `en`), brief ONLY it, and name the rest as out of scope.

---

## Phase 3 — Render Gate and Content-Sufficiency Gate

### Render Gate

After fetching the homepage, count visible text characters and nav links in the returned body.

**Condition:** If `body_text_chars < 200` OR `nav_link_count == 0`:
- Log `[RENDER-ESCALATED]`
- Re-fetch using the **JS-rendering markdown crawler preference order: Jina → Firecrawl → Crawl4AI**

**Render escalation sequence:**

1. **Jina Reader** (default — zero install, renders JS server-side):
   ```bash
   curl -s "https://r.jina.ai/{homepage_url}"
   ```

2. **Firecrawl** (if MCP/CLI available — bypasses many WAF configs):
   ```
   firecrawl_scrape(url, formats=["markdown"])
   ```

3. **Crawl4AI** (if `crwl` is installed):
   ```bash
   crwl {homepage_url} -o md-fit -O out.md
   ```

4. **Chrome DevTools MCP** — use ONLY if all three markdown crawlers are unavailable OR the content is behind an auth/interactive wall (login/session gating). Use the namespace recorded in Phase 1 (`[CHROME-NAMESPACE:plugin]` or `[CHROME-NAMESPACE:project]`):
   ```
   # Plugin namespace:
   mcp__plugin_chrome-devtools-mcp_chrome-devtools__new_page → {page_id}
   mcp__plugin_chrome-devtools-mcp_chrome-devtools__navigate_page(url, type="url", timeout=10000)
   mcp__plugin_chrome-devtools-mcp_chrome-devtools__evaluate_script(() => document.body.innerText)

   # Project namespace:
   mcp__chrome-devtools__new_page → {page_id}
   mcp__chrome-devtools__navigate_page(url, type="url", timeout=10000)
   mcp__chrome-devtools__evaluate_script(() => document.body.innerText)
   ```

### Content-Sufficiency Gate

After the render attempt, evaluate the fetched content.

**Condition:** If `unique_headings < 2` AND `non_nav_prose_words < 150`:
- Log `[GREENFIELD-MODE]`
- Stop inferring — do not produce a redesign brief
- Tell the user the site is not a redesign target (placeholder, coming-soon, or under construction)
- Write only `INDEX.md` with the finding
- Halt the pipeline

### Signal Emission — Render and Sufficiency

> `coverage-metrics.py` computes `body_text_chars`, `nav_link_count`, `unique_headings`, and `non_nav_prose_words` deterministically against these same thresholds and emits `signals` accordingly.

- `[RENDER-ESCALATED]` — homepage body text < 200 visible chars OR 0 nav links; re-fetched via JS-rendering markdown crawler (Jina → Firecrawl → Crawl4AI); Chrome MCP used only if all crawlers unavailable or content is auth-gated.
- `[GREENFIELD-MODE]` — after render, site has < 2 unique headings AND < 150 words of non-nav prose; pipeline halts.

### Coverage Manifest

As pages are fetched, record their HTTP status:
- **Reachable** — 200/30x that resolve to 200
- **Gated/blocked** — 401, 403, challenge page (WAF bot check)

Log `[COVERAGE-PARTIAL:gated]` when one or more discovered URLs were gated or blocked and could not be fetched.

Include the coverage manifest in the session brief and surface it in `INDEX.md`.

### Signal Emission — Coverage

- `[COVERAGE-PARTIAL:gated]` — one or more URLs returned 401/403/challenge; coverage is incomplete.
- `[WAF-BLOCKED]` — homepage returns 403/challenge from curl, Firecrawl, Jina, AND browser-fetch (the full fallback chain); proceed with whatever partial content exists + a coverage note, do not hard-stop.

---

## Phase 4 — Content Crawl and Screenshots

### Crawl Budget

- Sample **1–2 pages per template cluster**; floor = homepage + primary nav targets
- Apply a clean-markdown character budget (default **60,000 chars total**) — stop when the budget is exhausted even if clusters remain
- Log `[SAMPLED:n-templates]` where `n` is the number of template clusters sampled

### Screenshots

Take **one screenshot per sampled template**; homepage gets two (above-fold and full-page).

Prefer screenshot sources in this order:

1. **Jina pageshot:** `curl -s -H "X-Respond-With: pageshot" "https://r.jina.ai/{url}"`
2. **Firecrawl:** `firecrawl_scrape(url, formats=["screenshot"])` (if MCP/CLI available)
3. **Crawl4AI:** Python `AsyncWebCrawler` with `CrawlerRunConfig(screenshot=True)` → base64 PNG (if `crwl` installed)
4. **Chrome MCP `take_screenshot`** (fallback — use recorded namespace):
   - Plugin: `mcp__plugin_chrome-devtools-mcp_chrome-devtools__take_screenshot`
   - Project: `mcp__chrome-devtools__take_screenshot`

If **no screenshot source** is available: log `[TOOL-UNAVAILABLE:chrome-mcp]` and proceed text-only with an explicit visual-gap note in the output.

### Signal Emission — Crawl

- `[SAMPLED:n-templates]` — crawl budget exhausted before all template clusters were sampled; `n` = number of clusters actually sampled.
- `[TOOL-UNAVAILABLE:chrome-mcp]` — no screenshot source available (Jina pageshot, Firecrawl, Crawl4AI, and Chrome MCP all unavailable); no screenshots; visual gaps are explicitly noted in output files.
