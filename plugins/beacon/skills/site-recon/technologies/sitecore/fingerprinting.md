# Sitecore Fingerprinting Guide

## Detection Methods

### 1. HTML Source Analysis

```bash
# Check for Sitecore-specific comments and markers
curl -s https://target.example.com/ | grep -iE 'sitecore|sc_site|sc_device|sc_itemid'

# Look for Sitecore-specific attributes (JSS/content-sdk)
curl -s https://target.example.com/ | grep -oE 'data-sc-[a-z0-9-]+' | sort | uniq | head -10

# Check for sc_mode query parameter references
curl -s https://target.example.com/ | grep -oE 'sc_mode=[a-z]+'

# Check for __NEXT_DATA__ with Sitecore (JSS + Next.js)
curl -s https://target.example.com/ | python3 -c "
import sys, json, re
html = sys.stdin.read()
m = re.search(r'__NEXT_DATA__\s*=\s*({.*?});', html, re.DOTALL)
if m:
    data = json.loads(m.group(1))
    if 'sitecore' in str(data.get('props', {})):
        print('[SITECORE-JSS-NEXTJS]')
        route = data.get('props', {}).get('sitecore', {}).get('route', {})
        print(f'  Route: {route.get(\"name\", \"unknown\")}')
        print(f'  Language: {route.get(\"language\", \"unknown\")}')
"

# Check for Content SDK (App Router) patterns
curl -s https://target.example.com/ | grep -oE 'data-content-sdk-[a-z-]+' | sort -u
```

**Key indicators:**
- `<!-- Sitecore -->` comment (definitive)
- `sc_site` query parameter
- `sc_mode` query parameter (edit/preview/normal)
- `sc_lang` query parameter (language version)
- `data-sc-itemid`, `data-sc-*` attributes
- `data-content-sdk-*` attributes (Content SDK / App Router)
- `__NEXT_DATA__` JSON with `sitecore` props (JSS + Next.js)
- Sitecore-specific CSS classes

### 2. Cookie Analysis

```bash
# Check for all Sitecore cookies
curl -I --max-time 10 "https://target.example.com/" 2>/dev/null | grep -i 'set-cookie' | grep -i 'sc_\|sitecore'

# Detailed cookie check
curl -sI --max-time 10 "https://target.example.com/" 2>/dev/null \
  | grep -i 'set-cookie' \
  | sed 's/Set-Cookie: //I' | cut -d= -f1 | sort -u
```

**Key cookies:**
- `SC_ANALYTICS` — Analytics tracking (High confidence)
- `SC_USRCONTEXT` — User context
- `SC_GUESTCONTEXT` — Guest/anonymous context
- `ASP.NET_SessionId` — ASP.NET session (low confidence, but supporting)
- `__RequestVerificationToken` — CSRF token (when present in cookie form)
- `PSA-*` — Publishing Service Agent cookies
- `SC_ANALYTICS_GLOBAL` — Global analytics cookie

### 3. URL Path Analysis

```bash
# Check for Sitecore paths (on-prem)
for path in "/sitecore" "/sitecore/login" "/sitecore/shell" "/sitecore/admin" \
            "/sitecore/config" "/sitecore/api" "/sitecore/debug" \
            "/-/" "/-/jss/" "/-/api/items/" "/-/media/" \
            "/api/sitecore/" "/api/editing/config" \
            "/xconnect/" "/xconnect/odata/" "/xconnect/xcontrib/" \
            "/sitecore/horizon/" "/sitecore/api/publishing/"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://target.example.com${path}")
  if [[ "$status" =~ ^2 ]]; then
    echo "SITECORE-PATH-FOUND: ${path} [${status}]"
  fi
done
```

### 4. Layout Service Detection

```bash
# Check Layout Service (with and without config)
curl -sf --max-time 10 "https://target.example.com/sitecore/api/layout/render/default?item=/" | head -100
curl -sf --max-time 10 "https://target.example.com/sitecore/api/layout/render/jss?item=/home" | head -100

# Check placeholder endpoint
curl -sf --max-time 10 "https://target.example.com/sitecore/api/layout/placeholder/jss?placeholderName=/main&item=/home&tracking=false" | head -50
```

### 5. Item Service Detection

```bash
# Check Item Service
curl -sf --max-time 10 "https://target.example.com/sitecore/api/items/-/items?path=/" | head -100
curl -sf --max-time 10 "https://target.example.com/sitecore/api/items/-/children?path=/" | head -100
```

### 6. JSS (JavaScript Services) Detection

```bash
# Check for JSS endpoints
curl -sf --max-time 10 "https://target.example.com/-/jss/" | head -100
curl -sf --max-time 10 "https://target.example.com/-/api/items/" | head -100

# Check JSS dictionary endpoint
curl -sf --max-time 10 "https://target.example.com/sitecore/api/jss/dictionary/default" | head -50

# Check for JSS app config (returns XML config patches)
curl -sf --max-time 10 "https://target.example.com/sitecore/config/" | grep -i 'jss\|javascriptservices'
```

### 7. Experience Edge (Cloud) Detection

```bash
# Check for cloud-hosted (XM Cloud / Experience Edge)
curl -sf --max-time 10 "https://edge.sitecorecloud.io/api/graphql/ide" | head -50

# Check if the target uses edge domain
curl -sI --max-time 10 "https://target.example.com/" 2>/dev/null \
  | grep -i 'edge.sitecorecloud.io\|x-sitecore\|xmc'

# Check XM Cloud editing config
curl -sf --max-time 10 "https://target.example.com/api/editing/config" | head -50
```

