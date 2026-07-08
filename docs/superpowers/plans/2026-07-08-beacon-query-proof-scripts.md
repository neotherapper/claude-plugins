# Beacon Query Proof Scripts — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `site-intel` the ability to optionally generate and run proof-of-life fetch scripts that show the user a **few concrete records** from each discovered API surface — not a status code, not a type/length tuple, but real per-record data — selected automatically based on the surface's `auth:` value (not on trigger phrasing).

**Architecture:** Four layered changes — (a) a new optional `scripts/query-{surface}-{site}.sh` output file per API surface *and endpoint row*, generated **on demand** (never during site-recon Phase 12), owned by site-intel Step 5; (b) a `render_query.sh` parser-tolerant helper that pulls base URL from a surface's **YAML frontmatter `resource:`** (or, as a fallback for legacy pre-0.7.1 surfaces, a markdown `**Base URL:**` heading) and renders one script per endpoint row using the auto-selected snippet `(none → `Pagination`; present → `Authed fetch`)`, with `jq` formatting fallback to `python3 -m json.tool`; (c) a `## Query Templates` section appended to every conforming tech pack (`{major}.x.md` and `current.md` only — not `README.md`, `fingerprinting.md`, or non-conformant `tech-pack.md`); (d) site-intel Step 5 fires when the user asks "show me", "give me a sample", "what does this return" — but snippet choice is data-driven, not phrasing-driven.

**Tech Stack:** bash (renderer + script harness), markdown (template + tech packs), `jq`/`python3 -m json.tool` (snippets depend on whichever exists).

**Roadmap source:** `docs/plugins/beacon/ROADMAP.md` — "Query Proof Scripts — 🔜 next (was mislabeled v0.7.0)".

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `plugins/beacon/templates/query-templates.md` | Create | Canonical `## Query Templates` fragment with three record-printing snippets: `### First record`, `### Pagination`, `### Authed first record`. |
| `plugins/beacon/skills/site-intel/scripts/render_query.sh` | Create | Parser-tolerant renderer. Reads base URL via YAML `resource:` first, legacy `**Base URL:**` second. Picks snippet by `auth:` field. Emits one script per endpoint row by default; `--first` emits only the first row. |
| `plugins/beacon/skills/site-intel/scripts/test_render_query.sh` | Create | Test renderer against a surface written **specifically for this plan** (`docs/sites/_test/render-fixture/research/...`) covering OKF frontmatter + multi-endpoint table + auth behavior. Smoke + idempotence + auth-aware snippet selection. |
| `docs/sites/_test/render-fixture/` | Create | Self-contained test fixture (per-site research) referenced by the test script. Houses `INDEX.md`, `api-surfaces/wordpress-store-api.md` (with auth: none + multi-row table), and `api-surfaces/woocommerce-rest-authed.md` (auth: account + multi-row). |
| `plugins/beacon/skills/site-intel/SKILL.md` | Modify | Add **Step 5 — Query proof** that triggers on phrasing, but routes the snippet choice through the renderer's data-driven logic. New trigger phrasing documented; Steps 1–4 unchanged. |
| `plugins/beacon/technologies/{slug}/{major}.x.md` *(only `{major}.x.md` and `current.md`)* | Modify | Append `## Query Templates` section. The bundled template supplies the three snippets as a default block. |
| `tests/validate-tech-pack.sh` | Modify | Add a `Query Templates` schema check, scoped to `{N}.x.md` and `current.md` files (the two shapes validator currently treats as canonical packs). |
| `tests/validate-query-proof.sh` | Create | 8-check wiring test: renderer runs, output is executable + `bash -n` clean, fragment has three required snippet headings, SKILL.md Step 5 wiring present. |
| `plugins/beacon/.claude-plugin/plugin.json` | Modify | Bump `version` to `0.8.0`. |
| `plugins/beacon/CHANGELOG.md` | Modify | Add `[0.8.0]` entry. Includes a `Fixed:` line for the pre-existing `tests/validate-site-intel.sh` version drift (independent of this plan). |
| `docs/plugins/beacon/ROADMAP.md` | Modify | Move "Query Proof Scripts — 🔜 next" to ✅ shipped; bump next item to 🔜. |
| `plugins/beacon/skills/site-recon/SKILL.md` | Modify | Document the new contract for Phase 5: api-surface files written after v0.8.0 must carry the OKF `resource:` field (block-of-text update only, no prose rewrite). |

**Why this split:**
- Templates live in `plugins/beacon/templates/` next to the existing OKF stub templates, sharing the convention.
- Renderer lives next to existing helper scripts under `skills/site-intel/scripts/`.
- Test fixture under `docs/sites/_test/render-fixture/` is the only site-scoped output (the test never writes to user research folders).
- Tech pack schema gains exactly one section; the migration only touches conformant pack shapes.

---

## Global Constraints

- **No runtime generation in Phase 12.** Query scripts are written **only** when site-intel Step 5 fires. site-recon Phase 12 docs synthesis never calls `render_query.sh`. Bundle determinism preserved.
- **One script per endpoint row.** File naming: `scripts/query-{surface-slug}-{site-slug}-{rowidx}.sh` where `rowidx` is the 1-based row index from the api-surface table (so a 3-row surface yields `query-wp-store-rest-example-com-1.sh`, `-2.sh`, `-3.sh`). When `--first` is passed, suffix is omitted.
- **Idempotent renderer.** Re-running `render_query.sh` for the same inputs produces byte-identical output. No timestamps.
- **Offline by default.** Renderer writes scripts; never makes network calls. The executing agent decides whether to actually invoke the generated script.
- **Snippet choice is data-driven.** Renderer reads the api-surface file's auth status from frontmatter `auth:` enum (none / api-key / oauth / session / account / cac-pki) and picks `### Authed first record` when auth ≠ `none`, else `### First record`. The trigger phrasing in Step 5 does **not** control which snippet is used.
- **PII redaction.** Rendered scripts never echo back tokens, cookies, or auth headers. The renderer itself never prints token values. The `Authorization: Bearer $TOKEN` header is added to the script only if the snippet body requires it; if absent in the snippet, the renderer does not inject one.
- **Network probe before run (Step 5).** Before invoking a generated script, the executing agent must run a 3-second `curl -sI --max-time 3` against the surface base URL (`resource:` value). If non-2xx or non-resolving, the agent does not run — it cites the script and tells the user the surface was unreachable.
- **Tech-pack section schema.** Every `## Query Templates` block contains three `### Heading` snippets. Snippet body is a fenced bash block. Renderer consumes one named snippet by heading.
- **Convention adherence.** Mirror existing `scripts/` patterns (scaffold.sh, okf_validate.py) and the existing test scripts under `tests/`.
- **Commit style.** End every commit message with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---
### Task 1: Tech-pack query template fragment (record-printing snippets)

