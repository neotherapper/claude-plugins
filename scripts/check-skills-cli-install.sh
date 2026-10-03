#!/usr/bin/env bash
#
# check-skills-cli-install.sh — end-to-end proof that a `skills` CLI *copy* of every skill works
# standalone. Installs all skills into a scratch project with `--copy` (what Pi, OpenCode, Cline,
# Kiro, Codex, ... users get), re-runs the portability checker against the copies, and smoke-tests
# the scripts and bundled resources from the copied folders only.
#
#   scripts/check-skills-cli-install.sh   # exit 1 if any check fails (all checks always print)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v npx >/dev/null 2>&1; then
  echo "FAIL  npx not found — install Node.js to run the skills CLI install check" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0
pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | tail -15 | sed 's/^/      /'; failures=$((failures + 1)); }
# check <label> <cmd...> : run, pass on exit 0, otherwise fail and show output
check() {
  local label="$1" out; shift
  if out="$("$@" 2>&1 </dev/null)"; then pass "$label"; else fail "$label" "$out"; fi
}

proj="$tmp/project"
mkdir -p "$proj" && (cd "$proj" && git init -q)

# NO_COLOR + </dev/null: GitHub Actions sets CI=true, which makes the CLI colourise / prompt.
echo "installing every skill with the skills CLI (--copy) ..."
if install_out="$(cd "$proj" && NO_COLOR=1 npx -y skills@latest add "$ROOT" --skill '*' -a universal --copy -y 2>&1 </dev/null)"; then
  pass "skills CLI install --copy"
else
  fail "skills CLI install --copy" "$install_out"
fi

S="$proj/.agents/skills"
if [ ! -d "$S" ] || [ -z "$(ls -A "$S" 2>/dev/null)" ]; then
  fail "installed skills present at .agents/skills" "$install_out"
  echo "$failures check(s) failed"; exit 1
fi
n_installed="$(find "$S" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
pass "installed $n_installed skill(s) at .agents/skills"

# Real copies, not symlinks back into the repo (a symlink would hide missing resources).
if find "$S" -mindepth 1 -maxdepth 1 -type l | grep -q .; then
  fail "installed skills are real copies" "$(find "$S" -mindepth 1 -maxdepth 1 -type l)"
else
  pass "installed skills are real copies (no symlinks)"
fi

check "portability checker against the copies" \
  python3 "$ROOT/scripts/check-skill-portability.py" --root "$S"

# --- smoke tests, run from the copies only ---------------------------------
check "aegis coverage.py --help" python3 "$S/site-security/scripts/coverage.py" --help

printf 'Book your appointment at our physiotherapy clinic. Opening hours and contact us.\n' > "$tmp/corpus.md"
cat > "$tmp/assert-category.py" <<'PY'
import json, sys
d = json.load(sys.stdin)
assert {"winner", "scores"} <= set(d), "missing keys in " + str(sorted(d))
assert d["winner"] == "local-service", "winner=" + str(d["winner"])
PY
if out="$(python3 "$S/site-redesign/scripts/detect-category.py" --categories "$S/site-redesign/categories" \
      --corpus "$tmp/corpus.md" 2>&1 </dev/null)" \
   && aout="$(printf '%s' "$out" | python3 "$tmp/assert-category.py" 2>&1)"; then
  pass "reframe detect-category.py picks local-service from copied category packs"
else
  fail "reframe detect-category.py from the copy" "${aout:-$out}"
fi

if out="$(cd "$tmp" && URL=https://example.com OUTPUT_ROOT="$tmp/out" bash "$S/site-recon/scripts/scaffold.sh" 2>&1 </dev/null)" \
   && [ -f "$tmp/out/INDEX.md" ]; then
  pass "beacon scaffold.sh renders templates from the copy (out/INDEX.md exists)"
else
  fail "beacon scaffold.sh from the copy" "$out"
fi

check "beacon har-reconstruct.py --help" python3 "$S/site-recon/scripts/har-reconstruct.py" --help

for f in evaluate/agents/scoring.md site-recon/technologies/REGISTRY.md; do
  if [ -f "$S/$f" ]; then pass "bundled resource present: $f"; else fail "bundled resource missing from the copy: $f"; fi
done

echo
if [ "$failures" -eq 0 ]; then echo "ok    every skill installs standalone and its smoke checks pass"; exit 0; fi
echo "$failures check(s) failed"; exit 1
