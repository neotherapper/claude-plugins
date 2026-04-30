#!/usr/bin/env bash
# TLS fingerprinting using testssl.sh, sslyze, tls-scan
# Usage: TARGET=example.com ./tls_fingerprint.sh
set -euo pipefail

if [[ -z "${TARGET:-}" ]]; then
  echo "Error: TARGET environment variable not set" >&2
  exit 1
fi

if command -v testssl.sh >/dev/null 2>&1; then
  echo "=== testssl.sh ==="
  testssl.sh --fast "${TARGET}"
fi

if command -v sslyze >/dev/null 2>&1; then
  echo "=== sslyze ==="
  sslyze --regular "${TARGET}:443"
fi

if command -v tls-scan >/dev/null 2>&1; then
  echo "=== tls-scan ==="
  tls-scan "${TARGET}:443"
fi
