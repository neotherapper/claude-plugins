#!/usr/bin/env bash
#
# validate-reframe-helpers.sh — contract smoke test for reframe's helper scripts.
#
# Runs each helper *the exact way SKILL.md invokes it* and asserts the CLI
# contract the skill depends on: the documented JSON keys, the documented exit
# codes, and one behavior sanity per script. This guards the WIRING — if a
# refactor renamed a JSON key (e.g. `winner` -> `category`) or changed an exit
# code, the per-function unit tests under scripts/ could still pass while the
# skill's instructions silently broke. This catches that.
#
#   bash tests/validate-reframe-helpers.sh
#
# (The per-function unit tests test_*.py stay in the repo for local dev.)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SCRIPTS="plugins/reframe/skills/site-redesign/scripts"
CATS="plugins/reframe/categories"

fails=0
red()   { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fails=$((fails+1)); }
green() { printf '  \033[32mok\033[0m    %s\n' "$1"; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Reframe helper contract smoke test..."
echo

# --- 1. coverage-metrics.py: CLI, JSON keys, gate behavior ----------------
printf '<div id="root"></div>\n' > "$tmp/shell.md"
if python3 "$SCRIPTS/coverage-metrics.py" "$tmp/shell.md" > "$tmp/cov.json" 2>/dev/null \
   && python3 - "$tmp/cov.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
need = {"body_text_chars", "nav_link_count", "unique_headings", "non_nav_prose_words", "signals"}
missing = need - set(d)
assert not missing, f"missing keys: {missing}"
assert isinstance(d["signals"], list), "signals must be a list"
assert "[RENDER-ESCALATED]" in d["signals"], "empty shell must fire [RENDER-ESCALATED]"
PY
then green "coverage-metrics.py: JSON contract + render gate on empty shell (file arg)"
else red "coverage-metrics.py: contract/behavior check failed (file arg)"; fi

# --stdin path + opposite behavior (rich page -> no signals)
rich="$(python3 -c "print('# Home\n## Services\nWe provide physiotherapy and rehabilitation care. '+'word '*80+'\n[Book](/book) [Contact](/contact) [About](/about)')")"
if printf '%s\n' "$rich" | python3 "$SCRIPTS/coverage-metrics.py" --stdin > "$tmp/cov2.json" 2>/dev/null \
   && python3 - "$tmp/cov2.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert d["signals"] == [], f"rich page should fire no signals, got {d['signals']}"
PY
then green "coverage-metrics.py: --stdin path, rich page fires no gate"
else red "coverage-metrics.py: --stdin / rich-page check failed"; fi

# --- 2. detect-category.py: CLI, JSON keys, winner selection --------------
printf 'Book your appointment at our physiotherapy clinic. Opening hours and contact us.\n' > "$tmp/clinic.md"
if python3 "$SCRIPTS/detect-category.py" --categories "$CATS" --corpus "$tmp/clinic.md" > "$tmp/cat.json" 2>/dev/null \
   && python3 - "$tmp/cat.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
need = {"winner", "scores", "tie", "tied"}
missing = need - set(d)
assert not missing, f"missing keys: {missing}"
assert isinstance(d["scores"], dict), "scores must be an object"
assert d["winner"] == "local-service", f"clinic corpus should win local-service, got {d['winner']}"
PY
then green "detect-category.py: JSON contract + dominant pick on real packs"
else red "detect-category.py: contract/behavior check failed"; fi

# zero-match corpus -> generic fallback (contract)
printf 'lorem ipsum dolor sit amet consectetur adipiscing elit.\n' > "$tmp/noise.md"
if python3 "$SCRIPTS/detect-category.py" --categories "$CATS" --corpus "$tmp/noise.md" > "$tmp/cat2.json" 2>/dev/null \
   && python3 - "$tmp/cat2.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert d["winner"] == "generic", f"zero-match corpus must fall back to generic, got {d['winner']}"
PY
then green "detect-category.py: zero-match corpus falls back to generic"
else red "detect-category.py: generic-fallback check failed"; fi

# --- 3. check-output-complete.sh: exit codes -----------------------------
good="$tmp/good"; mkdir -p "$good"
for f in INDEX brief run-sheet content-inventory ia-map current-critique; do
  printf '# %s\nresolved content, no tokens.\n' "$f" > "$good/$f.md"
done
# INDEX.md must carry the run log the substance gate (Check 3) asserts:
# every phase marker [P1✓]–[P9✓] plus a [PACK-LOADED:<cat>] token.
{
  printf '\n## Run log\n'
  printf '**Phase markers:** [P1✓] [P2✓] [P3✓] [P4✓] [P5✓] [P6✓] [P7✓] [P8✓] [P9✓]\n'
  printf '**Signals fired:** [PACK-LOADED:local-service]\n'
} >> "$good/INDEX.md"
if bash "$SCRIPTS/check-output-complete.sh" "$good" >/dev/null 2>&1
then green "check-output-complete.sh: exit 0 on complete output dir"
else red "check-output-complete.sh: should exit 0 on a complete dir"; fi

printf '\n{{LEFTOVER}}\n' >> "$good/brief.md"
if bash "$SCRIPTS/check-output-complete.sh" "$good" >/dev/null 2>&1
then red "check-output-complete.sh: should exit non-zero when a {{token}} remains"
else green "check-output-complete.sh: non-zero exit on leftover {{token}}"; fi

echo
if [ "$fails" -ne 0 ]; then
  echo "${fails} reframe-helper contract error(s)"
  exit 1
fi
echo "0 reframe-helper contract errors"
