#!/usr/bin/env bash
# validate-fingerprinting.sh — validates Phase 1 slug correctness and Phase 3 fingerprinting coverage
# Usage: ./tests/validate-fingerprinting.sh
# Exit code: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

SKILL_FILE="plugins/beacon/skills/site-recon/SKILL.md"
TECH_DIR="plugins/beacon/technologies"
EXCLUDED_PACK="graphql"
EXPECTED_PACK_COUNT=12
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [ "$result" = "ok" ]; then
    echo "  PASS  $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "Validating fingerprinting coverage: $SKILL_FILE"
echo "========================================"

# --- Slug checks (1-3) ---

# Check 1: SKILL.md exists
if [ -f "$SKILL_FILE" ]; then
  check "SKILL.md exists" "ok"
else
  check "SKILL.md exists" "fail"
fi

# Check 2: Double-dash slug bug absent (s|\.|--|g must NOT be present)
if [ -f "$SKILL_FILE" ] && ! grep -qF 's|\.|--|g' "$SKILL_FILE"; then
  check "Double-dash slug bug absent (s|.--|g not present)" "ok"
else
  check "Double-dash slug bug absent (s|.--|g not present)" "fail"
fi

# Check 3: Single-dash slug pattern present (s|\.|-|g must be present)
if [ -f "$SKILL_FILE" ] && grep -qF 's|\.|-|g' "$SKILL_FILE"; then
  check "Single-dash slug pattern present (s|.|-|g present)" "ok"
else
  check "Single-dash slug pattern present (s|.|-|g present)" "fail"
fi

# Check 3b: Slug sed command actually produces correct output for a full URL (portability check)
ACTUAL_SLUG=$(echo "https://example.com/path" | sed -E 's|https?://||;s|/.*||;s|\.|-|g')
if [ "$ACTUAL_SLUG" = "example-com" ]; then
  check "Slug sed command produces 'example-com' from 'https://example.com/path'" "ok"
else
  check "Slug sed command produces 'example-com' from 'https://example.com/path' (got: $ACTUAL_SLUG)" "fail"
fi

# --- Per-tech-pack signal checks (4-9) ---

# Check 4: Astro signals present
if [ -f "$SKILL_FILE" ] && grep -q '_astro/' "$SKILL_FILE" && grep -q 'astro-island' "$SKILL_FILE"; then
  check "Astro signals present (_astro/ and astro-island)" "ok"
else
  check "Astro signals present (_astro/ and astro-island)" "fail"
fi

# Check 5: Django signals present
if [ -f "$SKILL_FILE" ] && grep -q 'csrfmiddlewaretoken' "$SKILL_FILE"; then
  check "Django signals present (csrfmiddlewaretoken)" "ok"
else
  check "Django signals present (csrfmiddlewaretoken)" "fail"
fi

# Check 6: FastAPI signals present
if [ -f "$SKILL_FILE" ] && grep -q 'uvicorn' "$SKILL_FILE" && grep -q 'swagger-ui' "$SKILL_FILE"; then
  check "FastAPI signals present (uvicorn and swagger-ui)" "ok"
else
  check "FastAPI signals present (uvicorn and swagger-ui)" "fail"
fi

# Check 7: Rails signals present
if [ -f "$SKILL_FILE" ] && grep -q 'X-Runtime' "$SKILL_FILE" && grep -q 'csrf-token' "$SKILL_FILE"; then
  check "Rails signals present (X-Runtime and csrf-token)" "ok"
else
  check "Rails signals present (X-Runtime and csrf-token)" "fail"
fi

# Check 8: Shopify signals present
if [ -f "$SKILL_FILE" ] && grep -q 'x-shopify-stage' "$SKILL_FILE" && grep -q 'cdn\.shopify\.com' "$SKILL_FILE"; then
  check "Shopify signals present (x-shopify-stage and cdn.shopify.com)" "ok"
else
  check "Shopify signals present (x-shopify-stage and cdn.shopify.com)" "fail"
fi

# Check 9: Strapi signals present
if [ -f "$SKILL_FILE" ] && grep -q 'admin/init' "$SKILL_FILE" && grep -qi 'x-strapi-version' "$SKILL_FILE"; then
  check "Strapi signals present (admin/init and x-strapi-version)" "ok"
else
  check "Strapi signals present (admin/init and x-strapi-version)" "fail"
fi

# --- Coverage loop (10+) ---

# Dynamic: one check per non-graphql tech pack directory
# Note: some directory names differ from how the framework appears in docs
# (e.g. directory "nextjs" but SKILL.md says "Next.js") — handle with aliases
# Scoped to Phase 3 section only (stops at the next ## heading)
PHASE3_CONTENT=""
if [ -f "$SKILL_FILE" ]; then
  PHASE3_CONTENT=$(awk '/^## Phase 3/{found=1; next} found && /^## Phase [0-9]/{exit} found{print}' "$SKILL_FILE")
fi

for dir in "$TECH_DIR"/*/; do
  framework=$(basename "$dir")
  if [ "$framework" = "$EXCLUDED_PACK" ]; then
    continue
  fi
  search="$framework"
  case "$framework" in
    nextjs) search="Next\.js|__NEXT_DATA__" ;;
  esac
  if echo "$PHASE3_CONTENT" | grep -qiE "$search"; then
    check "Phase 3 has detection signal for '$framework'" "ok"
  else
    check "Phase 3 has detection signal for '$framework'" "fail"
  fi
done

# Final count check
ACTUAL_COUNT=$(ls -d "$TECH_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$ACTUAL_COUNT" -eq "$EXPECTED_PACK_COUNT" ]; then
  check "Tech pack directory count is $EXPECTED_PACK_COUNT (found: $ACTUAL_COUNT)" "ok"
else
  check "Tech pack directory count is $EXPECTED_PACK_COUNT (found: $ACTUAL_COUNT) — add fingerprint signals to SKILL.md Phase 3 first, then update EXPECTED_PACK_COUNT" "fail"
fi

echo "========================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
