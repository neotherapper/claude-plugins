#!/usr/bin/env bash
# validate-phase-11-browser.sh — validates phase-11-browser.md has all 15 required content checks
# Usage: ./tests/validate-phase-11-browser.sh
# Exit code: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

FILE="plugins/beacon/skills/site-recon/references/phase-11-browser.md"
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

echo "Validating phase-11-browser reference: $FILE"
echo "========================================"

# Check 1: File exists
if [ -f "$FILE" ]; then
  check "File exists: $FILE" "ok"
else
  check "File exists: $FILE" "fail"
fi

# Check 2: Phase 11a section present
if [ -f "$FILE" ] && grep -q "11a" "$FILE"; then
  check "Phase 11a section present" "ok"
else
  check "Phase 11a section present" "fail"
fi

# Check 3: Phase 11b section present
if [ -f "$FILE" ] && grep -q "11b" "$FILE"; then
  check "Phase 11b section present" "ok"
else
  check "Phase 11b section present" "fail"
fi

# Check 4: Phase 11c section present
if [ -f "$FILE" ] && grep -q "11c" "$FILE"; then
  check "Phase 11c section present" "ok"
else
  check "Phase 11c section present" "fail"
fi

# Check 5: Phase 11d section present
if [ -f "$FILE" ] && grep -q "11d" "$FILE"; then
  check "Phase 11d section present" "ok"
else
  check "Phase 11d section present" "fail"
fi

# Check 6: navigate_page is mentioned
if [ -f "$FILE" ] && grep -q "navigate_page" "$FILE"; then
  check "navigate_page is mentioned" "ok"
else
  check "navigate_page is mentioned" "fail"
fi

# Check 7: navigate_page(url, page_id) is NOT present (old signature)
if [ -f "$FILE" ] && ! grep -q "navigate_page(url, page_id)" "$FILE"; then
  check "navigate_page(url, page_id) NOT present (old signature absent)" "ok"
else
  check "navigate_page(url, page_id) NOT present (old signature absent)" "fail"
fi

# Check 8: list_network_requests is mentioned
if [ -f "$FILE" ] && grep -q "list_network_requests" "$FILE"; then
  check "list_network_requests is mentioned" "ok"
else
  check "list_network_requests is mentioned" "fail"
fi

# Check 9: url_filter is NOT present (old parameter)
if [ -f "$FILE" ] && ! grep -q "url_filter" "$FILE"; then
  check "url_filter NOT present (old parameter absent)" "ok"
else
  check "url_filter NOT present (old parameter absent)" "fail"
fi

# Check 10: wait_for used for networkidle is NOT present
if [ -f "$FILE" ] && ! grep -q "networkidle" "$FILE"; then
  check "networkidle NOT present (obsolete wait pattern absent)" "ok"
else
  check "networkidle NOT present (obsolete wait pattern absent)" "fail"
fi

# Check 11: list_pages mentioned (for Chrome mode detection)
if [ -f "$FILE" ] && grep -q "list_pages" "$FILE"; then
  check "list_pages mentioned (Chrome mode detection)" "ok"
else
  check "list_pages mentioned (Chrome mode detection)" "fail"
fi

# Check 12: [CHROME-MODE:auto-connect] signal present
if [ -f "$FILE" ] && grep -q "\[CHROME-MODE:auto-connect\]" "$FILE"; then
  check "[CHROME-MODE:auto-connect] signal present" "ok"
else
  check "[CHROME-MODE:auto-connect] signal present" "fail"
fi

# Check 13: [CHROME-MODE:new-instance] signal present
if [ -f "$FILE" ] && grep -q "\[CHROME-MODE:new-instance\]" "$FILE"; then
  check "[CHROME-MODE:new-instance] signal present" "ok"
else
  check "[CHROME-MODE:new-instance] signal present" "fail"
fi

# Check 14: cmux browser + network requests pattern present
if [ -f "$FILE" ] && grep -q "cmux browser" "$FILE" && grep -q "network requests" "$FILE"; then
  check "cmux browser + network requests pattern present" "ok"
else
  check "cmux browser + network requests pattern present" "fail"
fi

# Check 15: har-reconstruct.py mentioned with --domain flag
if [ -f "$FILE" ] && grep -q "har-reconstruct.py" "$FILE" && grep -q "\--domain" "$FILE"; then
  check "har-reconstruct.py mentioned with --domain flag" "ok"
else
  check "har-reconstruct.py mentioned with --domain flag" "fail"
fi

echo "========================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
