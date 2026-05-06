#!/usr/bin/env bash
# Config file leakage detection (publicly exposed files)
# Usage: TARGET=example.com ./config_leakage.sh
set -euo pipefail

if [[ -z "${TARGET:-}" ]]; then
  echo "Error: TARGET environment variable not set" >&2
  exit 1
fi

files=( .env config.yml settings.json .gitlab-ci.yml .github/workflows/*.yml )
for f in "${files[@]}"; do
  url="https://${TARGET}/${f}"
  status=$(curl -sf -o /dev/null -w "%{http_code}" "$url" || true)
  if [[ $status =~ ^2 ]]; then
    echo "PUBLIC CONFIG: $url"
    curl -sf "$url" | head -n 20
  fi
done
