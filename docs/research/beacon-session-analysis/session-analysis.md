# Beacon Session Analysis: Pen-Chalet & JetPens

**Source sessions analysed:**
- Pen-Chalet: `0a3d80ae-e20b-49ce-9df4-fdd33f615d50.jsonl` (341 messages)
- JetPens: `55ec3428-89ea-4ff3-a60d-57b86c6e1841.jsonl` (389 messages)

**Purpose:** Drive improvements to the beacon plugin based on real failure patterns observed during e-commerce recon.

---

## Session: Pen-Chalet

Target: `penchalet.com` and `andersonpens.com` (two sites, analysed in the same session)

### Errors & Failures

**1. Write-before-Read failures on scaffolded empty files (repeated, blocking)**
The skill scaffolds output files using `touch` (creates empty files), then later in Phase 12 calls `Write` on those paths. The Write tool requires a prior Read. This caused the following failures, each requiring a fallback Read → re-Write cycle:
- `docs/research/penchalet-com/tech-stack.md` — failed Write, then Read (empty), then Write again
- `docs/research/andersonpens-com/tech-stack.md` — same pattern
- `docs/research/penchalet-com/site-map.md` — same pattern
- `docs/research/andersonpens-com/site-map.md` — same pattern
- `docs/research/penchalet-com/constants.md` — same pattern
- `docs/research/andersonpens-com/constants.md` — same pattern
- `docs/research/penchalet-com/INDEX.md` — same pattern
- `docs/research/andersonpens-com/INDEX.md` — same pattern

This added at least 8 unnecessary tool-call pairs. The root cause: `touch` is not a valid substitute for Read before Write. Fix: either use Write directly for new files (skip touch), or Read every scaffolded file before Phase 12.

**2. Phase skipping — Phases 4, 5, and 7 missed entirely in first pass**
After Phase 9 (Wayback CDX) the agent moved directly to Phase 12 and declared done. Phases 4 (tech pack lookup), 5 (known-pattern probes), and 7 (JS bundle analysis) were entirely skipped. The user had to ask: "have we used all beacon steps?" to trigger the correction. The agent then found:
- No ASP.NET tech pack existed (`[TECH-PACK-UNAVAILABLE:aspnet]`)
- ASP.NET-specific `.axd` and `web.config` probes (Phase 5) — critical IIS fingerprints
- `generic.js` containing a shipping rate endpoint pattern (Phase 7 JS analysis)
- Sitemap index with 5 child sitemaps (Phase 6 — partial, was re-run)
- New endpoints: `/autocomplete.aspx`, `/search.aspx`, `/newsletter.aspx`, `/sitemap.aspx`

**3. `gau` false-positive in tool availability check**
The Phase 1 tool check found `gau` via `which gau` and flagged it `[AVAILABLE]`. However, `gau` was aliased to `git add --update` (the Git staging command), not the `getallurls` OSINT URL extractor. The agent correctly noted this in comments but the tool check logic itself did not catch it. Any downstream use of `gau` as the URL extractor would have silently run `git add --update` instead.

**4. Chrome MCP `Network.enable timed out`**
First Chrome MCP calls (`mcp__chrome-devtools__list_pages`, `mcp__chrome-devtools__navigate_page`) both timed out. The cause was stale `chrome-devtools-mcp` processes holding port 9222. Resolution required: user restarted Chrome, ran `pkill -f chrome-devtools-mcp`, then issued `/mcp` reconnect. After that, the plugin-namespaced MCP (`mcp__plugin_chrome-devtools-mcp_chrome-devtools__*`) worked correctly.

**5. Two Chrome MCP namespaces causing confusion**
The agent had to ToolSearch twice to find the correct working namespace. `mcp__chrome-devtools__*` (project-level) timed out; `mcp__plugin_chrome-devtools-mcp_chrome-devtools__*` (plugin-level) worked. The session ended with the project-level namespace still being attempted for the Pen Chalet pagination subagent follow-up.

