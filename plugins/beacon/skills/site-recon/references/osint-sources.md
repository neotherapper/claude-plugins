# OSINT Sources — Phase 9 Reference

---

## Prerequisites

The following tools are used in the examples below. Install them as needed:

- `curl` (with support for `-f` and `--max-time`)
- `python3` (for JSON parsing)
- `jq` (optional for JSON processing)
- `testssl.sh`, `sslyze`, `tls-scan` (TLS fingerprinting)
- `dig`, `nslookup` (DNS queries)
- `openssl` (SMTP enumeration)
- `grep`, `head`, `timeout`

---

## Passive DNS Lookup (VirusTotal, DNSDB)

Leverage passive DNS services to uncover historical subdomains, DNS records, and infrastructure changes.

```bash
TARGET="example.com"

# VirusTotal (no API key for basic lookup)
curl -sf --max-time 10 "https://www.virustotal.com/ui/domain_reports/${TARGET}" \
  | python3 -c "
import sys, json
j = json.load(sys.stdin)
subs = j.get('data', {}).get('attributes', {}).get('subdomains', [])
for s in subs[:100]:
    print(s)
"

# DNSDB (requires API key)
if [ -n "${DNSDB_API_KEY}" ]; then
  curl -sf --max-time 10 "https://api.dnsdb.info/lookup/rrset/name/${TARGET}/ANY" \
    -H "X-API-Key: ${DNSDB_API_KEY}" \
    | jq -r '.[].rrname' | sort -u
fi
```

**What to look for:**
- Historical subdomains no longer active.
- A records indicating past hosting providers.
- TXT records that may contain verification tokens or configuration snippets.

---

## Wayback Machine CDX (Historical Crawl)

```bash
TARGET="example.com"

# All URLs ever crawled (deduplicated)
curl -sf --max-time 10 "http://web.archive.org/cdx/search/cdx?url=*.${TARGET}/*&output=json&fl=original&collapse=urlkey&limit=5000" \
  | python3 -c "import sys,json; [print(r[0]) for r in json.load(sys.stdin)[1:]]"

# API paths only (filter for /api/, /v1/, /v2/)
curl -sf --max-time 10 "http://web.archive.org/cdx/search/cdx?url=${TARGET}/api/*&output=json&fl=original,statuscode&collapse=urlkey" \
  | python3 -c "import sys,json; [print(r[0],r[1]) for r in json.load(sys.stdin)[1:]]"

# Filter for JSON responses (likely API endpoints)
curl -sf --max-time 10 "http://web.archive.org/cdx/search/cdx?url=*.${TARGET}/*&output=json&fl=original,mimetype&filter=mimetype:application/json&collapse=urlkey" \
  | python3 -c "import sys,json; [print(r[0]) for r in json.load(sys.stdin)[1:]]"
```

*(The rest of Wayback analysis sections remain unchanged; they already contain useful versioning logic.)*

---

## CommonCrawl CDX API

```bash
TARGET="example.com"
CC_INDEX="CC-MAIN-2024-51"

curl -sf --max-time 10 "https://index.commoncrawl.org/${CC_INDEX}-index?url=*.${TARGET}/*&output=json&fl=url,status&limit=1000" \
  | python3 -c "import sys; [print(l) for l in sys.stdin]"
```

**When to use:** When Wayback results are sparse or the site is newer — CommonCrawl often has broader recent coverage.

---

## crt.sh — Certificate Transparency

```bash
TARGET="example.com"

curl -sf --max-time 10 "https://crt.sh/?q=%.${TARGET}&output=json" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
names = set()
for cert in data:
    for name in cert.get('name_value','').split('\n'):
        names.add(name.strip().lstrip('*.'))
for n in sorted(names):
    print(n)
"
```

**What to look for:**
- `api.example.com` — dedicated API subdomain
- `admin.example.com` — admin panel
- `staging.example.com` / `dev.example.com` — staging environments
- `*.internal.example.com` — internal services

---

## SecurityTrails (DNS + infrastructure history)

```bash
TARGET="example.com"

if [ -n "${SECURITYTRAILS_API_KEY}" ]; then
  # Subdomains
  curl -sf --max-time 10 "https://api.securitytrails.com/v1/domain/${TARGET}/subdomains" \
    -H "apikey: ${SECURITYTRAILS_API_KEY}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); [print(s) for s in d.get('subdomains',[])]"

  # Historical DNS A records
  curl -sf --max-time 10 "https://api.securitytrails.com/v1/history/${TARGET}/dns/a" \
    -H "apikey: ${SECURITYTRAILS_API_KEY}"
fi
```

