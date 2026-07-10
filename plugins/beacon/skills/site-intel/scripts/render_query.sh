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
# Renderer lives at <CLAUDE_PLUGINS>/plugins/beacon/skills/site-intel/scripts/.
# Default template lives at <CLAUDE_PLUGINS>/plugins/beacon/templates/query-templates.md.
# Steps up from $DIR:
#   ../       = site-intel/   ../..   = skills/    ../../../ = beacon/    ../../../../ = plugins/    (5 levels up = repo root)
PLUGIN_ROOT=$(cd "$DIR/../../../../.." && pwd)
DEFAULT_TEMPLATE="$PLUGIN_ROOT/plugins/beacon/templates/query-templates.md"

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

# Strip one surrounding matching pair of single or double quotes from a YAML
# scalar value, e.g. `"https://example.com"` -> `https://example.com`,
# `'none'` -> `none`. Already-unquoted values (`none`) pass through unchanged.
# The canonical OKF template quotes `resource:` (plugins/beacon/templates/okf/
# api-surface.md:4, `resource: "{{BASE_URL}}"`), and agent-authored surfaces
# routinely quote `auth:` too, so both extractions need this normalization.
strip_quotes() {
  local s=$1
  if [ "${#s}" -ge 2 ]; then
    case "$s" in
      \"*\") s=${s#\"}; s=${s%\"} ;;
      \'*\') s=${s#\'}; s=${s%\'} ;;
    esac
  fi
  printf '%s' "$s"
}

# --- Parse the surface ---
# 1) YAML frontmatter `resource:` (OKF 0.7.1+ surfaces)
FRONTMATTER=$(awk 'BEGIN{fm=0} /^---[[:space:]]*$/ { fm++; next } fm==1 && /^resource:[[:space:]]*/ { sub(/^resource:[[:space:]]*/, ""); print; exit } fm>=2 { exit }' "$SURFACE")
# 2) Legacy markdown ## Base URL: line
[ -z "$FRONTMATTER" ] && FRONTMATTER=$(awk '/^\*\*Base URL:\*\*/ { sub(/^\*\*Base URL:\*\*[[:space:]]*/, ""); print; exit }' "$SURFACE")
[ -n "$FRONTMATTER" ] || { echo "render_query: no resource: / ## Base URL: in $SURFACE" >&2; exit 65; }
BASE_URL=$(strip_quotes "$FRONTMATTER")

AUTH=$(awk 'BEGIN{fm=0} /^---[[:space:]]*$/ { fm++; next } fm==1 && /^auth:[[:space:]]*/ { sub(/^auth:[[:space:]]*/, ""); print; exit } fm>=2 { exit }' "$SURFACE")
AUTH=$(strip_quotes "$AUTH")
AUTH=$(printf '%s' "${AUTH:-none}" | tr 'A-Z' 'a-z')
SNIPPET="First record"
[ "$AUTH" != "none" ] && SNIPPET="Authed first record"
echo "[SNIPPET-PICK:site=${SITE} surface=${SURFACE##*/} auth=${AUTH} snippet=${SNIPPET}]" >&2

# Default --out-dir next to the api-surface file at ${research_folder}/scripts/
[ -n "$OUT_DIR" ] || OUT_DIR="$(dirname "$SURFACE")/../scripts"
mkdir -p "$OUT_DIR"

slug_surf=$(basename "$SURFACE" .md)

# When --first is set, a previous non-first run may have left row-indexed
# variants in OUT_DIR (e.g. ...-1.sh ...-2.sh). Prune ONLY numeric-suffix
# siblings so user-authored files matching the same prefix (e.g.
# query-store-api-example-com-handwritten.sh) survive.
if [ "$FIRST" -eq 1 ]; then
  rm -f "$OUT_DIR/query-${slug_surf}-${SITE}"-[[:digit:]]*.sh 2>/dev/null || true
fi

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
    in_block==1 && /^```/          { in_block=2; next }
    in_block==2 && /^```/          { in_block=0; print body; exit }
    in_block==2                    { body = body "\n" $0 }
  ' "$SRC")
  if [ -z "$BODY" ]; then
    echo "render_query: snippet not found: $SNIPPET in $SRC" >&2
    FAILED=$((FAILED + 1))
    continue
  fi

  # Token substitution using a literal splice. Both sed's s/// and awk's gsub()/
  # sub() interpret & and \ in the *replacement* as metacharacters (matched text,
  # backreferences), so a URL or path containing & or \ would corrupt for free.
  # scaffold.sh uses python str.replace() for the same reason (see plugins/beacon/
  # skills/site-recon/scripts/scaffold.sh:11-24). Here we use pure-bash index() +
  # substr() so we don't introduce a python dependency at this layer.
  splice() {
    # splice <string> <needle> <replacement>
    local s=$1 needle=$2 repl=$3
    while :; do
      local pos=${s%%"$needle"*}
      [ "$pos" = "$s" ] && { printf '%s' "$s"; return; }
      printf '%s%s' "$pos" "$repl"
      s=${s#"$pos""$needle"}
    done
  }
  BODY=$(splice "$BODY" '{SURFACE_BASE_URL}' "$BASE_URL")
  BODY=$(splice "$BODY" '{PATH}'          "$PATH_VAL")

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
