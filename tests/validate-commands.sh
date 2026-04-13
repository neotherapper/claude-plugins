#!/usr/bin/env bash
# Validates structure and content of beacon slash command files.
# Exit 0 = all checks pass. Exit 1 = one or more checks failed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMMANDS_DIR="$REPO_ROOT/plugins/beacon/commands"
ANALYZE_FILE="$COMMANDS_DIR/beacon-analyze.md"
LOAD_FILE="$COMMANDS_DIR/beacon-load.md"

PASS=0
FAIL=0

check() {
  local label="$1"
  local result="$2"   # "pass" or "fail"
  if [ "$result" = "pass" ]; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

# ── beacon-analyze.md ────────────────────────────────────────────────────────

# 1. File exists
if [ -f "$ANALYZE_FILE" ]; then
  check "beacon-analyze.md exists" "pass"
else
  check "beacon-analyze.md does not exist" "fail"
fi

# 2. Frontmatter has name:
if [ -f "$ANALYZE_FILE" ] && grep -q '^name:' "$ANALYZE_FILE"; then
  check "beacon-analyze.md frontmatter contains name:" "pass"
else
  check "beacon-analyze.md frontmatter missing name:" "fail"
fi

# 3. Frontmatter has description:
if [ -f "$ANALYZE_FILE" ] && grep -q '^description:' "$ANALYZE_FILE"; then
  check "beacon-analyze.md frontmatter contains description:" "pass"
else
  check "beacon-analyze.md frontmatter missing description:" "fail"
fi

# 4. Body invokes site-recon
if [ -f "$ANALYZE_FILE" ] && grep -q 'site-recon' "$ANALYZE_FILE"; then
  check "beacon-analyze.md body references site-recon" "pass"
else
  check "beacon-analyze.md body does not reference site-recon" "fail"
fi

# ── beacon-load.md ───────────────────────────────────────────────────────────

# 5. File exists
if [ -f "$LOAD_FILE" ]; then
  check "beacon-load.md exists" "pass"
else
  check "beacon-load.md does not exist" "fail"
fi

# 6. Frontmatter has name:
if [ -f "$LOAD_FILE" ] && grep -q '^name:' "$LOAD_FILE"; then
  check "beacon-load.md frontmatter contains name:" "pass"
else
  check "beacon-load.md frontmatter missing name:" "fail"
fi

# 7. Frontmatter has description:
if [ -f "$LOAD_FILE" ] && grep -q '^description:' "$LOAD_FILE"; then
  check "beacon-load.md frontmatter contains description:" "pass"
else
  check "beacon-load.md frontmatter missing description:" "fail"
fi

# 8. Body invokes site-intel
if [ -f "$LOAD_FILE" ] && grep -q 'site-intel' "$LOAD_FILE"; then
  check "beacon-load.md body references site-intel" "pass"
else
  check "beacon-load.md body does not reference site-intel" "fail"
fi

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