**When to use:** To understand infrastructure changes, CDN migrations, and historical IPs.

---

## Shodan (Internet‑scale scanning)

```bash
TARGET="example.com"

if [ -n "${SHODAN_API_KEY}" ]; then
  curl -sf --max-time 10 "https://api.shodan.io/shodan/host/search?key=${SHODAN_API_KEY}&query=hostname:${TARGET}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); [print(h.get('ip_str'), h.get('port'), h.get('product','')) for h in d.get('matches',[])]"
fi

# No key: use shodan.io in a browser manually.
```

**What to look for:** Exposed databases, admin panels, legacy services.

---

## TLS Fingerprinting (testssl.sh, sslyze, tls‑scan)

```bash
TARGET="example.com"

if which testssl.sh &>/dev/null; then
  testssl.sh --fast ${TARGET}
fi

if which sslyze &>/dev/null; then
  sslyze --regular ${TARGET}:443
fi

if which tls-scan &>/dev/null; then
  tls-scan ${TARGET}:443
fi
```

**What to look for:**
- Enabled TLS 1.0/1.1 or deprecated ciphers.
- Certificate chain anomalies (self‑signed, expired).
- Weak public‑key sizes.

---

## GraphQL Introspection Queries

```bash
TARGET="example.com"
ENDPOINT="https://${TARGET}/graphql"

curl -sf --max-time 10 -X POST "${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN_IF_NEEDED>" \
  -d '{"query":"{ __schema { types { name fields { name } } } }"}' \
  | jq .
```

**What to look for:** Types, queries, mutations, private fields, admin‑only operations.

---

## OpenAPI / Swagger Detection

```bash
TARGET="example.com"

# Common discovery paths
for path in "/swagger.json" "/swagger.yaml" "/openapi.json" "/openapi.yaml" "/v1/api-docs"; do
  url="https://${TARGET}${path}"
  status=$(curl -sf -o /dev/null -w "%{http_code}" "$url")
  if [ "$status" = "200" ]; then
    echo "FOUND: $url"
  fi
done

# GitHub search (manual or via API)
# Example dork: site:github.com "${TARGET}" "openapi" filetype:yaml
```

**What to look for:** Full endpoint listings, parameter schemas, auth flows, versioned docs.

---

## Configuration File Leakage (env, yaml, json, ini)

```bash
TARGET="example.com"

for file in .env config.yml settings.json .gitlab-ci.yml .github/workflows/*.yml; do
  url="https://${TARGET}/${file}"
  status=$(curl -sf -o /dev/null -w "%{http_code}" "$url")
  if [[ "$status" =~ ^2 ]]; then
    echo "PUBLIC CONFIG: $url"
    curl -sf "$url" | head -n 20
  fi
done
```

**What to look for:** API keys, DB credentials, internal service URLs, feature flags.

---

## SMTP Service Banner Enumeration

```bash
TARGET="example.com"

# Resolve MX records
mxhosts=$(dig +short MX ${TARGET} | awk '{print $2}' | tr -d '.')

for host in $mxhosts; do
  echo "--- ${host} ---"
  timeout 5 bash -c "echo -e 'QUIT\r\n' | openssl s_client -starttls smtp -connect ${host}:25 2>/dev/null | head -n 5"

done
```

**What to look for:** SMTP software/version, open‑relay indicators, TLS misconfigurations.

---

## robots.txt Analysis

```bash
TARGET_URL="https://example.com"

curl -sf "${TARGET_URL}/robots.txt" | while IFS= read -r line; do
  case "$line" in
    Disallow:*)
      path="${line#Disallow: }"
      echo "BLOCKED: $path"
      echo "$path" | grep -qE '^/api/|^/v[0-9]|^/admin/|^/internal/' && echo "  → potential API surface"
      ;;
    Sitemap:*)
      sitemap="${line#Sitemap: }"
      echo "SITEMAP: $sitemap"
      ;;
  esac
done
```

**Key signals:** `/api/*`, `/admin/*`, `/internal/*`, `/partner/*`.

---

