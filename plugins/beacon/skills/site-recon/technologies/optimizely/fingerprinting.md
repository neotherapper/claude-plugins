# Optimizely Fingerprinting Guide

## Detection Methods

### 1. HTML Source Analysis

```bash
# Check for Optimizely-specific comments and markers
curl -s https://target.example.com/ | grep -iE 'episerver|optimizely|\.epi|\.episerver|epi-ui|contentlink'

# Look for EPiServer-specific attributes
curl -s https://target.example.com/ | grep -oE 'data-epi-[a-z0-9-]+' | sort | uniq | head -10
```

**Key indicators:**
- `<!--.episerver-->` comment
- `EPiServer` or `episerver` in HTML
- `data-epi-*` attributes
- Content link patterns (`contentLink=`)

### 2. Cookie Analysis

```bash
# Check for Optimizely cookies
curl -I --max-time 10 "https://target.example.com/" 2>/dev/null | grep -i 'set-cookie' | grep -i 'epi'
```

**Key cookies:**
- `EPiServer` - Main session cookie
- `.EPiServerLogin` - Login cookie
- `.ASPXROLES` - Role cookie

### 3. URL Path Analysis

```bash
# Check for Optimizely paths
for path in "/episerver" "/Util/" "/cms/" "/epi-ui/" "/Modules/" "/api/episerver/"; do
  status=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "https://target.example.com${path}")
  if [[ "$status" =~ ^2 ]]; then
    echo "OPTIMIZELY-PATH-FOUND: ${path} [${status}]"
  fi
done
```

### 4. API Detection

```bash
# Check Content Delivery API
curl -sf --max-time 10 "https://target.example.com/api/episerver/v3/content?contentLink=/" | head -100

# Check search API
curl -sf --max-time 10 "https://target.example.com/api/episerver/search/?q=test" | head -100
```

### 5. Version Detection

```bash
# Check version in HTML
curl -s https://target.example.com/ | grep -oE 'Episerver [0-9]+\.[0-9]+\.[0-9]+'
curl -s https://target.example.com/ | grep -oE 'Optimizely [0-9]+\.[0-9]+\.[0-9]+'

# Check admin page
curl -sf --max-time 10 "https://target.example.com/episerver/" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'
```

### 6. DXP Detection

```bash
# Check for Optimizely DXP hosting
curl -I --max-time 10 "https://target.example.com/" 2>/dev/null | grep -i 'x-original-host'
curl -s https://target.example.com/ | grep -i 'optimizely.com\|azure\|epidmx'

# Check for .optimizely.com domains
curl -s https://target.example.com/ | grep -oE 'https?://[^"]*\.optimizely\.com[^"]*' | head -5
```

### 7. Confidence Levels

| Confidence | Indicators |
|------------|------------|
| **Definitive** | `<!--.episerver-->` comment, `EPiServer` cookie |
| **High** | `/episerver/` path, Content Delivery API response |
| **Medium** | EPiServer markers in HTML, API patterns |
| **Low** | Generic .NET patterns, Optimizely branding |

### 8. False Positive Mitigation

**Not Optimizely if:**
- No EPiServer markers in HTML
- Different URL structure than Episerver conventions
- No Content Delivery API response
- Different authentication mechanisms

**Verification command:**
```bash
# Comprehensive Optimizely check
curl -s https://target.example.com/ | python3 -c "
import sys, re
html = sys.stdin.read()

indicators = {
    'episerver_comment': '<!--.episerver-->' in html.lower() or '<!-- episerver' in html.lower(),
    'episerver_html': 'episerver' in html.lower(),
    'epi_attributes': 'data-epi' in html.lower(),
    'contentlink': 'contentlink' in html.lower(),
    'epi_paths': '/episerver/' in html or '/Util/' in html,
}

score = sum(indicators.values())
if score >= 2:
    print('[OPTIMIZELY-CONFIRMED] Multiple indicators found')
    for k, v in indicators.items():
        if v: print(f'  - {k}')
else:
    print('[OPTIMIZELY-NOT-DETECTED] Insufficient evidence')
"
```

### 9. Integration with Beacon Phase 3

Add to site-recon Phase 3 (Fingerprint):

```bash
# Optimizely detection in fingerprint phase
if curl -s "${TARGET_URL}" | grep -q -E 'episerver|optimizely|\.epi|ContentLink|/episerver/'; then
    echo "[FRAMEWORK-DETECTED:optimizely]"
    # Trigger tech pack load in Phase 4
fi
```