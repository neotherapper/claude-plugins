# Output Synthesis

Phase 12 reads the completed session brief and writes all research output files to disk.
No network calls. No new tools. Pure synthesis from what Phases 1–11 captured.

## What Phase 12 Reads

| Session brief section | Used for |
|----------------------|----------|
| Infrastructure table | `tech-stack.md` rows + INDEX.md tokens |
| Discovered URLs list | `site-map.md` grouped by phase |
| Discovered Endpoints table (Method, Path, Auth, Phase, Notes) | `api-surfaces/{surface}.md` files + `smoke-test.sh` `check()` calls |
| JS globals + API response constants | `constants.md` rows |
| Phase 11 results block | `constants.md` rows (enums, flags from JS globals) |
| `[PHASE-11-SKIPPED]` / `[OPENAPI-SKIPPED:...]` signals | `OPENAPI_STATUS` token |

## Output Files

### tech-stack.md

**CRITICAL:** `tech-stack.md` contains **site-specific discovered data** from the session brief —
NOT the content of the loaded tech pack. The tech pack is a probe guide, not a report.
Do not copy any content from the tech pack file into tech-stack.md. If the tech pack was
loaded as `[LOADED:wordpress:6.x]`, tech-stack.md says `Framework: WordPress 6.5` (what you
found on the site), not the WordPress tech pack instructions.

Copy the Infrastructure table rows from the session brief verbatim into this format:

```markdown
# {SITE_NAME} — Tech Stack

**Analysed:** {DATE}

| Property | Value | Source |
|----------|-------|--------|
| Framework | {FRAMEWORK} {VERSION} | {signal e.g. "wp-content/ in HTML"} |
| CDN | {CDN} | {signal} |
| Auth | {AUTH} | {signal} |
| Bot protection | {BOT_PROTECTION} | {signal} |
| Hosting | {HOSTING} | {signal} |
```

### site-map.md

List every URL discovered, grouped by the phase that found it:

```markdown
# {SITE_NAME} — Site Map

**Analysed:** {DATE}

## Phase 2 — Passive Recon
- {url}

## Phase 5 — Known Patterns
- {url}

## Phase 11 — Active Browse
- {url}
```

Omit any phase group that found no URLs.

### constants.md

Load `templates/constants.md.template`. Replace tokens and populate rows from the session brief.

**How to populate rows:**

- **Nonces & CSRF Tokens**: Nonce values from JS globals (e.g. `window.wpApiSettings.nonce`) or `data-nonce` HTML attributes. Include the session-specific caution — these values expire.
- **Taxonomy IDs**: Category IDs, tag IDs, post type slugs, CPT slugs from API responses.
- **Enum Values**: Status strings, type values, state machine values from API responses (e.g. `"status": "publish"`, `"type": "post"`).
- **Feature Flags**: Boolean flags or A/B variant IDs from JS globals or API responses.
- **Locale & i18n**: Language codes, currency codes, locale strings from API responses or JS globals.
- **Misc Constants**: API version strings, build IDs, CDN base URLs, or anything else that doesn't fit the above.

**Omit any section with no data** — drop the entire `##` block if nothing was found for that category.

**Row format:** `| {key} | {value} | {source e.g. "window.wpApiSettings"} |`

### scripts/test-{site-slug}.sh

Load `templates/smoke-test.sh.template`. Replace tokens:

| Token | Value |
|-------|-------|
| `{{SITE_SLUG}}` | Site slug (e.g. `example-com`) |
| `{{PLUGIN_VERSION}}` | Current plugin version from `.claude-plugin/plugin.json` |
| `{{DATE}}` | Session date |
| `{{BASE_URL}}` | Target site root URL (e.g. `https://example.com`) |

Replace `{{SMOKE_TEST_CHECKS}}` with one `check()` call per row in the Discovered Endpoints table:

```bash
check "{METHOD} {path}" "{BASE_URL}{path}" "{expected_status}" "{auth_required}"
```

- `{auth_required}` is `"true"` if the Auth column = Yes, `"false"` otherwise.
- `{expected_status}` is `"200"` unless the session brief notes a different expected status.

Example generated block:
```bash
check "GET /api/v1/posts" "$BASE_URL/api/v1/posts" "200" "false"
check "POST /api/v1/auth/login" "$BASE_URL/api/v1/auth/login" "200" "true"
check "GET /api/v1/users" "$BASE_URL/api/v1/users" "200" "true"
```

### api-surfaces/{surface}.md

Load `templates/api-surface.md.template` once per distinct API surface discovered.

**What counts as a distinct surface:** A logically-related group of endpoints sharing a base path and auth mechanism (e.g., `/wp-json/wp/v2/*` = one surface, `/wp-json/wc/v3/*` = a separate surface). Single-endpoint discoveries can be grouped into a surface named for their type (e.g., `rest-api`, `graphql`, `ajax`).