## Sitemap.xml Mining

```bash
TARGET_URL="https://example.com"

curl -sf "${TARGET_URL}/sitemap.xml" \
  | grep -oP '(?<=<loc>)[^<]+' \
  | head -n 200

curl -sf "${TARGET_URL}/sitemap.xml" \
  | grep -oP '(?<=<loc>)[^<]+' \
  | sed 's|https\?://[^/]*/||' \
  | cut -d'/' -f1 \
  | sort | uniq -c | sort -rn
```

**What to extract:** URL path prefixes reveal site structure (e.g., `/products/`, `/blog/`, `/api/docs/`).

---

## JSON‑LD Structured Data Extraction

```bash
TARGET_URL="https://example.com"

curl -sf "${TARGET_URL}" \
  | python3 -c "
import sys, re, json
html = sys.stdin.read()
blocks = re.findall(r'<script[^>]+type=[\"\\\']application/ld\\+json[\"\\\'][^>]*>(.*?)</script>', html, re.DOTALL)
for b in blocks:
    try:
        d = json.loads(b.strip())
        print(json.dumps(d, indent=2))
    except:
        pass
"
```

**Schema types:** `Organization`, `WebSite`, `Product`, `LocalBusiness`, `BreadcrumbList`, `SearchAction`.
`SearchAction` objects directly reveal search API endpoints.

---

## theHarvester (email + subdomain enumeration)

```bash
if which theHarvester &>/dev/null; then
  theHarvester -d "${TARGET}" -b google,bing,crtsh -l 100 2>/dev/null
fi
```

**What it finds:** Emails, subdomains, and other reconnaissance data.

---

## Paste Site Search

```bash
TARGET="example.com"

# Google dorks (run in browser):
# site:pastebin.com "${TARGET}"
# site:gist.github.com "${TARGET}"
```

**What to look for:** Leaked API keys, credentials.

---

## Bug Bounty Scope Search

```bash
TARGET="example.com"

# In browser:
# site:hackerone.com "${TARGET}"
# site:bugcrowd.com "${TARGET}"
```

**What it reveals:** Documented in‑scope API endpoints and out‑of‑scope areas.

---
## Additional OSINT Techniques

- **Censys alternative queries** – Use Censys API to enumerate TLS certificates, services, and exposed ports.
  ```bash
  if [ -n "${CENSYS_API_ID}" ] && [ -n "${CENSYS_API_SECRET}" ]; then
    curl -sf --max-time 10 -u "${CENSYS_API_ID}:${CENSYS_API_SECRET}" "https://search.censys.io/api/v2/hosts/search?q=${TARGET}" | jq .
  fi
  ```

- **Netcraft Site Report** – Provides hosting history, technology stack, and phishing data.
  ```bash
  curl -sf --max-time 10 "https://siteinfo.netcraft.com/site/${TARGET}"
  ```

- **Cloudflare Radar (domain‑stats)** – Shows traffic trends and top‑level resolver usage.
  ```bash
  curl -sf --max-time 10 "https://radar.cloudflare.com/api/v1/domain/${TARGET}"
  ```

- **Public code search for hard‑coded secrets** – Expand GitHub dork to include configuration files.
  ```bash
  # Run in browser or via API:
  # site:github.com "${TARGET}" ("AWS_SECRET_ACCESS_KEY" OR "PRIVATE_KEY" OR "password")
  ```

- **Nmap service & script scans** – Quick network fingerprint without full port sweep.
  ```bash
  nmap -sV -p 80,443,22,25 --script=http-enum,ssl-cert,ssh-auth-methods "${TARGET}"
  ```

- **ZoomEye (alternative to Shodan)** – Search by hostname for exposed services.
  ```bash
  if [ -n "${ZOOMEYE_API_KEY}" ]; then
    curl -sf --max-time 10 "https://api.zoomeye.org/host/search?query=hostname:${TARGET}" -H "API-KEY: ${ZOOMEYE_API_KEY}" | jq .
  fi
  ```

- **VirusTotal file hash lookup** – Find files previously submitted that reference the domain.
  ```bash
  # Replace <HASH> with known file hash
  curl -sf --max-time 10 "https://www.virustotal.com/api/v3/files/<HASH>" -H "x-apikey: ${VT_API_KEY}"
  ```

