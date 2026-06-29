#!/usr/bin/env bash
#
# check-output-complete.sh — Deterministic verifier for reframe output completeness.
#
# After a reframe run, the output dir docs/sites/{slug}/redesign/ must contain six
# finalized Markdown files with NO unresolved {{TOKEN}} template placeholders left.
#
#   bash check-output-complete.sh <output-dir>
#
# where <output-dir> is a docs/sites/{slug}/redesign/ directory.
#
# Checks:
#   1. Each of the six expected files exists and is non-empty
#   2. No *.md file in the dir contains an unresolved {{...}} token
#   3. INDEX.md run log lists all phase markers [P1✓]–[P9✓] and a [PACK-LOADED:<cat>] (unless [GREENFIELD-MODE])
#
# Exit codes:
#   0 - All checks pass
#   1 - One or more checks fail
#   2 - Usage error (missing/invalid argument)
#
set -uo pipefail

# Color codes (matching validate-marketplace.sh)
RED='\033[31m'
GREEN='\033[32m'
RESET='\033[0m'

# Expected output files (top-level *.md only; .crawl/ is git-ignored)
EXPECTED_FILES=(
  "INDEX.md"
  "brief.md"
  "run-sheet.md"
  "content-inventory.md"
  "ia-map.md"
  "current-critique.md"
)

# Validate argument
if [[ $# -ne 1 ]]; then
  echo "Usage: bash check-output-complete.sh <output-dir>"
  echo ""
  echo "  <output-dir>  Path to docs/sites/{slug}/redesign/ directory"
  exit 2
fi

OUTPUT_DIR="$1"

# Check if argument is a directory
if [[ ! -d "$OUTPUT_DIR" ]]; then
  echo "Usage: bash check-output-complete.sh <output-dir>"
  echo ""
  echo "Error: <output-dir> is not a directory: $OUTPUT_DIR"
  exit 2
fi

# Track failures
FAILED=0

# Greenfield runs halt after writing only INDEX.md (SKILL.md Phase 3).
GREENFIELD=0
if [[ -f "$OUTPUT_DIR/INDEX.md" ]] && grep -q '\[GREENFIELD-MODE\]' "$OUTPUT_DIR/INDEX.md"; then
  GREENFIELD=1
fi

# Check 1: Each expected file exists and is non-empty
echo "Checking file completeness..."
for file in "${EXPECTED_FILES[@]}"; do
  filepath="$OUTPUT_DIR/$file"
  if [[ $GREENFIELD -eq 1 && "$file" != "INDEX.md" ]]; then
    printf "  ${GREEN}ok${RESET}    $file skipped (greenfield)\n"
    continue
  fi
  if [[ ! -f "$filepath" ]]; then
    printf "  ${RED}FAIL${RESET}  Missing: $file\n"; FAILED=1
  elif [[ ! -s "$filepath" ]]; then
    printf "  ${RED}FAIL${RESET}  Empty: $file\n"; FAILED=1
  else
    printf "  ${GREEN}ok${RESET}    $file exists and is non-empty\n"
  fi
done

# Check 2: No unresolved {{...}} tokens in any top-level *.md file
echo ""
echo "Checking for unresolved tokens..."
TOKENS_FOUND=0
while IFS= read -r -d '' md_file; do
  # Extract the filename relative to output dir for clearer error messages
  rel_file="${md_file#$OUTPUT_DIR/}"

  # Search for {{ patterns (grepping for unresolved tokens)
  if grep -q '{{' "$md_file"; then
    # Extract the actual tokens from this file
    unresolved=$(grep -o '{{[^}]*}}' "$md_file" | sort -u)
    printf "  ${RED}FAIL${RESET}  Unresolved tokens in $rel_file:\n"
    while IFS= read -r token; do
      printf "        $token\n"
    done <<< "$unresolved"
    FAILED=1
    TOKENS_FOUND=$((TOKENS_FOUND + 1))
  fi
done < <(find "$OUTPUT_DIR" -maxdepth 1 -name "*.md" -type f -print0)

if [[ $TOKENS_FOUND -eq 0 ]]; then
  # Count how many .md files we checked (excluding .crawl/)
  md_count=$(find "$OUTPUT_DIR" -maxdepth 1 -name "*.md" -type f | wc -l)
  printf "  ${GREEN}ok${RESET}    No unresolved tokens in $md_count file(s)\n"
fi

# Check 3: Run-log substance assertions in INDEX.md
echo ""
echo "Checking run-log (phase markers + pack)..."
INDEX="$OUTPUT_DIR/INDEX.md"
if [[ ! -f "$INDEX" ]]; then
  printf "  ${RED}FAIL${RESET}  INDEX.md missing — cannot verify run log\n"; FAILED=1
elif [[ $GREENFIELD -eq 1 ]]; then
  printf "  ${GREEN}ok${RESET}    greenfield halt recorded\n"
else
  for n in 1 2 3 4 5 6 7 8 9; do
    if ! grep -q "\[P${n}✓\]" "$INDEX"; then
      printf "  ${RED}FAIL${RESET}  Phase marker [P${n}✓] not found in INDEX.md run log\n"
      FAILED=1
    fi
  done
  if ! grep -q '\[PACK-LOADED:' "$INDEX"; then
    printf "  ${RED}FAIL${RESET}  No [PACK-LOADED:<cat>] in INDEX.md — category detection did not run\n"
    FAILED=1
  fi
  if [[ $FAILED -eq 0 ]]; then
    printf "  ${GREEN}ok${RESET}    all phase markers + pack present\n"
  fi
fi

# Summary
echo ""
if [[ $FAILED -eq 0 ]]; then
  echo "${GREEN}✓ All checks passed${RESET}"
  exit 0
else
  echo "${RED}✗ One or more checks failed${RESET}"
  exit 1
fi
