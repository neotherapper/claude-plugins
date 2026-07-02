# Output Synthesis

Phase 12 reads the completed session brief and writes all research output files to disk.
No network calls. No new tools. Pure synthesis from what Phases 1–11 captured.

**Every markdown output file already exists.** `scaffold.sh` created `INDEX.md`, `tech-stack.md`,
`site-map.md`, and `constants.md` in Phase 1 with valid OKF frontmatter (`status: draft`). Phase 12
**edits these files in place**: resolve the body content/tokens described below and, only once
every file is fully resolved and `okf_validate.py` passes, flip each file's frontmatter `status:`
to `complete` (see "Flip to status: complete" near the end of this doc). Never re-render a file
from scratch from the **legacy** `templates/*.md.template` files (`templates/INDEX.md.template`,
`templates/tech-stack.md.template`, `templates/site-map.md.template`,
`templates/constants.md.template`, `templates/api-surface.md.template`) — those carry no
frontmatter, and overwriting a scaffolded file with one of them silently drops the frontmatter,
which fails `okf_validate.py` outright and (for `INDEX.md` specifically) permanently disarms the
`Stop`-hook completion gate. Those legacy templates are superseded for every markdown OKF concept.
`templates/smoke-test.sh.template` is the one exception — it produces a shell script, not an OKF
markdown concept, so it stays in use unchanged.

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

`tech-stack.md` already exists (scaffolded from `templates/okf/tech-stack.md`, `type: tech-stack`,
`status: draft`). Edit it in place: keep the frontmatter block, and replace the body (everything
below the closing `---`) with the Infrastructure table rows from the session brief verbatim, in
this format:

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

`site-map.md` already exists (scaffolded from `templates/okf/site-map.md`, `type: site-map`,
`status: draft`). Edit it in place: keep the frontmatter block, and replace the body with every
URL discovered, grouped by the phase that found it:

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

