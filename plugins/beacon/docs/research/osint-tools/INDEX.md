# OSINT Tools — Research Reference

> Passive intelligence gathering techniques for Beacon's Phase 9. All techniques query third-party databases — none touch the target site directly.

## Tool Overview

| Tool | Cost | API Key | Best for |
|------|------|---------|---------|
| crt.sh | Free | None | Subdomain discovery via SSL certs |
| GAU (GetAllURLs) | Free | None | Historical URL inventory from 4 sources |
| Wayback CDX API | Free | None | Historical endpoint snapshots |
| CommonCrawl CDX | Free | None | Crawled URL inventory |
| GitHub code search | Free tier | Token recommended | Leaked references, SDK usage |
| Google dorks | Free | None | Exposed files, staging envs, API docs |

## crt.sh — Certificate Transparency

Certificate transparency logs record every SSL cert issued. `crt.sh` makes them searchable.

### API Usage

```bash
# All subdomains for a domain (JSON)
curl -s "https://crt.sh/?q=%.example.com&output=json" | \
  jq -r '.[].name_value' | sort -u

# Filter out wildcards
curl -s "https://crt.sh/?q=%.example.com&output=json" | \
  jq -r '.[].name_value' | grep -v '^\*' | sort -u
```

### What to look for

- `api.example.com` → main API subdomain
- `staging.example.com`, `dev.example.com` → staging environments
- `admin.example.com` → admin panels
- `app.example.com` → separate application
- `cdn.example.com`, `assets.example.com` → asset hosts

Beacon runs this in Phase 2 (passive recon) and reuses the results in Phase 9.

## GAU — GetAllURLs

Aggregates URLs from Wayback Machine, AlienVault OTX, CommonCrawl, and URLScan.io.

### Installation

```bash
go install github.com/lc/gau/v2/cmd/gau@latest
# or
brew install gau
```

### Usage

```bash
# Basic URL dump
echo "example.com" | gau

# Exclude binary/media files
echo "example.com" | gau --blacklist woff,ttf,jpg,jpeg,png,gif,svg,ico,mp4,mp3

# Include subdomains
echo "example.com" | gau --subs

# Limit to specific providers
echo "example.com" | gau --providers wayback,commoncrawl

# Output to file
echo "example.com" | gau --blacklist woff,ttf,jpg,png > urls.txt
```

### Output format

Plain URLs, one per line:
```
https://example.com/api/v1/users
https://example.com/api/v2/products
https://api.example.com/graphql
```

### Fallback (if GAU not installed)

Use the Wayback CDX API directly (see below).

## Wayback Machine CDX API

Query the Internet Archive's index without installing anything.

### Endpoints (all free, no auth)

```bash
# All URLs for a domain (status 200 only)
curl "https://web.archive.org/cdx/search/cdx?url=example.com/*&output=json&filter=statuscode:200&fl=original,statuscode,timestamp&limit=1000"

# API paths only
curl "https://web.archive.org/cdx/search/cdx?url=example.com/api/*&output=json&fl=original,timestamp&collapse=urlkey&limit=500"

# Get unique URLs (collapse on urlkey)
curl "https://web.archive.org/cdx/search/cdx?url=*.example.com/*&output=json&fl=original&collapse=urlkey&limit=2000"
```

### Parameters

| Param | Values | Purpose |
|-------|--------|---------|
| `url` | `domain.com/*` or `*.domain.com/*` | Target URL pattern |
| `output` | `json`, `text`, `csv` | Response format |
| `filter` | `statuscode:200` | Only successful responses |
| `fl` | `original,statuscode,timestamp,mimetype` | Fields to return |
| `collapse` | `urlkey` | Deduplicate by URL |
| `limit` | integer | Max results |
| `from` / `to` | `YYYYMMDD` | Date range |

### Parse JSON output

The first row is the field names:
```bash
curl "https://web.archive.org/cdx/search/cdx?url=example.com/api/*&output=json&fl=original&collapse=urlkey&limit=500" | \
  python3 -c "import sys,json; data=json.load(sys.stdin); [print(row[0]) for row in data[1:]]"
```

## CommonCrawl CDX API

CommonCrawl crawls billions of pages monthly. Their CDX index is queryable.

### Get latest crawl index

