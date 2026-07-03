#!/usr/bin/env bash
#
# validate-slug-rule.sh — guard the canonical site-slug rule shared by the
# site-analysis plugins (beacon, reframe). Two checks:
#
#   1. DRIFT  — every copy of the slug one-liner committed in the repo must be
#               byte-identical to the canonical form. The rule is restated in
#               several docs + the reframe skill; if any copy diverges (as one
#               did in PR #26, where `www.` was stripped before lowercasing),
#               this fails.
#   2. CORRECT — the canonical rule must map a table of inputs (including the
#               edge cases that were historically buggy: uppercase WWW., mixed
#               case host, :port, path) to the expected slug.
#
#   bash tests/validate-slug-rule.sh
#
# Exit 0 = all good; exit 1 = drift or a wrong slug.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fails=0
red()   { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fails=$((fails+1)); }
green() { printf '  \033[32mok\033[0m    %s\n' "$1"; }

# The single canonical implementation. Keep this in lockstep with
# docs/SLUG_RULES.md — that doc is the human-facing source of truth.
slugify() {
  printf '%s' "$1" | tr 'A-Z' 'a-z' \
    | sed -E 's#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g'
}

# The exact sed program every copy must contain (single-quoted = fully literal,
# so the $ anchors are not expanded by the shell).
CANON_SED='s#^https?://##; s/^www\.//; s#/.*$##; s/:[0-9]+$//; s/\./-/g'

echo "Validating canonical slug rule..."
echo

# --- Check 1: no drift across committed copies ----------------------------
# A line is a slug-rule copy if it assigns a `SLUG` variable through
# `tr 'A-Z' 'a-z'` — that pairing is specific to the filesystem-safe slug used
# for `docs/sites/{slug}/`. Other lowercase-then-sed one-liners exist for
# unrelated purposes (e.g. beacon's Phase 9 `DOMAIN=` derivation, which feeds
# a live network target into curl/TARGET and must NOT strip `www.` or turn
# `.` into `-` — doing so would probe the wrong host or an unresolvable one);
# those are intentionally different rules and must not be flagged as drift.
# Scans .sh too (not just .md) — a prior gap let scaffold.sh ship its own
# undetected copy; this file is excluded since it's the checker, not a copy
# (its own slugify() reference implementation spans multiple lines).
copies=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  copies=$((copies+1))
  file="${line%%:*}"
  rest="${line#*:}"
  lineno="${rest%%:*}"
  if [[ "$line" != *"$CANON_SED"* ]]; then
    red "drifted slug copy at ${file}:${lineno} — does not match canonical sed"
  fi
done < <(git grep -n "SLUG=.*tr 'A-Z' 'a-z'" -- '*.md' '*.sh' ':!tests/validate-slug-rule.sh' 2>/dev/null || true)

if [ "$copies" -eq 0 ]; then
  red "found no slug-rule copies to check — did the grep pattern or file layout change?"
else
  green "checked ${copies} slug-rule copy/copies for drift"
fi

# --- Check 2: canonical rule produces the expected slugs -------------------
# input|expected
cases=(
  "https://www.example.com/|example-com"
  "https://api.example.com/v2|api-example-com"
  "http://example.com:8080|example-com"
  "https://Example.COM|example-com"
  "https://WWW.example.com|example-com"
  "https://EXAMPLE.com:443/path/x|example-com"
  "http://sub.Domain.CO.uk/page|sub-domain-co-uk"
)
for c in "${cases[@]}"; do
  in="${c%%|*}"; want="${c#*|}"
  got="$(slugify "$in")"
  if [ "$got" != "$want" ]; then
    red "slug('$in') = '$got', expected '$want'"
  fi
done
[ "$fails" -eq 0 ] && green "canonical rule correct on ${#cases[@]} cases (incl. WWW./mixed-case/:port/path)"

echo
if [ "$fails" -ne 0 ]; then
  echo "${fails} slug-rule error(s)"
  exit 1
fi
echo "0 slug-rule errors"
