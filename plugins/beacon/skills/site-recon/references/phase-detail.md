# site-recon — Phase Detail Reference

Load this file when you need exact probe URLs, bash commands, or grep patterns for a phase.

---

## Phase 2 — Passive Recon

Run all of these on every site. They use only curl — no tools required.

```bash
DOMAIN="example.com"
URL="https://example.com"

# Robots and sitemaps
curl -sI "${URL}/robots.txt" -o /dev/null -w "%{http_code}" && curl -s "${URL}/robots.txt"
curl -s "${URL}/sitemap.xml" | head -50
curl -s "${URL}/sitemap_index.xml" | head -50
curl -s "${URL}/wp-sitemap.xml" | head -20          # WordPress 5.5+

# Well-known URLs
curl -s "${URL}/.well-known/security.txt"
curl -s "${URL}/.well-known/openapi.json" -o /dev/null -w "%{http_code}"
curl -s "${URL}/.well-known/jwks.json" -o /dev/null -w "%{http_code}"
curl -s "${URL}/humans.txt"

# HTTP headers (full)
curl -sI "${URL}" 2>&1
```

**crt.sh subdomain enumeration:**
```bash
curl -s "https://crt.sh/?q=%.${DOMAIN}&output=json" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
names = set()
for r in data:
    for n in r['name_value'].split('\n'):
        if not n.startswith('*'): names.add(n.strip())
for n in sorted(names): print(n)
"
```

Look for: `api.`, `staging.`, `dev.`, `admin.`, `app.`, `beta.` subdomains.

**What to record in session brief:**
- Subdomains found (with note on type: api/admin/staging)
- Sitemap URL and approximate page count
- robots.txt Disallow count and any interesting paths
- JWKS found? → confirms JWT auth
- security.txt contact email (useful for scoping)

---

## Phase 5 — Apply Tech Pack Checklist

Work through Section 9 of the loaded tech pack line by line. For each item:

1. Execute the curl probe
2. Record: ✓ 200 / ✗ 403 / – 404 / ? unexpected
3. On 200: add endpoint to "Discovered Endpoints" in session brief
4. On 403: note as auth-gated (still document it)
5. On 404: note as not present

Log format:
```
✓ GET /wp-json/             → 200 (17 namespaces)
✓ GET /wp-json/wp/v2/posts  → 200 (public, returns 10 posts)
✗ GET /wp-json/wp/v2/users  → 403 (user enumeration blocked)
– GET /wp-json/acf/v3/      → 404 (ACF not installed)
```

---

## Phase 6 — Feeds & Structured Data

```bash
URL="https://example.com"

# RSS/Atom detection from HTML
curl -s "${URL}" | grep -oP 'href="[^"]+(?:rss|atom|feed)[^"]*"'

# Common feed paths
for path in /feed /rss /rss.xml /atom.xml /feeds/posts /feed/atom; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${URL}${path}")
  echo "${STATUS} ${path}"
done

# JSON-LD extraction
curl -s "${URL}" | python3 -c "
import sys, re, json
html = sys.stdin.read()
for match in re.finditer(r'<script[^>]+type=[\"'\''']application/ld\+json[\"'\'''][^>]*>(.*?)</script>', html, re.S):
    try:
        data = json.loads(match.group(1))
        print(json.dumps(data, indent=2)[:500])
    except: pass
"

# GraphQL introspection
for gql_path in /graphql /api/graphql /gql /graph; do
  curl -s -X POST "${URL}${gql_path}" \
    -H "Content-Type: application/json" \
    -d '{"query":"{ __typename }"}' | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print('${gql_path}: OPEN' if 'data' in d else '${gql_path}: closed/404')" 2>/dev/null || echo "${gql_path}: 404"
done

# API version enumeration
for v in /api /api/v1 /api/v2 /api/v3 /v1 /v2; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${URL}${v}")
  [ "$STATUS" = "200" ] && echo "FOUND: ${URL}${v}"
done
```

---

## Phase 7 — JS Bundle & Source Map Analysis

**Step 1: Find all JS bundle URLs**
```bash
URL="https://example.com"

# From page HTML
curl -s "${URL}" | grep -oP 'src="[^"]+\.js[^"?#]*' | sed 's/src="//'

# Next.js: check asset manifest
curl -s "${URL}/_next/static/chunks/pages/_app.js" -o /dev/null -w "%{http_code}"
curl -s "${URL}/_next/static/chunks/" 2>/dev/null

# Nuxt
curl -s "${URL}/_nuxt/" 2>/dev/null

# Generic asset manifest
for manifest in /asset-manifest.json /static/js/main.js /assets/js/app.js; do
  curl -s -o /dev/null -w "%{http_code} ${manifest}\n" "${URL}${manifest}"
done
```

