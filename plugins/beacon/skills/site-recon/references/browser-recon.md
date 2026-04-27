# Phase 11 — Active Browser Recon

This reference covers the full Phase 11 execution flow: tool detection, auth setup, browse plan execution, HAR reconstruction, and OpenAPI generation.

---

## Cloudflare and Bot Protection

When the target site is behind Cloudflare (detected by 403 on Phase 2 curl probes):

### Identification
A Cloudflare block is confirmed when:
- `GET /robots.txt` via curl returns HTTP 403 (not 401 — that is auth)
- Response body contains `cloudflare` or `cf-ray` header is present
- Log immediately: `[CF-BLOCKED:curl]`

### Pivot strategy
All Phase 2, 5, 6, 8 probes must be run via browser `fetch()` from inside a page
already loaded on the target domain (which holds a CF clearance cookie):

```javascript
// Run inside evaluate_script() from a page on the target domain
const result = await fetch('/robots.txt').then(async r => ({
  status: r.status,
  type: r.type,
  body: r.ok ? await r.text() : null
}));
JSON.stringify(result)
```

Log: `[CF-PIVOT:browser-fetch]`

**CORS-blocked probes:** Same-origin `fetch()` from page context works for all paths on the
same domain. Cross-origin requests (e.g., to crt.sh from within the target page) return
`{status: 0, type: "opaqueredirect"}` — this means the route exists but CORS blocks the body.
Log as `[CORS-OPAQUE:{path}]` and note the route exists.

### Cloudflare Turnstile
If a page triggers a Turnstile challenge (visible as a spinner/checkbox in the page), the CDP
`click()` on the verify checkbox will time out with: `The element did not become interactive
within the configured timeout`. This is a fundamental limitation — Turnstile is designed to
prevent CDP interaction.

**Resolution:** switch to a cmux surface that holds an existing CF clearance from a real browser
session. Do NOT retry the CDP click — it will always fail. Log: `[CF-TURNSTILE-BLOCKED:{url}]`

---

## Phase 11a — Tool Detection + Auth Setup

### Detection Logic

```
Chrome DevTools MCP:
  → Check if mcp__chrome-devtools__list_pages is callable
  YES:
    → Call list_pages
    → Returns pages with real URLs (non-about:blank)?
        YES → [CHROME-MODE:auto-connect] — user's Chrome sessions inherited
        NO  → [CHROME-MODE:new-instance] — fresh headless instance, no sessions
  NO:
    → Check cmux: [ -n "$CMUX_SURFACE_ID" ] || which cmux >/dev/null 2>&1
    YES → cmux mode
    NO  → log [PHASE-11-SKIPPED] → skip to Phase 12
```

### Auth Setup (new-instance Chrome or cmux only)

Check `.beacon/auth-state.json` — if exists, offer to load it.

- cmux load: `cmux browser surface:N state load .beacon/auth-state.json`

If not found, offer 3 options:

**A) Manual login**
- Navigate to site, pause, wait for user confirmation
- `cmux browser surface:N state save .beacon/auth-state.json`
- Log `[PHASE-11-AUTH:manual]`

**B) Skip auth**
- Log `[PHASE-11-UNAUTH]`

**C) Auto-connect setup**
- Print platform instructions (macOS/Linux/Windows) for `--remote-debugging-port=9222`
- Instruct updating MCP config `wsEndpoint`

---

## Phase 11b — Browse Plan Execution

Execute each URL from the Phase 10 browse plan (up to 10 URLs, in priority order):

### Chrome DevTools MCP Per-URL Loop — CORRECTED v0.21.0 Signatures

```
1. new_page → page_id
2. select_page(page_id)
3. navigate_page(url, type="url", timeout=10000)
   NOTE: NO page_id parameter in navigate_page
4. Poll evaluate_script(() => document.readyState) until "complete"
   (retry 3× with 2s delay) — use readyState polling, not the wait_for idle variant
5. evaluate_script() for JS globals:
   - __NEXT_DATA__
   - __NUXT__
   - Shopify
   - __remixContext
   - __initialData__
   - plus catch-all __ prefix scan
6. list_network_requests({resourceTypes: ["xhr", "fetch"]})
   NOTE: filter requests client-side — no extra filter parameter supported
7. get_network_request(reqid) per matching request
8. take_snapshot()
```

Key corrections vs older signatures:
- `navigate_page(url, type="url", timeout=10000)` — no `page_id` argument
- `list_network_requests({resourceTypes: [...]})` — filter results client-side after retrieval
- Use `document.readyState` polling (readyState === "complete") for load detection

## cmux Browser Commands (Phase 11) — CORRECTED SIGNATURES

The cmux commands in this file reflect v1.x syntax observed in production sessions.
`cmux browser wait --load-state complete` is NOT a valid command in this version.

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

**Backslash escaping in eval:** When the JS string contains backslashes or single quotes,
pass it as a heredoc or use double-outer/single-inner quoting:
```bash
cmux browser --surface $SURF eval "JSON.stringify(fetch('/api/products').then(r=>r.json()))"
# Not safe with single quotes inside — use JSON.stringify to wrap
```

---

## Phase 11c — HAR Reconstruction

Save raw captures before reconstruction:

- Chrome MCP → `.beacon/chrome-requests.json`
- cmux → `.beacon/cmux-requests.json`

Run har-reconstruct.py:

```bash
python3 scripts/core/har-reconstruct.py \
  --input .beacon/chrome-requests.json \
  --output .beacon/capture.har \
  --domain {target-domain}
```

The `--domain` flag filters requests to only the target domain, keeping the HAR clean of third-party noise.

---

## Phase 11d — OpenAPI Generation + Passive Spec Merge

```bash
npx har-to-openapi .beacon/capture.har \
  --include-domains {site-domain} \
  --format yaml \
  --attempt-to-parameterize-url \
  --infer-parameter-types \
  --guess-authentication-headers \
  --drop-paths-without-successful-response \
  -o docs/research/{site-slug}/specs/{site-slug}.openapi.yaml
```

If har-to-openapi unavailable: log `[OPENAPI-SKIPPED:har-to-openapi-unavailable]`

**Passive spec merge** (if Phase 8 saved `specs/{site-slug}.openapi-passive.yaml`):
1. Read both specs
2. Add endpoints from passive spec not present in observed spec; mark with `x-beacon-source: passive`
3. Flag conflicts between specs: add `x-beacon-note: "passive spec claims {passive_status}, observed {observed_status}"` to conflicting endpoints
4. Write single merged `specs/{site-slug}.openapi.yaml`
5. Remove `specs/{site-slug}.openapi-passive.yaml` (prevents stale duplicate in output)

---

## Graceful Degradation Signals

| Signal | Meaning |
|--------|---------|
| `[CHROME-MODE:auto-connect]` | Chrome MCP connected to user's browser — sessions inherited |
| `[CHROME-MODE:new-instance]` | Chrome MCP launched fresh headless instance |
| `[PHASE-11-AUTH:manual]` | User logged in manually; auth state saved |
| `[PHASE-11-UNAUTH]` | Phase 11 ran without authentication |
| `[PHASE-11-SKIPPED]` | No browser tool available |
| `[OPENAPI-SKIPPED:har-to-openapi-unavailable]` | HAR preserved; tool missing |