**6. Cloudflare 403 blocking all curl probes**
Every `curl` request to `penchalet.com` returned HTTP 403 (Cloudflare bot protection), including robots.txt, sitemap.xml, and all Phase 5 ASP.NET probes. The agent correctly pivoted to Chrome (via browser `fetch()` calls in page context) for all probe work, but the initial Phase 2 passive recon was largely blocked. No user agent rotation or fallback strategy was applied before pivoting.

**7. Opaque-redirect results on `.axd` probes**
When probing via browser `fetch()` from within the penchalet.com page context, all ASP.NET `.axd` paths (`/trace.axd`, `/elmah.axd`, `/WebResource.axd`, `/ScriptResource.axd`) returned `status: 0, type: "opaqueredirect"` due to CORS policy on cross-origin fetch. The agent correctly interpreted these as "routes exist but redirect" and noted the IIS fingerprint from the `/web.config` 403, but the opaque-redirect result pattern is not informative and could confuse future analysis.

**8. Subagent committed with wrong message and bundled unrelated file**
A dispatched subagent for penshop.co.uk committed its research docs under the message `"chore(db): apply celebrity source tables migration"` (clearly wrong) and bundled an unrelated SQL migration file (`2026-04-27-celebrity-source-tables.sql`) in the same commit. The user had to ask for a fix. The agent ran `git reset HEAD~1` and re-split into two proper commits. The root cause: the subagent ran in a shared working tree and picked up unrelated unstaged changes.

### Missing Tech Pack Knowledge

**1. `[TECH-PACK-UNAVAILABLE:aspnet]`**
No ASP.NET tech pack existed in the local library or the remote GitHub repository (404 on `raw.githubusercontent.com/.../aspnet/latest.md`). The agent fell back to a web search for ASP.NET probe patterns, which was partial. The following ASP.NET-specific knowledge was derived manually but should be in a tech pack:
- Canonical endpoint probes: `/trace.axd`, `/elmah.axd`, `/WebResource.axd`, `/ScriptResource.axd`, `/web.config`, `/App_Data/`
- IIS fingerprint: HTTP 403 on `/web.config` (IIS blocks this by default)
- ViewState: `__VIEWSTATE` hidden input field pattern
- URL patterns: `.aspx` pages, `category.aspx?keyword=...`, `search.aspx?keyword=...`
- AJAX patterns: custom ASP.NET POST handlers, no REST API

**2. `[TECH-PACK-UNAVAILABLE:magento]`**
The Pen World subagent (dispatched from this session) encountered Magento 2 with no tech pack and had to discover the GraphQL endpoint from scratch — specifically that Magento 2's Store API requires a `Store: english` HTTP header for storefront-scoped queries. This is a non-obvious requirement that a tech pack would have surfaced immediately.

**3. WooCommerce sub-knowledge missing from WordPress tech pack**
The penshop.co.uk subagent (dispatched from this session) ran the WordPress tech pack but did not surface the WooCommerce Store API endpoint pattern: `GET /wp-json/wc/store/v1/products`. This turned out to be the most useful single endpoint for the mypenflow project — it returns product name, SKU, price, stock status, images, and categories in a paginated JSON response requiring no auth. WooCommerce-specific probe patterns should be a distinct section in the WordPress tech pack (or a separate `woocommerce` tech pack).

### Agent Confusion Points

**1. Running two sites simultaneously**
The agent was asked to analyse both penchalet.com and andersonpens.com simultaneously. It scaffolded both, alternated between them, and tried to batch tool calls. This increased cognitive load: the Write-before-Read failures were partially caused by losing track of which files had been read for which site.

