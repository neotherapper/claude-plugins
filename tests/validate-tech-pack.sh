#!/usr/bin/env bash
# validate-tech-pack.sh — validates a tech pack file has all 10 required sections
# Usage: ./tests/validate-tech-pack.sh <path-to-tech-pack.md>
# Exit code: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

FILE="${1:-plugins/beacon/technologies/wordpress/6.x.md}"
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

echo "Validating tech pack: $FILE"
echo "========================================"

# Check 1: File exists
if [ -f "$FILE" ]; then
  check "File exists: $FILE" "ok"
else
  check "File exists: $FILE" "fail"
fi

# Check 2: YAML frontmatter exists (opening --- on line 1)
if [ -f "$FILE" ] && head -1 "$FILE" | grep -q "^---$"; then
  check "YAML frontmatter exists (--- on line 1)" "ok"
else
  check "YAML frontmatter exists (--- on line 1)" "fail"
fi

# Check 3: Frontmatter has framework: field
if [ -f "$FILE" ] && grep -q "^framework:" "$FILE"; then
  check "Frontmatter has 'framework:' field" "ok"
else
  check "Frontmatter has 'framework:' field" "fail"
fi

# Check 4: Frontmatter has version: field
if [ -f "$FILE" ] && grep -q "^version:" "$FILE"; then
  check "Frontmatter has 'version:' field" "ok"
else
  check "Frontmatter has 'version:' field" "fail"
fi

# Check 5: Frontmatter has last_updated: field
if [ -f "$FILE" ] && grep -q "^last_updated:" "$FILE"; then
  check "Frontmatter has 'last_updated:' field" "ok"
else
  check "Frontmatter has 'last_updated:' field" "fail"
fi

# Check 6: Frontmatter has status: field
if [ -f "$FILE" ] && grep -q "^status:" "$FILE"; then
  check "Frontmatter has 'status:' field" "ok"
else
  check "Frontmatter has 'status:' field" "fail"
fi

# Check 7: Exactly 10 numbered H2 sections exist
if [ -f "$FILE" ]; then
  COUNT=$(grep -c "^## [0-9]\+\." "$FILE" || true)
  if [ "$COUNT" -eq 10 ]; then
    check "Exactly 10 numbered H2 sections (found: $COUNT)" "ok"
  else
    check "Exactly 10 numbered H2 sections (found: $COUNT)" "fail"
  fi
else
  check "Exactly 10 numbered H2 sections (found: 0)" "fail"
fi

# Check 8: Section "1. Fingerprinting Signals" present
if [ -f "$FILE" ] && grep -q "^## 1\. Fingerprinting Signals" "$FILE"; then
  check "Section '1. Fingerprinting Signals' present" "ok"
else
  check "Section '1. Fingerprinting Signals' present" "fail"
fi

# Check 9: Section "2. Default API Surfaces" present
if [ -f "$FILE" ] && grep -q "^## 2\. Default API Surfaces" "$FILE"; then
  check "Section '2. Default API Surfaces' present" "ok"
else
  check "Section '2. Default API Surfaces' present" "fail"
fi

# Check 10: Section "9. Probe Checklist" present
if [ -f "$FILE" ] && grep -q "^## 9\. Probe Checklist" "$FILE"; then
  check "Section '9. Probe Checklist' present" "ok"
else
  check "Section '9. Probe Checklist' present" "fail"
fi

# Check 11: Section "10. Gotchas" present
if [ -f "$FILE" ] && grep -q "^## 10\. Gotchas" "$FILE"; then
  check "Section '10. Gotchas' present" "ok"
else
  check "Section '10. Gotchas' present" "fail"
fi

# Check 12: At least 5 probe checklist items (lines matching ^- \[ \] after Probe Checklist heading)
if [ -f "$FILE" ]; then
  # Extract lines after "## 9. Probe Checklist" until the next ## heading
  PROBE_COUNT=$(awk '/^## 9\. Probe Checklist/{found=1; next} found && /^## /{exit} found && /^- \[ \]/{count++} END{print count+0}' "$FILE")
  if [ "$PROBE_COUNT" -ge 5 ]; then
    check "At least 5 probe checklist items in section 9 (found: $PROBE_COUNT)" "ok"
  else
    check "At least 5 probe checklist items in section 9 (found: $PROBE_COUNT)" "fail"
  fi
else
  check "At least 5 probe checklist items in section 9 (found: 0)" "fail"
fi

echo "========================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
