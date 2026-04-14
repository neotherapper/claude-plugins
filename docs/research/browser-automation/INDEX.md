# Browser Automation — Research Reference

> Beacon uses browser automation in Phase 11 (active browse) to execute the browse plan compiled in Phase 10. Two options: Chrome DevTools MCP or cmux browser. Always prefer cmux in cmux sessions.

## Two Browser Surfaces

| Surface | When to use | How to check availability |
|---------|------------|--------------------------|
| cmux browser | When running inside cmux terminal | `echo $CMUX_SURFACE_ID` — non-empty means cmux |
| Chrome DevTools MCP | When NOT in cmux, MCP is available | Check for `mcp__chrome-devtools__*` tools |
| Neither available | Fallback: static curl only | Phase 11 skipped; note in session brief |

## cmux Browser (preferred in cmux sessions)

cmux is the terminal multiplexer used in the nikai project. It ships a WebKit-based browser.

### Quick Reference

```bash
# Find existing browser surfaces
cmux tree   # look for [browser] in output

# Open a browser in current pane
cmux browser open-split https://example.com

# Navigate to URL (N = surface number from cmux tree)
cmux browser surface:N goto https://example.com/api

# Wait for page load
cmux browser surface:N wait --load-state complete

# Get accessibility snapshot (for AI reasoning — structured text, not screenshot)
cmux browser surface:N snapshot --compact

# Take screenshot to file
cmux browser surface:N screenshot --out /tmp/page.png

# Evaluate JavaScript
cmux browser surface:N evaluate "document.querySelectorAll('a[href*=\"api\"]').length"

# Click an element
cmux browser surface:N click "button[data-id=login]"

# Fill a form field
cmux browser surface:N fill "input[name=email]" "test@example.com"
```

### CMUX_SURFACE_ID

Inside a cmux terminal, `$CMUX_SURFACE_ID` is auto-set. The `--surface` flag is usually optional.

```bash
# These are equivalent inside cmux
cmux browser surface:${CMUX_SURFACE_ID} goto https://example.com
cmux browser goto https://example.com  # CMUX_SURFACE_ID auto-used
```

### Beacon Browse Plan Execution (cmux)

```bash
# Phase 11 — execute browse plan
URL="https://example.com"
SITE="example-com"
CAPTURE_DIR="docs/research/${SITE}"

# Open browser
cmux browser open-split ${URL}
cmux browser wait --load-state complete

# For each URL in browse plan:
cmux browser goto https://example.com/api/docs
cmux browser wait --load-state complete
cmux browser snapshot --compact > ${CAPTURE_DIR}/browse-snapshots/api-docs.txt

# Trigger authenticated requests (if auth was found in earlier phases)
# ...

# Take screenshots of interesting pages
cmux browser screenshot --out ${CAPTURE_DIR}/browse-snapshots/api-docs.png
```

Full cmux reference: `docs/guides/cmux-browser.md` (in nikai project)

## Chrome DevTools MCP (non-cmux sessions)

When `mcp__chrome-devtools__*` tools are available in the session.

### Page Management

```
mcp__chrome-devtools__new_page
  → opens a new browser tab, returns page_id

mcp__chrome-devtools__list_pages
  → returns all open pages with their IDs and URLs

mcp__chrome-devtools__select_page(page_id)
  → switches focus to a specific page

mcp__chrome-devtools__close_page(page_id)
  → closes a page

mcp__chrome-devtools__navigate_page(url, page_id?)
  → navigate to URL

mcp__chrome-devtools__wait_for(selector_or_condition, timeout_ms?)
  → wait for element or network idle
```

### Content & Snapshots

```
mcp__chrome-devtools__take_screenshot(options?)
  → PNG screenshot, returns base64 or file path

mcp__chrome-devtools__take_snapshot
  → DOM/accessibility snapshot (structured text, better for AI reasoning)

mcp__chrome-devtools__evaluate_script(script, page_id?)
  → run JavaScript in the page context
  
  Useful scripts:
  - Get all script src URLs:
    Array.from(document.querySelectorAll('script[src]')).map(s => s.src)
  - Get all API-looking links:
    Array.from(document.querySelectorAll('a[href*="api"]')).map(a => a.href)
  - Get performance resource timing:
    performance.getEntriesByType('resource').map(r => r.name)
  - Get window globals:
    Object.keys(window).filter(k => k.startsWith('__'))
  - Get __NEXT_DATA__:
    JSON.stringify(window.__NEXT_DATA__, null, 2)
```

### Network Interception

```
mcp__chrome-devtools__list_network_requests(options?)
  options:
    url_filter: string (regex or substring match)
    method: "GET" | "POST" | ...
    status_code: number
  → returns array of { url, method, status, headers, timing }

mcp__chrome-devtools__get_network_request(request_id)
  → full request/response including body

mcp__chrome-devtools__get_console_message
mcp__chrome-devtools__list_console_messages
  → browser console output (errors, logs, warnings)
```

### Interaction

