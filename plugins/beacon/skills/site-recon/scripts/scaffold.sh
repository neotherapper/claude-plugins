#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
TPL="$DIR/../../../templates/okf"
: "${URL:?set URL}"
SLUG=$(printf '%s' "$URL" | tr 'A-Z' 'a-z' | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g')
OUTPUT_ROOT="${OUTPUT_ROOT:-docs/sites/${SLUG}/research}"
[ -n "${OUTPUT_ROOT_OVERRIDDEN:-}" ] && echo "[OUTPUT-OVERRIDE:${OUTPUT_ROOT}]"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
mkdir -p "$OUTPUT_ROOT/api-surfaces" "$OUTPUT_ROOT/specs" "$OUTPUT_ROOT/.beacon"
render() { sed -e "s#{{SITE_SLUG}}#${SLUG}#g" -e "s#{{SITE_NAME}}#${SLUG}#g" \
              -e "s#{{URL}}#${URL}#g" -e "s#{{TIMESTAMP}}#${TS}#g" "$1"; }
for f in INDEX tech-stack site-map constants; do render "$TPL/$f.md" > "$OUTPUT_ROOT/$f.md"; done
render "$TPL/session-brief.md"   > "$OUTPUT_ROOT/.beacon/session-brief.md"
render "$TPL/phase-checklist.md" > "$OUTPUT_ROOT/.beacon/phase-checklist.md"
printf '{"output_root":"%s","retries":0}\n' "$OUTPUT_ROOT" > "$OUTPUT_ROOT/.beacon/recon-active.json"
echo "[SCAFFOLD:${OUTPUT_ROOT}]"
