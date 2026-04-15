# API Setup

Configure environment variables so namesmith can check domain availability and prices. The skill uses a 3-tier fallback: Cloudflare → Porkbun → whois.

## Tier 1: Cloudflare Registrar API (Recommended)

Best choice if you already have a Cloudflare account. Returns availability + at-cost price in a single batch call (up to 20 domains per request).

### Required environment variables

```bash
export CF_API_TOKEN="your-cloudflare-api-token"
export CF_ACCOUNT_ID="your-cloudflare-account-id"
```

### How to get these values

**CF_ACCOUNT_ID:**
1. Log in to dash.cloudflare.com
2. Select any domain (or go to the overview page)
3. Find Account ID in the right sidebar, or from the URL: `dash.cloudflare.com/{account_id}/...`

**CF_API_TOKEN:**
1. Go to dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use the "Edit zone DNS" template, or create a custom token with:
   - Permissions: `Zone > Domain > Read`, `Account > Registrar > Edit`
   - Account Resources: Include your account
4. Copy the token value (shown once)

### Verification

```bash
curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/registrar/domains" \
  -H "Authorization: Bearer $CF_API_TOKEN" | jq '.success'
```

Expected: `true`

---

## Tier 2: Porkbun API

Good fallback if you do not have a Cloudflare account. Free account required; API key is free.

### Required environment variables

```bash
export PORKBUN_API_KEY="pk1_your_api_key"
export PORKBUN_SECRET="sk1_your_secret_key"
```

### How to get these values

1. Create a free account at porkbun.com
2. Go to Account → API Access
3. Enable API access
4. Generate API key and secret key
5. Copy both values

### Verification

```bash
curl -s -X POST "https://api.porkbun.com/api/json/v3/ping" \
  -H "Content-Type: application/json" \
  -d "{\"apikey\":\"$PORKBUN_API_KEY\",\"secretapikey\":\"$PORKBUN_SECRET\"}" | jq '.status'
```

Expected: `"SUCCESS"`

### Note on Porkbun pricing

`get-prices.sh` uses the Porkbun pricing endpoint which requires NO authentication. Price lookups always work even without a Porkbun API key.

---

## Tier 3: whois + DNS fallback (no API key required)

When neither Cloudflare nor Porkbun credentials are set, the skill uses system `whois` and DNS queries.

### Requirements

`whois` must be installed:

```bash
# macOS
brew install whois

# Ubuntu/Debian
sudo apt-get install whois

# Check
whois --version
```

### Limitations of Tier 3

- No price information (returns `na` for price)
- Slower (one query per domain, no batching)
- Rate-limited by whois servers (some registrars block repeated queries)
- Redemption status detection is less reliable than API tiers

### When to use Tier 3

Use Tier 3 only to get started quickly. For production use with many domains, configure Tier 1 or Tier 2.

---

## Persisting credentials

Add to your shell profile for permanent setup:

```bash
# ~/.zshrc or ~/.bashrc
export CF_API_TOKEN="..."
export CF_ACCOUNT_ID="..."
# OR
export PORKBUN_API_KEY="..."
export PORKBUN_SECRET="..."
```

Then reload: `source ~/.zshrc`

Or use a `.env` file in your project and load it before starting Claude Code:

```bash
source .env && claude
```

---

## Priority order

The `check-domains.sh` script auto-detects which tier to use:

```
CF_API_TOKEN + CF_ACCOUNT_ID set? → Tier 1 (Cloudflare)
  ↓ no
PORKBUN_API_KEY + PORKBUN_SECRET set? → Tier 2 (Porkbun)
  ↓ no
whois available? → Tier 3 (whois + DNS)
  ↓ no
All checks return: unknown
```