**What to look for:** Persistent infrastructure artifacts, hidden admin panels, leaked keys in code, unusual service banners, historic traffic spikes, and any artifacts that map to the target’s attack surface.

---
## Subdomain Brute‑Force (Amass)

```bash
TARGET="example.com"
amass enum -d "${TARGET}" -src -ip -json amass_output.json
```

**What to look for:** Subdomains discovered via DNS brute‑force and OSINT sources, enumeration of IP ranges.

---
## Public Git Repository Discovery

```bash
TARGET="example.com"
# Search for exposed .git directories
curl -sf --max-time 10 "https://${TARGET}/.git/HEAD" && echo "Public .git repo exposed"
```

**What to look for:** Presence of `.git` directories, exposed commit history, configuration files.

---

## Cloud Infrastructure Enumeration

### Cloud Storage Discovery

```bash
TARGET="example.com"
TARGET_SLUG=$(echo "${TARGET}" | tr '.' '-')

# AWS S3 buckets
for pattern in "${TARGET_SLUG}" "${TARGET}" "${TARGET//./-}" "assets-${TARGET}" "${TARGET}-assets" "${TARGET}-media"; do
  curl -sf --max-time 5 "https://${pattern}.s3.amazonaws.com/" && echo "S3 bucket found: ${pattern}"
  curl -sf --max-time 5 "https://s3.amazonaws.com/${pattern}/" && echo "S3 bucket found (path style): ${pattern}"
done

# Azure Blob Storage
curl -sf --max-time 5 "https://${TARGET_SLUG}.blob.core.windows.net/" && echo "Azure Blob Storage found"
curl -sf --max-time 5 "https://${TARGET}.blob.core.windows.net/" && echo "Azure Blob Storage found"

# Google Cloud Storage
curl -sf --max-time 5 "https://storage.googleapis.com/${TARGET_SLUG}/" && echo "GCS bucket found"
curl -sf --max-time 5 "https://${TARGET}.storage.googleapis.com/" && echo "GCS bucket found"

# Cloudflare R2
curl -sf --max-time 5 "https://${TARGET_SLUG}.r2.cloudflarestorage.com/" && echo "Cloudflare R2 bucket found"
```

**What to look for:** Publicly accessible cloud storage buckets containing assets, backups, or sensitive data.

---

## Container & Orchestration Discovery

```bash
TARGET="example.com"

# Docker Registry API
curl -sf --max-time 5 "https://${TARGET}/v2/_catalog" && echo "Docker Registry API accessible"
curl -sf --max-time 5 "https://${TARGET}/v2/" && echo "Docker Registry v2 endpoint"

# Kubernetes API (common ports)
for port in 6443 8443 8080; do
  curl -k -sf --max-time 5 "https://${TARGET}:${port}/api/v1/namespaces" && echo "Kubernetes API found on port ${port}"
  curl -k -sf --max-time 5 "https://${TARGET}:${port}/apis/apps/v1/deployments" && echo "Kubernetes deployments endpoint on port ${port}"
done

# Container orchestration dashboards
for path in "/dashboard" "/kubernetes-dashboard" "/k8s-dashboard" "/rancher" "/portainer"; do
  curl -sf --max-time 5 "https://${TARGET}${path}" | grep -q "<title>" && echo "Container dashboard found at ${path}"
done
```

**What to look for:** Exposed container registries, Kubernetes API endpoints, and management dashboards.

---

## CI/CD Pipeline Enumeration

```bash
TARGET="example.com"

# GitHub Actions (via API if repository known)
# curl -sf --max-time 5 "https://api.github.com/repos/${ORG}/${REPO}/actions/workflows"

# GitLab CI
curl -sf --max-time 5 "https://${TARGET}/.gitlab-ci.yml" && echo "GitLab CI config found"
curl -sf --max-time 5 "https://gitlab.${TARGET}/.gitlab-ci.yml" && echo "GitLab CI config found on gitlab subdomain"

# Jenkins
curl -sf --max-time 5 "https://${TARGET}/jenkins/" | grep -q "Jenkins" && echo "Jenkins dashboard found"
curl -sf --max-time 5 "https://${TARGET}/jenkins/api/json" && echo "Jenkins API accessible"

# CircleCI, Travis CI configuration patterns
for file in ".circleci/config.yml" ".travis.yml" "azure-pipelines.yml" ".github/workflows/" ".gitlab/"; do
  curl -sf --max-time 5 "https://${TARGET}/${file}" && echo "CI/CD config found: ${file}"
done
```

