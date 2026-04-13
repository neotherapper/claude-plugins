#!/usr/bin/env bash
# validate-templates.sh — validates the output template files for Beacon Phase 12
# Tests that all 4 template files exist and contain required {{TOKEN}} placeholders
# Usage: ./tests/validate-templates.sh
# Exit code: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

PASS=0
FAIL=0

TEMPLATES_DIR="plugins/beacon/templates"

INDEX_TPL="$TEMPLATES_DIR/INDEX.md.template"
TECH_STACK_TPL="$TEMPLATES_DIR/tech-stack.md.template"
API_SURFACE_TPL="$TEMPLATES_DIR/api-surface.md.template"
SITE_MAP_TPL="$TEMPLATES_DIR/site-map.md.template"

check() {
  local desc="$1"
  local result="$2"  # "ok" or "fail"
  if [ "$result" = "ok" ]; then
    echo "  PASS  $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $desc"
    FAIL=$((FAIL + 1))
  fi
}

contains_token() {
  local file="$1"
  local token="$2"
  if grep -qF "$token" "$file" 2>/dev/null; then
    echo "ok"
  else
    echo "fail"
  fi
}

echo "Validating Beacon output templates"
echo "========================================"

# ── Check 1-4: All template files exist ──────────────────────────────────────
echo ""
echo "1. Template files exist"

[ -f "$INDEX_TPL" ]       && check "INDEX.md.template exists"       "ok" || check "INDEX.md.template exists"       "fail"
[ -f "$TECH_STACK_TPL" ]  && check "tech-stack.md.template exists"  "ok" || check "tech-stack.md.template exists"  "fail"
[ -f "$API_SURFACE_TPL" ] && check "api-surface.md.template exists" "ok" || check "api-surface.md.template exists" "fail"
[ -f "$SITE_MAP_TPL" ]    && check "site-map.md.template exists"    "ok" || check "site-map.md.template exists"    "fail"

# ── Check 5-10: INDEX.md.template tokens ─────────────────────────────────────
echo ""
echo "2. INDEX.md.template required tokens"

if [ -f "$INDEX_TPL" ]; then
  check "INDEX contains {{SITE_NAME}}"              "$(contains_token "$INDEX_TPL" '{{SITE_NAME}}')"
  check "INDEX contains {{DATE}}"                   "$(contains_token "$INDEX_TPL" '{{DATE}}')"
  check "INDEX contains {{URL}}"                    "$(contains_token "$INDEX_TPL" '{{URL}}')"
  check "INDEX contains {{FRAMEWORK}}"              "$(contains_token "$INDEX_TPL" '{{FRAMEWORK}}')"
  check "INDEX contains {{TOOL_AVAILABILITY_BLOCK}}" "$(contains_token "$INDEX_TPL" '{{TOOL_AVAILABILITY_BLOCK}}')"
  check "INDEX contains {{API_SURFACE_ROWS}}"       "$(contains_token "$INDEX_TPL" '{{API_SURFACE_ROWS}}')"
else
  check "INDEX contains {{SITE_NAME}}"              "fail"
  check "INDEX contains {{DATE}}"                   "fail"
  check "INDEX contains {{URL}}"                    "fail"
  check "INDEX contains {{FRAMEWORK}}"              "fail"
  check "INDEX contains {{TOOL_AVAILABILITY_BLOCK}}" "fail"
  check "INDEX contains {{API_SURFACE_ROWS}}"       "fail"
fi

# ── Check 11-14: tech-stack.md.template tokens ───────────────────────────────
echo ""
echo "3. tech-stack.md.template required tokens"

if [ -f "$TECH_STACK_TPL" ]; then
  check "tech-stack contains {{FRAMEWORK}}"        "$(contains_token "$TECH_STACK_TPL" '{{FRAMEWORK}}')"
  check "tech-stack contains {{VERSION}}"          "$(contains_token "$TECH_STACK_TPL" '{{VERSION}}')"
  check "tech-stack contains {{AUTH_MECHANISM}}"   "$(contains_token "$TECH_STACK_TPL" '{{AUTH_MECHANISM}}')"
  check "tech-stack contains {{CDN}}"              "$(contains_token "$TECH_STACK_TPL" '{{CDN}}')"
else
  check "tech-stack contains {{FRAMEWORK}}"        "fail"
  check "tech-stack contains {{VERSION}}"          "fail"
  check "tech-stack contains {{AUTH_MECHANISM}}"   "fail"
  check "tech-stack contains {{CDN}}"              "fail"
fi

# ── Check 15-19: api-surface.md.template tokens ──────────────────────────────
echo ""
echo "4. api-surface.md.template required tokens"

if [ -f "$API_SURFACE_TPL" ]; then
  check "api-surface contains {{SURFACE_NAME}}"    "$(contains_token "$API_SURFACE_TPL" '{{SURFACE_NAME}}')"
  check "api-surface contains {{BASE_URL}}"        "$(contains_token "$API_SURFACE_TPL" '{{BASE_URL}}')"
  check "api-surface contains {{AUTH_REQUIRED}}"   "$(contains_token "$API_SURFACE_TPL" '{{AUTH_REQUIRED}}')"
  check "api-surface contains {{ENDPOINT_ROWS}}"   "$(contains_token "$API_SURFACE_TPL" '{{ENDPOINT_ROWS}}')"
  check "api-surface contains {{EXAMPLE_REQUEST}}" "$(contains_token "$API_SURFACE_TPL" '{{EXAMPLE_REQUEST}}')"
else
  check "api-surface contains {{SURFACE_NAME}}"    "fail"
  check "api-surface contains {{BASE_URL}}"        "fail"
  check "api-surface contains {{AUTH_REQUIRED}}"   "fail"
  check "api-surface contains {{ENDPOINT_ROWS}}"   "fail"
  check "api-surface contains {{EXAMPLE_REQUEST}}" "fail"
fi

# ── Check 20-23: site-map.md.template tokens ─────────────────────────────────
echo ""
echo "5. site-map.md.template required tokens"

if [ -f "$SITE_MAP_TPL" ]; then
  check "site-map contains {{SITE_NAME}}"          "$(contains_token "$SITE_MAP_TPL" '{{SITE_NAME}}')"
  check "site-map contains {{URL_COUNT}}"          "$(contains_token "$SITE_MAP_TPL" '{{URL_COUNT}}')"
  check "site-map contains {{PUBLIC_ROUTES_TABLE}}" "$(contains_token "$SITE_MAP_TPL" '{{PUBLIC_ROUTES_TABLE}}')"
  check "site-map contains {{API_ROUTES_TABLE}}"   "$(contains_token "$SITE_MAP_TPL" '{{API_ROUTES_TABLE}}')"
else
  check "site-map contains {{SITE_NAME}}"          "fail"
  check "site-map contains {{URL_COUNT}}"          "fail"
  check "site-map contains {{PUBLIC_ROUTES_TABLE}}" "fail"
  check "site-map contains {{API_ROUTES_TABLE}}"   "fail"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
