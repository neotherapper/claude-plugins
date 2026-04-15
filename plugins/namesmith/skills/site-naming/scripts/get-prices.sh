#!/usr/bin/env bash
# get-prices.sh — Porkbun TLD pricing lookup for namesmith
#
# Usage: get-prices.sh <tld1> [tld2] ... [tldN]
#   TLDs can be provided with or without leading dot: "com" or ".com"
#
# Output (one line per TLD):
#   <tld> <registration_price_usd> <renewal_price_usd>
#   com 9.06 9.06
#   io 35.98 35.98
#   unknown_tld na na
#
# Auth: none required
# API: POST https://api.porkbun.com/api/json/v3/pricing/get
#
# Exit codes:
#   0 = at least one TLD priced
#   1 = all TLDs unknown
#   2 = no TLDs provided

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: get-prices.sh <tld1> [tld2] ..." >&2
  exit 2
fi

# Fetch the full pricing table once (no auth required)
PRICING_JSON=$(curl -s -X POST \
  "https://api.porkbun.com/api/json/v3/pricing/get" \
  -H "Content-Type: application/json" \
  -d '{}' 2>/dev/null) || true

if ! echo "$PRICING_JSON" | jq -e '.status == "SUCCESS"' > /dev/null 2>&1; then
  # API unavailable — output na for all requested TLDs
  for tld in "$@"; do
    tld="${tld#.}"  # strip leading dot if present
    echo "$tld na na"
  done
  exit 1
fi

all_unknown=true

for tld in "$@"; do
  tld="${tld#.}"  # strip leading dot if present

  reg_price=$(echo "$PRICING_JSON" | jq -r --arg tld "$tld" '.pricing[$tld].registration // "na"' 2>/dev/null)
  renew_price=$(echo "$PRICING_JSON" | jq -r --arg tld "$tld" '.pricing[$tld].renewal // "na"' 2>/dev/null)

  echo "$tld $reg_price $renew_price"

  if [[ "$reg_price" != "na" ]]; then
    all_unknown=false
  fi
done

if [[ "$all_unknown" == "true" ]]; then
  exit 1
fi

exit 0
