#!/usr/bin/env bash
# Passive DNS lookup – VirusTotal + DNSDB
# Usage: TARGET=example.com ./passive_dns.sh
set -euo pipefail

if [[ -z "${TARGET:-}" ]]; then
  echo "Error: TARGET environment variable not set" >&2
  exit 1
fi

echo "--- VirusTotal (no API key) ---"
curl -sf --max-time 10 "https://www.virustotal.com/ui/domain_reports/${TARGET}" \
  | python3 -c "import sys, json; j=json.load(sys.stdin); subs=j.get('data',{}).get('attributes',{}).get('subdomains',[]); print('\n'.join(subs[:100]))"

if [[ -n "${DNSDB_API_KEY:-}" ]]; then
  echo "--- DNSDB ---"
  curl -sf --max-time 10 "https://api.dnsdb.info/lookup/rrset/name/${TARGET}/ANY" \
    -H "X-API-Key: ${DNSDB_API_KEY}" \
    | jq -r '.[].rrname' | sort -u
else
  echo "DNSDB API key not set – skipping DNSDB lookup"
fi
