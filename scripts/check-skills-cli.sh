#!/usr/bin/env bash
#
# check-skills-cli.sh — prove that the universal `skills` CLI (npx skills add <repo>) discovers
# exactly the skills this repo ships, so `npx skills add neotherapper/claude-plugins` keeps working
# for every harness the CLI targets (Pi, OpenCode, Cline, Kiro, Codex, Cursor, ... 70+).
#
# Why a check and not prose: the install path in README.md is only true while the CLI's scanner
# still finds plugins/<plugin>/skills/<skill>/SKILL.md. A renamed folder, a broken frontmatter, or
# a CLI discovery change would silently drop a skill from every non-Claude harness.
#
#   scripts/check-skills-cli.sh   # exit 1 if the CLI's list != the canonical skill set
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v npx >/dev/null 2>&1; then
  echo "FAIL  npx not found — install Node.js to run the skills CLI check" >&2
  exit 1
fi

expected="$(python3 - "$ROOT" <<'PY'
import os, sys
root = sys.argv[1]
sys.path.insert(0, os.path.join(root, "scripts", "lib"))
from skill_frontmatter import discover_skills
skills, dupes = discover_skills(root)
for name in sorted(set(skills) - set(dupes)):
    print(name)
PY
)"

# `--list` prints one indented name line per skill ("│    site-recon") followed by its description.
raw="$(cd "$ROOT" && npx -y skills@latest add "$ROOT" --list 2>&1)" || {
  echo "FAIL  'npx skills add . --list' exited non-zero:" >&2
  echo "$raw" | tail -20 >&2
  exit 1
}
found="$(printf '%s\n' "$raw" | sed -n -E 's/^[│ ]*([a-z0-9][a-z0-9-]*)[[:space:]]*$/\1/p' | sort -u)"

missing="$(comm -23 <(printf '%s\n' "$expected") <(printf '%s\n' "$found"))"
extra="$(comm -13 <(printf '%s\n' "$expected") <(printf '%s\n' "$found"))"

n_exp="$(printf '%s\n' "$expected" | grep -c .)"
n_found="$(printf '%s\n' "$found" | grep -c .)"
echo "skills CLI discovered $n_found skill(s); repo ships $n_exp"

status=0
if [ -n "$missing" ]; then
  echo "FAIL  shipped but NOT discovered by the skills CLI:"; printf '      %s\n' $missing; status=1
fi
if [ -n "$extra" ]; then
  echo "FAIL  discovered by the skills CLI but not a canonical skill (duplicate exposure?):"; printf '      %s\n' $extra; status=1
fi
[ "$status" -eq 0 ] && echo "ok    every canonical skill is installable via 'npx skills add neotherapper/claude-plugins'"
exit "$status"
