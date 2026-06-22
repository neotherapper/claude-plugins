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
- Re-fetch via Chrome DevTools MCP using the sequence below

**Chrome MCP render sequence — plugin namespace:**
```
mcp__plugin_chrome-devtools-mcp_chrome-devtools__new_page
  → returns {page_id: "..."}
mcp__plugin_chrome-devtools-mcp_chrome-devtools__select_page(page_id)
mcp__plugin_chrome-devtools-mcp_chrome-devtools__navigate_page(url, type="url", timeout=10000)
# Poll until loaded (retry 3× with 2s delay):
mcp__plugin_chrome-devtools-mcp_chrome-devtools__evaluate_script(() => document.readyState)
# Capture rendered text:
mcp__plugin_chrome-devtools-mcp_chrome-devtools__evaluate_script(() => document.body.innerText)
# Capture DOM/a11y tree:
mcp__plugin_chrome-devtools-mcp_chrome-devtools__take_snapshot
```

**Chrome MCP render sequence — project namespace:**
```
mcp__chrome-devtools__new_page
  → returns {page_id: "..."}
mcp__chrome-devtools__select_page(page_id)
mcp__chrome-devtools__navigate_page(url, type="url", timeout=10000)
# Poll until loaded (retry 3× with 2s delay):
mcp__chrome-devtools__evaluate_script(() => document.readyState)
# Capture rendered text:
mcp__chrome-devtools__evaluate_script(() => document.body.innerText)
# Capture DOM/a11y tree:
mcp__chrome-devtools__take_snapshot
```

Use the namespace recorded in Phase 1 (`[CHROME-NAMESPACE:plugin]` or `[CHROME-NAMESPACE:project]`).

### Content-Sufficiency Gate

After the render attempt, evaluate the fetched content.

**Condition:** If `unique_headings < 2` AND `non_nav_prose_words < 150`:
- Log `[GREENFIELD-MODE]`
- Stop inferring — do not produce a redesign brief
- Tell the user the site is not a redesign target (placeholder, coming-soon, or under construction)
- Write only `INDEX.md` with the finding
- Halt the pipeline

### Signal Emission — Render and Sufficiency

- `[RENDER-ESCALATED]` — homepage body text < 200 visible chars OR 0 nav links; Chrome MCP headless render invoked.
- `[GREENFIELD-MODE]` — after render, site has < 2 unique headings AND < 150 words of non-nav prose; pipeline halts.

---

## Phase 3 — Coverage Manifest

As pages are fetched, record their HTTP status:
- **Reachable** — 200/30x that resolve to 200
- **Gated/blocked** — 401, 403, challenge page (WAF bot check)

Log `[COVERAGE-PARTIAL:gated]` when one or more discovered URLs were gated or blocked and could not be fetched.

Include the coverage manifest in the session brief and surface it in `INDEX.md`.

### Signal Emission — Coverage

- `[COVERAGE-PARTIAL:gated]` — one or more URLs returned 401/403/challenge; coverage is incomplete.
- `[WAF-BLOCKED]` — homepage returns 403/challenge from curl, Firecrawl, AND Jina (the full fallback chain); proceed with whatever partial content exists + a coverage note, do not hard-stop.

---

## Phase 4 — Content Crawl and Screenshots

### Crawl Budget

- Sample **1–2 pages per template cluster**; floor = homepage + primary nav targets
- Apply a clean-markdown character budget (default **60,000 chars total**) — stop when the budget is exhausted even if clusters remain
- Log `[SAMPLED:n-templates]` where `n` is the number of template clusters sampled

### Screenshots

- Take **one screenshot per sampled template** via Chrome MCP `take_screenshot`
- Homepage gets two screenshots: above-fold and full-page
- If Chrome MCP is unavailable: log `[TOOL-UNAVAILABLE:chrome-mcp]` and proceed text-only with an explicit visual-gap note in the output

**Screenshot commands:**

Plugin namespace:
```
mcp__plugin_chrome-devtools-mcp_chrome-devtools__take_screenshot
```

Project namespace:
```
mcp__chrome-devtools__take_screenshot
```

### Signal Emission — Crawl

- `[SAMPLED:n-templates]` — crawl budget exhausted before all template clusters were sampled; `n` = number of clusters actually sampled.
- `[TOOL-UNAVAILABLE:chrome-mcp]` — Chrome DevTools MCP unavailable; no screenshots; visual gaps are explicitly noted in output files.
