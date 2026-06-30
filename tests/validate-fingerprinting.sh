#!/usr/bin/env bash
# validate-fingerprinting.sh — validates Phase 3 fingerprinting coverage
#
# Checks:
#   1. Existence guards: SKILL.md and references/fingerprints.md present
#   2. Named signal checks: 6 specific fingerprint signals in the union of
#      (Phase 3 section of SKILL.md) + (references/fingerprints.md)
#   3. Coverage loop: informational scan over all tech packs (WARNs only;
#      uncovered packs do NOT cause a non-zero exit)
#
# Usage: bash tests/validate-fingerprinting.sh
# Exit code: 0 = existence guards + named signal checks pass, 1 = real failure

set -euo pipefail

WORKTREE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKTREE_ROOT"

SKILL_FILE="plugins/beacon/skills/site-recon/SKILL.md"
FINGERPRINTS_FILE="plugins/beacon/skills/site-recon/references/fingerprints.md"
TECH_DIR="plugins/beacon/technologies"
EXCLUDED_PACK="graphql"

PASS=0
FAIL=0
WARN=0

pass() { echo "  PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL+1)); }
warn() { echo "  WARN  $1"; WARN=$((WARN+1)); }

echo "Validating fingerprinting coverage (Phase 3 + references)"
echo "========================================"

# --- Existence guards ---

if [ -f "$SKILL_FILE" ]; then
  pass "SKILL.md exists"
else
  fail "SKILL.md exists"
fi

if [ -f "$FINGERPRINTS_FILE" ]; then
  pass "references/fingerprints.md exists"
else
  fail "references/fingerprints.md exists"
fi

# Bail early if either guard file is missing — can't build the union
if [ "$FAIL" -gt 0 ]; then
  echo "========================================"
  echo "Results: $PASS passed, $FAIL failed, $WARN warnings"
  exit 1
fi

# --- Build union: Phase 3 section of SKILL.md + full fingerprints.md ---
# grep searches run against this single temp file to avoid scanning multiple files.

UNION_FILE="$(mktemp)"
trap 'rm -f "$UNION_FILE"' EXIT

# Extract Phase 3 section (stops at the next ## Phase N heading)
awk '/^## Phase 3/{found=1; next} found && /^## Phase [0-9]/{exit} found{print}' \
  "$SKILL_FILE" >> "$UNION_FILE"

# Append the full fingerprints reference
cat "$FINGERPRINTS_FILE" >> "$UNION_FILE"

# --- Named signal checks (hard failures — exit 1 if any are missing) ---

if grep -q '_astro/' "$UNION_FILE" && grep -q 'astro-island' "$UNION_FILE"; then
  pass "Astro signals present (_astro/ and astro-island)"
else
  fail "Astro signals present (_astro/ and astro-island)"
fi

if grep -q 'csrfmiddlewaretoken' "$UNION_FILE"; then
  pass "Django signals present (csrfmiddlewaretoken)"
else
  fail "Django signals present (csrfmiddlewaretoken)"
fi

if grep -q 'uvicorn' "$UNION_FILE" && grep -q 'swagger-ui' "$UNION_FILE"; then
  pass "FastAPI signals present (uvicorn and swagger-ui)"
else
  fail "FastAPI signals present (uvicorn and swagger-ui)"
fi

if grep -q 'X-Runtime' "$UNION_FILE" && grep -q 'csrf-token' "$UNION_FILE"; then
  pass "Rails signals present (X-Runtime and csrf-token)"
else
  fail "Rails signals present (X-Runtime and csrf-token)"
fi

# x-shopify-stage: case-insensitive (header casing may vary in docs)
if grep -qi 'x-shopify-stage' "$UNION_FILE" && grep -q 'cdn\.shopify\.com' "$UNION_FILE"; then
  pass "Shopify signals present (x-shopify-stage and cdn.shopify.com)"
else
  fail "Shopify signals present (x-shopify-stage and cdn.shopify.com)"
fi

# x-strapi-version: case-insensitive (header casing may vary in docs)
if grep -q 'admin/init' "$UNION_FILE" && grep -qi 'x-strapi-version' "$UNION_FILE"; then
  pass "Strapi signals present (admin/init and x-strapi-version)"
else
  fail "Strapi signals present (admin/init and x-strapi-version)"
fi

# --- Coverage loop (informational — WARNs only, no exit 1) ---
# Regression-guard: reports which packs have no Phase 3 signal in the union.
# Uncovered packs do NOT cause a non-zero exit.

TOTAL=$(ls -d "$TECH_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
covered=0
uncovered=0

echo ""
echo "Tech pack coverage scan ($TOTAL total packs, excluding '$EXCLUDED_PACK')..."

for dir in "$TECH_DIR"/*/; do
  framework=$(basename "$dir")
  if [ "$framework" = "$EXCLUDED_PACK" ]; then
    continue
  fi
  # Alias: directory name differs from how the framework appears in docs
  search="$framework"
  case "$framework" in
    nextjs)         search='Next\.js|__NEXT_DATA__' ;;
    zend-framework) search='[Zz]end' ;;
    aspnet)         search='ASP\.NET|__VIEWSTATE|\.aspx' ;;
  esac
  if grep -qiE "$search" "$UNION_FILE"; then
    pass "Coverage: '$framework' has a Phase 3 fingerprint signal"
    covered=$((covered+1))
  else
    warn "Coverage: '$framework' has NO Phase 3 fingerprint signal"
    uncovered=$((uncovered+1))
  fi
done

echo ""
echo "Coverage: $covered/$((covered+uncovered)) tech packs have a Phase 3 fingerprint signal ($uncovered uncovered — see WARN lines)"
echo "========================================"
echo "Results: $PASS passed, $FAIL failed, $WARN warnings (coverage gaps)"

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
