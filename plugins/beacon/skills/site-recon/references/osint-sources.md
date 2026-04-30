# OSINT Sources — Phase 9 Reference


---

## Passive DNS Lookup (VirusTotal, DNSDB)

Leverage passive DNS services to uncover historical subdomains, DNS records, and infrastructure changes.

```bash
TARGET="example.com"

<<<<<<< HEAD
# All URLs ever crawled (deduplicated)
curl -s "http://web.archive.org/cdx/search/cdx?url=*.${TARGET}/*&output=json&fl=original&collapse=urlkey&limit=5000" \
  | python3 -c "import sys,json; [print(r[0]) for r in json.load(sys.stdin)[1:]]"

# API paths only (filter for /api/, /v1/, /v2/)
curl -s "http://web.archive.org/cdx/search/cdx?url=${TARGET}/api/*&output=json&fl=original,statuscode&collapse=urlkey" \
  | python3 -c "import sys,json; [print(r[0],r[1]) for r in json.load(sys.stdin)[1:]]"

# Filter for JSON responses (likely API endpoints)
curl -s "http://web.archive.org/cdx/search/cdx?url=*.${TARGET}/*&output=json&fl=original,mimetype&filter=mimetype:application/json&collapse=urlkey" \
  | python3 -c "import sys,json; [print(r[0]) for r in json.load(sys.stdin)[1:]]"
```

---

## Wayback Machine Versioning Analysis

Track API endpoint evolution over time by filtering CDX results by timestamp. Reveals deprecated endpoints that may still be accessible, versioned API paths, and historical authentication patterns.

```bash
TARGET="example.com"

# Get API endpoints by year — reveals versioning history
for YEAR in 2022 2023 2024 2025 2026; do
  echo "=== ${YEAR} ==="
  curl -s "http://web.archive.org/cdx/search/cdx?url=*.${TARGET}/api/*&output=json&fl=original,timestamp&from=${YEAR}0101&to=${YEAR}1231&collapse=urlkey" \
    | python3 -c "import sys,json; [print(r[0], r[1][:4]+'-'+r[1][4:6]+'-'+r[1][6:8]) for r in json.load(sys.stdin)[1:]]" 2>/dev/null
done

# Find deprecated endpoints still responding 200
# Step 1: Get historical endpoints
HISTORICAL=$(curl -s "http://web.archive.org/cdx/search/cdx?url=*.${TARGET}/*&output=json&fl=original&collapse=urlkey&limit=1000" \
  | python3 -c "import sys,json; print('\n'.join([r[0] for r in json.load(sys.stdin)[1:]]))" 2>/dev/null)

# Step 2: Probe each historical path against live site
echo "$HISTORICAL" | grep -E "(/api/|/v[0-9]|/admin/)" | while read url; do
  path=$(echo "$url" | sed "s|https\?://[^/]*/||")
  status=$(curl -s -o /dev/null -w "%{http_code}" "https://${TARGET}/${path}")
  [ "$status" = "200" ] && echo "LIVE (was historical): /${path}"
done
```

**What it reveals:**
- Endpoints deprecated in UI but still accessible server-side
- API versioning patterns (`/api/v1/` → `/api/v2/`) 
- Authentication changes over time (old endpoints may have weaker auth)
- Retired admin paths that still respond

**Versioning patterns to look for:**
| Pattern | Example | Risk if still live |
|---------|---------|-------------------|
| `/api/v1/`, `/api/v2/` | Versioned REST APIs | Old version may lack current auth checks |
| `/_old/`, `/legacy/` | Legacy paths | Often forgotten, weaker security |
| `/beta/`, `/staging/` | Pre-production | Debug mode, test credentials |
| `/wp-json/wp/v1/` → `/wp/v2/` | WordPress REST | v1 may have different permissions |
| `/rest/V1/` → `/rest/V2/` | Magento/Adobe Commerce | Version落差 in auth |

**What to extract:** URL paths, especially `/api/*`, `/v[0-9]/*`, `/graphql`, `/admin/*`

---

## CommonCrawl CDX API

Complementary to Wayback — different crawl coverage, same query format.

