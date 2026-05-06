#!/usr/bin/env bash
# OpenAPI / Swagger detection (common endpoints)
# Usage: TARGET=example.com ./openapi_detect.sh
set -euo pipefail

if [[ -z "${TARGET:-}" ]]; then
  echo "Error: TARGET environment variable not set" >&2
  exit 1
fi

for path in "/swagger.json" "/swagger.yaml" "/openapi.json" "/openapi.yaml" "/v1/api-docs"; do
  url="https://${TARGET}${path}"
  status=$(curl -sf -o /dev/null -w "%{http_code}" "$url")
  if [[ "$status" == "200" ]]; then
    echo "FOUND: $url"
  fi
done