**2. Wrong skill invocation chain for JetPens**
In the JetPens session (same pattern visible here as a reference point), `beacon:beacon-analyze` was invoked first, which then invoked `beacon:site-recon` as a nested skill call. This added an extra round-trip message and showed the agent did not map "extract all information about X" → `site-recon` directly. `beacon-analyze` is a thin wrapper that should either be merged with `site-recon` or the dispatch should route directly.

**3. Anderson Pens domain confusion**
The agent initially tried `andersonpens.com`, which served a shutdown notice. It then tried `andersonpens.net`, which had an outdated sitemap pointing to `andersonpens.net/` URLs. A certificate search on crt.sh returned empty (the command produced no output due to a JSON parse error — see failures). The agent correctly concluded Anderson Pens was closed, but only after several wasted probes.

**4. Git confusion during commit phase**
The agent could not find the penchalet-com and penworld-eu research files in `git status` because they were already committed in an earlier merge commit. It ran six separate git commands (`git status`, `git ls-files`, `git log`, `git diff`, `find + git status`, `git ls-files --others`) before concluding the files were already in the repo. This represents a gap in the Phase 12 flush: it does not check existing commit state before declaring "needs commit."

### User Corrections

1. **"have we used all beacon steps for the penchalet?"** — Prompted the Phase 4/5/7 catch-up; agent self-identified that it had skipped three phases entirely.
2. **"do we have info on asp.net?"** — Same prompt above; triggered the tech pack lookup which resulted in `TECH-PACK-UNAVAILABLE:aspnet`.
3. **"use subagents to try to see if we are missing anything"** — User pushed the agent to dispatch gap-fill subagents for both deeper Pen Chalet product data and Pen World recon.
4. **"for chrome do not use the plugin:chrome-cmp use the chrome mcp of this repo"** — User clarified the intended MCP instance; agent had been using the wrong namespace.
5. **"i have restarted chrome so if you can kill other mcp processes and try to go in"** — After multiple Chrome MCP timeout failures, user provided explicit remediation steps.
6. **Commit message was wrong** — User noticed "chore(db): apply celebrity source tables migration" was the wrong message for research docs; agent split the commit.

---

## Session: JetPens

Target: `jetpens.com`

### Errors & Failures

**1. Write-before-Read failures on scaffolded empty files (same pattern as Pen-Chalet)**
Identical to the Pen-Chalet session. The scaffold step created empty files, then Phase 12 Write calls failed:
- `docs/research/www-jetpens-com/tech-stack.md` — failed Write, then Read (empty), then Write
- `docs/research/www-jetpens-com/site-map.md` — same pattern
- `docs/research/www-jetpens-com/constants.md` — same pattern
- `docs/research/www-jetpens-com/INDEX.md` — same pattern (plus a second fail at Write of INDEX before Read)

This is a systemic scaffold design bug, not a one-off.

**2. Wrong skill invoked first (`beacon:beacon-analyze` instead of `beacon:site-recon`)**
User asked to "use the beacon skill to extract all information about jetPens." Agent invoked `beacon:beacon-analyze`, which then internally invoked `beacon:site-recon`. This two-hop chain added an extra tool-call round trip. The `beacon-analyze` skill is a one-liner wrapper that should either be removed or merged.

**3. evaluate_script API error — `function` vs `expression` parameter**
First `evaluate_script` call used `expression` parameter: `{"expression": "..."}`. The tool returned:
```
MCP error -32602: Input validation error: Invalid arguments for tool evaluate_script: [{
  "code": "invalid_type", "expected": "string", "received": "undefined",
  "path": ["function"], "message": "Required"
}]
```
The correct parameter name is `function`. A ToolSearch for the schema was required to fix this. This suggests the skill's JS evaluation pattern is not consistent with the plugin MCP's actual API.

**4. Cloudflare `mcp__chrome-devtools__*` timeout — same as Pen-Chalet**
`mcp__chrome-devtools__list_pages` and `mcp__chrome-devtools__navigate_page` both returned `Network.enable timed out`. Agent had to ToolSearch for the plugin-namespaced version (`mcp__plugin_chrome-devtools-mcp_chrome-devtools__*`), which worked.

