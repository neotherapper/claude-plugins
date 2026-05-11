# Sitecore Fingerprinting Guide

## Detection Methods

### 1. HTML Source Analysis

```bash
# Check for Sitecore-specific comments and markers
curl -s https://target.example.com/ | grep -iE 'sitecore|sc_site|sc_device|sc_itemid'

# Look for Sitecore-specific attributes
curl -s https://target.example.com/ | grep -oE 'data-sc-[a-z0-9-]+' | sort | uniq | head -10
```

**Key indicators:**
- `<!-- Sitecore -->` comment
- `sc_site` query parameter
- `data-sc-itemid` attributes
- Sitecore-specific CSS classes

### 2. Cookie Analysis

```bash
# Check for Sitecore cookies
curl -I --max-time 10 "https://target.example.com/" 2>/dev/null | grep -i 'set-cookie' | grep -i 'sc_'
```

**Key cookies:**
- `SC_ANALYTICS` - Analytics tracking
- `SC_USRCONTEXT` - User context
- `SC_GUESTCONTEXT` - Guest/anonymous context

### 3. URL Path Analysis

```bash
# Check for Sitecore paths
for path in "/sitecore" "/sitecore/login" "/sitecore/shell" "/sitecore/admin" "/-/" "/-/jss/" "/api/sitecore/"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://target.example.com${path}")
  if [[ "$status" =~ ^2 ]]; then
    echo "SITECORE-PATH-FOUND: ${path} [${status}]"
  fi
done
```

### 4. Layout Service Detection

```bash
# Check Layout Service
curl -sf --max-time 10 "https://target.example.com/sitecore/api/layout/render/item?item=/" | head -100
curl -sf --max-time 10 "https://target.example.com/sitecore/api/layout/render/item?item=/home" | head -100
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
```

### 7. Version Detection

```bash
# Check version in HTML
curl -s https://target.example.com/ | grep -oE 'Sitecore [0-9]+\.[0-9]+\.[0-9]+'

# Check Sitecore shell
curl -sf --max-time 10 "https://target.example.com/sitecore/shell" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'

# Check login page
curl -sf --max-time 10 "https://target.example.com/sitecore/login" | grep -oE 'version [0-9]+\.[0-9]+'
```

### 8. GraphQL Detection

```bash
# Check GraphQL endpoint
curl -sf --max-time 10 -X POST "https://target.example.com/sitecore/api/graph/" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { __typename }"}'
```

### 9. Confidence Levels

| Confidence | Indicators |
|------------|------------|
| **Definitive** | `<!-- Sitecore -->` comment, `/sitecore/` path accessible |
| **High** | Sitecore cookies, Layout Service response |
| **Medium** | JSS endpoints, Item Service patterns |
| **Low** | Generic .NET patterns, Sitecore markers in HTML |

### 10. False Positive Mitigation

**Not Sitecore if:**
- No Sitecore markers in HTML
- Different URL structure than Sitecore conventions
- No Layout Service response
- Different authentication mechanisms

**Verification command:**
```bash
# Comprehensive Sitecore check
curl -s https://target.example.com/ | python3 -c "
import sys, re
html = sys.stdin.read()

indicators = {
    'sitecore_comment': '<!-- Sitecore' in html or '<!--Sitecore' in html,
    'sc_site_param': 'sc_site' in html,
    'sc_device': 'sc_device' in html.lower(),
    'sitecore_api': '/sitecore/api/' in html or 'sitecore' in html.lower(),
    'itemid_attr': 'data-sc-itemid' in html,
}

score = sum(indicators.values())
if score >= 2:
    print('[SITECORE-CONFIRMED] Multiple indicators found')
    for k, v in indicators.items():
        if v: print(f'  - {k}')
else:
    print('[SITECORE-NOT-DETECTED] Insufficient evidence')
"
```

### 11. Integration with Beacon Phase 3

Add to site-recon Phase 3 (Fingerprint):

```bash
# Sitecore detection in fingerprint phase
if curl -s "${TARGET_URL}" | grep -q -E 'sitecore|SC_ANALYTICS|sc_site|/\.sitecore/'; then
    echo "[FRAMEWORK-DETECTED:sitecore]"
    # Trigger tech pack load in Phase 4
fi
```