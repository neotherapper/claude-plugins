#!/usr/bin/env bash
# GraphQL introspection query
# Usage: TARGET=example.com ./graphql_introspect.sh
set -euo pipefail

if [[ -z "${TARGET:-}" ]]; then
  echo "Error: TARGET environment variable not set" >&2
  exit 1
fi

ENDPOINT="https://${TARGET}/graphql"

curl -sf --max-time 10 -X POST "${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { types { name fields { name } } } }"}' \
  | jq .
