#!/usr/bin/env bash
# Tests for okf-gate.sh Option A semantics: the gate is a silent no-op until
# INDEX.md claims status:complete; only then does it validate/block/release.
set -euo pipefail
HOOKS=$(cd "$(dirname "$0")" && pwd)
SCAF="$HOOKS/../skills/site-recon/scripts"

# ---- Case 1: draft INDEX (fresh scaffold) -> silent no-op, marker survives ----
T1=$(mktemp -d); cd "$T1"
OUTPUT_ROOT="$T1/out" URL="https://example.com" bash "$SCAF/scaffold.sh" >/dev/null
bash "$HOOKS/okf-gate.sh" || { echo "FAIL: case1 gate should no-op (exit 0) on draft INDEX"; exit 1; }
test -f "$T1/out/.beacon/recon-active.json" || { echo "FAIL: case1 marker deleted on draft no-op (must be left alone)"; exit 1; }
echo "case1 OK: draft INDEX -> no-op, marker preserved"

# ---- Case 2: complete + valid -> pass, marker deleted ----
T2=$(mktemp -d); cd "$T2"
mkdir -p "$T2/out/.beacon"
cat > "$T2/out/INDEX.md" <<'EOF'
---
type: site-index
title: "Example — Research Index"
resource: "https://example.com"
tags: []
timestamp: "2026-07-02T00:00:00Z"
status: complete
---

# Example — Research Index

Minimal valid complete bundle. No links, no unfilled tokens.
EOF
printf '{"output_root":"%s","retries":0}\n' "$T2/out" > "$T2/out/.beacon/recon-active.json"
python3 "$HOOKS/../skills/site-recon/scripts/okf_validate.py" "$T2/out" || { echo "FAIL: case2 fixture is not actually valid — fix the fixture"; exit 1; }
bash "$HOOKS/okf-gate.sh" || { echo "FAIL: case2 gate rejected a valid complete bundle"; exit 1; }
test -f "$T2/out/.beacon/recon-active.json" && { echo "FAIL: case2 marker not deleted on success"; exit 1; }
echo "case2 OK: complete+valid -> pass, marker deleted"

# ---- Case 2b: complete (QUOTED status) + valid -> pass, marker deleted ----
# Regression coverage for FIX 1: the gate's completion check must use the validator's
# quote-normalizing frontmatter parser, not a `grep '^status: complete$'` that misses
# `status: "complete"`.
T2B=$(mktemp -d); cd "$T2B"
mkdir -p "$T2B/out/.beacon"
cat > "$T2B/out/INDEX.md" <<'EOF'
---
type: site-index
title: "Example — Research Index"
resource: "https://example.com"
tags: []
timestamp: "2026-07-02T00:00:00Z"
status: "complete"
---

# Example — Research Index

Minimal valid complete bundle, quoted status. No links, no unfilled tokens.
EOF
printf '{"output_root":"%s","retries":0}\n' "$T2B/out" > "$T2B/out/.beacon/recon-active.json"
python3 "$HOOKS/../skills/site-recon/scripts/okf_validate.py" "$T2B/out" || { echo "FAIL: case2b fixture is not actually valid — fix the fixture"; exit 1; }
bash "$HOOKS/okf-gate.sh" || { echo "FAIL: case2b gate rejected a valid complete bundle with quoted status"; exit 1; }
test -f "$T2B/out/.beacon/recon-active.json" && { echo "FAIL: case2b marker not deleted (quoted status not recognised as complete)"; exit 1; }
echo "case2b OK: complete (quoted status)+valid -> pass, marker deleted"

# ---- Case 3: complete + invalid -> block, retries increment, then release ----
T3=$(mktemp -d); cd "$T3"
mkdir -p "$T3/out/.beacon"
# claim complete but leave an unfilled template token → invalid
printf -- '---\ntype: site-index\ntitle: X\nstatus: complete\n---\n{{FRAMEWORK}}\n' > "$T3/out/INDEX.md"
printf '{"output_root":"%s","retries":0}\n' "$T3/out" > "$T3/out/.beacon/recon-active.json"
if bash "$HOOKS/okf-gate.sh"; then echo "FAIL: case3 gate passed an invalid complete bundle"; exit 1; fi
test -f "$T3/out/.beacon/recon-active.json" || { echo "FAIL: case3 marker deleted on block (should be blocked, not consumed)"; exit 1; }
RETRIES=$(python3 -c "import json; print(json.load(open('$T3/out/.beacon/recon-active.json'))['retries'])")
[ "$RETRIES" -eq 1 ] || { echo "FAIL: case3 expected retries=1, got $RETRIES"; exit 1; }
# second block -> retries=2
bash "$HOOKS/okf-gate.sh" >/dev/null 2>&1 || true
RETRIES=$(python3 -c "import json; print(json.load(open('$T3/out/.beacon/recon-active.json'))['retries'])")
[ "$RETRIES" -eq 2 ] || { echo "FAIL: case3 expected retries=2 after second block, got $RETRIES"; exit 1; }
# third run: retries>=2 -> release with OKF-GATE-FAILED, exit 0, marker gone
if ! bash "$HOOKS/okf-gate.sh" 2>"$T3/okf-gate-failed.stderr"; then
  echo "FAIL: case3 gate should allow stop after retry cap exhausted"; exit 1
