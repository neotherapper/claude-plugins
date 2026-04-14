#!/usr/bin/env bash
# validate-output-synthesis.sh — validates output-synthesis.md has all 10 required content checks
# Usage: ./tests/validate-output-synthesis.sh
# Exit code: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

FILE="plugins/beacon/skills/site-recon/references/output-synthesis.md"
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

echo "Validating output-synthesis reference: $FILE"
echo "========================================"

# Check 1: File exists
if [ -f "$FILE" ]; then
  check "File exists: $FILE" "ok"
else
  check "File exists: $FILE" "fail"
fi

# Check 2: Has "What Phase 12 Reads" section
if [ -f "$FILE" ] && grep -q "What Phase 12 Reads" "$FILE"; then
  check "Has 'What Phase 12 Reads' section" "ok"
else
  check "Has 'What Phase 12 Reads' section" "fail"
fi

# Check 3: Has "Output Files" section
if [ -f "$FILE" ] && grep -q "## Output Files" "$FILE"; then
  check "Has '## Output Files' section" "ok"
else
  check "Has '## Output Files' section" "fail"
fi

# Check 4: Has "Token Resolution" section
if [ -f "$FILE" ] && grep -q "Token Resolution" "$FILE"; then
  check "Has 'Token Resolution' section" "ok"
else
  check "Has 'Token Resolution' section" "fail"
fi

# Check 5: OPENAPI_STATUS documented
if [ -f "$FILE" ] && grep -q "OPENAPI_STATUS" "$FILE"; then
  check "OPENAPI_STATUS documented" "ok"
else
  check "OPENAPI_STATUS documented" "fail"
fi

# Check 6: constants.md mentioned
if [ -f "$FILE" ] && grep -q "constants.md" "$FILE"; then
  check "constants.md mentioned" "ok"
else
  check "constants.md mentioned" "fail"
fi

# Check 7: smoke-test mentioned
if [ -f "$FILE" ] && grep -q "smoke-test" "$FILE"; then
  check "smoke-test mentioned" "ok"
else
  check "smoke-test mentioned" "fail"
fi

# Check 8: tech-stack.md mentioned
if [ -f "$FILE" ] && grep -q "tech-stack.md" "$FILE"; then
  check "tech-stack.md mentioned" "ok"
else
  check "tech-stack.md mentioned" "fail"
fi

# Check 9: site-map.md mentioned
if [ -f "$FILE" ] && grep -q "site-map.md" "$FILE"; then
  check "site-map.md mentioned" "ok"
else
  check "site-map.md mentioned" "fail"
fi

# Check 10: [PHASE-11-SKIPPED] resolution documented
if [ -f "$FILE" ] && grep -q "\[PHASE-11-SKIPPED\]" "$FILE"; then
  check "[PHASE-11-SKIPPED] resolution documented" "ok"
else
  check "[PHASE-11-SKIPPED] resolution documented" "fail"
fi

# Check 11: INDEX.md.template reference present
if [ -f "$FILE" ] && grep -q "INDEX.md.template" "$FILE"; then
  check "INDEX.md.template reference present" "ok"
else
  check "INDEX.md.template reference present" "fail"
fi

echo "========================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