```bash
TARGET="example.com"

# Most recent crawl index (update CCYY-WW to latest at index.commoncrawl.org)
CC_INDEX="CC-MAIN-2024-51"

curl -s "https://index.commoncrawl.org/${CC_INDEX}-index?url=*.${TARGET}/*&output=json&fl=url,status&limit=1000" \
  | python3 -c "import sys; [print(l) for l in sys.stdin]"
```

**When to use:** When Wayback results are sparse or site is newer — CommonCrawl often
has broader recent coverage.

---

## crt.sh — Certificate Transparency

Discovers subdomains via TLS certificate logs. Reveals staging, dev, admin, API subdomains.

```bash
TARGET="example.com"

# All subdomains (parsed from JSON)
curl -s "https://crt.sh/?q=%.${TARGET}&output=json" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
names = set()
for cert in data:
    for name in cert.get('name_value','').split('\n'):
        names.add(name.strip().lstrip('*.'))
for n in sorted(names):
    print(n)
" 2>/dev/null

# Filter for API / admin subdomains
# ... | grep -E 'api\.|admin\.|staging\.|dev\.|internal\.'
```

**What to look for:**
- `api.example.com` — dedicated API subdomain
- `admin.example.com` — admin panel (may have different auth surface)
- `staging.example.com` / `dev.example.com` — flag as `[STAGING-ENV]`
- `*.internal.example.com` — internal services (may be exposed)

---

## GitHub Code Search

Finds API clients, configuration files, and documentation referencing the target.

```bash
# Search for API usage examples in public repos
# Run these as Google/GitHub search queries — no CLI required

# Endpoint references in code
site:github.com "example.com/api" filetype:js OR filetype:py OR filetype:ts

# OpenAPI/Swagger specs committed to repos
site:github.com "example.com" "openapi" OR "swagger" filetype:yaml OR filetype:json

# Client libraries or SDKs
site:github.com "example.com" "axios" OR "fetch" OR "requests" "/api/"

# Environment variable files with base URLs
site:github.com "example.com" "NEXT_PUBLIC_API_URL" OR "API_BASE_URL"
```

**What to extract:** Endpoint paths, auth patterns, request/response examples in real code.

---

## Google Dorking for API Discovery

Systematic Google queries to surface endpoints, documentation, and specs.

```bash
# Search queries (run manually in browser or via SerpAPI)

# OpenAPI/Swagger docs
site:example.com "swagger" OR "openapi" OR "/api/docs"

# API endpoint patterns
site:example.com inurl:"/api/v" OR inurl:"/graphql"

# Developer documentation
site:example.com "api" "authentication" "endpoint"

# Third-party mentions of the API
inurl:github.com "example.com" "endpoint" "api"

# Exposed API keys or configuration (caution — report, don't use)
site:example.com filetype:json "api_key" OR "secret_key"
```

---

## SecurityTrails (DNS + infrastructure history)

Reveals infrastructure changes, historical IPs, and related domains. Requires API key.

```bash
# Only use if SECURITYTRAILS_API_KEY is set — otherwise skip and note [TOOL-UNAVAILABLE:securitytrails]
if [ -n "${SECURITYTRAILS_API_KEY}" ]; then
  # Subdomains
  curl -s "https://api.securitytrails.com/v1/domain/${TARGET}/subdomains" \
    -H "apikey: ${SECURITYTRAILS_API_KEY}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{s}.{d[\"endpoint\"]}') for s in d.get('subdomains',[])]"

  # Historical DNS A records (reveals past IPs / hosting changes)
  curl -s "https://api.securitytrails.com/v1/history/${TARGET}/dns/a" \
    -H "apikey: ${SECURITYTRAILS_API_KEY}"
fi
```

**When to use:** When the site has an interesting infrastructure story (CDN changes, cloud migrations, IP history).

---

## Shodan (internet-scale infrastructure)

Finds exposed services, open ports, and infrastructure details by organisation or IP.
Requires API key.

```bash
# Only use if SHODAN_API_KEY is set
if [ -n "${SHODAN_API_KEY}" ]; then
  # Search by hostname
  curl -s "https://api.shodan.io/shodan/host/search?key=${SHODAN_API_KEY}&query=hostname:${TARGET}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); [print(h.get('ip_str'), h.get('port'), h.get('product','')) for h in d.get('matches',[])]"
fi

# No key: use shodan.io in browser to search for the domain manually
# Document: open ports, server banners, TLS certificate details
```