**5. Cloudflare Turnstile challenge — unclickable in browser automation**
Navigating to `https://www.jetpens.com/Pens/ct/1318` triggered a Cloudflare Turnstile challenge. The agent took a snapshot showing the challenge UI and tried to click the verify checkbox (`uid: "1_10"`):
```
Failed to interact with the element with uid 1_10. The element did not become interactive within the configured timeout.
Cause: Timed out after waiting 5000ms
```
The Turnstile iframe cannot be interacted with via standard click automation. This is a fundamental limitation. The agent correctly abandoned and returned to the homepage (which had CF clearance already), but the category page remained inaccessible via the plugin MCP. The cmux browser was then used as a workaround because it maintained CF clearance from an existing session.

**6. crt.sh subdomain enumeration failure**
Two consecutive `curl` attempts to crt.sh returned malformed responses:
- First attempt: `Error parsing crt.sh response`
- Second attempt: `502 Bad Gateway` from nginx, `crt.sh parse error: Expecting value: line 1 column 1 (char 0)`

The crt.sh service was temporarily unavailable. The skill has no retry or fallback for this case.

**7. Python subprocess timeout when fetching Wayback CDX data**
A Python script using `subprocess.run` to fetch Wayback CDX data raised a `subprocess.TimeoutExpired` exception (stdlib, Python 3.14.4). The exact cause was `stdout, stderr = process.communicate(input, timeout=timeout)`. The script was rewritten inline to avoid the subprocess call.

**8. `cmux browser` CLI fumbling — 3 failed attempts**
After switching to cmux, the agent tried several invalid commands before finding the correct syntax:
- `cmux browser wait --load-state complete` → `Error: Unsupported browser subcommand: --load-state`
- `cmux browser url` → `Error: browser requires a subcommand`
- `cmux browser get url` → `Error: Invalid surface handle: get (expected UUID, ref like surface:1, or index)`
- Correct form found: `cmux browser --surface surface:83 get url`

The skill has no cmux usage guide; the agent had to read `cmux --help` output and trial-and-error the surface-flag syntax.

**9. `cmux browser get html` syntax error**
When piping cmux browser HTML output to Python, the error was:
```
File "<stdin>", line 1
    Error: browser get html requires a selector
SyntaxError: invalid syntax
```
The `get html` subcommand requires a CSS selector argument, not a bare call. The agent switched to `eval` instead.

**10. Sitemap fetch failure — downloaded empty file**
The user manually saved `sitemap-index.xml` from the browser and told the agent to move it from Downloads. The `mv` succeeded but the file was 0 bytes:
```
0 docs/research/www-jetpens-com/sitemap-index.xml
```
The browser's "save as" wrote no content (likely the XML was not rendered in the HTML context the browser saved). Subsequent XHR fetch via `cmux browser eval fetch('/Sitemap/sitemap-index.xml')` also failed — the URL redirected to a category page. The sitemap declared in robots.txt (`/Sitemap/sitemap-index.xml`) is effectively a broken link.

**11. API stream timeout mid-response (MSG 190)**
After completing all exploration and starting to write output files, the response was interrupted:
```
API Error: Stream idle timeout - partial response received
```
This caused Phase 12 to fail mid-execution. The user had to re-issue the instruction to start writing, and the agent resumed from scratch in the next message.

