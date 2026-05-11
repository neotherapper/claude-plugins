# Umbraco Fingerprinting Guide

## Detection Methods

### 1. HTML Source Analysis

```bash
# Check for Umbraco-specific comments and markers
curl -s https://target.example.com/ | grep -iE 'umbraco|umb_|umb-'

# Look for Umbraco-specific attributes
curl -s https://target.example.com/ | grep -oE 'data-umb-[a-z0-9-]+' | sort | uniq | head -10
```

**Key indicators:**
- `<!--Umbraco-->` comment
- `umb_*` CSS classes or IDs
- `data-umb-*` attributes
- Umbraco JavaScript references

### 2. Cookie Analysis

```bash
# Check for Umbraco cookies
curl -I --max-time 10 "https://target.example.com/" 2>/dev/null | grep -i 'set-cookie' | grep -iE 'umb|session'
```

**Key cookies:**
- `UMB_UPDCHK` - Update check
- `UMB_SESSION` - Session
- `umb_auth` - Authentication

### 3. URL Path Analysis

```bash
# Check for Umbraco paths
for path in "/umbraco" "/Umbraco" "/backoffice" "/api/members" "/api/content"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://target.example.com${path}")
  if [[ "$status" =~ ^2 ]]; then
    echo "UMBRACO-PATH-FOUND: ${path} [${status}]"
  fi
done
```

### 4. Delivery API Detection

```bash
# Check Delivery API
curl -sf --max-time 10 "https://target.example.com/umbraco/delivery/api/v1/content/item/" | head -100
```

### 5. Backoffice Detection

```bash
# Check backoffice
curl -sf --max-time 10 "https://target.example.com/umbraco/" | head -100
curl -sf --max-time 10 "https://target.example.com/umbraco/login" | head -100
```

### 6. Version Detection

```bash
# Check version in HTML
curl -s https://target.example.com/ | grep -oE 'Umbraco [0-9]+\.[0-9]+\.[0-9]+'
curl -s https://target.example.com/ | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+'

# Check backoffice
curl -sf --max-time 10 "https://target.example.com/umbraco/" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
```

### 7. Umbraco Cloud Detection

```bash
# Check for Umbraco Cloud hosting
curl -I --max-time 10 "https://target.example.com/" 2>/dev/null | grep -i 'x-umbraco'
curl -s https://target.example.com/ | grep -i 'ucommerce\|umbraco.cloud'
```

### 8. Confidence Levels

| Confidence | Indicators |
|------------|------------|
| **Definitive** | `<!--Umbraco-->` comment, `/umbraco/` path |
| **High** | Umbraco cookies, Delivery API response |
| **Medium** | Umbraco markers in HTML, member API |
| **Low** | Generic .NET patterns, Umbraco JS global |

### 9. False Positive Mitigation

**Not Umbraco if:**
- No Umbraco markers in HTML
- Different URL structure than Umbraco conventions
- No Delivery API response
- Different authentication mechanisms

**Verification command:**
```bash
# Comprehensive Umbraco check
curl -s https://target.example.com/ | python3 -c "
import sys, re
html = sys.stdin.read()

indicators = {
    'umbraco_comment': '<!--Umbraco-->' in html or '<!-- umbraco' in html.lower(),
    'umb_cookies': 'umb' in html.lower(),
    'umb_attributes': 'data-umb-' in html,
    'umbraco_api': '/umbraco/' in html or '/Umbraco/' in html,
    'umb_session': 'umb_session' in html.lower(),
}

score = sum(indicators.values())
if score >= 2:
    print('[UMBRACO-CONFIRMED] Multiple indicators found')
    for k, v in indicators.items():
        if v: print(f'  - {k}')
else:
    print('[UMBRACO-NOT-DETECTED] Insufficient evidence')
"
```

### 10. Integration with Beacon Phase 3

Add to site-recon Phase 3 (Fingerprint):

```bash
# Umbraco detection in fingerprint phase
if curl -s "${TARGET_URL}" | grep -q -E 'Umbraco|umb_|\.umb|/umbraco/|data-umb-'; then
    echo "[FRAMEWORK-DETECTED:umbraco]"
    # Trigger tech pack load in Phase 4
fi
```