**What to look for:** CI/CD configuration files, automation endpoints, and build pipeline access.

---

## Advanced API Documentation Discovery

```bash
TARGET="example.com"

# RAML (RESTful API Modeling Language)
curl -sf --max-time 5 "https://${TARGET}/api.raml" && echo "RAML spec found"
curl -sf --max-time 5 "https://${TARGET}/api/api.raml" && echo "RAML spec found"

# API Blueprint
curl -sf --max-time 5 "https://${TARGET}/api.apib" && echo "API Blueprint found"
curl -sf --max-time 5 "https://${TARGET}/docs/api.apib" && echo "API Blueprint found"

# GraphQL Playground/IDE endpoints
curl -sf --max-time 5 "https://${TARGET}/graphql" | grep -q "GraphQL" && echo "GraphQL endpoint found"
curl -sf --max-time 5 "https://${TARGET}/graphiql" | grep -q "GraphiQL" && echo "GraphiQL IDE found"
curl -sf --max-time 5 "https://${TARGET}/playground" | grep -q "GraphQL" && echo "GraphQL Playground found"

# Postman/Insomnia collections
for ext in "json" "yaml" "yml"; do
  curl -sf --max-time 5 "https://${TARGET}/postman-collection.${ext}" && echo "Postman collection found"
  curl -sf --max-time 5 "https://${TARGET}/insomnia-collection.${ext}" && echo "Insomnia collection found"
done
```

**What to look for:** Alternative API specification formats and interactive API exploration tools.

---

## Mobile App Analysis Techniques

```bash
# Mobile API endpoint patterns often include:
# - /api/v1/ (versioned APIs)
# - /mobile/ or /m/ prefixes
# - /app/ endpoints
# - Firebase Realtime Database endpoints
# - OneSignal push notification endpoints

TARGET="example.com"

# Common mobile API patterns
for path in "/api/v1/" "/mobile/" "/m/" "/app/"; do
  curl -sf --max-time 5 "https://${TARGET}${path}" && echo "Mobile API pattern found: ${path}"
done

# Firebase endpoints (common in mobile apps)
curl -sf --max-time 5 "https://${TARGET}.firebaseio.com/.json" && echo "Firebase Realtime Database found"
curl -sf --max-time 5 "https://${TARGET}-default-rtdb.firebaseio.com/.json" && echo "Firebase default database found"

# Mobile push notification services
curl -sf --max-time 5 "https://${TARGET}/onesignal/" | grep -q "OneSignal" && echo "OneSignal push service found"
curl -sf --max-time 5 "https://${TARGET}/push/" | grep -q "push" && echo "Push notification endpoint found"
```

**What to look for:** Mobile-optimized API endpoints, Firebase configurations, and push notification services.

---

## Modern Web Framework Analysis

```bash
TARGET="example.com"

# Next.js App Router (Next.js 13+)
curl -sf --max-time 5 "https://${TARGET}/_next/" | grep -q "next" && echo "Next.js detected"
curl -sf --max-time 5 "https://${TARGET}/api/" | grep -q "route" && echo "Next.js API routes possibly present"

# Vite/Rollup source maps
curl -sf --max-time 5 "https://${TARGET}/src/main.ts" && echo "Vite source file exposed"
curl -sf --max-time 5 "https://${TARGET}/dist/main.js.map" && echo "Source map exposed"
curl -sf --max-time 5 "https://${TARGET}/assets/index.*.js.map" && echo "Vite/Rollup source map exposed"

# WebAssembly modules
curl -sf --max-time 5 "https://${TARGET}/static/js/main.wasm" && echo "WebAssembly module found"
curl -sf --max-time 5 "https://${TARGET}/pkg/*.wasm" && echo "Rust WebAssembly module possibly found"

# Edge runtime detection (Cloudflare Workers, Vercel Edge)
curl -I --max-time 5 "https://${TARGET}" | grep -i "server" | grep -E "(workers|vercel|netlify|cloudflare)" && echo "Edge runtime detected"
```

**What to look for:** Modern framework artifacts, source maps, WebAssembly modules, and edge runtime indicators.

---

## CORS & CSP Header Analysis