**Surface naming:** lowercase, hyphenated. Examples: `wordpress-rest-api`, `woocommerce-api`, `graphql`, `ajax-endpoints`.

**Token replacement:**

| Token | Value |
|-------|-------|
| `{{SURFACE_NAME}}` | Human-readable surface name (e.g. `WordPress REST API`) |
| `{{SITE_NAME}}` | Site name from session brief header |
| `{{BASE_URL}}` | Base URL of the surface (e.g. `https://example.com/wp-json/wp/v2`) |
| `{{AUTH_REQUIRED}}` | `Yes`, `No`, or `Partial (some endpoints require auth)` |
| `{{DISCOVERY_PHASE}}` | Phase number that first discovered this surface (e.g. `5`) |
| `{{DATE}}` | Session date |
| `{{ENDPOINT_ROWS}}` | One row per endpoint: `\| METHOD \| /path \| Yes/No \| {shape} \| {notes} \|` |
| `{{AUTH_DETAIL}}` | Auth mechanism description (token type, header name, acquisition method) |
| `{{RATE_LIMIT_NOTES}}` | Rate limit headers observed (e.g. `X-RateLimit-Limit: 100/hr`) or `Not detected` |
| `{{SURFACE_NOTES}}` | Additional observations (versioning, pagination, CORS, etc.) |
| `{{EXAMPLE_REQUEST}}` | One representative `curl` command for an unauthenticated or low-risk endpoint |
| `{{EXAMPLE_RESPONSE}}` | Truncated JSON response shape (keys only, no real data) |

Write each surface file to: `docs/research/{site-slug}/api-surfaces/{surface-name}.md`

If no distinct API surfaces were found (static site, all endpoints behind auth with no observable shape), write a single `api-surfaces/no-public-surfaces.md` noting that observation.

## Token Resolution

Load `templates/INDEX.md.template` and resolve all tokens:

| Token | Resolves to |
|-------|-------------|
| `{{SITE_NAME}}` | Site name from session brief header |
| `{{DATE}}` | Session date |
| `{{URL}}` | Target URL |
| `{{PLUGIN_VERSION}}` | Current plugin version from `.claude-plugin/plugin.json` |
| `{{FRAMEWORK}}` / `{{VERSION}}` | From infrastructure table |
| `{{CDN}}` | From infrastructure table |
| `{{AUTH}}` | From infrastructure table |
| `{{BOT_PROTECTION}}` | From infrastructure table |
| `{{HOSTING}}` | From infrastructure table |
| `{{TOOL_AVAILABILITY_BLOCK}}` | All `[AVAILABLE]` / `[TOOL-UNAVAILABLE:...]` signals from Phase 1 |
| `{{API_SURFACE_ROWS}}` | One table row per API surface from Discovered Endpoints, grouped by surface name |
| `{{API_SURFACE_FILE_ROWS}}` | One `\| [api-surfaces/{name}.md](...) \| {description} \|` row per surface file written in Phase 12 (omit row if none) |
| `{{KEY_FINDINGS}}` | 3–5 bullet points summarising the most important discoveries |
| `{{OPENAPI_STATUS}}` | See OPENAPI_STATUS Resolution below |
| `{{SITE_SLUG}}` | Slug form of site name |

## OPENAPI_STATUS Resolution

Inspect the session brief for Phase 11 signals and resolve the `{{OPENAPI_STATUS}}` token:

```
[PHASE-11-SKIPPED] present in session brief
  → {{OPENAPI_STATUS}} = "" (omit the row entirely — leave no blank line)

[OPENAPI-SKIPPED:har-to-openapi-unavailable] present in session brief
  → {{OPENAPI_STATUS}} = "| `.beacon/capture.har` | HAR capture (raw traffic — har-to-openapi unavailable) |"

Neither signal present (Phase 11 ran and produced a spec)
  → {{OPENAPI_STATUS}} = "| [specs/{site-slug}.openapi.yaml](specs/{site-slug}.openapi.yaml) | OpenAPI spec (observed traffic) |"
```

## Completion Checklist

After writing all files, confirm:

- [ ] `docs/research/{site-slug}/INDEX.md` — all tokens resolved, no `{{` remaining
- [ ] `docs/research/{site-slug}/tech-stack.md` — infrastructure table present
- [ ] `docs/research/{site-slug}/site-map.md` — URLs grouped by phase
- [ ] `docs/research/{site-slug}/constants.md` — populated sections only (no empty tables)
- [ ] `docs/research/{site-slug}/api-surfaces/` — at least one surface file (or `no-public-surfaces.md`)
- [ ] `docs/research/{site-slug}/specs/{site-slug}.openapi.yaml` — present if Phase 8 or 11 produced one, absent otherwise
- [ ] `docs/research/{site-slug}/scripts/test-{site-slug}.sh` — one `check()` call per endpoint
