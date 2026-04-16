#!/usr/bin/env bash
# test-check-domains.sh — integration tests for check-domains.sh
#
# Requires: CF_API_TOKEN, CF_ACCOUNT_ID, PORKBUN_API_KEY, PORKBUN_SECRET
# Run: bash test-check-domains.sh
#
# Tests real API calls against known domains to verify:
# - Argument validation
# - CF API jq path and field parsing
# - .io routing to Porkbun (not CF)
# - Output format (status domain price)
# - Tier fallback behavior

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_SCRIPT="${SCRIPT_DIR}/check-domains.sh"

passed=0
failed=0

# ─────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────

pass() {
  echo "  PASS: $1"
  passed=$((passed + 1))
}

fail() {
  echo "  FAIL: $1"
  echo "        Expected: $2"
  echo "        Got:      $3"
  failed=$((failed + 1))
}

# ─────────────────────────────────────────────────────────
# Test 1: No arguments → exit 2
# ─────────────────────────────────────────────────────────
echo "Test 1: No arguments exits with code 2"
exit_code=0
bash "$CHECK_SCRIPT" 2>/dev/null || exit_code=$?
if [[ $exit_code -eq 2 ]]; then
  pass "exit code 2"
else
  fail "exit code" "2" "$exit_code"
fi

# ─────────────────────────────────────────────────────────
# Test 2: Known taken domain (google.com)
# ─────────────────────────────────────────────────────────
echo "Test 2: Known taken domain returns 'taken'"
result=$(bash "$CHECK_SCRIPT" google.com 2>/dev/null)
if echo "$result" | grep -q "^taken google.com"; then
  pass "google.com is taken"
else
  fail "google.com status" "taken google.com ..." "$result"
fi

# ─────────────────────────────────────────────────────────
# Test 3: Likely available domain returns 'available' with price
# ─────────────────────────────────────────────────────────
echo "Test 3: Available domain returns price from CF API"
result=$(bash "$CHECK_SCRIPT" xzq9k7m2v4p1.com 2>/dev/null)
status=$(echo "$result" | awk '{print $1}')
price=$(echo "$result" | awk '{print $3}')
if [[ "$status" == "available" ]]; then
  pass "gibberish .com is available"
  # Verify price is a number (CF returns registration_cost)
  if [[ "$price" =~ ^[0-9]+\.[0-9]+$ ]]; then
    pass "price is numeric: $price"
  else
    fail "price format" "numeric (e.g. 10.46)" "$price"
  fi
else
  fail "xzq9k7m2v4p1.com status" "available" "$status"
fi

# ─────────────────────────────────────────────────────────
# Test 4: Output format — each line is "status domain price"
# ─────────────────────────────────────────────────────────
echo "Test 4: Output format is 'status domain price' (3 fields per line)"
result=$(bash "$CHECK_SCRIPT" google.com xzq9k7m2v4p1.dev 2>/dev/null)
all_valid=true
while IFS= read -r line; do
  field_count=$(echo "$line" | awk '{print NF}')
  if [[ "$field_count" -ne 3 ]]; then
    all_valid=false
    fail "line format" "3 fields" "$field_count fields: $line"
  fi
done <<< "$result"
if [[ "$all_valid" == "true" ]]; then
  pass "all lines have 3 fields"
fi

# ─────────────────────────────────────────────────────────
# Test 5: .io domains route to Porkbun (not CF)
# ─────────────────────────────────────────────────────────
echo "Test 5: .io domain does not error (routes to Porkbun)"
result=$(bash "$CHECK_SCRIPT" xzq9k7m2v4p1.io 2>&1)
# Should not contain "unbound variable" or other bash errors
if echo "$result" | grep -qi "error\|unbound"; then
  fail ".io routing" "no errors" "$result"
else
  status=$(echo "$result" | head -1 | awk '{print $1}')
  if [[ "$status" == "available" || "$status" == "taken" || "$status" == "unknown" ]]; then
    pass ".io routed without error, status: $status"
  else
    fail ".io status" "available|taken|unknown" "$status"
  fi
fi

# ─────────────────────────────────────────────────────────
# Test 6: Mixed TLDs — .io splits from .com/.dev
# ─────────────────────────────────────────────────────────
echo "Test 6: Mixed TLDs processed without errors"
result=$(bash "$CHECK_SCRIPT" google.com xzq9k7m2v4p1.dev xzq9k7m2v4p1.io 2>&1)
line_count=$(echo "$result" | wc -l | tr -d ' ')
if echo "$result" | grep -qi "error\|unbound"; then
  fail "mixed TLDs" "no errors" "$result"
elif [[ "$line_count" -eq 3 ]]; then
  pass "3 domains in, 3 lines out"
else
  fail "line count" "3" "$line_count"
fi

# ─────────────────────────────────────────────────────────
# Test 7: Batch size — more than 20 domains don't crash
# ─────────────────────────────────────────────────────────
echo "Test 7: Batch of 25 domains doesn't crash"
domains=()
for i in $(seq 1 25); do
  domains+=("xzq${i}test.com")
done
result=$(bash "$CHECK_SCRIPT" "${domains[@]}" 2>&1)
result_lines=$(echo "$result" | wc -l | tr -d ' ')
if echo "$result" | grep -qi "error\|unbound"; then
  fail "batch 25" "no errors" "$(echo "$result" | grep -i 'error\|unbound' | head -1)"
elif [[ "$result_lines" -eq 25 ]]; then
  pass "25 domains in, 25 lines out"
else
  fail "batch line count" "25" "$result_lines"
fi

# ─────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
total=$((passed + failed))
echo "Results: $passed/$total passed"
if [[ $failed -gt 0 ]]; then
  echo "FAILED ($failed failures)"
  exit 1
else
  echo "ALL PASSED"
  exit 0
fi
