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
  local result="$2"   # "true" or "false"
  if [ "$result" = "true" ]; then
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
  ANALYZE_EXISTS=true
  check "beacon-analyze.md exists" true
else
  ANALYZE_EXISTS=false
  check "beacon-analyze.md exists" false
fi

if $ANALYZE_EXISTS; then
  # 2. Opening frontmatter fence at line 1
  head -1 "$ANALYZE_FILE" | grep -q '^---$' && check "beacon-analyze.md has opening frontmatter fence" true || check "beacon-analyze.md has opening frontmatter fence" false

  # 3. Frontmatter has name: (position-aware: inside first frontmatter block)
  awk '/^---/{f++} f==1 && /^name:/{found=1} END{exit !found}' "$ANALYZE_FILE" && check "beacon-analyze.md frontmatter contains name:" true || check "beacon-analyze.md frontmatter contains name:" false

  # 4. Exact name value
  grep -q '^name: beacon:analyze$' "$ANALYZE_FILE" && check "beacon-analyze.md name is beacon:analyze" true || check "beacon-analyze.md name is beacon:analyze" false

  # 5. Frontmatter has description: (position-aware)
  awk '/^---/{f++} f==1 && /^description:/{found=1} END{exit !found}' "$ANALYZE_FILE" && check "beacon-analyze.md frontmatter contains description:" true || check "beacon-analyze.md frontmatter contains description:" false

  # 6. Body invokes site-recon
  grep -q 'site-recon' "$ANALYZE_FILE" && check "beacon-analyze.md body references site-recon" true || check "beacon-analyze.md body does not reference site-recon" false
else
  echo "SKIP: content checks for beacon-analyze.md (file missing)"
fi

# ── beacon-load.md ───────────────────────────────────────────────────────────

# 7. File exists
if [ -f "$LOAD_FILE" ]; then
  LOAD_EXISTS=true
  check "beacon-load.md exists" true
else
  LOAD_EXISTS=false
  check "beacon-load.md exists" false
fi

if $LOAD_EXISTS; then
  # 8. Opening frontmatter fence at line 1
  head -1 "$LOAD_FILE" | grep -q '^---$' && check "beacon-load.md has opening frontmatter fence" true || check "beacon-load.md has opening frontmatter fence" false

  # 9. Frontmatter has name: (position-aware)
  awk '/^---/{f++} f==1 && /^name:/{found=1} END{exit !found}' "$LOAD_FILE" && check "beacon-load.md frontmatter contains name:" true || check "beacon-load.md frontmatter contains name:" false

  # 10. Exact name value
  grep -q '^name: beacon:load$' "$LOAD_FILE" && check "beacon-load.md name is beacon:load" true || check "beacon-load.md name is beacon:load" false

  # 11. Frontmatter has description: (position-aware)
  awk '/^---/{f++} f==1 && /^description:/{found=1} END{exit !found}' "$LOAD_FILE" && check "beacon-load.md frontmatter contains description:" true || check "beacon-load.md frontmatter contains description:" false

  # 12. Body invokes site-intel
  grep -q 'site-intel' "$LOAD_FILE" && check "beacon-load.md body references site-intel" true || check "beacon-load.md body does not reference site-intel" false
else
  echo "SKIP: content checks for beacon-load.md (file missing)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
