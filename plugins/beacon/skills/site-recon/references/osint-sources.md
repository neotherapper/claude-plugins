# OSINT Sources — Phase 9 Reference

Detailed data sources, query patterns, and extraction techniques for Phase 9. Load this
file when executing Phase 9 for thorough coverage beyond the SKILL.md summary.

---

## Wayback Machine CDX API

The most reliable passive URL discovery source — no API key, always available.

```bash
TARGET="example.com"

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

---

## DNSDumpster (free DNS enumeration)

Free DNS enumeration — fills gap between crt.sh (certificates) and paid tools. No API key required.

```bash
TARGET="example.com"

# DNS enumeration via web interface (parse HTML)
curl -s "https://dnsdumpster.com/${TARGET}" \
  | grep -oP '(?<=<td>)[^<]+(?=</td>)' \
  | grep -E '^[a-z0-9]' | sort -u
```

**What to look for:**
- Subdomains beyond certificate logs (crt.sh misses non-HTTPS subdomains)
- Flag patterns: `api`, `admin`, `staging`, `dev`, `internal`, `vpn`

**When to use:** As supplement to crt.sh when certificate-based enumeration returns few results.

---

## VirusTotal (passive DNS)

Passive DNS history — reveals historical subdomains and relationships. Free tier: 3-5 queries/day.

```bash
TARGET="example.com"

# Query via web (no key needed for basic domain lookup):
curl -s "https://www.virustotal.com/ui/domain_reports/${TARGET}" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
if 'data' in d:
    subdomains = d['data'].get('attributes', {}).get('subdomains', [])
    for s in subdomains[:50]:
        print(s)
"
```

**What to look for:**
- Historical subdomains no longer in use
- DNS record types revealing infrastructure

**When to use:** When crt.sh returns sparse results.

---

## BuiltWith (technology stack)

Technology stack fingerprinting — validates/complements Phase 3 manual detection.

```bash
TARGET="example.com"

# BuiltWith lookup via web
curl -s "https://builtwith.com/${TARGET}" \
  | grep -oP '(?<=<div[^>]*>)[^<]+(?=</div>)' \
  | head -50
```

**What to look for:**
- JS libraries, frameworks, CMS detection
- Hosting provider, CDN

**When to use:** To validate framework detection in Phase 3.

---

## urlscan.io (live page capture)

Live page capture with historical snapshots — catches endpoints CDX misses.

```bash
TARGET="example.com"

# Search for previous scans of domain
curl -s "https://urlscan.io/api/v1/search/?q=domain:${TARGET}&limit=50" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
for result in d.get('results', []):
    print(result.get('_id'), result.get('task', {}).get('url'))
"
```

**What it reveals:**
- Live DOM, AJAX endpoints, hidden parameters
- API keys embedded in frontend JS

**When to use:** To capture live state where Wayback CDX returns stale data.

---

## ASN/IP Range Lookup (infrastructure)

Maps IP ranges to organisations — discovers adjacent services, cloud infrastructure.

```bash
TARGET="example.com"

# Get IP for target
IP=$(dig +short ${TARGET} | head -1)

# Query ARIN whois for ASN
whois -h whois.arin.net "n ${IP}" | grep -i "orgid\|asn"
```

**What it reveals:**
- Hosting provider and ASN
- Cloud infrastructure (AWS, Azure, GCP IP ranges)

**When to use:** To understand infrastructure story.

---

## Censys (Shodan alternative)

Internet-wide scanning data — alternative to Shodan for TLS/cert analysis.

```bash
TARGET="example.com"

# Search certificates (free endpoint)
curl -s "https://search.censys.io/api/v1/search/certificates?q=${TARGET}&per_page=50"
```

**What to look for:**
- TLS certificates beyond crt.sh

**When to use:** As alternative to Shodan.

---

## S3 Bucket Enumeration

Common misconfiguration — exposed buckets with backups, data, or API keys.

```bash
TARGET="example.com"

# Brute-force common bucket names
bucket_names=("${TARGET}" "www-${TARGET}" "static-${TARGET}" "assets-${TARGET}")

for bucket in "${bucket_names[@]}"; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "https://${bucket}.s3.amazonaws.com/")
  [ "$status" = "200" ] && echo "PUBLIC: https://${bucket}.s3.amazonaws.com/"
done
```

**What to look for:**
- Public read access to bucket contents

**When to use:** For sites with AWS infrastructure.

---

## Farsight DNSDB (passive DNS alternative)

Passive DNS with different coverage than crt.sh.

```bash
TARGET="example.com"

# Use https://www.dnsdb.org/ (web interface)
```

**What it reveals:**
- Historical DNS records different from crt.sh

**When to use:** As supplement to crt.sh.

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

## Package Registry Search

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
- JSON-LD types found: {list}
- Search endpoint: {url if found}
```