`Content-Security-Policy` and `Access-Control-Allow-Origin` headers directly enumerate allowed API origins and internal domains — one of the highest-signal sources for API surface mapping.

> **CSP `connect-src` extraction runs inline in Phase 2** (`SKILL.md`) — that version also parses the `<meta>` CSP and captures `wss://` origins and ports. Use it as the single source; the CORS-across-paths probe below is complementary and not duplicated there.

```bash
TARGET="example.com"

# Check CORS headers across multiple paths (complements the Phase 2 CSP connect-src extraction)
for path in "/api" "/api/products" "/graphql" "/admin"; do
  curl -sI -H "Origin: https://example.com" "https://${TARGET}${path}" | \
    grep -i "access-control"
done
```

**What to look for:**
- `connect-src 'self' https://api.example.com https://*.akamaihd.net` — internal API domains and CDN origins
- `Access-Control-Allow-Origin: https://dashboard.example.com` — reveals admin/subdomain relationships
- CSP `frame-ancestors` reveals what can embed the site

---

## SPF/DKIM/DMARC Record Analysis

DNS TXT records for email authentication reveal all sending infrastructure (third-party email services, internal servers).

```bash
TARGET="example.com"

# SPF record — lists all authorized sending IPs/domains
dig +short TXT "${TARGET}" | grep "v=spf1"

# Check for includes that reveal third-party services
dig +short TXT "${TARGET}" | grep -oE "include:[^ ]+" | while read inc; do
  domain="${inc#include }"
  echo "SPF include: $domain"
  dig +short TXT "$domain" 2>/dev/null | head -3
done

# DMARC — reveals reporting address
dig +short TXT "_dmarc.${TARGET}"
```

**What to look for:**
- `v=spf1 include:_spf.google.com` → Google Workspace
- `v=spf1 include:servers.mcsv.net` → Mailchimp
- `v=spf1 include:amazonses.com` → AWS SES
- `v=spf1 include:sendgrid.net` → SendGrid
- DMARC `rua=mailto:dmarc-reports@example.com` → reporting address domain

---

## Favicon Hash Matching

Compute the mmh3 hash of `favicon.ico` and search Shodan to identify exact framework version and find related subdomains.

```bash
TARGET="example.com"

# Get favicon and compute mmh3 hash
curl -sf --max-time 10 "https://${TARGET}/favicon.ico" -o /tmp/favicon.ico
pip install mmh3 2>/dev/null || true
HASH=$(python3 -c "
import mmh3, sys
try:
    with open('/tmp/favicon.ico', 'rb') as f:
        print(mmh3.hash(f.read()))
except: print('error')
" 2>/dev/null)

echo "Favicon hash: ${HASH}"
echo "Search Shodan: https://www.shodan.io/search?query=icon_hash:${HASH}"
```

**What it reveals:**
- Framework/fingerprint from hash → exact version
- Same hash = same stack = shadow IT subdomains
- Also try: https:// favicon.io / https://api.faviconkit.com/{domain}

---

## GA/GTM ID Cross-Referencing

Google Analytics and Tag Manager IDs can be searched across the web to find sister domains, staging environments, and subdomains not in crt.sh.

```bash
TARGET="example.com"

# Extract GA4 (G-XXXXX) and UA-XXXXX IDs from page source
curl -sf --max-time 10 "https://${TARGET}" | grep -oE "G-[A-Z0-9]{10,}" | sort -u
curl -sf --max-time 10 "https://${TARGET}" | grep -oE "UA-[0-9]{7,}-[0-9]{1,}" | sort -u

# Extract GTM container ID
curl -sf --max-time 10 "https://${TARGET}" | grep -oE "GTM-[A-Z0-9]{4,7}" | sort -u
```

**Search strategies (run in browser):**
- `G-XXXXXXXXXX site:*` — find all sites with same GA4
- `UA-XXXXXX-X site:*` — find all sites with same UA
- `GTM-XXXXXX site:*` — find all sites with same GTM container
- GTM container ID → query GTM API to enumerate all tags (includes API endpoints used for analytics)

---

## Third-Party API Key Extraction from Page Source

Third-party API keys embedded in page/bundle source confirm integrations in use and reveal backend services.