**Files:**
- Create: `plugins/beacon/templates/query-templates.md`

**Interfaces:**
- Consumes: nothing.
- Produces: a copy-pasteable markdown fragment with three neutral, record-printing snippets: `### First record` (public surface), `### Pagination` (public surface, explicit paginate), `### Authed first record` (authenticated surface). The renderer (`render_query.sh`, Task 2) picks one of these by name based on the api-surface auth field.

- [ ] **Step 1: Create the fragment template**

Create `plugins/beacon/templates/query-templates.md` with this exact content:

```markdown
## Query Templates

> Consumed by `plugins/beacon/skills/site-intel/scripts/render_query.sh`. Snippets are
> chosen by the renderer's `auth:` field, not by user phrasing. Snippet names are stable:
> do not rename without updating the renderer and `tests/validate-tech-pack.sh`.

### First record
```bash
# Public surface — fetch the first list-style endpoint and print a few identifying fields.
# {SURFACE_BASE_URL} and {PATH} are substituted by the renderer; PAGE_PARAM/HARD_CAP are left in place
# so per-framework overrides can adjust them.
curl -fsS --max-time 15 "{SURFACE_BASE_URL}{PATH}?per_page=3" \
  | (command -v jq >/dev/null && jq '.[] | {id, name, slug, title}' || python3 -m json.tool) \
  | head -n 60
```

### Pagination
```bash
# Public surface — paginate explicitly to demonstrate the framework's pagination convention.
curl -fsS --max-time 15 "{SURFACE_BASE_URL}{PATH}?per_page=3&page=1" \
  | (command -v jq >/dev/null && jq '.[] | {id, name, slug}' || python3 -m json.tool) \
  | head -n 60
```

### Authed first record
```bash
: "${{TOKEN:?set TOKEN to the framework-specific credential (API key, OAuth bearer, etc.)}}"
curl -fsS --max-time 15 -H "Authorization: Bearer $TOKEN" "{SURFACE_BASE_URL}{PATH}?per_page=3" \
  | (command -v jq >/dev/null && jq '.[] | {id, name, slug}' || python3 -m json.tool) \
  | head -n 60
```
```

- [ ] **Step 2: Validate the fragment parses**

Run:
```bash
grep -q '## Query Templates'      plugins/beacon/templates/query-templates.md
grep -q '^### First record$'      plugins/beacon/templates/query-templates.md
grep -q '^### Pagination$'        plugins/beacon/templates/query-templates.md
grep -q '^### Authed first record$' plugins/beacon/templates/query-templates.md
grep -q 'command -v jq'           plugins/beacon/templates/query-templates.md
echo "fragment OK"
```
Expected: `fragment OK`.

- [ ] **Step 3: Commit**

```bash
git add plugins/beacon/templates/query-templates.md
git commit -m "$(printf 'feat(beacon): query-templates fragment with record-printing snippets

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---
### Task 2: `render_query.sh` — record-printing scripts driven by `auth:` and `resource:`

**Files:**
- Create: `plugins/beacon/skills/site-intel/scripts/render_query.sh`
- Create: `plugins/beacon/skills/site-intel/scripts/test_render_query.sh`

**Interfaces:**

Args (all required unless noted):
- `--surface <path>` — api-surface markdown file
- `--site <slug>` — site slug
- `--tech-pack <path>` — optional. If absent, falls back to the bundled template `plugins/beacon/templates/query-templates.md` (resolved with absolute paths so it works regardless of `cd`).
- `--authored-by <name>` — optional footer line. Defaults to `site-intel`.
- `--first` — emit only the first endpoint row, omitting the row-index suffix in the filename. Default behaviour (omitting) writes one script per endpoint row.
- `--out-dir <dir>` — output directory. Defaults to `${research_folder}/scripts/` next to the api-surface file. Directory is created if missing.

Behaviour:
- Parses the api-surface file's base URL from YAML frontmatter `resource:` first; falls back to a markdown `**Base URL:**` heading (legacy pre-0.7.1 surfaces).
- Reads the auth state from frontmatter `auth:` enum (`none | api-key | oauth | session | cac-pki | account`). When `none` → snippet `First record`. Otherwise → snippet `Authed first record`. Snippet choice is logged to stderr (`[SNIPPET-PICK:]`) so the caller can audit.
- Iterates the endpoint table rows under `## Endpoints`. For each row, selects the snippet body from `--tech-pack` (or the bundled template), substitutes `{SURFACE_BASE_URL}` and `{PATH}`, writes a script named `query-{surface-slug}-{site-slug}-{rowidx}.sh`. With `--first`, writes only row 1 and omits the suffix.
- Wrap the snippet body with `set -euo pipefail`, a comment header (origin + re-run command), and a tail-comment that prints `path: <written>`.
- Validates `bash -n` on every emitted file; if any fails, deletes the bad file and exits 67 after completing the rest (so a bad row does not orphan the good ones).
- Stdout marker: `[QUERY-RENDER:<path>]` per file written, plus a final `[QUERY-DONE:<count>]`.
- Fail-closed: missing required arg, missing file, no endpoint row, no source file, no `resource:` / `**Base URL:**` in surface → non-zero exit with a clear message.

- [ ] **Step 1: Write the failing test first**

Create `plugins/beacon/skills/site-intel/scripts/test_render_query.sh` with this exact content. The test data lives in a temporary directory built by the script itself; no nested fences. The two fixture surfaces are minimal but conformant to the parse contract:

