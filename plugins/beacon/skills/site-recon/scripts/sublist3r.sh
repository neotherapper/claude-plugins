#!/usr/bin/env bash
# Subdomain enumeration using Sublist3r (if installed)
# Usage: TARGET=example.com ./sublist3r.sh
set -euo pipefail

if [[ -z "${TARGET:-}" ]]; then
  echo "Error: TARGET env var not set" >&2
  exit 1
fi

if command -v sublist3r >/dev/null 2>&1; then
  echo "Running Sublist3r for ${TARGET}..."
  out="$(mktemp)"
  trap 'rm -f "$out"' EXIT
  sublist3r -d "${TARGET}" -o "$out"
  cat "$out"
else
  echo "sublist3r not installed – skipping subdomain enumeration"
fi
