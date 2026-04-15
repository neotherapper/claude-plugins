#!/usr/bin/env bash
# validate-site-intel.sh — validates site-intel SKILL.md structure and tech pack cross-reference logic
# Usage: ./tests/validate-site-intel.sh
# Exit code: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

SKILL_FILE="plugins/beacon/skills/site-intel/SKILL.md"
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

echo "Validating site-intel skill: $SKILL_FILE"
echo "========================================"

# Check 1: SKILL.md exists
if [ -f "$SKILL_FILE" ]; then
  check "SKILL.md exists" "ok"
else
  check "SKILL.md exists" "fail"
fi

# Check 2: version is 0.6.0
if [ -f "$SKILL_FILE" ] && grep -q 'version: 0.6.0' "$SKILL_FILE"; then
  check "version is 0.6.0" "ok"
else
  check "version is 0.6.0" "fail"
fi

# Check 3: Step 1 (folder discovery) present
if [ -f "$SKILL_FILE" ] && grep -q 'docs/research/' "$SKILL_FILE"; then
  check "Step 1: folder discovery present" "ok"
else
  check "Step 1: folder discovery present" "fail"
fi

# Check 4: Step 2 (INDEX.md first) present
if [ -f "$SKILL_FILE" ] && grep -q 'INDEX.md' "$SKILL_FILE"; then
  check "Step 2: INDEX.md first-read present" "ok"
else
  check "Step 2: INDEX.md first-read present" "fail"
fi

# Check 5: routing table covers tech-stack.md
if [ -f "$SKILL_FILE" ] && grep -q 'tech-stack.md' "$SKILL_FILE"; then
  check "Routing table: tech-stack.md covered" "ok"
else
  check "Routing table: tech-stack.md covered" "fail"
fi

# Check 6: routing table covers api-surfaces/
if [ -f "$SKILL_FILE" ] && grep -q 'api-surfaces/' "$SKILL_FILE"; then
  check "Routing table: api-surfaces/ covered" "ok"
else
  check "Routing table: api-surfaces/ covered" "fail"
fi

# Check 7: routing table covers specs/
if [ -f "$SKILL_FILE" ] && grep -q 'specs/' "$SKILL_FILE"; then
  check "Routing table: specs/ covered" "ok"
else
  check "Routing table: specs/ covered" "fail"
fi

# Check 8: routing table covers scripts/
if [ -f "$SKILL_FILE" ] && grep -q 'scripts/' "$SKILL_FILE"; then
  check "Routing table: scripts/ covered" "ok"
else
  check "Routing table: scripts/ covered" "fail"
fi

# Check 9: tech pack cross-reference step present (references technologies/ directory)
if [ -f "$SKILL_FILE" ] && grep -q 'technologies/' "$SKILL_FILE"; then
  check "Tech pack cross-reference: technologies/ directory referenced" "ok"
else
  check "Tech pack cross-reference: technologies/ directory referenced" "fail"
fi

# Check 10: tech pack trigger heuristics present (anchored to Step 3a unique phrase)
if [ -f "$SKILL_FILE" ] && grep -q 'Load the tech pack when' "$SKILL_FILE"; then
  check "Tech pack trigger heuristics present" "ok"
else
  check "Tech pack trigger heuristics present" "fail"
fi

# Check 11: framework detection from tech-stack/INDEX mentioned (anchored to Step 3a unique phrase)
if [ -f "$SKILL_FILE" ] && grep -q 'Read the framework name and major version' "$SKILL_FILE"; then
  check "Framework detection from tech-stack/INDEX mentioned" "ok"
else
  check "Framework detection from tech-stack/INDEX mentioned" "fail"
fi

# Check 12: "do not guess" or "only report" guard present
if [ -f "$SKILL_FILE" ] && grep -qiE 'do not guess|only report|not.*fabricate' "$SKILL_FILE"; then
  check "Do-not-guess guard present" "ok"
else
  check "Do-not-guess guard present" "fail"
fi

echo "========================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
