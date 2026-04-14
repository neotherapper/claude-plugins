#!/usr/bin/env bash
# validate-constants-template.sh — validates constants.md.template has all required tokens and sections
# Usage: ./tests/validate-constants-template.sh
# Exit code: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

FILE="plugins/beacon/templates/constants.md.template"
PASS=0
FAIL=0

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

echo "Validating constants template: $FILE"
echo "========================================"

# Check 1: File exists
if [ -f "$FILE" ]; then
  check "File exists: $FILE" "ok"
else
  check "File exists: $FILE" "fail"
fi

# Check 2: Has {{SITE_NAME}} token
if [ -f "$FILE" ] && grep -q "{{SITE_NAME}}" "$FILE"; then
  check "Has {{SITE_NAME}} token" "ok"
else
  check "Has {{SITE_NAME}} token" "fail"
fi

# Check 3: Has {{DATE}} token
if [ -f "$FILE" ] && grep -q "{{DATE}}" "$FILE"; then
  check "Has {{DATE}} token" "ok"
else
  check "Has {{DATE}} token" "fail"
fi

# Check 4: Has {{PLUGIN_VERSION}} token
if [ -f "$FILE" ] && grep -q "{{PLUGIN_VERSION}}" "$FILE"; then
  check "Has {{PLUGIN_VERSION}} token" "ok"
else
  check "Has {{PLUGIN_VERSION}} token" "fail"
fi

# Check 5: Has Nonces section
if [ -f "$FILE" ] && grep -q "## Nonces" "$FILE"; then
  check "Has '## Nonces' section" "ok"
else
  check "Has '## Nonces' section" "fail"
fi

# Check 6: Has Taxonomy IDs section
if [ -f "$FILE" ] && grep -q "## Taxonomy IDs" "$FILE"; then
  check "Has '## Taxonomy IDs' section" "ok"
else
  check "Has '## Taxonomy IDs' section" "fail"
fi

# Check 7: Has Enum Values section
if [ -f "$FILE" ] && grep -q "## Enum Values" "$FILE"; then
  check "Has '## Enum Values' section" "ok"
else
  check "Has '## Enum Values' section" "fail"
fi

# Check 8: Has Feature Flags section
if [ -f "$FILE" ] && grep -q "## Feature Flags" "$FILE"; then
  check "Has '## Feature Flags' section" "ok"
else
  check "Has '## Feature Flags' section" "fail"
fi

# Check 9: Has Locale section
if [ -f "$FILE" ] && grep -q "## Locale" "$FILE"; then
  check "Has '## Locale' section" "ok"
else
  check "Has '## Locale' section" "fail"
fi

# Check 10: Has Misc Constants section
if [ -f "$FILE" ] && grep -q "## Misc Constants" "$FILE"; then
  check "Has '## Misc Constants' section" "ok"
else
  check "Has '## Misc Constants' section" "fail"
fi

# Check 11: Has at least one _ROWS}} token
if [ -f "$FILE" ] && grep -q "_ROWS}}" "$FILE"; then
  check "Has at least one _ROWS}} token" "ok"
else
  check "Has at least one _ROWS}} token" "fail"
fi

echo "========================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