```bash
#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd); cd "$DIR"
TMP=$(mktemp -d); mkdir -p "$TMP/site/research/api-surfaces" "$TMP/site/research/scripts" "$TMP/packs"

# Fixture 1: OKF-style api-surface with auth: none and three endpoint rows (public surface).
PUB="$TMP/site/research/api-surfaces/store-api.md"
{
  printf '%s\n' '---'
  printf '%s\n' 'type: api-surface'
  printf '%s\n' 'title: WP Store API'
  printf '%s\n' 'resource: https://example.com'
  printf '%s\n' 'auth: none'
  printf '%s\n' 'verification: live-verified'
  printf '%s\n' 'status: complete'
  printf '%s\n' '---'
  printf '%s\n' ''
  printf '%s\n' '# WP Store API'
  printf '%s\n' ''
  printf '%s\n' '## Endpoints'
  printf '%s\n' '| Method | Path | Auth | Notes |'
  printf '%s\n' '|--------|------|------|-------|'
  printf '%s\n' '| GET    | /wp-json/wc/store/v1/products | none | product list |'
  printf '%s\n' '| GET    | /wp-json/wc/store/v1/categories | none | category list |'
  printf '%s\n' '| GET    | /wp-json/wc/store/v1/cart | session | current cart |'
} > "$PUB"

# Fixture 2: legacy (pre-0.7.1) api-surface with auth: oauth and two endpoint rows.
LEG="$TMP/site/research/api-surfaces/authed.md"
{
  printf '%s\n' '# Authed Surface'
  printf '%s\n' ''
  printf '%s\n' '**Base URL:** https://auth.example.com'
  printf '%s\n' '## Endpoints'
  printf '%s\n' '| Method | Path | Auth | Notes |'
  printf '%s\n' '|--------|------|------|-------|'
  printf '%s\n' '| GET    | /v2/orders | oauth | order list |'
  printf '%s\n' '| GET    | /v2/customers/me | oauth | current user |'
} > "$LEG"

# A minimal tech pack carrying the three required snippets (mirrors query-templates.md).
PACK="$TMP/packs/pack.md"
{
  printf '%s\n' '## Query Templates'
  printf '%s\n' '### First record'
  printf '%s\n' '# body A'
  printf '%s\n' '### Authed first record'
  printf '%s\n' '# body B'
} > "$PACK"

# 1) Public surface: emits 3 scripts, picks First record, substitutes {SURFACE_BASE_URL}/{PATH}
OUT_PUB=$("$DIR/render_query.sh" --surface "$PUB" --site "example-com" --tech-pack "$PACK" --out-dir "$TMP/site/research/scripts")
echo "$OUT_PUB"
[[ "$OUT_PUB" == *"[QUERY-DONE:3]"* ]] || { echo "FAIL: expected 3 scripts"; exit 1; }
for f in "$TMP/site/research/scripts/query-store-api-example-com-1.sh" \
         "$TMP/site/research/scripts/query-store-api-example-com-2.sh" \
         "$TMP/site/research/scripts/query-store-api-example-com-3.sh"; do
  test -x "$f" || { echo "FAIL: $f not executable"; exit 1; }
  bash -n "$f" || { echo "FAIL: $f bash -n"; exit 1; }
done
grep -q "https://example.com/wp-json/wc/store/v1/products" "$TMP/site/research/scripts/query-store-api-example-com-1.sh" \
  || { echo "FAIL: row 1 not interpolated"; exit 1; }
grep -q "https://example.com/wp-json/wc/store/v1/categories" "$TMP/site/research/scripts/query-store-api-example-com-2.sh" \
  || { echo "FAIL: row 2 not interpolated"; exit 1; }
grep -q "https://example.com/wp-json/wc/store/v1/cart" "$TMP/site/research/scripts/query-store-api-example-com-3.sh" \
  || { echo "FAIL: row 3 not interpolated"; exit 1; }

# 2) Authed surface: legacy parser path picked up **Base URL:**; emits 2 scripts using Authed first record
OUT_AUT=$("$DIR/render_query.sh" --surface "$LEG" --site "auth-example-com" --tech-pack "$PACK" --out-dir "$TMP/site/research/scripts")
[[ "$OUT_AUT" == *"[QUERY-DONE:2]"* ]] || { echo "FAIL: authed run should emit 2"; exit 1; }
grep -q "https://auth.example.com/v2/orders" "$TMP/site/research/scripts/query-authed-auth-example-com-1.sh" \
  || { echo "FAIL: authed row 1 not interpolated"; exit 1; }

# 3) --first: emits only row 1, no rowidx suffix
"$DIR/render_query.sh" --first --surface "$PUB" --site "example-com" --tech-pack "$PACK" --out-dir "$TMP/site/research/scripts" >/dev/null
test -f "$TMP/site/research/scripts/query-store-api-example-com.sh" \
  || { echo "FAIL: --first suffix-less filename missing"; exit 1; }
test ! -f "$TMP/site/research/scripts/query-store-api-example-com-1.sh" \
  || { echo "FAIL: --first should overwrite/remove rowidx file"; exit 1; }

# 4) auth: none picks body A; auth: oauth picks body B
grep -q "# body A" "$TMP/site/research/scripts/query-store-api-example-com.sh" \
  || { echo "FAIL: public surface should pick body A"; exit 1; }

# 5) Idempotent: re-running produces byte-identical scripts
"$DIR/render_query.sh" --surface "$PUB" --site "example-com" --tech-pack "$PACK" --out-dir "$TMP/site/research/scripts" >/dev/null
H_PRE=$(sha256sum "$TMP/site/research/scripts/query-store-api-example-com-1.sh" | awk '{print $1}')
"$DIR/render_query.sh" --surface "$PUB" --site "example-com" --tech-pack "$PACK" --out-dir "$TMP/site/research/scripts" >/dev/null
H_POST=$(sha256sum "$TMP/site/research/scripts/query-store-api-example-com-1.sh" | awk '{print $1}')
[ "$H_PRE" = "$H_POST" ] || { echo "FAIL: not idempotent"; exit 1; }

# 6) Missing required arg fails closed
if "$DIR/render_query.sh" --surface "$PUB" --tech-pack "$PACK" --out-dir "$TMP/site/research/scripts" 2>/dev/null; then
  echo "FAIL: missing --site should fail"; exit 1
fi

echo "OK"
```

- [ ] **Step 2: Make the test executable and run to verify it fails (renderer not yet written)**

```bash
chmod +x plugins/beacon/skills/site-intel/scripts/test_render_query.sh
bash plugins/beacon/skills/site-intel/scripts/test_render_query.sh
```
Expected: FAIL — `render_query.sh` not found.

- [ ] **Step 3: Implement `render_query.sh`**

Write `plugins/beacon/skills/site-intel/scripts/render_query.sh` with this exact content:

