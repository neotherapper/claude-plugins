#!/usr/bin/env bash
# start-server.sh — start the learn visual server
# Usage: ./start-server.sh --project-dir <path> [--port <n>] [--host <h>] [--foreground]
set -euo pipefail

PROJECT_DIR=""
PORT="7337"
HOST="127.0.0.1"
FOREGROUND=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    --port)        PORT="$2";        shift 2 ;;
    --host)        HOST="$2";        shift 2 ;;
    --foreground)  FOREGROUND=true;  shift   ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$PROJECT_DIR" ]]; then
  echo '{"error":"--project-dir is required"}' >&2
  exit 1
fi

BASE_DIR="$PROJECT_DIR/.learn/server"
SCREEN_DIR="$BASE_DIR/content"
STATE_DIR="$BASE_DIR/state"

mkdir -p "$SCREEN_DIR" "$STATE_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_server() {
  node "$SCRIPT_DIR/server.js" \
    --screen-dir "$SCREEN_DIR" \
    --state-dir  "$STATE_DIR"  \
    --port       "$PORT"       \
    --host       "$HOST"
}

if [[ "$FOREGROUND" == "true" ]] || [[ "${CODEX_CI:-}" == "1" ]]; then
  run_server
else
  run_server &
  SERVER_PID=$!
  trap 'kill "$SERVER_PID" 2>/dev/null' EXIT
  # Wait up to 5 seconds for server-info
  for i in $(seq 1 50); do
    if [[ -f "$STATE_DIR/server-info" ]]; then
      echo "$SERVER_PID" > "$STATE_DIR/server.pid"
      # Read server-info written by server.js, append pid
      SERVER_INFO=$(cat "$STATE_DIR/server-info")
      # Inject pid: strip trailing } and append ,"pid":<SERVER_PID>}
      echo "${SERVER_INFO%\}},\"pid\":$SERVER_PID}"
      trap - EXIT
      exit 0
    fi
    sleep 0.1
  done
  echo '{"error":"server did not start within 5 seconds"}' >&2
  exit 1
fi
