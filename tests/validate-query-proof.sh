#!/usr/bin/env bash
# validate-query-proof.sh — checks the Query Proof Scripts feature wiring.
set -euo pipefail
PASS=0; FAIL=0
check() {
  if [ "$2" = "ok" ]; then echo "  PASS  $1"; PASS=$((PASS+1))
  else echo "  FAIL  $1"; FAIL=$((FAIL+1)); fi
}

[ -x plugins/beacon/skills/site-intel/scripts/render_query.sh ] \
  && check "render_query.sh exists and executable" ok \
  || check "render_query.sh exists and executable" fail

[ -x plugins/beacon/skills/site-intel/scripts/test_render_query.sh ] \
  && check "test_render_query.sh exists and executable" ok \
  || check "test_render_query.sh exists and executable" fail

[ -f plugins/beacon/templates/query-templates.md ] \
  && check "query-templates.md fragment exists" ok \
  || check "query-templates.md fragment exists" fail

grep -q '^### First record$'          plugins/beacon/templates/query-templates.md \
  && check "fragment has ### First record" ok \
  || check "fragment has ### First record" fail

grep -q '^### Pagination$'            plugins/beacon/templates/query-templates.md \
  && check "fragment has ### Pagination" ok \
  || check "fragment has ### Pagination" fail

grep -q '^### Authed first record$'   plugins/beacon/templates/query-templates.md \
  && check "fragment has ### Authed first record" ok \
  || check "fragment has ### Authed first record" fail

grep -q '## Step 5'                plugins/beacon/skills/site-intel/SKILL.md \
  && check "site-intel SKILL.md mentions Step 5" ok \
  || check "site-intel SKILL.md mentions Step 5" fail

grep -q 'render_query.sh'          plugins/beacon/skills/site-intel/SKILL.md \
  && check "site-intel SKILL.md references render_query.sh" ok \
  || check "site-intel SKILL.md references render_query.sh" fail

echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