**What to look for:** Exposed databases (27017 MongoDB, 5432 PostgreSQL), admin panels on
non-standard ports, legacy services.

---

## robots.txt Analysis

Beyond simple parsing — extract structural signals.

```bash
TARGET_URL="https://example.com"

curl -s "${TARGET_URL}/robots.txt" | while IFS= read -r line; do
  case "$line" in
    Disallow:*)
      path="${line#Disallow: }"
      echo "BLOCKED: $path"
      # Flag patterns that suggest API surfaces
      echo "$path" | grep -qE '^/api/|^/v[0-9]|^/admin/|^/internal/' && echo "  → potential API surface"
      ;;
    Sitemap:*)
      sitemap="${line#Sitemap: }"
      echo "SITEMAP: $sitemap"
      ;;
  esac
done
```

**Key signals in Disallow paths:**
- `/api/*` — explicit API root blocked from crawlers (confirms API exists)
- `/admin/*` — admin panel (worth noting location)
- `/internal/*` — internal endpoints (confirms internal/external split)
- `/partner/*` — partner/B2B API tier

---

## Sitemap.xml Mining

Extract all indexed paths; reveal content structure and publishing patterns.

```bash
TARGET_URL="https://example.com"

# Fetch and parse sitemap (handles both sitemap_index.xml and sitemap.xml)
curl -s "${TARGET_URL}/sitemap.xml" \
  | grep -oP '(?<=<loc>)[^<]+' \
  | head -200

# Analyse URL patterns
# Group by path prefix to understand site sections
curl -s "${TARGET_URL}/sitemap.xml" \
  | grep -oP '(?<=<loc>)[^<]+' \
  | sed 's|https\?://[^/]*/||' \
  | cut -d'/' -f1 \
  | sort | uniq -c | sort -rn
```

**What to extract:** URL path prefixes reveal site structure. A sitemap with
`/products/`, `/blog/`, `/api/docs/` tells you what the site considers public.

---

## JSON-LD Structured Data Extraction

Structured data embedded in HTML for SEO — often more accurate than scraped HTML.

```bash
TARGET_URL="https://example.com"

# Extract all JSON-LD blocks
curl -s "${TARGET_URL}" \
  | python3 -c "
import sys, re, json
html = sys.stdin.read()
blocks = re.findall(r'<script[^>]+type=[\"\\']application/ld\+json[\"\\'][^>]*>(.*?)</script>', html, re.DOTALL)
for b in blocks:
    try:
        d = json.loads(b.strip())
        print(json.dumps(d, indent=2))
    except:
        pass
"
```

**Schema types and what they reveal:**

| `@type` | What to extract |
|---------|----------------|
| `Organization` | Company name, logo URL, social profiles (`sameAs`), contact points |
| `WebSite` | Site name, URL, search action (`potentialAction`) |
| `Product` | Price, availability, SKU, brand — e-commerce API shape |
| `LocalBusiness` | Address, phone, hours, geo coordinates |
| `BreadcrumbList` | Site hierarchy and URL patterns |
| `SearchAction` | Search endpoint URL and query parameter name |

A `SearchAction` object directly reveals the search API endpoint:
```json
"potentialAction": {
  "@type": "SearchAction",
  "target": "https://example.com/search?q={search_term_string}"
}
```

---

## theHarvester (email + subdomain enumeration)

Command-line OSINT tool. Aggregates results from multiple sources.

```bash
# Only if theHarvester is installed
if which theHarvester &>/dev/null; then
  theHarvester -d "${TARGET}" -b google,bing,crtsh -l 100 2>/dev/null
fi
```

**What it finds:** Emails (reveals internal user naming conventions), subdomains from
multiple sources simultaneously.
=======
# VirusTotal (no API key for basic lookup)
curl -s "https://www.virustotal.com/ui/domain_reports/${TARGET}" \
  | python3 -c "
import sys, json
j = json.load(sys.stdin)
subs = j.get('data', {}).get('attributes', {}).get('subdomains', [])
for s in subs[:100]:
    print(s)
"

# DNSDB (requires API key)
if [ -n "${DNSDB_API_KEY}" ]; then
  curl -s "https://api.dnsdb.info/lookup/rrset/name/${TARGET}/ANY" \
    -H "X-API-Key: ${DNSDB_API_KEY}" \
    | jq -r '.[].rrname' | sort -u