**Step 2: Download and grep each bundle**
```bash
BUNDLE_URL="https://example.com/_next/static/chunks/pages/_app-abc123.js"
curl -s "${BUNDLE_URL}" -o /tmp/bundle.js

# API paths
grep -oP '"/api/[^"?#]+' /tmp/bundle.js | sort -u
grep -oP '"https?://[^"]+/api/[^"]+' /tmp/bundle.js | sort -u

# fetch() and axios calls
grep -oP 'fetch\("[^"]+' /tmp/bundle.js | sort -u
grep -oP 'axios\.[a-z]+\("[^"]+' /tmp/bundle.js | sort -u

# WebSocket / SSE
grep -oP 'new WebSocket\("[^"]+' /tmp/bundle.js
grep -oP 'new EventSource\("[^"]+' /tmp/bundle.js

# GraphQL
grep -oP '"/?graphql[^"]*"' /tmp/bundle.js
grep -oP 'query\s*:\s*`[^`]{0,200}' /tmp/bundle.js | head -5

# Auth patterns
grep -oP '"Bearer [^"]{0,80}' /tmp/bundle.js
grep -oP 'Authorization[^;]{0,100}' /tmp/bundle.js
grep -oP 'nonce[^;]{0,60}' /tmp/bundle.js | head -5
```

**Step 3: Check for source maps**
```bash
BUNDLE_URL="https://example.com/_next/static/chunks/main-abc123.js"
MAP_URL="${BUNDLE_URL}.map"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${MAP_URL}")
if [ "$STATUS" = "200" ]; then
  echo "Source map available: ${MAP_URL}"
  curl -s "${MAP_URL}" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'Sources: {len(d.get(\"sources\", []))} files')
for s in d.get('sources', [])[:20]:
    print(' ', s)
"
fi
```

---

## Phase 9 — OSINT

Run all of these. They query third-party databases — none touch the target site.

**Wayback Machine CDX API:**
```bash
DOMAIN="example.com"

# All API paths, status 200, deduplicated
curl -s "https://web.archive.org/cdx/search/cdx?url=${DOMAIN}/*&output=json&filter=statuscode:200&fl=original&collapse=urlkey&limit=1000" | \
  python3 -c "
import sys, json
data = json.load(sys.stdin)
for row in data[1:]:  # skip header row
    url = row[0]
    if any(p in url for p in ['/api/', '/v1/', '/v2/', 'graphql', 'swagger', 'openapi']):
        print(url)
"
```

**CommonCrawl CDX API:**
```bash
# Get latest index name
INDEX=$(curl -s "https://index.commoncrawl.org/collinfo.json" | \
  python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

echo "Using index: ${INDEX}"

curl -s "https://index.commoncrawl.org/${INDEX}/cdx?url=${DOMAIN}/api/*&output=json&fl=url&limit=500" | \
  python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if line:
        try: print(json.loads(line)['url'])
        except: pass
"
```

**GitHub code search:**
```bash
# Requires GitHub token for >10 req/min
TOKEN="${GITHUB_TOKEN:-}"  # optional
AUTH="${TOKEN:+-H \"Authorization: token ${TOKEN}\"}"

curl -s ${AUTH} \
  "https://api.github.com/search/code?q=${DOMAIN}+fetch+language:javascript&per_page=10" | \
  python3 -c "
import sys, json
d = json.load(sys.stdin)
for item in d.get('items', []):
    print(item['html_url'])
    print('  ', item['repository']['full_name'])
"
```

**Google dorks** (run each via WebSearch tool):
```
site:{domain} inurl:api
site:{domain} inurl:swagger OR inurl:openapi
site:{domain} inurl:/v1/ OR inurl:/v2/
site:{domain} filetype:json
site:{domain} inurl:graphql
site:{domain} intitle:"index of" inurl:api
site:{domain} inurl:admin OR inurl:dashboard
site:{domain} ext:env OR ext:yaml OR ext:config
```

**Session brief OSINT summary format:**
```
### Phase 9 — OSINT
Subdomains (Phase 2 crt.sh, reused): api.example.com, staging.example.com
Wayback: 23 API paths found (3 novel vs Phase 5)
CommonCrawl: 8 additional paths
GitHub: 4 repos reference the domain; no exposed keys
Google dorks: swagger UI found at /api/docs; no .env files exposed
```
