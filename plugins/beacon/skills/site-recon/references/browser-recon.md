# Phase 11 — Active Browser Recon

This reference covers the full Phase 11 execution flow: tool detection, auth setup, browse plan execution, HAR reconstruction, and OpenAPI generation.

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

### cmux Per-URL Loop

```bash
cmux browser surface:N goto {url}
cmux browser surface:N wait --load-state complete
cmux browser surface:N eval "JSON.stringify((() => { ... globals ... })()"
cmux browser surface:N network requests
cmux browser surface:N snapshot --compact
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