fi
```

**What to look for:**
- Historical subdomains no longer active.
- A records indicating past hosting providers.
- TXT records that may contain verification tokens or configuration snippets.

---

## TLS Fingerprinting (testssl.sh, sslyze, tls-scan)

Identify supported cipher suites, protocol versions, and certificate details to spot misconfigurations or legacy support.

```bash
TARGET="example.com"

# testssl.sh (requires installation)
if which testssl.sh &>/dev/null; then
  testssl.sh --fast ${TARGET}
fi

# sslyze (Python package)
if which sslyze &>/dev/null; then
  sslyze --regular ${TARGET}:443
fi

# tls-scan (Go binary)
if which tls-scan &>/dev/null; then
  tls-scan ${TARGET}:443
fi
```

**What to look for:**
- Enabled TLS 1.0/1.1 or deprecated ciphers.
- Certificate chain anomalies (self‑signed, expired).
- Public key size below recommended thresholds.

---

## GraphQL Introspection Queries

Many services expose a GraphQL endpoint that can be introspected to reveal the full schema.

```bash
TARGET="example.com"
ENDPOINT="https://${TARGET}/graphql"

# Basic introspection query via curl
curl -s -X POST "${ENDPOINT}" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { types { name fields { name } } } }"}' \
  | jq .
```

**What to look for:**
- List of types, queries, and mutations revealing data models.
- Potential enumeration of private fields or admin‑only queries.
- Endpoints that differ from documented public API paths.

---

## OpenAPI / Swagger Detection

Detect OpenAPI specifications via common URLs or GitHub searches.

```bash
TARGET="example.com"

# Common discovery paths
for path in "/swagger.json" "/swagger.yaml" "/openapi.json" "/openapi.yaml" "/v1/api-docs"; do
  url="https://${TARGET}${path}"
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  if [ "$status" = "200" ]; then
    echo "FOUND: $url"
  fi
done

# GitHub search for OpenAPI specs referencing the domain (run manually or via API)
# Example Google dork: site:github.com "${TARGET}" "openapi" filetype:yaml
```

**What to look for:**
- Full endpoint listings, parameter schemas, and example payloads.
- Authentication flows (API keys, OAuth scopes).
- Versioned API docs (`/v1/openapi.json`).

---

## Configuration File Leakage (env, yaml, json, ini)

Search for exposed configuration files that may contain secrets, database URLs, or internal endpoints.

```bash
TARGET="example.com"