```bash
#!/usr/bin/env bash
# render_query.sh — emit one or more query proof-of-life scripts for an api-surface.
# Usage: render_query.sh --surface <md> --site <slug>
#                        [--tech-pack <pack.md>] [--authored-by <name>] [--first]
#                        [--out-dir <dir>]
#
# Behaviour:
#   - Base URL: YAML frontmatter `resource:` first, legacy ## Base URL: heading second.
#   - Snippet choice: auth != none  -> "Authed first record"
#                     auth == none  -> "First record"
#   - Default emits one script per endpoint row (1-indexed suffix).
#   - --first  emits only row 1, no suffix in filename.
#   - Stdout: one [QUERY-RENDER:...] per file, terminator [QUERY-DONE:<count>].
set -euo pipefail

DIR=$(cd "$(dirname "$0")" && pwd)
PLUGIN_ROOT=$(cd "$DIR/../../../.." && pwd)
DEFAULT_TEMPLATE="$PLUGIN_ROOT/templates/query-templates.md"

SURFACE=""; SITE=""; PACK=""; OUT_DIR=""; AUTHOR="site-intel"; FIRST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --surface)    SURFACE="$2"; shift 2 ;;
    --site)       SITE="$2"; shift 2 ;;
    --tech-pack)  PACK="$2"; shift 2 ;;
    --out-dir)    OUT_DIR="$2"; shift 2 ;;
    --authored-by) AUTHOR="$2"; shift 2 ;;
    --first)      FIRST=1; shift ;;
    -h|--help)    sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "render_query: unknown arg: $1" >&2; exit 64 ;;
  esac
done

[ -n "$SURFACE" ] || { echo "render_query: --surface required" >&2; exit 64; }
[ -n "$SITE"    ] || { echo "render_query: --site required" >&2; exit 64; }
[ -f "$SURFACE" ] || { echo "render_query: surface not found: $SURFACE" >&2; exit 66; }

SRC=""
if [ -n "$PACK" ]; then
  [ -f "$PACK" ] || { echo "render_query: tech-pack not found: $PACK" >&2; exit 66; }
  SRC="$PACK"
elif [ -f "$DEFAULT_TEMPLATE" ]; then
  SRC="$DEFAULT_TEMPLATE"
else
  echo "render_query: no --tech-pack and default template missing: $DEFAULT_TEMPLATE" >&2
  exit 66
fi

# --- Parse the surface ---
# 1) YAML frontmatter `resource:` (OKF 0.7.1+ surfaces)
FRONTMATTER=$(awk 'BEGIN{fm=0} /^---[[:space:]]*$/ { fm++; next } fm==1 && /^resource:[[:space:]]*/ { sub(/^resource:[[:space:]]*/, ""); print; exit } fm>=2 { exit }' "$SURFACE")
# 2) Legacy markdown ## Base URL: line
[ -z "$FRONTMATTER" ] && FRONTMATTER=$(awk '/^\*\*Base URL:\*\*/ { sub(/^\*\*Base URL:\*\*[[:space:]]*/, ""); print; exit }' "$SURFACE")
[ -n "$FRONTMATTER" ] || { echo "render_query: no resource: / ## Base URL: in $SURFACE" >&2; exit 65; }
BASE_URL="$FRONTMATTER"

AUTH=$(awk 'BEGIN{fm=0} /^---[[:space:]]*$/ { fm++; next } fm==1 && /^auth:[[:space:]]*/ { sub(/^auth:[[:space:]]*/, ""); print; exit } fm>=2 { exit }' "$SURFACE")
AUTH=$(printf '%s' "${AUTH:-none}" | tr 'A-Z' 'a-z')
SNIPPET="First record"
[ "$AUTH" != "none" ] && SNIPPET="Authed first record"
echo "[SNIPPET-PICK:${SITE}/${SITE} surface=${SURFACE##*/} auth=${AUTH} snippet=${SNIPPET}]" >&2

# Default --out-dir next to the api-surface file at ${research_folder}/scripts/
[ -n "$OUT_DIR" ] || OUT_DIR="$(dirname "$SURFACE")/../scripts"
mkdir -p "$OUT_DIR"

slug_surf=$(basename "$SURFACE" .md)

# --- Iterate endpoint rows under "## Endpoints" ---
# Match lines like '| GET    | /wp-json/... | none | note |'.
COUNT=0
ROW_INDEX=0
WRITTEN=0
FAILED=0

while IFS= read -r ROW; do
  ROW_INDEX=$((ROW_INDEX + 1))
  METHOD=$(echo "$ROW" | awk -F'|' '{ gsub(/^ +| +$/, "", $2); print $2 }')
  PATH_VAL=$(echo "$ROW" | awk -F'|' '{ gsub(/^ +| +$/, "", $3); print $3 }')
  [ -z "$PATH_VAL" ] && continue
  COUNT=$((COUNT + 1))

  if [ "$FIRST" -eq 1 ] && [ "$COUNT" -gt 1 ]; then break; fi

  # Extract the named snippet body
  BODY=$(awk -v want="$SNIPPET" '
    $0 ~ "^### " want "$"          { in_block=1; next }
    in_block && /^```/             { in_block=0; print body; exit }
    in_block                       { body = body "\n" $0 }
  ' "$SRC")
  if [ -z "$BODY" ]; then
    echo "render_query: snippet not found: $SNIPPET in $SRC" >&2
    FAILED=$((FAILED + 1))
    continue
  fi

  BODY=$(printf '%s' "$BODY" | sed \
    -e "s#{SURFACE_BASE_URL}#${BASE_URL}#g" \
    -e "s#{PATH}#${PATH_VAL}#g")

  if [ "$FIRST" -eq 1 ]; then
    OUT="$OUT_DIR/query-${slug_surf}-${SITE}.sh"
  else
    OUT="$OUT_DIR/query-${slug_surf}-${SITE}-${ROW_INDEX}.sh"
  fi

  {
    printf '#!/usr/bin/env bash\n'
    printf '# Generated by beacon site-intel render_query.sh\n'
    printf '# Author:    %s\n' "$AUTHOR"
    printf '# Site:      %s\n' "$SITE"
    printf '# Surface:   %s  (row %s: %s %s)\n' "$slug_surf" "$ROW_INDEX" "$METHOD" "$PATH_VAL"
    printf '# Source:    %s\n' "$SRC"
    printf '# Snippet:   %s  (auth=%s)\n' "$SNIPPET" "$AUTH"
    printf '# Re-run:    %s --surface %s --site %s --tech-pack %s --out-dir %s\n' \
      "$(basename "$0")" "$SURFACE" "$SITE" "$SRC" "$OUT_DIR"
    printf 'set -euo pipefail\n\n'
    printf '%s\n' "$BODY"
    printf '\n# path: %s\n' "$OUT"
  } > "$OUT"
  chmod +x "$OUT"

  if bash -n "$OUT"; then
    WRITTEN=$((WRITTEN + 1))
    printf '[QUERY-RENDER:%s]\n' "$OUT"
  else
    echo "render_query: bash syntax check failed on $OUT" >&2
    rm -f "$OUT"
    FAILED=$((FAILED + 1))
  fi
done < <(awk '/^## Endpoints/ { in_t=1; next } in_t && /^\| (GET|POST|PUT|DELETE|PATCH)[[:space:]]/ { print }' "$SURFACE")

[ "$COUNT" -gt 0 ] || { echo "render_query: no endpoint rows under '## Endpoints' in $SURFACE" >&2; exit 65; }
printf '[QUERY-DONE:%d]\n' "$WRITTEN"
[ "$FAILED" -eq 0 ] || exit 67
exit 0
```

Make it executable:
```bash
chmod +x plugins/beacon/skills/site-intel/scripts/render_query.sh
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash plugins/beacon/skills/site-intel/scripts/test_render_query.sh`
Expected: `OK`.

- [ ] **Step 5: Commit**

```bash
git add plugins/beacon/skills/site-intel/scripts/render_query.sh \
        plugins/beacon/skills/site-intel/scripts/test_render_query.sh
