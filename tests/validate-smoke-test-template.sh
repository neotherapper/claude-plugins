#!/usr/bin/env bash
# validate-smoke-test-template.sh — validates smoke-test.sh.template has all required elements
# Usage: ./tests/validate-smoke-test-template.sh
# Exit code: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

FILE="plugins/beacon/templates/smoke-test.sh.template"
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

echo "Validating smoke-test template: $FILE"
echo "========================================"

# Check 1: File exists
if [ -f "$FILE" ]; then
  check "File exists: $FILE" "ok"
else
  check "File exists: $FILE" "fail"
fi

# Check 2: Has bash shebang
if [ -f "$FILE" ] && head -1 "$FILE" | grep -q "#!/usr/bin/env bash"; then
  check "Has bash shebang (#!/usr/bin/env bash)" "ok"
else
  check "Has bash shebang (#!/usr/bin/env bash)" "fail"
fi

# Check 3: Has {{SITE_SLUG}} token
if [ -f "$FILE" ] && grep -q "{{SITE_SLUG}}" "$FILE"; then
  check "Has {{SITE_SLUG}} token" "ok"
else
  check "Has {{SITE_SLUG}} token" "fail"
fi

# Check 4: Has {{BASE_URL}} token
if [ -f "$FILE" ] && grep -q "{{BASE_URL}}" "$FILE"; then
  check "Has {{BASE_URL}} token" "ok"
else
  check "Has {{BASE_URL}} token" "fail"
fi

# Check 5: Has {{SMOKE_TEST_CHECKS}} token
if [ -f "$FILE" ] && grep -q "{{SMOKE_TEST_CHECKS}}" "$FILE"; then
  check "Has {{SMOKE_TEST_CHECKS}} token" "ok"
else
  check "Has {{SMOKE_TEST_CHECKS}} token" "fail"
fi

# Check 6: Has check() function definition
if [ -f "$FILE" ] && grep -q "check()" "$FILE"; then
  check "Has check() function definition" "ok"
else
  check "Has check() function definition" "fail"
fi

# Check 7: Has ANSI color variables
if [ -f "$FILE" ] && grep -q "GREEN=" "$FILE" && grep -q "RED=" "$FILE" && grep -q "YELLOW=" "$FILE" && grep -q "NC=" "$FILE"; then
  check "Has ANSI color variables (GREEN, RED, YELLOW, NC)" "ok"
else
  check "Has ANSI color variables (GREEN, RED, YELLOW, NC)" "fail"
fi

# Check 8: Has auth_required SKIP logic
if [ -f "$FILE" ] && grep -q "auth_required" "$FILE"; then
  check "Has auth_required SKIP logic" "ok"
else
  check "Has auth_required SKIP logic" "fail"
fi

# Check 9: Has exit 1 for failures
if [ -f "$FILE" ] && grep -q "exit 1" "$FILE"; then
  check "Has exit 1 for failures" "ok"
else
  check "Has exit 1 for failures" "fail"
fi

# Check 10: Has --max-time in curl call
if [ -f "$FILE" ] && grep -q "\-\-max-time" "$FILE"; then
  check "Has --max-time flag in curl call" "ok"
else
  check "Has --max-time flag in curl call" "fail"
fi

echo "========================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