# Common config filenames
for file in .env config.yml settings.json .gitlab-ci.yml .github/workflows/*.yml; do
  url="https://${TARGET}/${file}"
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  if [[ "$status" =~ ^2 ]]; then
    echo "PUBLIC CONFIG: $url"
    # Optionally dump a few lines for manual review
    curl -s "$url" | head -n 20
  fi
done
```

**What to look for:**
- API keys, database connection strings, AWS credentials.
- Internal service URLs (`internal.api.example.com`).
- Feature flags revealing hidden functionality.

---

## SMTP Service Banner Enumeration

Enumerate mail servers and capture SMTP banners to discover software versions and potential open relay.

```bash
TARGET="example.com"

# Resolve MX records
mxhosts=$(dig +short MX ${TARGET} | awk '{print $2}' | tr -d '.')

for host in $mxhosts; do
  echo "--- ${host} ---"
  # Connect to SMTP (port 25) and grab banner
  timeout 5 bash -c "echo -e 'QUIT\r\n' | openssl s_client -starttls smtp -connect ${host}:25 2>/dev/null | head -n 5"

done
```

**What to look for:**
- SMTP software and version (e.g., Postfix 3.5.9).
- Open relay indicators (`220 <host> ESMTP` without authentication).
- Misconfigured TLS settings.

---

## Additional High‑Value OSINT Techniques

- **Certificate Transparency Logs via crt.sh / Censys** – already covered.
- **Search engine dorks for exposed admin panels** – e.g., `inurl:/admin/login`.
- **Public code search for hard‑coded endpoints** – extend GitHub Code Search patterns.
- **Third‑party asset discovery (e.g., Cloudflare Radar, Netcraft)**.

---

## Paste Site Search


Search for leaked credentials on paste sites.

```bash
TARGET="example.com"

# Google dorks (run in browser):
# site:pastebin.com "${TARGET}"
# site:gist.github.com "${TARGET}"
```

**What to look for:**
- Leaked API keys, credentials

**When to use:** Selectively — high noise but high impact.

---

## Bug Bounty Scope Search

Bug bounty program scopes reveal documented attack surface.

```bash
TARGET="example.com"

# In browser:
# site:hackerone.com "${TARGET}"
# site:bugcrowd.com "${TARGET}"
```

**What it reveals:**
- Documented API endpoints (in‑scope)
- Out‑of‑scope areas

**When to use:** To understand target's documented attack surface.

---

## Phase 9 Session Brief Format

Document all OSINT findings in the session brief under:

```markdown
### OSINT Findings

**CDX Sources:**
- Wayback CDX: {N} URLs found — notable patterns: {patterns}
- CommonCrawl: {N} URLs found / skipped (no recent index)

**Versioning Analysis (Wayback):**
- Historical endpoints found: {N} — version patterns: {patterns}
- Deprecated endpoints still live: {list}

**Subdomains (crt.sh, DNSDumpster):**
- {subdomain} [{flag: STAGING-ENV / API / ADMIN}]

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
- JSON‑LD types found: {list}
- Search endpoint: {url if found}
```

Search NPM/PyPI for official SDKs.

```bash
TARGET="example.com"

# npm: https://www.npmjs.com/search?q=${TARGET}
# PyPI: https://pypi.org/search/?q=${TARGET}
```

**What it reveals:**
- Official SDK structure, auth patterns

**When to use:** For sites with official developer SDKs.

---

## Bug Bounty Scope Search

Bug bounty program scopes reveal documented attack surface.

```bash
TARGET="example.com"

# In browser:
# site:hackerone.com "${TARGET}"
# site:bugcrowd.com "${TARGET}"
```

**What it reveals:**
- Documented API endpoints (in‑scope)
- Out‑of‑scope areas

**When to use:** To understand target's documented attack surface.

---

## Phase 9 Session Brief Format

Document all OSINT findings in the session brief under:

```markdown
### OSINT Findings

**CDX Sources:**
- Wayback CDX: {N} URLs found — notable patterns: {patterns}
- CommonCrawl: {N} URLs found / skipped (no recent index)

**Versioning Analysis (Wayback):**
- Historical endpoints found: {N} — version patterns: {patterns}
- Deprecated endpoints still live: {list}

**Subdomains (crt.sh, DNSDumpster):**
- {subdomain} [{flag: STAGING-ENV / API / ADMIN}]

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
- JSON‑LD types found: {list}
- Search endpoint: {url if found}
```

Search NPM/PyPI for official SDKs.

```bash
TARGET="example.com"

# npm: https://www.npmjs.com/search?q=${TARGET}
# PyPI: https://pypi.org/search/?q=${TARGET}
```

**What it reveals:**
- Official SDK structure, auth patterns

**When to use:** For sites with official developer SDKs.

---

## Bug Bounty Scope Search

Bug bounty program scopes reveal documented attack surface.

```bash
TARGET="example.com"

# In browser:
# site:hackerone.com "${TARGET}"
# site:bugcrowd.com "${TARGET}"
```

**What it reveals:**
- Documented API endpoints (in-scope)
- Out-of-scope areas

**When to use:** To understand target's documented attack surface.
>>>>>>> 3a8fbf6 (Add top CMS framework guides: Joomla, Webflow, Drupal)

---

## Phase 9 Session Brief Format

Document all OSINT findings in the session brief under:

```markdown
### OSINT Findings

**CDX Sources:**
- Wayback CDX: {N} URLs found — notable patterns: {patterns}
- CommonCrawl: {N} URLs found / skipped (no recent index)

**Versioning Analysis (Wayback):**
- Historical endpoints found: {N} — version patterns: {patterns}
- Deprecated endpoints still live: {list}

**Subdomains (crt.sh):**
- {subdomain} [{flag: STAGING-ENV / API / ADMIN}]

**GitHub Search:**
- Found: {what} at {repo URL}
- Not found: no public repos reference this domain

**Structured Data:**
- JSON-LD types found: {list}
- Search endpoint: {url if found}
```