`constants.md` already exists (scaffolded from `templates/okf/constants.md`, `type: constants`,
`status: draft`). Edit it in place: keep the frontmatter block, and populate the body table rows
from the session brief (do not load the legacy `templates/constants.md.template` — it has no
frontmatter and would drop the scaffolded stub's frontmatter if rendered as the whole file).

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

Load `templates/smoke-test.sh.template` (a shell script, not an OKF markdown concept — unaffected
by the frontmatter-preservation rules above). Replace tokens:

| Token | Value |
|-------|-------|
| `{{SITE_SLUG}}` | Site slug (e.g. `example-com`) |
| `{{PLUGIN_VERSION}}` | Current plugin version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` |
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

Load `templates/okf/api-surface.md` (the OKF stub — **not** the legacy
`templates/api-surface.md.template`, which has no frontmatter) once per distinct API surface
discovered. These files are not pre-scaffolded by `scaffold.sh` (the surface count isn't known
until Phase 12): create each fresh with `status: draft`, then flip it to `complete` in the same
final pass as the other files (see "Flip to status: complete" below).

**What counts as a distinct surface:** A logically-related group of endpoints sharing a base path and auth mechanism (e.g., `/wp-json/wp/v2/*` = one surface, `/wp-json/wc/v3/*` = a separate surface). Single-endpoint discoveries can be grouped into a surface named for their type (e.g., `rest-api`, `graphql`, `ajax`).

**Surface naming:** lowercase, hyphenated. Examples: `wordpress-rest-api`, `woocommerce-api`, `graphql`, `ajax-endpoints`.

**Frontmatter enum fields — set from findings, do not leave the stub's defaults:**

| Field | Set to |
|-------|--------|
| `access_mode` | `open-api` / `bulk-download` / `scrape` / `gated` / `mixed` — per `references/okf-profile.md` |
| `auth` | `none` / `api-key` / `oauth` / `session` / `cac-pki` / `account` — the surface's real auth mechanism |
| `bot_protection` | The WAF identified for this surface (`references/okf-profile.md` enum), or `none` |
| `verification` | `live-verified` if this session hit it directly (curl or Phase 11), `wayback-verified` if only seen via Phase 9 OSINT, else `asserted-unverified` |

**Token replacement (remaining frontmatter + body):**

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

Replace the stub's minimal `## Endpoints` / `{{ENDPOINTS}}` body with the fuller section layout
these tokens imply (endpoint table, auth detail, rate limits, notes, example request/response) —
the same shape this doc has always described; only the frontmatter source (the OKF stub, not the
legacy template) has changed.

Write each surface file to: `docs/sites/{site-slug}/research/api-surfaces/{surface-name}.md`

If no distinct API surfaces were found (static site, all endpoints behind auth with no observable shape), write a single `api-surfaces/no-public-surfaces.md` — still based on `templates/okf/api-surface.md` so it carries valid frontmatter — noting that observation.

## Token Resolution — edit the scaffolded INDEX.md in place

`INDEX.md` already exists (scaffolded from `templates/okf/INDEX.md` in Phase 1, with valid OKF
frontmatter and `status: draft`). **Edit it in place** — keep the frontmatter block (`type:
site-index`, `tags`); `scaffold.sh` already resolved `{{SITE_NAME}}`, `{{URL}}`, and `{{TIMESTAMP}}`
at scaffold time, so only re-resolve `title`/`resource`/`timestamp` if a caller-supplied
`OUTPUT_ROOT` bypassed `scaffold.sh` entirely. Replace the body (everything below the closing
`---`) with the fully resolved sections below, resolving every token listed in the table —
including `{{FRAMEWORK}}`, which `scaffold.sh` leaves templated in the scaffolded body.

**Never** render `INDEX.md` fresh from `${CLAUDE_PLUGIN_ROOT}/templates/INDEX.md.template` — that
legacy template has no frontmatter, so writing it as the whole file would drop the frontmatter
Phase 1 wrote and permanently disarm the `Stop`-hook completion gate (it keys on `INDEX.md`'s
`status:` line).

Resolve all tokens:

| Token | Resolves to |
|-------|-------------|
| `{{SITE_NAME}}` | Site name from session brief header |
| `{{DATE}}` | Session date |
| `{{URL}}` | Target URL |
| `{{PLUGIN_VERSION}}` | Current plugin version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` |
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

## Flip to status: complete (final Phase 12 action)

Once every output file's body is fully resolved (no `{{TOKEN}}` left anywhere) and
`okf_validate.py "$OUTPUT_ROOT"` passes while every file is still `status: draft`, flip each
finished file's frontmatter `status:` field from `draft` to `complete`:

1. Flip `tech-stack.md`, `site-map.md`, `constants.md`, and every `api-surfaces/*.md` first.
2. Flip `INDEX.md` **last** — this is the final action of Phase 12. Write the line unquoted and
   lowercase: `status: complete` (no quotes, no trailing comment). The `Stop`-hook gate
   (`hooks/okf-gate.sh`) matches `^status:[[:space:]]*complete[[:space:]]*$` on `INDEX.md`; anything
   else (`status: "complete"`, `Status: Complete`, a trailing `# done` comment) will not match, and
   the gate stays a silent no-op forever.
3. Re-run `python3 "${CLAUDE_PLUGIN_ROOT}/skills/site-recon/scripts/okf_validate.py" "$OUTPUT_ROOT"`
   once more after the flip. Flipping to `status: complete` activates the validator's
   unfilled-token check on every file that just changed — this final run is what actually proves
   the bundle is complete, not just draft-valid. Fix any reported violation before ending the run;
   the `Stop` hook runs the identical check and will block otherwise.

## Completion Checklist

After writing all files, confirm:

- [ ] Every markdown file's OKF frontmatter block is intact (never overwritten from a legacy
      `templates/*.md.template`) — `type` present on every file, and the full access triad
      (`access_mode`, `auth`, `verification`) present on every `api-surface` file
- [ ] `docs/sites/{site-slug}/research/INDEX.md` — all tokens resolved, no `{{` remaining
- [ ] `docs/sites/{site-slug}/research/tech-stack.md` — infrastructure table present
- [ ] `docs/sites/{site-slug}/research/site-map.md` — URLs grouped by phase
- [ ] `docs/sites/{site-slug}/research/constants.md` — populated sections only (no empty tables)
- [ ] `docs/sites/{site-slug}/research/api-surfaces/` — at least one surface file (or `no-public-surfaces.md`)
- [ ] `docs/sites/{site-slug}/research/specs/{site-slug}.openapi.yaml` — present if Phase 8 or 11 produced one, absent otherwise
- [ ] `docs/sites/{site-slug}/research/scripts/test-{site-slug}.sh` — one `check()` call per endpoint
- [ ] Every finished file's `status:` flipped `draft → complete`, `INDEX.md` last, unquoted and lowercase
- [ ] `python3 "${CLAUDE_PLUGIN_ROOT}/skills/site-recon/scripts/okf_validate.py" "$OUTPUT_ROOT"` exits 0 after the flip