fi
grep -q 'OKF-GATE-FAILED' "$T3/okf-gate-failed.stderr" || { echo "FAIL: case3 no OKF-GATE-FAILED message"; exit 1; }
test -f "$T3/out/.beacon/recon-active.json" && { echo "FAIL: case3 marker not cleared after retry cap"; exit 1; }
echo "case3 OK: complete+invalid -> block (retries 1, 2), then release with OKF-GATE-FAILED"

# ---- Case 4: two concurrent recons under one cwd -> each marker evaluated
# independently, not just the first one `find` happens to return. Regression
# coverage for the unscoped `find | head -1` marker-discovery bug: site-a is
# complete+valid (should be cleaned up), site-b is still mid-run/draft (must
# be left untouched) — both must be handled correctly in the SAME gate run. ----
T4=$(mktemp -d); cd "$T4"
mkdir -p "$T4/site-a/research/.beacon" "$T4/site-b/research/.beacon"
cat > "$T4/site-a/research/INDEX.md" <<'EOF'
---
type: site-index
title: "Site A — Research Index"
resource: "https://a.example.com"
tags: []
timestamp: "2026-07-02T00:00:00Z"
status: complete
---

# Site A — Research Index

Minimal valid complete bundle. No links, no unfilled tokens.
EOF
printf '{"output_root":"%s","retries":0}\n' "$T4/site-a/research" > "$T4/site-a/research/.beacon/recon-active.json"
cat > "$T4/site-b/research/INDEX.md" <<'EOF'
---
type: site-index
title: "Site B — Research Index"
resource: "https://b.example.com"
tags: []
timestamp: "2026-07-02T00:00:00Z"
status: draft
---

# Site B — Research Index

Still mid-run.
EOF
printf '{"output_root":"%s","retries":0}\n' "$T4/site-b/research" > "$T4/site-b/research/.beacon/recon-active.json"
bash "$HOOKS/okf-gate.sh" || { echo "FAIL: case4 gate should not block (only site-a is complete, and it's valid)"; exit 1; }
test -f "$T4/site-a/research/.beacon/recon-active.json" && { echo "FAIL: case4 site-a (complete+valid) marker not deleted"; exit 1; }
test -f "$T4/site-b/research/.beacon/recon-active.json" || { echo "FAIL: case4 site-b (draft) marker deleted — must be left alone"; exit 1; }
echo "case4 OK: two concurrent recons -> each marker evaluated independently (complete+valid cleaned, draft untouched)"

# ---- Case 5: two concurrent recons, one complete+invalid -> gate blocks
# overall (exit 2) while STILL cleaning up the other, unrelated complete+valid
# bundle in the same run. ----
T5=$(mktemp -d); cd "$T5"
mkdir -p "$T5/site-a/research/.beacon" "$T5/site-c/research/.beacon"
cat > "$T5/site-a/research/INDEX.md" <<'EOF'
---
type: site-index
title: "Site A — Research Index"
resource: "https://a.example.com"
tags: []
timestamp: "2026-07-02T00:00:00Z"
status: complete
---

# Site A — Research Index

Minimal valid complete bundle. No links, no unfilled tokens.
EOF
printf '{"output_root":"%s","retries":0}\n' "$T5/site-a/research" > "$T5/site-a/research/.beacon/recon-active.json"
printf -- '---\ntype: site-index\ntitle: X\nstatus: complete\n---\n{{FRAMEWORK}}\n' > "$T5/site-c/research/INDEX.md"
printf '{"output_root":"%s","retries":0}\n' "$T5/site-c/research" > "$T5/site-c/research/.beacon/recon-active.json"
if bash "$HOOKS/okf-gate.sh"; then echo "FAIL: case5 gate should block — site-c is complete+invalid"; exit 1; fi
test -f "$T5/site-a/research/.beacon/recon-active.json" && { echo "FAIL: case5 site-a (complete+valid) marker not deleted despite site-c blocking"; exit 1; }
test -f "$T5/site-c/research/.beacon/recon-active.json" || { echo "FAIL: case5 site-c (complete+invalid) marker deleted — should be blocked, not consumed"; exit 1; }
echo "case5 OK: one recon blocks overall exit while an unrelated complete+valid recon still gets cleaned up"

# ---- hooks.json parses ----
python3 -c "import json; json.load(open('$HOOKS/hooks.json'))" || { echo "FAIL: hooks.json invalid JSON"; exit 1; }
echo "hooks.json OK: valid JSON"

echo OK
