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
```

---

*All commands include `-f` and `--max-time` where appropriate to fail fast and avoid hangs. Adjust tool installation as needed.*