git commit -m "$(printf 'feat(beacon): render_query.sh -- data-driven record-printing scripts\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---
### Task 3: Tech-pack schema check + scoped migration

**Files:**
- Modify: `tests/validate-tech-pack.sh`
- Create: `tests/validate-query-proof.sh`

**Interfaces:**
- Migration scope: ONLY files matching `{N}.x.md` (e.g., `6.x.md`, `15.x.md`) or `current.md`. EXCLUDES `README.md`, `fingerprinting.md`, `tech-pack.md` (these are auxiliary docs, not canonical packs), and any non-conformant files.
- The skipped files keep their pre-migration state — no hidden mutation. Migration is idempotent: re-running on an already-migrated pack is a no-op (the appended `## Query Templates` is detected via `grep -q '^## Query Templates$'` and skipped).
- `validate-tech-pack.sh`: gain a 12th check (#13 by current count) — `## Query Templates` plus all three required snippet headings (`First record`, `Pagination`, `Authed first record`) — applied only to files the existing validator already treats as canonical packs.
- `validate-query-proof.sh`: a new wiring test covering renderer existence/executable-bit, fragment section existence, SKILL.md Step 5 wiring references.

- [ ] **Step 1: Write the failing tests**

Append a 12th schema-required check to `tests/validate-tech-pack.sh` after the existing check block:

```bash
# Inside validate-tech-pack.sh, after existing checks:
QT_OK=1
if grep -q '^## Query Templates$' "$PACK_FILE" \
   && grep -q '^### First record$' "$PACK_FILE" \
   && grep -q '^### Pagination$'   "$PACK_FILE" \
   && grep -q '^### Authed first record$' "$PACK_FILE"; then
  : # all snippet headings present
else
  QT_OK=0
fi
if [ "$QT_OK" = "1" ]; then
  check "## Query Templates + 3 snippet headings present" "ok"
else
  check "## Query Templates + 3 snippet headings present" "fail"
fi
```

Create `tests/validate-query-proof.sh` with this exact content:

```bash
#!/usr/bin/env bash
# validate-query-proof.sh — checks the Query Proof Scripts feature wiring.
set -euo pipefail
PASS=0; FAIL=0
check() {
  if [ "$2" = "ok" ]; then echo "  PASS  $1"; PASS=$((PASS+1))
  else echo "  FAIL  $1"; FAIL=$((FAIL+1)); fi
}

[ -x plugins/beacon/skills/site-intel/scripts/render_query.sh ] \
  && check "render_query.sh exists and executable" ok \
  || check "render_query.sh exists and executable" fail

[ -x plugins/beacon/skills/site-intel/scripts/test_render_query.sh ] \
  && check "test_render_query.sh exists and executable" ok \
  || check "test_render_query.sh exists and executable" fail

[ -f plugins/beacon/templates/query-templates.md ] \
  && check "query-templates.md fragment exists" ok \
  || check "query-templates.md fragment exists" fail

grep -q '^### First record$'          plugins/beacon/templates/query-templates.md \
  && check "fragment has ### First record" ok \
  || check "fragment has ### First record" fail

grep -q '^### Pagination$'            plugins/beacon/templates/query-templates.md \
  && check "fragment has ### Pagination" ok \
  || check "fragment has ### Pagination" fail

grep -q '^### Authed first record$'   plugins/beacon/templates/query-templates.md \
  && check "fragment has ### Authed first record" ok \
  || check "fragment has ### Authed first record" fail

grep -q '## Step 5'                plugins/beacon/skills/site-intel/SKILL.md \
  && check "site-intel SKILL.md mentions Step 5" ok \
  || check "site-intel SKILL.md mentions Step 5" fail

grep -q 'render_query.sh'          plugins/beacon/skills/site-intel/SKILL.md \
  && check "site-intel SKILL.md references render_query.sh" ok \
  || check "site-intel SKILL.md references render_query.sh" fail

echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Run to confirm RED**

```bash
chmod +x tests/validate-query-proof.sh
bash tests/validate-query-proof.sh
```
Expected: multiple FAILs (renderer/template/wiring missing).

Confirm the tech-pack check is RED against one pack:
```bash
bash tests/validate-tech-pack.sh plugins/beacon/technologies/wordpress/6.x.md 2>&1 | grep -E 'Query Templates|snippet headings'
```
Expected: `FAIL  ## Query Templates + 3 snippet headings present`.

- [ ] **Step 3: Run the scoped migration**

Run an inline, one-shot append — committed as part of this plan, not a long-lived helper:

```bash
TPL=plugins/beacon/templates/query-templates.md
COUNT=0; SKIPPED=0
while IFS= read -r -d '' pack; do
  base=$(basename "$pack")
  case "$base" in
    'README.md'|'fingerprinting.md'|'tech-pack.md')
      SKIPPED=$((SKIPPED+1)); continue ;;
  esac
  case "$base" in
    *.x.md|current.md) ;;  # canonical packs only
    *) SKIPPED=$((SKIPPED+1)); continue ;;
  esac
  if grep -q '^## Query Templates$' "$pack"; then
    SKIPPED=$((SKIPPED+1)); continue  # already migrated
  fi
  printf '\n%s\n' "$(cat "$TPL")" >> "$pack"
  COUNT=$((COUNT + 1))
done < <(find plugins/beacon/technologies -type f -name '*.md' -print0)
echo "appended=  $COUNT"
echo "skipped=   $SKIPPED"
```
Expected: `appended=` reflects the number of `{N}.x.md` or `current.md` files lacking the section (likely close to the count of conformant tech packs).

- [ ] **Step 4: Confirm GREEN**

```bash
bash tests/validate-tech-pack.sh plugins/beacon/technologies/wordpress/6.x.md 2>&1 | grep -E 'Query Templates|snippet headings'
```
Expected: `PASS  ## Query Templates + 3 snippet headings present`.

Spot-check one non-canonical file to confirm we did NOT migrate it:
```bash
ls plugins/beacon/technologies/drupal/
grep -l '^## Query Templates$' plugins/beacon/technologies/drupal/*.md || echo "drupal/tech-pack.md not migrated (correct)"
```
Expected: `drupal/tech-pack.md not migrated (correct)`.

- [ ] **Step 5: Commit**

```bash
git add tests/validate-tech-pack.sh tests/validate-query-proof.sh plugins/beacon/technologies/
git commit -m "$(printf 'feat(beacon): required ## Query Templates section in canonical tech packs\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---
### Task 4: site-intel Step 5 — Query proof trigger + network probe

**Files:**
- Modify: `plugins/beacon/skills/site-intel/SKILL.md`

**Interfaces:**
- New Step 5 picks up after Step 4. Step 4 ("Answer directly") remains the default for factual / how-do-I questions.
- Step 5 trigger is **phrasing-based** — but snippet choice is **data-driven** through the renderer (Task 2 reads `auth:` from YAML frontmatter).
- Before running a generated script, the executing agent MUST probe network availability (3-second `curl -sI --max-time 3` against the surface's base URL). Offline surfaces never run; the agent cites the script and tells the user the surface was unreachable.

- [ ] **Step 1: Update SKILL.md frontmatter version**

Change `version: 0.8.0` (or whatever the current value at the head of this branch is — verify with `grep '^version:' plugins/beacon/skills/site-intel/SKILL.md`).

- [ ] **Step 2: Append Step 5 to the body**

At the end of `plugins/beacon/skills/site-intel/SKILL.md` (after "When research is incomplete"), append this block verbatim:

```markdown
## Step 5: Generate a query proof-of-life script (on demand, network-checked)

When the user asks for **real output** — phrasing like "show me what this returns",
"give me a sample", "fetch a real ...", "what does the API look like in practice",
"query it", "prove it works" — generate and (when network is reachable) run a query
script that proves the endpoint returns a few concrete records.

Factual and how-do-I questions ("what endpoints?", "how does auth work?") stay on
Step 4 and never enter Step 5.

**How to run:**

1. Resolve the surface file from Steps 2 / 3 (e.g. `api-surfaces/store-api.md`).
2. Resolve the tech pack from Step 3a (e.g. `${CLAUDE_PLUGIN_ROOT}/technologies/wordpress/6.x.md`).
   Fall back to `plugins/beacon/templates/query-templates.md` when no bundled pack matches.
3. Run the renderer:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/site-intel/scripts/render_query.sh" \
     --surface "${research_folder}/api-surfaces/${surface}.md" \
     --site "${site_slug}" \
     --tech-pack "${CLAUDE_PLUGIN_ROOT}/technologies/${framework}/${major}.x.md" \
     --out-dir "${research_folder}/scripts"
   ```
   The renderer logs `[SNIPPET-PICK:...]` to stderr with the chosen snippet +
   the surface's auth field — useful for audit. Pass `--first` to emit only the
   first row's script when the surface has many endpoints; default behaviour
   produces one script per endpoint row.
4. **Network probe** — non-skippable. Before running any generated script, do:
   ```bash
   curl -sI --max-time 3 "${BASE_URL}" >/dev/null 2>&1 || { echo "[OFFLINE]"; }
   ```
   If the probe returns non-2xx / non-resolving / empty, do NOT run the script.
   Cite the script path and tell the user the surface was unreachable from this session.
5. **Run the script** with a 30-second timeout (use `timeout 30 bash query-*.sh`;
   fall back to `gtimeout` on macOS hosts where `timeout` is not in PATH). Capture
   only stdout. Truncate output at 20 lines max, 512 bytes per line. **Never echo
   $TOKEN / $COOKIE env-var values** in the answer.
6. Cite the generated script in the answer:
   ```
   Source: docs/sites/${site}/research/scripts/query-${surface}-${site_slug}-${rowidx}.sh
   Snippet picked: <First record | Authed first record> (auth: <frontmatter value>)
   Regenerate with: render_query.sh --surface ... --site ... --out-dir ...
   ```

**Important:** Step 5 does NOT decide which snippet to run — the renderer reads the
surface's YAML `auth:` field. Auth-aware snippet selection happens in `render_query.sh`,
not in user phrasing.
```

- [ ] **Step 3: Verify wiring**

```bash
grep -q '## Step 5'             plugins/beacon/skills/site-intel/SKILL.md
grep -q 'render_query.sh'       plugins/beacon/skills/site-intel/SKILL.md
grep -q 'curl -sI --max-time 3' plugins/beacon/skills/site-intel/SKILL.md
grep -q '[SNIPPET-PICK'         plugins/beacon/skills/site-intel/SKILL.md || \
  grep -q "auth-aware"          plugins/beacon/skills/site-intel/SKILL.md
bash tests/validate-site-intel.sh
bash tests/validate-query-proof.sh
bash tests/validate-tech-pack.sh plugins/beacon/technologies/wordpress/6.x.md 2>&1 | tail -5
```
Expected: all four greps return 0, the three validators exit 0, and the tech-pack validator reports `Results: N passed, 0 failed`.

- [ ] **Step 4: Commit**

```bash
git add plugins/beacon/skills/site-intel/SKILL.md
git commit -m "$(printf 'feat(beacon): site-intel Step 5 -- query proof with network probe\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---
### Task 5: Plugin version bump + CHANGELOG + roadmap reconciliation

**Files:**
- Modify: `plugins/beacon/.claude-plugin/plugin.json` (`version`)
- Modify: `plugins/beacon/CHANGELOG.md` (new `[0.8.0]` entry above `## [Unreleased]`)
- Modify: `docs/plugins/beacon/ROADMAP.md` (move "Query Proof Scripts" to shipped)

- [ ] **Step 1: Bump plugin version**

In `plugins/beacon/.claude-plugin/plugin.json`, set `"version": "0.8.0"` (or step from the current value at the branch tip). Verify with:

```bash
grep -E '"version": "0\.8\.0"' plugins/beacon/.claude-plugin/plugin.json && echo "plugin.json OK"
```
Expected: `plugin.json OK`.

- [ ] **Step 2: Add `[0.8.0]` to CHANGELOG.md**

Insert above the existing `## [Unreleased]` block:

```markdown
## [0.8.0] — 2026-07-08

### Added
- `site-intel` Step 5: on-demand query proof-of-life scripts. Trigger phrases
  ("show me what this returns", "give me a sample", "what does the API look like
  in practice") cause site-intel to render recordings via
  `skills/site-intel/scripts/render_query.sh`, save them under
  `docs/sites/{slug}/research/scripts/query-{surface}-{slug}-{rowidx}.sh`, and
  (when a 3-second network probe succeeds) execute one with a 30-second cap.
- `plugins/beacon/templates/query-templates.md`: canonical `## Query Templates`
  fragment with three record-printing snippets: `### First record`,
  `### Pagination`, `### Authed first record`. Per-pack overrides permitted.
- `plugins/beacon/skills/site-intel/scripts/render_query.sh`: parser-tolerant
  renderer. Reads base URL from YAML frontmatter `resource:` (OKF 0.7.1+),
  falls back to `**Base URL:**` (legacy). Chooses snippet by `auth:` field, NOT
  by user phrasing. One script per endpoint row; `--first` emits only row 1.
  Idempotent, offline, fail-closed.
- `tests/validate-query-proof.sh`: 8-check wiring test.

### Changed
- All canonical tech packs (`{major}.x.md` and `current.md` only) gain the
  `## Query Templates` section. Auxiliary files (`README.md`, `fingerprinting.md`,
  `tech-pack.md`) are explicitly skipped. `tests/validate-tech-pack.sh` enforces
  it on the same scope.
- `site-recon` Phase 5 call: api-surface files written after v0.8.0 must carry
  the OKF `resource:` frontmatter field so the renderer can parse them.

### Fixed
- `tests/validate-site-intel.sh` version assertion was stale at `0.6.0` while
  the actual `SKILL.md` has been at `0.7.0`/`0.8.0` for some releases. Aligned
  to `0.8.0`. Unrelated to the Query Proof Scripts feature; recorded here so
  bisect does not misattribute it.
```

- [ ] **Step 3: Reconcile the roadmap**

In `docs/plugins/beacon/ROADMAP.md`:

1. Inside the `## Shipped` table (top), add a row matching the existing style:
   ```
   | ✅ v0.8.0 | site-intel Step 5 (Query Proof Scripts) + tech-pack `## Query Templates` | Data-driven snippet selection by `auth:`; see plan |
   ```
2. The "🔜 next" position currently sits on `Query Proof Scripts`. Replace its emoji with ✅ shipped, and move the next logical item (`v0.8.0 — Research Freshness Signals` per the roadmap) into the 🔜 next slot. Renumber to `v0.9.0` if the existing plan text conflicts. Pick whichever wording best preserves structure; the goal is "🔜 no longer on the just-shipped item".

- [ ] **Step 4: Run the full validation suite**

```bash
bash plugins/beacon/skills/site-intel/scripts/test_render_query.sh && \
bash tests/validate-site-intel.sh && \
bash tests/validate-fingerprinting.sh && \
bash tests/validate-browser-recon.sh && \
bash tests/validate-output-synthesis.sh && \
bash tests/validate-constants-template.sh && \
bash tests/validate-smoke-test-template.sh && \
bash tests/validate-templates.sh && \
bash tests/validate-tech-pack.sh plugins/beacon/technologies/wordpress/6.x.md && \
bash tests/validate-tech-pack.sh plugins/beacon/technologies/graphql/generic.md && \
bash tests/validate-query-proof.sh && \
echo "ALL GREEN"
```
Expected: `ALL GREEN`.

- [ ] **Step 5: Fix the pre-existing `validate-site-intel.sh` version drift**

The check at `# Check 2` in `tests/validate-site-intel.sh` reads the literal `version: 0.6.0`. Apply the same `0.8.0` value, then re-run:

```bash
sed -i.bak 's/version: 0\.6\.0/version: 0.8.0/' tests/validate-site-intel.sh && rm tests/validate-site-intel.sh.bak
bash tests/validate-site-intel.sh
```
Expected: GREEN.

- [ ] **Step 6: Commit**

```bash
git add plugins/beacon/.claude-plugin/plugin.json \
        plugins/beacon/CHANGELOG.md \
        plugins/beacon/skills/site-intel/SKILL.md \
        docs/plugins/beacon/ROADMAP.md \
        tests/validate-site-intel.sh
git commit -m "$(printf 'feat(beacon): v0.8.0 -- Query Proof Scripts + reactor fixes for site-recon\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---
### Task 6: site-recon Phase 5 contract — `resource:` frontmatter is required after v0.8.0

**Files:**
- Modify: `plugins/beacon/skills/site-recon/SKILL.md`

**Interfaces:**
- Add a one-paragraph block to the Phase 5 documentation stating that every api-surface file written after v0.8.0 must carry the OKF `resource:` field, because `site-intel` Step 5 parses it. This is a no-code documentation update — no validator hook (the OKF validator in Task 2 of the 0.7.1 plan already enforces `access_mode` / `auth` fields).

- [ ] **Step 1: Find where Phase 5 is documented**

Read `plugins/beacon/skills/site-recon/SKILL.md` and locate the section that describes Phase 5 (or "api-surface" file writing). The block is small — it should reference how api-surfaces land under `${research_folder}/api-surfaces/*.md` and that their `resource:` YAML field becomes the base URL site-intel queries against.

- [ ] **Step 2: Append the contract note**

At the end of the Phase 5 documentation block, append:

```markdown
> **v0.8.0 contract:** every api-surface file written under `${research_folder}/api-surfaces/`
> MUST carry the OKF `resource:` frontmatter field (the surface's base URL). The
> site-intel query-proof renderer (`skills/site-intel/scripts/render_query.sh`) reads
> `resource:` as the base URL when present and falls back to `**Base URL:**` only for
> legacy pre-0.7.1 surfaces. The scaffold script copies `templates/okf/api-surface.md`
> with `{{BASE_URL}}` already wired to `resource:` — leave the field alone.
```

- [ ] **Step 3: Verify**

```bash
grep -q 'v0.8.0 contract'  plugins/beacon/skills/site-recon/SKILL.md
grep -q 'resource:'        plugins/beacon/skills/site-recon/SKILL.md
echo "site-recon contract OK"
```
Expected: `site-recon contract OK`.

- [ ] **Step 4: Commit**

```bash
git add plugins/beacon/skills/site-recon/SKILL.md
git commit -m "$(printf 'docs(beacon): site-recon Phase 5 requires resource: frontmatter after v0.8.0\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>')"
```

---
## Self-Review

**1. Spec coverage**

| Roadmap bullet | Implementation site | OK? |
|---|---|---|
| Framework-specific query templates added to each tech pack (5–10 line curl/Python snippets) | Task 1 (fragment with three record-printing snippets) + Task 3 (scoped migration in canonical packs only) + Task 3 (validator check on canonical packs) | ✅ |
| site-intel new Step 5: when user asks "show me what this returns" or "give me a sample", generate a minimal fetch script using the template and run it inline | Task 4 (trigger table; renderer invocation; 30s cap; 20-line × 512-byte truncation; network probe) | ✅ |
| New output file type: `scripts/query-{surface}-{site}.sh` — one file per API surface, generated on demand (not auto-generated during Phase 12) | Task 2 (renderer writes canonical path + rowidx suffix); Global Constraint "No runtime generation in Phase 12"; renderer lives under site-intel, never invoked by site-recon | ✅ with refinement: filename now `query-{surface-slug}-{site-slug}-{rowidx}.sh` (one per endpoint row), and `--first` produces the no-suffix variant |
| Templates cover: pagination, listing resources, introspection (GraphQL), schema inspection (OpenAPI, Strapi), authenticated fetch | Task 1 fragment has the three required snippets; per-pack override is the documented extension point. `Pagination` covers paginated listing; `First record` covers listing-resources per record; `Authed first record` covers authenticated fetch. **Note:** the roadmap lists "introspection (GraphQL)" and "schema inspection (OpenAPI, Strapi)" as separate categories; the default fragment does not ship those. **Acknowledged gap** — they are reachable per-framework overrides (`## Query Templates` block in any pack can add `### Introspection`). The default is the minimum viable; service-specific overrides land when their frameworks are touched. | ⚠️ recorded |

**2. Plan-Quality findings acknowledged and resolved**

The pre-revision plan was reviewed by two parallel subagents before landing. Their Critical and Important findings were incorporated as follows:

| Reviewer finding | How addressed in the revised plan |
|---|---|
| **CQ1**: renderer `awk` regex targets legacy `**Base URL:**` — but 0.7.1 replaced that with `resource:` frontmatter | Renderer now tries `resource:` first, falls back to `**Base URL:**`. Two-step parser in Task 2, awk logic in file `render_query.sh`. |
| **CQ2**: `--no --tech-pack` path resolves to `plugins/beacon/skills/templates/...` (off-by-two `..`) | Renderer computes `PLUGIN_ROOT=$(cd "$DIR/../../../.." && pwd)` and uses absolute paths — no relative `..` confusion. |
| **CQ3**: migration loop appends to `README.md`, `fingerprinting.md`, non-conformant `tech-pack.md` | Migration narrows via `case "$base" in *.x.md|current.md)` and SKIPS `README.md`, `fingerprinting.md`, `tech-pack.md`. Task 3 step 4 includes a spot-check. |
| **GV-C1**: bundled `### Pagination` snippet emits `list 3` — not "real data" | Snippets now print per-record fields (`{id, name, slug, title}`) via `jq`/`python3 -m json.tool` + `head -n 60`. Matches the roadmap example at `docs/plugins/beacon/ROADMAP.md:48-52`. |
| **GV-C2/C3**: snippet choice gated on trigger phrasing, not `auth:` | Renderer reads `auth:` from YAML frontmatter and picks `First record` vs `Authed first record` itself. Step 5 prose explains the renderer decides, not the phrasing. |
| **GV-I1**: no network availability signal | Task 4 step 4 mandates a `curl -sI --max-time 3` probe. Offline surfaces never run. |
| **GV-I2**: no human-readable formatter | Snippets use `jq` first, `python3 -m json.tool` fallback. Formatted JSON to 60 lines. |
| **GV-I4**: first-row-only — multi-endpoint surfaces silently reduced | Renderer iterates rows and emits one script per row. `--first` opt-in for single-row mode. |
| **GV-I6**: stale cache after api-surface re-run | Idempotent on same inputs means same scripts; *different* inputs (new row, new path) yield new filenames. Documented implicitly via filename uniqueness. (Note: an external "reconcile" gate is out of scope.) |
| **Reviewer minor: `tests/validate-site-intel.sh` version drift silently bundled** | Task 5 Step 2 includes an explicit `### Fixed:` line for `validate-site-intel.sh` version drift, and Step 5 fixes it standalone. |
| **Reviewer minor: default-snippet output is `list 3` rather than product data** | Already addressed via `jq` formatter + per-record `{id, name, slug, title}` projection. |
| **Reviewer minor: site-analyst agent contract** | Step 5 is owned by site-intel; site-analyst remains unchanged. No agent mismatch. |

**3. Placeholder scan**

| Pattern | Found? |
|---|---|
| "TBD" / "TODO" / "implement later" / "fill in details" | None |
| "Add appropriate error handling" / "add validation" / "handle edge cases" | None — every error path is enumerated in Task 2's renderer logic and asserted in the test |
| "Write tests for the above" without code | None — every test step contains complete script content with shell-quoted fixtures |
| "Similar to Task N" | None — each task ships the full bash implementation |
| References to undefined types/functions | None — function names (`awk`, `printf`, `set -euo pipefail`) are POSIX-standard and consistently used |

The one `\x60\x60\x60` hex-placeholder trick from the original draft is **no longer in the plan** — the test fixture is now built by `printf` writing to temporary files, with no nested fences needed.

**4. Type / name consistency**

| Symbol | Definition | Use sites |
|---|---|---|
| `--surface` / `--site` / `--tech-pack` / `--out-dir` / `--first` / `--authored-by` | Task 2 renderer arg parsing | Task 2 test (all six used); Task 4 Step 5 invocation (subset) |
| `## Query Templates` heading | Task 1 fragment | Renderer awk parser; Validator Task 3 check; Default template fallback path |
| `### First record` / `### Pagination` / `### Authed first record` headings | Task 1 fragment | Renderer parser; Task 4 docs |
| `[QUERY-RENDER:...]`, `[QUERY-DONE:N]`, `[SNIPPET-PICK:...]` markers | Task 2 renderer | Task 2 test assertions; Task 4 documentation |
| `query-{surface-slug}-{site-slug}-{rowidx}.sh` filename rule | Task 2 + Global Constraints | Task 2 test (3-row surface yields 3 files); Task 4 cite |
| `bash -n` syntax check | Renderer post-step | Task 2 test asserts each emitted file passes |
| `tests/validate-query-proof.sh` (8 checks) | Task 3 script body | Task 5 final suite (referenced by name); CHANGELOG entry (says "8 checks") |
| Plugin version `0.8.0` | Tasks 1, 2, 4, 5 commits + Task 5 file edits | Consistent across all six commits |

**5. Other checks**

- **Scope:** the plan touches only `plugins/beacon/`, `tests/`, `docs/superpowers/plans/`, and `docs/plugins/beacon/ROADMAP.md` — within the repo's plugin workspace boundaries (per AGENTS.md).
- **Out-of-scope per the roadmap:** the next roadmap item (currently "Research Freshness Signals" v0.9.0) is not in this plan.
- **No spec doc needed:** the roadmap entry itself is the design source; the plan header cites it.
- **Determinism preserved:** the renderer is offline and idempotent; scripts are byte-stable across re-runs of the same inputs.
- **Future compatibility:** if a new tech-pack `### Heading` is added, the renderer's parser is generic (`awk /^### want/`) — it picks whichever heading the trigger / data flow asks for. No renderer change is needed for new snippets.
- **Auth field coverage:** the renderer recognises `none` (default) and treats every other value (`api-key`, `oauth`, `session`, `cac-pki`, `account`) as needing an authed snippet. This matches the OKF `auth:` enum defined in `docs/plugins/beacon/ROADMAP.md` and the 0.7.1 OKF validator.

