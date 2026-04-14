#!/usr/bin/env bash
# validate-har-reconstruct.sh — validates har-reconstruct.py implementation
# Usage: ./tests/validate-har-reconstruct.sh
# Exit code: 0 = all checks passed, 1 = one or more checks failed
# This is a TDD RED validation script — expected to fail until har-reconstruct.py is fully implemented

set -euo pipefail

SCRIPT="plugins/beacon/scripts/core/har-reconstruct.py"
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"  # "ok" or "fail"
  if [ "$result" = "ok" ]; then
    echo "  PASS  $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "Validating har-reconstruct.py"
echo "========================================"

# Check 1: File exists
if [ -f "$SCRIPT" ]; then
  check "File exists: $SCRIPT" "ok"
else
  check "File exists: $SCRIPT" "fail"
fi

# Check 2: Python shebang on line 1
if [ -f "$SCRIPT" ] && head -1 "$SCRIPT" | grep -q "^#!/usr/bin/env python"; then
  check "Python shebang on line 1" "ok"
else
  check "Python shebang on line 1" "fail"
fi

# Check 3: --input flag present in --help output
if [ -f "$SCRIPT" ] && python3 "$SCRIPT" --help 2>/dev/null | grep -q "\-\-input"; then
  check "--input flag present in --help output" "ok"
else
  check "--input flag present in --help output" "fail"
fi

# Check 4: --output flag present in --help output
if [ -f "$SCRIPT" ] && python3 "$SCRIPT" --help 2>/dev/null | grep -q "\-\-output"; then
  check "--output flag present in --help output" "fail"
else
  check "--output flag present in --help output" "fail"
fi

# Check 5: --domain flag present in --help output
if [ -f "$SCRIPT" ] && python3 "$SCRIPT" --help 2>/dev/null | grep -q "\-\-domain"; then
  check "--domain flag present in --help output" "ok"
else
  check "--domain flag present in --help output" "fail"
fi

# Check 6: Chrome MCP fixture — script exits 0 with minimal JSON input
if [ -f "$SCRIPT" ]; then
  TEMP_DIR=$(mktemp -d)
  FIXTURE_INPUT="$TEMP_DIR/fixture.json"
  FIXTURE_OUTPUT="$TEMP_DIR/output.har"

  cat > "$FIXTURE_INPUT" << 'EOF'