```
mcp__chrome-devtools__click(selector, page_id?)
  → click element by CSS selector or XPath

mcp__chrome-devtools__fill(selector, value, page_id?)
  → fill form field

mcp__chrome-devtools__fill_form(form_data, page_id?)
  → fill multiple fields at once

mcp__chrome-devtools__hover(selector, page_id?)
  → hover over element

mcp__chrome-devtools__press_key(key, page_id?)
  → send keyboard event

mcp__chrome-devtools__type_text(text, page_id?)
  → type text at current focus

mcp__chrome-devtools__drag(source_selector, target_selector)
  → drag and drop

mcp__chrome-devtools__handle_dialog(action, text?)
  → accept/dismiss alert/confirm/prompt dialogs

mcp__chrome-devtools__upload_file(selector, file_path)
  → upload file via input[type=file]
```

### Performance & Diagnostics

```
mcp__chrome-devtools__performance_start_trace
mcp__chrome-devtools__performance_stop_trace
mcp__chrome-devtools__performance_analyze_insight(insight_name)
  → performance analysis

mcp__chrome-devtools__lighthouse_audit(url, options?)
  → run Lighthouse audit (performance, accessibility, SEO)

mcp__chrome-devtools__take_memory_snapshot
  → heap snapshot for memory analysis
```

### Browser Configuration

```
mcp__chrome-devtools__emulate(device_or_viewport)
  → emulate mobile device or set viewport
  device options: "iPhone 12", "iPad", etc.
  or: { width: 375, height: 812, mobile: true }

mcp__chrome-devtools__resize_page(width, height)
  → resize browser window
```

## Beacon Browse Plan — Execution Pattern

The browse plan compiled in Phase 10 lists:
1. URLs to visit (priority-ordered)
2. Actions per URL (click, fill, scroll)
3. What to capture (network requests, snapshots, JS globals)

### Execute the plan (Chrome DevTools MCP)

```markdown
1. Open new page
   → mcp__chrome-devtools__new_page → page_id

2. For each URL in browse plan:
   a. Navigate
      → mcp__chrome-devtools__navigate_page(url, page_id)
      → mcp__chrome-devtools__wait_for("networkidle", 5000)
   
   b. Capture JS globals (if tech pack says to check them)
      → mcp__chrome-devtools__evaluate_script("window.__NEXT_DATA__")
   
   c. Get all network requests triggered by page load
      → mcp__chrome-devtools__list_network_requests({ url_filter: "/api/" })
   
   d. Perform actions from browse plan (click login, submit forms, etc.)
   
   e. Re-capture network requests after interactions
      → mcp__chrome-devtools__list_network_requests()
   
   f. Take accessibility snapshot for documentation
      → mcp__chrome-devtools__take_snapshot

3. Export all captured network requests as HAR
   → mcp__chrome-devtools__list_network_requests() → filter → format as HAR

4. Convert to OpenAPI
   → har-to-openapi capture.har --include-domains {domain} > openapi.yaml
```

## HAR Export from Chrome DevTools MCP

Chrome DevTools MCP doesn't natively export HAR, but you can reconstruct one:

```javascript
// Collect all network requests during session
const requests = await mcp__chrome-devtools__list_network_requests({});

// Format as minimal HAR
const har = {
  log: {
    version: "1.2",
    creator: { name: "beacon-plugin", version: "0.1.0" },
    entries: requests.map(r => ({
      request: {
        method: r.method,
        url: r.url,
        headers: Object.entries(r.request_headers || {}).map(([k,v]) => ({name:k,value:v})),
        postData: r.request_body ? { text: r.request_body } : undefined
      },
      response: {
        status: r.status,
        headers: Object.entries(r.response_headers || {}).map(([k,v]) => ({name:k,value:v})),
        content: { text: r.response_body || "" }
      }
    }))
  }
};
```

## Session Brief — Phase 11 Entries

```markdown
## Phase 11 — Active Browse

### Tool used: Chrome DevTools MCP
### Pages visited:
- https://example.com/ — captured 8 API requests
- https://example.com/login — captured auth flow (POST /api/auth/login)
- https://example.com/dashboard — captured 3 authenticated API calls

### New endpoints discovered (not found in phases 2-9):
- POST /api/auth/login → returns JWT token
- GET /api/user/profile (authenticated)
- GET /api/notifications?page=1

### HAR captured: .beacon/capture.har (47 requests)
### OpenAPI generated: docs/research/example-com/specs/example-com.openapi.yaml
  source: har-capture
```

## When Neither Tool Is Available

Phase 11 is **skipped entirely**. Log in session brief:

```markdown
## Phase 11 — Active Browse
[TOOL-UNAVAILABLE:cmux-browser]
[TOOL-UNAVAILABLE:chrome-devtools-mcp]
Skipped. Static analysis (Phases 2-9) provides the API surface. HAR capture not performed.
```

The OpenAPI spec is generated from statically-discovered endpoints in Phase 12 instead.

## Source

- Design spec Phase 11 and Phase 10 (browse plan) sections
- nikai CLAUDE.md cmux browser section
- Chrome DevTools MCP tool list (session-loaded MCP tools)