```bash
curl -s "https://index.commoncrawl.org/collinfo.json" | \
  python3 -c "import sys,json; data=json.load(sys.stdin); print(data[0]['id'])"
# Returns something like: CC-MAIN-2025-18
```

### Query the index

```bash
INDEX="CC-MAIN-2025-18"
curl "https://index.commoncrawl.org/${INDEX}/cdx?url=example.com/api/*&output=json&fl=url,status,mime&limit=500"
```

### Differences from Wayback

- Wayback = historical archive (goes back to 1996)
- CommonCrawl = recent crawls (monthly snapshots, typically 3-5 TB per crawl)
- CommonCrawl has broader coverage of obscure sites
- Both cover API paths, but CommonCrawl is better for current endpoint state

## GitHub Code Search

Find code that references the target domain — reveals SDK usage, leaked API keys, endpoint patterns.

### API (requires GitHub token for higher rate limits)

```bash
TOKEN="ghp_..."  # optional but recommended
DOMAIN="example.com"

# JavaScript files fetching from the domain
curl -H "Authorization: token ${TOKEN}" \
  "https://api.github.com/search/code?q=${DOMAIN}+fetch+language:javascript&per_page=30"

# API endpoint strings
curl -H "Authorization: token ${TOKEN}" \
  "https://api.github.com/search/code?q=%22${DOMAIN}%2Fapi%22+language:javascript&per_page=30"

# Any file referencing the domain
curl -H "Authorization: token ${TOKEN}" \
  "https://api.github.com/search/code?q=${DOMAIN}&per_page=30"
```

### Useful search queries

```
"example.com/api" language:javascript
"api.example.com" extension:env
"EXAMPLE_API_KEY" OR "EXAMPLE_SECRET"
"https://example.com" language:python
```

### Rate limits

- Unauthenticated: 10 requests/minute
- Authenticated: 30 requests/minute
- Results capped at 1000 per query

## Google Dorks

Passive search using Google operators to find exposed files and endpoints.

### Standard Beacon Dork Library

Run these searches during Phase 9. Replace `{domain}` with target domain.

```
site:{domain} inurl:api
site:{domain} inurl:swagger OR inurl:openapi
site:{domain} inurl:/v1/ OR inurl:/v2/
site:{domain} filetype:json
site:{domain} "api_key" OR "apikey" OR "api-key"
site:{domain} inurl:graphql
site:{domain} inurl:admin OR inurl:dashboard
site:{domain} intitle:"index of" inurl:api
site:{domain} inurl:debug OR inurl:test OR inurl:staging
site:{domain} ext:env OR ext:yaml OR ext:config
```

### Automation

Google dorks cannot be queried via API (scraping violates ToS). Options:
1. Use Claude's `WebSearch` tool with each dork query
2. Use Firecrawl search: `firecrawl search "site:example.com inurl:api"`
3. Use SerpAPI or similar (paid)

### Log format for session brief

```
OSINT: Google dorks run
  site:example.com inurl:api → 4 results (see api-surfaces/google-dorks.md)
  site:example.com inurl:swagger → 1 result: https://example.com/api/swagger-ui.html
```

## Session Brief Format for OSINT Phase

```markdown
## Phase 9 — OSINT Results

### Subdomains (crt.sh)
- api.example.com (found cert 2024-11-03)
- staging.example.com (found cert 2024-09-15)
- admin.example.com (found cert 2023-06-01)

### Historical URLs (Wayback + GAU)
- /api/v1/users (last seen 2024-08-12, status 200)
- /api/v2/products (last seen 2024-11-01, status 200)
- /api/v1/orders (last seen 2023-03-05, status 301 → /api/v2/orders)

### GitHub References
- 3 public repos reference api.example.com
- No exposed API keys found

### Google Dorks
- swagger UI found: https://example.com/api/docs
- No exposed .env files
```

## Beacon Phase 9 Execution Order

1. Reuse crt.sh results from Phase 2 (already cached)
2. Run GAU (or Wayback CDX fallback) — parse for `/api/` paths
3. Query CommonCrawl CDX — augment URL list
4. GitHub code search — look for domain references
5. Run Google dorks via WebSearch (5-10 targeted queries)
6. Merge all findings into session brief

## Source

Ported from nikai research:
- `research/knowledge-base/02_Research_Findings.md` (passive datasets section)
- Elevate Greece analysis (`docs/research/elevate-greece/`) — practical OSINT application
- Design spec Phase 9 detail section