[{"reqid": 1, "method": "GET", "url": "https://example.com/api/v1/users", "status": 200, "request_headers": {"Accept": "application/json"}, "response_headers": {"Content-Type": "application/json"}, "response_body": "{\"users\": []}"}]
EOF

  if python3 "$SCRIPT" --input "$FIXTURE_INPUT" --output "$FIXTURE_OUTPUT" 2>/dev/null; then
    check "Chrome MCP fixture: script exits 0 with minimal JSON input" "ok"
  else
    check "Chrome MCP fixture: script exits 0 with minimal JSON input" "fail"
  fi

  # Check 7: Output HAR file was created at --output path
  if [ -f "$FIXTURE_OUTPUT" ]; then
    check "Output HAR file was created at --output path" "ok"
  else
    check "Output HAR file was created at --output path" "fail"
  fi

  # Check 8: Output is valid JSON
  if [ -f "$FIXTURE_OUTPUT" ] && python3 -c "import json; json.load(open('$FIXTURE_OUTPUT'))" 2>/dev/null; then
    check "Output is valid JSON" "ok"
  else
    check "Output is valid JSON" "fail"
  fi

  # Check 9: log.version equals "1.2"
  if [ -f "$FIXTURE_OUTPUT" ]; then
    VERSION=$(python3 -c "import json; har = json.load(open('$FIXTURE_OUTPUT')); print(har.get('log', {}).get('version', ''))" 2>/dev/null || echo "")
    if [ "$VERSION" = "1.2" ]; then
      check "log.version equals \"1.2\"" "ok"
    else
      check "log.version equals \"1.2\" (got: $VERSION)" "fail"
    fi
  else
    check "log.version equals \"1.2\"" "fail"
  fi

  # Check 10: HAR has at least 1 entry
  if [ -f "$FIXTURE_OUTPUT" ]; then
    ENTRY_COUNT=$(python3 -c "import json; har = json.load(open('$FIXTURE_OUTPUT')); print(len(har.get('log', {}).get('entries', [])))" 2>/dev/null || echo "0")
    if [ "$ENTRY_COUNT" -ge 1 ]; then
      check "HAR has at least 1 entry (found: $ENTRY_COUNT)" "ok"
    else
      check "HAR has at least 1 entry (found: $ENTRY_COUNT)" "fail"
    fi
  else
    check "HAR has at least 1 entry (found: 0)" "fail"
  fi

  # Check 11: Entry has all required HAR 1.2 fields
  if [ -f "$FIXTURE_OUTPUT" ]; then
    REQUIRED_FIELDS=$(python3 << 'PYEOF'
import json
try:
    har = json.load(open('FIXTURE_OUTPUT'))
    entries = har.get('log', {}).get('entries', [])
    if not entries:
        print("no_entries")
    else:
        entry = entries[0]
        required = ['startedDateTime', 'time', 'cache', 'timings', 'request', 'response']
        missing = [f for f in required if f not in entry]
        if missing:
            print("missing:" + ",".join(missing))
        else:
            print("ok")
except Exception as e:
    print("error:" + str(e))
PYEOF
    )
    # Replace placeholder
    REQUIRED_FIELDS=$(python3 -c "
import json
try:
    har = json.load(open('$FIXTURE_OUTPUT'))
    entries = har.get('log', {}).get('entries', [])
    if not entries:
        print('no_entries')
    else:
        entry = entries[0]
        required = ['startedDateTime', 'time', 'cache', 'timings', 'request', 'response']
        missing = [f for f in required if f not in entry]
        if missing:
            print('missing:' + ','.join(missing))
        else:
            print('ok')
except Exception as e:
    print('error:' + str(e))
" 2>/dev/null || echo "error")

    if [ "$REQUIRED_FIELDS" = "ok" ]; then
      check "Entry has all required HAR 1.2 fields" "ok"
    else
      check "Entry has all required HAR 1.2 fields ($REQUIRED_FIELDS)" "fail"
    fi
  else
    check "Entry has all required HAR 1.2 fields" "fail"
  fi

  # Check 12: Analytics domain filtering — 2-entry fixture with --domain filter
  FIXTURE_MULTI="$TEMP_DIR/fixture-multi.json"
  FIXTURE_FILTERED="$TEMP_DIR/output-filtered.har"

  cat > "$FIXTURE_MULTI" << 'EOF'
[
  {"reqid": 1, "method": "GET", "url": "https://example.com/api/users", "status": 200, "request_headers": {"Accept": "application/json"}, "response_headers": {"Content-Type": "application/json"}, "response_body": "{\"users\": []}"},
  {"reqid": 2, "method": "POST", "url": "https://google-analytics.com/collect", "status": 204, "request_headers": {"Content-Type": "application/x-www-form-urlencoded"}, "response_headers": {"Server": "Google"}, "response_body": ""}
]
EOF

  if [ -f "$SCRIPT" ] && python3 "$SCRIPT" --input "$FIXTURE_MULTI" --output "$FIXTURE_FILTERED" --domain example.com 2>/dev/null; then
    if [ -f "$FIXTURE_FILTERED" ]; then
      FILTERED_ENTRY_COUNT=$(python3 -c "import json; har = json.load(open('$FIXTURE_FILTERED')); print(len(har.get('log', {}).get('entries', [])))" 2>/dev/null || echo "0")
      if [ "$FILTERED_ENTRY_COUNT" -eq 1 ]; then
        check "Analytics domain filtering: --domain example.com filters to exactly 1 entry" "ok"
      else
        check "Analytics domain filtering: --domain example.com filters to exactly 1 entry (got: $FILTERED_ENTRY_COUNT)" "fail"
      fi
    else
      check "Analytics domain filtering: --domain example.com filters to exactly 1 entry" "fail"
    fi
  else
    check "Analytics domain filtering: --domain example.com filters to exactly 1 entry" "fail"
  fi

  # Cleanup
  rm -rf "$TEMP_DIR"
else
  # Script doesn't exist, so checks 6-12 all fail
  check "Chrome MCP fixture: script exits 0 with minimal JSON input" "fail"
  check "Output HAR file was created at --output path" "fail"
  check "Output is valid JSON" "fail"
  check "log.version equals \"1.2\"" "fail"
  check "HAR has at least 1 entry (found: 0)" "fail"
  check "Entry has all required HAR 1.2 fields" "fail"
  check "Analytics domain filtering: --domain example.com filters to exactly 1 entry" "fail"
fi

echo "========================================"
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
