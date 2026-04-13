#!/usr/bin/env bash
# validate-schemas.sh — validates the schema files for Beacon
# Tests that schema files exist, are valid JSON, and contain required structural elements
# Usage: ./tests/validate-schemas.sh
# Exit code: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

PASS=0
FAIL=0

TECH_PACK_SCHEMA="plugins/beacon/schemas/tech-pack.schema.json"
OUTPUT_SCHEMA="plugins/beacon/schemas/output.schema.json"

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

echo "Validating Beacon schema files"
echo "========================================"

# Check 1: tech-pack.schema.json exists
if [ -f "$TECH_PACK_SCHEMA" ]; then
  check "tech-pack.schema.json exists" "ok"
else
  check "tech-pack.schema.json exists" "fail"
fi

# Check 2: output.schema.json exists
if [ -f "$OUTPUT_SCHEMA" ]; then
  check "output.schema.json exists" "ok"
else
  check "output.schema.json exists" "fail"
fi

# Check 3: tech-pack.schema.json is valid JSON
if [ -f "$TECH_PACK_SCHEMA" ] && python3 -m json.tool "$TECH_PACK_SCHEMA" > /dev/null 2>&1; then
  check "tech-pack.schema.json is valid JSON" "ok"
else
  check "tech-pack.schema.json is valid JSON" "fail"
fi

# Check 4: output.schema.json is valid JSON
if [ -f "$OUTPUT_SCHEMA" ] && python3 -m json.tool "$OUTPUT_SCHEMA" > /dev/null 2>&1; then
  check "output.schema.json is valid JSON" "ok"
else
  check "output.schema.json is valid JSON" "fail"
fi

# Check 5: tech-pack.schema.json contains all 10 required section names in enum
SECTIONS=(
  "1. Fingerprinting Signals"
  "2. Default API Surfaces"
  "3. Config / Constants Locations"
  "4. Auth Patterns"
  "5. JS Bundle Patterns"
  "6. Source Map Patterns"
  "7. Common Plugins & Extensions"
  "8. Known Public Data"
  "9. Probe Checklist"
  "10. Gotchas"
)

for section in "${SECTIONS[@]}"; do
  if [ -f "$TECH_PACK_SCHEMA" ] && grep -qF "\"$section\"" "$TECH_PACK_SCHEMA"; then
    check "tech-pack.schema.json contains section: $section" "ok"
  else
    check "tech-pack.schema.json contains section: $section" "fail"
  fi
done

# Check 6: tech-pack.schema.json documents required frontmatter field names
FRONTMATTER_FIELDS=("framework" "version" "last_updated" "author" "status")

for field in "${FRONTMATTER_FIELDS[@]}"; do
  if [ -f "$TECH_PACK_SCHEMA" ] && grep -q "\"$field\"" "$TECH_PACK_SCHEMA"; then
    check "tech-pack.schema.json documents frontmatter field: $field" "ok"
  else
    check "tech-pack.schema.json documents frontmatter field: $field" "fail"
  fi
done

echo "========================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