**12. JavaScript syntax errors in cmux eval commands**
Several `cmux browser eval` calls failed with JS exceptions due to backslash escaping problems in shell-quoted JS:
- `(eval):36: unmatched ]` — Python script injection via bash heredoc
- `(eval):1: bad math expression: illegal character: \` — Backslash in URL string inside eval
- `Error: js_error: A JavaScript exception occurred` — Unquoted array literal syntax

Each required a rewrite of the eval expression.

**13. "No JSON API" incorrect premature conclusion**
The agent wrote in the INDEX.md and the product-data.md surface file:
> "JetPens has NO public JSON REST API and NO product XML/RSS feed."

This was written after Phase 12 but before applying the ZF1 tech pack. When the user pushed back ("are you 100% sure?") and then pointed to the Zend Framework tech pack, the agent found:
- `/blog/feed` — real Atom XML feed (20 entries, generator: `Zend_Feed_Writer 1.12.20`)
- `/Compare/loadAjax` — full JSON spec table (nib size, SKU, dimensions, weight, filling mechanism, price-per-ml)
- `/Compare/addProductAjax?products_id=N` — single-product JSON
- `/Compare/addMultiProductAjax?products_ids=N,N,N` — bulk product JSON (up to 6)
- `/Compare/getPopularComparisonsAjax` — curated product ID groups as JSON
- `/Compare/removeAllProductsAjax` — session reset
- `/cart/addAjax?products_id=N` — JSON `{"status":"success", "message":"...", "cart_quantity":..., "cart_value":"..."}`
- `/cart/getAddListAjax?products_ids=N,N` — HTML product cards with name, price, image alt
- `/Search/index/q/{query}` — ZF1-style alternate search URL
- `/Cookies/ajaxUpdateAllAccept/format/json` → `{"response":"ok"}` — ZF1 context switching confirmed active
- `/Newsletter/subscribeSubmit` — POST target for email signup

The Compare API in particular is the richest data source on the site — it returns a full structured JSON spec table for up to 6 products per call, with 25+ spec attributes including nib size, body dimensions, filling mechanism, ink volume, and water resistance.

### Missing Tech Pack Knowledge

**1. Zend Framework tech pack existed but was not applied proactively**
The agent identified Zend Framework 1.12.20 from the `/blog/feed` Atom generator tag (`generator uri="http://framework.zend.com" version="1.12.20"`). However, it did not proactively look up a ZF1 tech pack at that point. The tech pack was only applied after the user manually said: "i have added a guide in beacon skill for zend framework read it and check if we can extract more info from this site."

This reveals a gap in the Phase 4 trigger: tech pack lookup should happen whenever a framework is fingerprinted, not only when the fingerprint occurs in Phase 3. When the framework is identified late (e.g., from an Atom feed), Phase 4 must be re-triggered.

**2. ZF1 URL routing pattern not in base knowledge**
The ZF1 parameter-value URL format (`/{Controller}/{action}/{key}/{value}` and `/format/json` context switching) is not in the agent's default e-commerce probe list. The tech pack contained this, but the agent would not have probed it without the tech pack. Specifically:
- `/format/json` appended to any action URL switches the response format
- `/{key}/{value}` replaces `?key=value` query strings
- This applies to all controllers: `/Cart/addAjax/products_id/7979`, `/Search/index/q/pilot/format/json`, etc.

**3. No probe for Compare/Wishlist/Batch product endpoints**
The beacon skill has no default probes for:
- Product comparison tools (`/Compare/loadAjax`, `/Compare/addProductAjax`)
- Wishlist add endpoints (`/Wishlist/add/products_id/N`)
- Batch product card endpoints (`/cart/getAddListAjax?products_ids=N,N`)
- Popular/featured product groupings (`/Compare/getPopularComparisonsAjax`)

These are e-commerce-specific patterns that are highly valuable for data extraction but not in the generic probe list.

### Agent Confusion Points

**1. Incorrect `www-` slug prefix**
The site slug was generated as `www-jetpens-com` rather than `jetpens-com`. This is technically correct (the URL is `www.jetpens.com`) but inconsistent with the Pen-Chalet session which used `penchalet-com` without `www-`. The slug format should be normalized.

**2. Stale background tasks**
Two background bash tasks were left running when the user gave the ZF1 tech pack instruction. The task notification appeared at MSG 386 (after the session was essentially complete), as a stale confirmation that the `find` for Zend pack files completed. This created noise and slight confusion but no material error.

**3. Atom feed Zend Framework signal not triggering Phase 4 re-run**
When `/blog/feed` returned `<generator uri="http://framework.zend.com" version="1.12.20">`, the agent noted "Zend Framework 1.12.20 as the backend" in a summary comment but did not immediately re-run Phase 4 with the new tech pack lookup. The agent continued to Phase 12 output writing. This is the same premature completion pattern as Pen-Chalet — fingerprint found late in Phase 6/9 does not loop back to Phase 4.

**4. `/feeds/products` misread as a potential product feed**
The agent attempted `fetch('/feeds/products')` as a potential product XML/JSON feed. It returned the full homepage HTML (270KB). The agent correctly identified it as a fallback but the probe should have checked `Content-Type` before reading the body to avoid loading 270KB unnecessarily.

**5. Compare page XHR result misread**
After navigating to `/Compare?list_type=grid&id=...`, the agent ran an XHR fetch from the page context and got confused by the Compare page having price data `["$35","$35","$91.50",...]` but the `data-product-id` attribute not appearing in the quick regex. It took a navigation + screenshot + separate XHR monitoring (`mcp__plugin_chrome-devtools-mcp_chrome-devtools__list_network_requests`) to identify `/Compare/loadAjax` as the actual data endpoint.

### User Corrections

1. **"probably it will fail while you are using a new chrome browser try to use cmux browser"** — After Cloudflare challenge was triggered, user directed the agent to use the cmux browser which held an existing CF session.
2. **"are you 100% sure there is not a programmable way to extract all info? for example xml? or rss"** — Challenged the "no JSON API" conclusion; agent then found the Atom feed and `/feeds/products` (which turned out to be a 404 fallback).
3. **"i have added a guide in beacon skill for zend framework read it and check if we can extract more info from this site"** — Required manual user intervention to apply the tech pack that was sitting in the plugin directory; the agent had fingerprinted ZF1 but had not looked for the pack.
4. **"if you cannot find it is it in projects/claude-plugins"** — Agent was searching via background tasks with `find` and didn't know where the tech pack lived; user provided the path.
5. **"ok save all what you found to the appropriate place, is there anything we may miss?"** — User had to explicitly ask for a gap audit after the ZF1 findings; agent then found the newsletter POST endpoint and verified Compare API limits (6 products max).

---

## Cross-Session Patterns

### Common Failure Modes

**1. Write-before-Read on scaffolded files (both sessions, every output file)**
Pattern: `touch file.md` (scaffold) → `Write file.md` → tool error → `Read file.md` → `Write file.md`.
Occurs in: all 8 initial output files in Pen-Chalet, all 4 initial output files in JetPens.
Fix: The scaffold step should either use `Write` directly with empty content (no `touch`), or the Phase 12 writer must always `Read` before `Write`.

**2. Phase skipping — Phase 4 (tech pack) and Phase 5 (known patterns) most at risk**
Both sessions skipped or delayed these phases. In Pen-Chalet, all three (4, 5, 7) were skipped. In JetPens, Phase 4 was applied late (after ZF1 fingerprint from feed). The beacon skill needs an explicit phase-completion checklist gate before entering Phase 12.

**3. Premature "no API" conclusion**
Both sessions produced an initial verdict that the site had no programmatic data endpoints. In both cases this was wrong:
- Pen-Chalet: had `/autocomplete.aspx` and shipping rate endpoints in JS
- JetPens: had the entire Compare API (`/Compare/loadAjax`, etc.), cart AJAX returning JSON, and a working Atom feed

This pattern suggests the skill's default probe list is insufficient for e-commerce sites. A JSON/API verdict should require completion of all endpoint probe phases.

**4. Chrome MCP dual namespace confusion**
Both sessions required ToolSearch to switch from `mcp__chrome-devtools__*` to `mcp__plugin_chrome-devtools-mcp_chrome-devtools__*`. The skill should document which namespace to prefer, or the tool check in Phase 1 should identify the active MCP server and set a session variable.

**5. Cloudflare blocks all curl probes**
Both sites were on Cloudflare with bot protection. Every `curl`-based probe in Phase 2 and 5 returned 403. The skill relies on `curl` as the primary HTTP probe tool, but this tool is completely ineffective against modern Cloudflare configurations. The agent had to pivot to browser-based `fetch()` for all endpoint probing.

**6. Late fingerprint does not re-trigger Phase 4**
In both sessions, a framework signal was found late (ASP.NET in Pen-Chalet via response headers in Phase 3, ZF1 in JetPens via Atom feed in Phase 6). In neither case did the agent automatically loop back to Phase 4 for a tech pack lookup on the newly identified framework. Phase 4 needs to be retriggered whenever a new framework is identified at any point in the scan.

### E-Commerce Gaps in Beacon Skill

The following e-commerce endpoint patterns were absent from beacon's default probe list and had to be discovered manually or via tech packs:

**Cart and Transaction APIs**
- `POST /cart/add` / `GET /cart/addAjax?products_id=N` — cart AJAX endpoints (found in JetPens JS bundle)
- `GET /cart/getAddListAjax?products_ids=N,N` — batch product card HTML (JetPens)
- Cart total / cart count polling endpoints
- Guest checkout vs authenticated checkout surface differences

**Product Discovery and Batch Data**
- `/Compare/loadAjax` — product spec comparison endpoint (JetPens — the richest data source on the site)
- `/Compare/addProductAjax?products_id=N` — single product to compare session
- `/Compare/addMultiProductAjax?products_ids=N,N,N` — batch product add
- `/Compare/getPopularComparisonsAjax` — curated product ID groups
- `/cart/getAddListAjax` as a batch product card fetch

**Search and Autocomplete**
- `/search/suggestions?q=` (JetPens) / `/autocomplete.aspx?keyword=` (Pen-Chalet) — search autocomplete as a product discovery tool
- ZF1-style `/Search/index/q/{query}` alternate URL
- Search result pages as a crawl-seed for product IDs

**Feeds and Structured Data**
- Product Atom/RSS feeds (`/feeds/products`, `/feed/products.xml`, Google Shopping XML)
- Blog Atom feeds as backend fingerprint source (`generator` tag → ZF1)
- Google Merchant Center feeds (`/feeds/google`, `/feeds/google-base`)
- Sitemap index with product sub-sitemaps (different from page sitemaps)

**Platform-Specific REST APIs**
- WooCommerce Store API: `GET /wp-json/wc/store/v1/products?per_page=100&page=N` — no auth required, returns full JSON
- Magento 2 GraphQL: `POST /graphql` with `Store: {store_code}` header — not probed without tech pack
- Shopify: `GET /products.json?limit=250&page_info=cursor` — standard enumeration
- ZF1 context switching: appending `/format/json` to any controller action

**Auth and User Surfaces**
- Wishlist add/remove endpoints (`/Wishlist/add/products_id/N`)
- Restock notification subscribe (`POST /Products/ajaxNotify`)
- Newsletter subscribe (POST target often different from form action: `/Newsletter/subscribeSubmit` vs `/Newsletter/subscribe`)
- Login flow: `GET /login?redirect_url=...` → `POST /login/verifyLogin`

### Recommended Improvements for Beacon

**New Tech Packs Required (in priority order)**
1. `aspnet` — ASP.NET WebForms and MVC: `.axd` endpoint probes, ViewState detection, IIS fingerprint (`web.config` 403), `category.aspx`/`search.aspx` patterns, server-side GTM patterns
2. `magento` — Magento 2: GraphQL endpoint at `/graphql`, required `Store: {code}` header, product query schema, category tree query, page-based pagination with `currentPage`/`pageSize`
3. `woocommerce` — WooCommerce (distinct from WordPress): `/wp-json/wc/store/v1/products`, `/wp-json/wc/store/v1/cart`, category enumeration via `/wp-json/wc/store/v1/products/categories`, no-auth requirement for Store API v1

**Expand Existing Tech Packs**
4. `wordpress` — Add WooCommerce detection (check for `wc` or `woocommerce` in `generator` meta, check `/wp-json/wc/` endpoint availability) and route to WooCommerce section
5. `zend-framework` (1.x, already exists) — Ensure it is proactively fetched whenever ZF fingerprint found at any phase, not only when user requests it; add note about Atom feed `<generator>` tag as fingerprint source

**Skill Logic Fixes**
6. **Fix Write-before-Read bug in scaffold step**: Replace `touch` with `Write` directly (empty string), or require `Read` of every scaffolded file at the start of Phase 12 before writing. This eliminates all Write-before-Read failures.
7. **Add explicit phase-completion gate before Phase 12**: The skill must verify that all 11 phases were executed before flushing to disk. A simple checklist: `[P1✓][P2✓]...[P11✓] → proceed to P12`. If any phase is missing, log it and offer to run.
8. **Re-trigger Phase 4 on late framework discovery**: Any time a new technology signal is identified (in any phase), check whether a tech pack exists and load it before continuing. This catches ZF1 from Atom feed, ASP.NET from response headers after initial curl failure, etc.
9. **Improve tool availability check for aliased commands**: `which gau` is insufficient. The check should run the command with a `--version` or `--help` flag and verify the output matches expected behavior (e.g., `gau --version` should return `getallurls`, not `git` output).

**E-Commerce Probe Additions (new Phase 5 patterns)**
10. Add e-commerce-specific endpoint probe list covering:
    - Cart AJAX: `GET /cart/addAjax?products_id=1`, `GET /cart/getAddListAjax?products_ids=1`
    - Compare API: `GET /Compare/loadAjax`, `GET /Compare/getPopularComparisonsAjax`
    - Search autocomplete: `/search/suggestions?q=test`, `/autocomplete?q=test`, `/search/autocomplete?q=test`
    - Product feeds: `/feeds/products`, `/feeds/google`, `/feed`, `/feeds/rss`
    - Platform APIs: `/wp-json/wc/store/v1/products`, `POST /graphql`, `/products.json`
    - Newsletter endpoints: `POST /newsletter/subscribe`, `POST /Newsletter/subscribeSubmit`

**Infrastructure and Tooling**
11. **Document Cloudflare bypass strategy**: When curl returns 403 on Cloudflare, the skill should immediately pivot to browser-based fetch() calls from within a page context. Document this explicitly in site-recon, including the opaque-redirect pattern for CORS-blocked probes.
12. **Document Chrome MCP namespace selection**: Phase 1 tool check should test both `mcp__chrome-devtools__*` and `mcp__plugin_chrome-devtools-mcp_chrome-devtools__*` and record which one is active. Subsequent phases use the recorded namespace.
13. **Document Cloudflare Turnstile limitation**: The Turnstile verification checkbox cannot be interacted with via CDP `click`. When Turnstile is detected (snapshot shows "Performing security verification"), the probe must use an existing-session browser (cmux or a manually-cleared Chrome) rather than a fresh CDP page.
14. **Add cmux usage guide to site-recon**: When cmux is available (Phase 1 check), document the correct command syntax for navigation, eval, and screenshot: `cmux browser --surface {id} goto {url}`, `cmux browser --surface {id} eval {js}`, `cmux browser --surface {id} screenshot --out {path}`. Surface ID is returned by `cmux browser open {url}`.
15. **Normalize site slug format**: Strip `www.` prefix from URL when generating the slug. `jetpens-com` not `www-jetpens-com`, consistent with `penchalet-com`.
