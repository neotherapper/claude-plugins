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
# Literal (non-regex) token substitution via python3 — a sed-based render corrupts or
# aborts on URLs containing &, #, or \ (sed replacement-text metacharacters); python's
# str.replace() treats the URL as opaque literal text, so it cannot be corrupted.
render() {
  python3 - "$1" "$SLUG" "$URL" "$TS" <<'PYEOF'
import sys
path, slug, url, ts = sys.argv[1:5]
text = open(path, encoding="utf-8").read()
text = (text.replace("{{SITE_SLUG}}", slug)
            .replace("{{SITE_NAME}}", slug)
            .replace("{{URL}}", url)
            .replace("{{TIMESTAMP}}", ts))
sys.stdout.write(text)
PYEOF
}
for f in INDEX tech-stack site-map constants; do render "$TPL/$f.md" > "$OUTPUT_ROOT/$f.md"; done
render "$TPL/session-brief.md"   > "$OUTPUT_ROOT/.beacon/session-brief.md"
render "$TPL/phase-checklist.md" > "$OUTPUT_ROOT/.beacon/phase-checklist.md"
printf '{"output_root":"%s","retries":0}\n' "$OUTPUT_ROOT" > "$OUTPUT_ROOT/.beacon/recon-active.json"
echo "[SCAFFOLD:${OUTPUT_ROOT}]"
