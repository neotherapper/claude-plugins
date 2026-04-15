#!/usr/bin/env bash
# check-domains.sh — 3-tier domain availability checker for namesmith
#
# Usage: check-domains.sh <domain1> [domain2] ... [domainN]
#
# Output (one line per domain):
#   available <domain> <price_usd>
#   taken     <domain> na
#   redemption <domain> na
#   unknown   <domain> na
#
# Env vars (optional):
#   CF_API_TOKEN + CF_ACCOUNT_ID  → Tier 1: Cloudflare Registrar API
#   PORKBUN_API_KEY + PORKBUN_SECRET → Tier 2: Porkbun API
#   (neither set) → Tier 3: whois + DNS
#
# Exit codes:
#   0 = at least one domain resolved
#   1 = all domains unknown
#   2 = no domains provided

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: check-domains.sh <domain1> [domain2] ..." >&2
  exit 2
fi

DOMAINS=("$@")

# ─────────────────────────────────────────────────────────
# Tier 1: Cloudflare Registrar API
# POST /accounts/{id}/registrar/domain-check (up to 20 per call)
# Returns: availability + at-cost price
# ─────────────────────────────────────────────────────────
check_cloudflare() {
  local domains=("$@")
  local batch_size=20
  local i=0
  local total=${#domains[@]}

  while [[ $i -lt $total ]]; do
    local batch=("${domains[@]:$i:$batch_size}")
    local json_array
    json_array=$(printf '%s\n' "${batch[@]}" | jq -R . | jq -s .)

    local response
    response=$(curl -s --max-time 15 -X POST \
      "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}/registrar/domain-check" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"domains\": ${json_array}}" 2>/dev/null) || true

    if echo "$response" | jq -e '.success == true' > /dev/null 2>&1; then
      echo "$response" | jq -r '.result[] | "\(.available | if . then "available" else "taken" end) \(.name) \(.price // "na")"'
    else
      # CF call failed — fall through to Tier 2 for these domains
      for domain in "${batch[@]}"; do
        echo "unknown $domain na"
      done
    fi

    i=$((i + batch_size))
  done
}

# ─────────────────────────────────────────────────────────
# Tier 2: Porkbun API
# POST /api/json/v3/domain/checkDomain/{domain}
# Returns: availability + price
# ─────────────────────────────────────────────────────────
check_porkbun() {
  local domain="$1"
  local response
  response=$(curl -s --max-time 15 -X POST \
    "https://api.porkbun.com/api/json/v3/domain/checkDomain/${domain}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg k "${PORKBUN_API_KEY}" --arg s "${PORKBUN_SECRET}" '{apikey: $k, secretapikey: $s}')" 2>/dev/null) || true

  local status
  status=$(echo "$response" | jq -r '.status // "ERROR"' 2>/dev/null)

  if [[ "$status" == "SUCCESS" ]]; then
    local avail
    avail=$(echo "$response" | jq -r '.avail // "no"' 2>/dev/null)
    local price
    price=$(echo "$response" | jq -r '.pricing.registration // "na"' 2>/dev/null)
    if [[ "$avail" == "yes" ]]; then
      echo "available $domain $price"
    else
      echo "taken $domain na"
    fi
  else
    echo "unknown $domain na"
  fi
}

# ─────────────────────────────────────────────────────────
# Tier 3: whois + DNS dual verification
# Uses whois for availability, DNS for redemption detection
# ─────────────────────────────────────────────────────────
check_whois() {
  local domain="$1"

  if ! command -v whois &>/dev/null; then
    echo "unknown $domain na"
    return
  fi

  local whois_output
  whois_output=$(whois "$domain" 2>/dev/null) || true

  # Redemption detection: domain expired but in grace period
  if echo "$whois_output" | grep -qiE "redemption period|pendingDelete|pending delete"; then
    echo "redemption $domain na"
    return
  fi

  # Check for "No match" or "NOT FOUND" patterns indicating availability
  if echo "$whois_output" | grep -qiE "^No match|NOT FOUND|No entries found|Domain not found|AVAILABLE"; then
    echo "available $domain na"
    return
  fi

  # Cross-verify with DNS: if whois shows registered but DNS fails, mark as redemption candidate
  if echo "$whois_output" | grep -qi "Domain Name:"; then
    # Registered — verify DNS resolves
    if command -v dig &>/dev/null; then
      local dns_result
      dns_result=$(dig +short "$domain" 2>/dev/null | head -1)
      if [[ -z "$dns_result" ]]; then
        # Registered but no DNS — likely expired/parked/redemption candidate
        echo "redemption $domain na"
      else
        echo "taken $domain na"
      fi
    else
      echo "taken $domain na"
    fi
    return
  fi

  echo "unknown $domain na"
}

# ─────────────────────────────────────────────────────────
# Main routing logic
# ─────────────────────────────────────────────────────────

all_unknown=true

if [[ -n "${CF_API_TOKEN:-}" && -n "${CF_ACCOUNT_ID:-}" ]]; then
  # Tier 1: Cloudflare (batch)
  results=$(check_cloudflare "${DOMAINS[@]}")
  echo "$results"
  if echo "$results" | grep -qv "^unknown"; then
    all_unknown=false
  fi

elif [[ -n "${PORKBUN_API_KEY:-}" && -n "${PORKBUN_SECRET:-}" ]]; then
  # Tier 2: Porkbun (per-domain)
  for domain in "${DOMAINS[@]}"; do
    result=$(check_porkbun "$domain")
    echo "$result"
    if [[ "$result" != unknown* ]]; then
      all_unknown=false
    fi
  done

else
  # Tier 3: whois fallback (per-domain)
  for domain in "${DOMAINS[@]}"; do
    result=$(check_whois "$domain")
    echo "$result"
    if [[ "$result" != unknown* ]]; then
      all_unknown=false
    fi
  done
fi

if [[ "$all_unknown" == "true" ]]; then
  exit 1
fi

exit 0
