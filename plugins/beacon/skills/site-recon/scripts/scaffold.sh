#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
TPL="$DIR/../../../templates/okf"
: "${URL:?set URL}"
SLUG=$(python3 "$DIR/slugify.py" "$URL")
if [ -z "${OUTPUT_ROOT:-}" ]; then
  OUTPUT_ROOT="docs/sites/${SLUG}/research"
  # T6-m1: only on the default path, deterministically flag a pre-0.7.0 legacy
  # workspace for this slug. This was prose in SKILL.md — skippable under synthesis
  # pressure — so the detection lives here. Suppressed whenever the caller supplied
  # an explicit OUTPUT_ROOT (incl. SKILL.md's own docs/research/{slug} example), so
  # we never nag a caller away from a path they deliberately chose.
  [ -d "docs/research/${SLUG}" ] && echo "[LEGACY-WORKSPACE:docs/research/${SLUG}]"
fi
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
# T5-m1: build the marker with json.dumps (OUTPUT_ROOT passed as argv, never
# interpolated) so a path containing " or \ still yields well-formed JSON. A
# printf'd %s here breaks json.load in okf-gate.sh and the gate fails open.
python3 -c 'import json,sys; sys.stdout.write(json.dumps({"output_root": sys.argv[1], "retries": 0}) + "\n")' \
  "$OUTPUT_ROOT" > "$OUTPUT_ROOT/.beacon/recon-active.json"
echo "[SCAFFOLD:${OUTPUT_ROOT}]"
