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

# Fixture 2: legacy (pre-0.7.1) style api-surface WITH minimal frontmatter so the
# renderer can read auth=. Real pre-0.7.1 surfaces had no frontmatter at all (and
# the renderer then defaults auth=none); this fixture adds the auth header on top
# of the legacy ## Base URL: layout to exercise the auth-driven snippet path too.
LEG="$TMP/site/research/api-surfaces/authed.md"
{
  printf '%s\n' '---'
  printf '%s\n' 'auth: oauth'
  printf '%s\n' '---'
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
  printf '%s\n' '```bash'
  printf '%s\n' '# public surface snippet'
  printf '%s\n' 'curl -fsS "{SURFACE_BASE_URL}{PATH}?per_page=3" | jq ".[]"'
  printf '%s\n' '```'
  printf '%s\n' '### Authed first record'
  printf '%s\n' '```bash'
  printf '%s\n' '# authed surface snippet'
  printf '%s\n' 'curl -fsS -H "Authorization: Bearer $TOKEN" "{SURFACE_BASE_URL}{PATH}?per_page=3" | jq ".[]"'
  printf '%s\n' '```'
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
grep -q "# public surface snippet" "$TMP/site/research/scripts/query-store-api-example-com.sh" \
  || { echo "FAIL: public surface should pick public snippet"; exit 1; }

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
