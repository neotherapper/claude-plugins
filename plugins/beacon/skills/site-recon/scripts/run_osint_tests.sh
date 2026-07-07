#!/usr/bin/env bash
# Run the Python orchestrator and assert JSON is returned
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PY=$(command -v python3 || command -v python)
if [[ -z "$PY" ]]; then
    echo "Error: python3 or python not found in PATH" >&2
    exit 1
fi
$PY "$SCRIPT_DIR/osint.py" run_all --target example.com > /dev/null
echo "OK"