> **The core key sweep — Stripe `pk_live_`, Google/Firebase `AIza`, Mapbox `pk.`, Sentry DSN — runs in Phase 9** (`SKILL.md`) over *all* JS bundles. The patterns below extend it with services the core sweep omits (reCAPTCHA, Algolia, Intercom); apply them to the homepage/bundle source when broader coverage is needed.

```bash
TARGET="example.com"

# reCAPTCHA site key
curl -sf "https://${TARGET}" | grep -oE "6L[A-Za-z0-9_-]{35,45}" | head -1

# Algolia application ID
curl -sf "https://${TARGET}" | grep -oE "appId['\"]?\s*:\s*['\"][A-Za-z0-9]{10,20}" | head -1

# Intercom app ID
curl -sf "https://${TARGET}" | grep -oE "app_id['\"]?\s*:\s*['\"][0-9]{5,10}" | head -1
```

**What it reveals:**
- Confirms third-party integrations in use
- Key prefixes identify the exact service
- Stripe `pk_live_` (see the Phase 9 sweep) = live payments enabled
- Key can be tested (not exploited) to confirm validity

---

## WAF Fingerprinting Expansion

Beyond Cloudflare and DataDome, detect additional WAFs that reveal infrastructure:

```bash
TARGET="example.com"

# Detect WAF from response headers
HEADERS=$(curl -sI "https://${TARGET}" 2>&1)

echo "$HEADERS" | grep -i "x-sucuri-id" && echo "→ Sucuri WAF"
echo "$HEADERS" | grep -i "x-iinfo" && echo "→ Imperva/Incapsula"
echo "$HEADERS" | grep -i "x-amzn-requestid" && echo "→ AWS WAF"
echo "$HEADERS" | grep -i "x-wa-info" && echo "→ F5 BIG-IP"
echo "$HEADERS" | grep -i "barra_counter_session" && echo "→ Barracuda"
echo "$HEADERS" | grep -i "server" | grep -i "ddos-guard" && echo "→ DDOS-Guard"
echo "$HEADERS" | grep -i "x-cdn" | grep -i "fastly" && echo "→ Fastly WAF"

# Detect from response body (block pages)
BODY=$(curl -sf --max-time 5 "https://${TARGET}/?waf-test=1" 2>&1)
echo "$BODY" | grep -i "cloudflare" && echo "→ Cloudflare"
echo "$BODY" | grep -i "datadome" && echo "→ DataDome"
echo "$BODY" | grep -i "perimeterx" && echo "→ PerimeterX"
echo "$BODY" | grep -i "incapsula" && echo "→ Imperva"
```

---

## Phase 9 Session Brief Format

Document all OSINT findings in the session brief under:

```markdown
### OSINT Findings

**CDX Sources:**
- Wayback CDX: {N} URLs found — notable patterns: {patterns}
- CommonCrawl: {N} URLs found / skipped (no recent index)

**Versioning Analysis (Wayback):**
- Historical endpoints: {N} — version patterns: {patterns}
- Deprecated endpoints still live: {list}

**Subdomains (crt.sh, DNSDumpster):**
- {subdomain} [{flag: STAGING‑ENV / API / ADMIN}]

**Passive DNS (VirusTotal, DNSDB):**
- Historical subdomains: {list}

**Infrastructure (ASN):**
- ASN: {number} — provider: {name}

**Live Capture (urlscan.io):**
- Recent scans: {N}
- Notable findings: {endpoint patterns}

**External References:**
- GitHub: {found/not found}
- Package registries: {NPM/PyPI packages}
- Bug bounty scope: {program URL if found}

**Structured Data:**
- JSON‑LD types: {list}
- Search endpoint: {url if found}

**DNS Records (Phase 9):**
- SPF includes: {third-party email services (Google, Mailchimp, SendGrid, etc.)}
- DMARC reporting: {reporting domain}
- DKIM selector: {if found}

**Third-Party Integrations (page source):**
- Stripe: {pk_live_ found / not found}
- reCAPTCHA: {site key found / not found}
- GA4/UA: {tracking IDs found}
- GTM: {container ID found}
- Other: {Algolia, Intercom, Mapbox, etc.}

**WAF Detection:**
- {WAF name} — signal: {header/body}

**Favicon:**
- Hash: {mmh3 hash}
- Framework match: {from Shodan search}
```

---

*All commands include `-f` and `--max-time` where appropriate to fail fast and avoid hangs. Adjust tool installation as needed.*