### 8. Version Detection

```bash
# Check version in HTML (on-prem)
curl -s https://target.example.com/ | grep -oE 'Sitecore [0-9]+\.[0-9]+(\.[0-9]+)?'

# Check Sitecore shell for version
curl -sf --max-time 10 "https://target.example.com/sitecore/shell" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'

# Check login page for version string
curl -sf --max-time 10 "https://target.example.com/sitecore/login" | grep -oE 'version [0-9]+\.[0-9]+'

# Check sitecore.version.xml
curl -sf --max-time 10 "https://target.example.com/sitecore/shell/sitecore.version.xml"

# Check response headers for version hints
curl -sI --max-time 10 "https://target.example.com/" 2>/dev/null | grep -iE 'sitecore|x-version|x-powered-by'

# Check via DLL version (if .NET errors leak paths)
curl -sf --max-time 10 "https://target.example.com/nonexistent.aspx" | grep -oE 'Sitecore\.Kernel[^"]*Version=|Version: [0-9.]+'
```

### 9. GraphQL Detection

```bash
# Check on-prem GraphQL endpoint
curl -sf --max-time 10 -X POST "https://target.example.com/sitecore/api/graph/" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { __typename }"}'

# Check Experience Edge GraphQL
curl -sf --max-time 10 -X POST "https://edge.sitecorecloud.io/api/graphql/v1" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { __typename }"}'

# Check for GraphQL schema download
curl -sf --max-time 10 "https://target.example.com/sitecore/api/graph/?schema"
```

### 10. SXA (Sitecore Experience Accelerator) Detection

```bash
# Check for SXA endpoints
curl -sf --max-time 10 "https://target.example.com/sitecore/sxa/" | head -50

# Check for SXA-specific media paths
curl -sf --max-time 10 "https://target.example.com/-/sxa/" | head -50

# Check for SXA in generator tags
curl -s https://target.example.com/ | grep -oE 'SXA[^"]*'
```

### 11. Identity Server Detection

```bash
# Check if the login page redirects to Identity Server
curl -sf --max-time 10 -L "https://target.example.com/sitecore/login" \
  | grep -oE 'https?://[^"\'\' ]*identity[^"\'\' ]*' | sort -u

# Check .well-known for OIDC
curl -sf --max-time 10 "https://target.example.com/.well-known/openid-configuration" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'issuer' in d and 'sitecore' in d.get('issuer','').lower():
        print(f'[SITECORE-IDENTITY-SERVER] Issuer: {d[\"issuer\"]}')
except: pass
" 2>/dev/null
```

### 12. Confidence Levels

| Confidence | Indicators |
|------------|------------|
| **Definitive** | `<!-- Sitecore -->` comment, `/sitecore/` path accessible with layout service response |
| **High** | Sitecore cookies (SC_ANALYTICS), Layout Service returns JSON, edge.sitecorecloud.io |
| **Medium** | JSS endpoints, Item Service patterns, `sc_mode=` in URLs, `data-sc-*` attributes |
| **Low** | Generic .NET patterns, ASP.NET_SessionId, Sitecore markers in HTML comments |

### 13. False Positive Mitigation

**Not Sitecore if:**
- No Sitecore markers in HTML
- Different URL structure than Sitecore conventions
- No Layout Service response (returns 404, not JSON)
- Different authentication mechanisms (no `__RequestVerificationToken` pattern)
- Is Umbraco if it responds to `/umbraco/` routes (often confused with Sitecore as both are .NET CMS)

**Verification command:**
```bash
# Comprehensive Sitecore check
curl -s https://target.example.com/ | python3 -c "
import sys, re
html = sys.stdin.read()

indicators = {
    'sitecore_comment': '<!-- Sitecore' in html or '<!--Sitecore' in html,
    'sc_site_param': 'sc_site' in html,
    'sc_mode_param': 'sc_mode=' in html,
    'sc_device': 'sc_device' in html.lower(),
    'sitecore_api': '/sitecore/api/' in html or 'sitecore' in html.lower(),
    'itemid_attr': 'data-sc-itemid' in html,
    'content_sdk': 'data-content-sdk-' in html,
    'jss_nextjs': '__NEXT_DATA__' in html and 'sitecore' in html.lower(),
}

score = sum(indicators.values())
if score >= 2:
    print('[SITECORE-CONFIRMED] Multiple indicators found')
    for k, v in indicators.items():
        if v: print(f'  - {k}')
elif score == 1:
    print('[SITECORE-POSSIBLE] Weak signal — one indicator found')
    for k, v in indicators.items():
        if v: print(f'  - {k}')
else:
    print('[SITECORE-NOT-DETECTED] Insufficient evidence')
"
```

### 14. Integration with Beacon Phase 3

```bash
# Sitecore detection in fingerprint phase
if curl -s "${TARGET_URL}" | grep -q -E 'sitecore|SC_ANALYTICS|sc_site|/\.sitecore/|data-sc-itemid'; then
    echo "[FRAMEWORK-DETECTED:sitecore]"
    # Check variant
    if curl -s "${TARGET_URL}" | grep -q 'edge.sitecorecloud.io'; then
        echo "[SITECORE-XM-CLOUD]"
    fi
    if curl -sf --max-time 5 "${TARGET_URL}/-/jss/" > /dev/null 2>&1; then
        echo "[SITECORE-JSS]"
    fi
    if curl -s "${TARGET_URL}" | grep -q '__NEXT_DATA__'; then
        echo "[SITECORE-JSS-NEXTJS]"
    fi
fi
```