# AEM Fingerprinting Guide

## Detection Methods

### 1. HTML Source Analysis

```bash
# Check for AEM-specific comments and markers
curl -s https://target.example.com/ | grep -iE 'CQ|AEM|Adobe|DAM|sling|granite|day|crx'

# Look for AEM selectors in URLs
curl -s https://target.example.com/ | grep -oE '\.(html|json|infinity|model\.json|sitemap)' | head -10
```

**Key indicators:**
- `<!-- CQ -->` - Classic AEM
- `<!-- DAM -->` - Digital Asset Management
- `<!-- Sling -->` - Sling framework
- `data-sly-*` - Sightly/HTL templating
- AEM-specific CSS class names

### 2. URL Pattern Analysis

```bash
# Check for AEM URL patterns
for suffix in ".html" ".json" ".infinity" ".model.json" "/jcr:content" "/_jcr_content"; do
  curl -sf --max-time 5 "https://target.example.com/page${suffix}" -o /dev/null && echo "AEM-URL-PATTERN: ${suffix}"
done
```

**AEM-specific selectors:**
- `.html` - Default HTML rendering
- `.json` - JSON export
- `.infinity` - Sling infinity selector
- `.model.json` - Sling model JSON
- `:layout` - Layout variants

### 3. Header Analysis

```bash
# Check for Sling/Adobe headers
curl -I https://target.example.com/ 2>/dev/null | grep -iE 'sling|adobe|cq|dispatcher'

# Check server header
curl -I https://target.example.com/ 2>/dev/null | grep -i 'server'
```

**Key headers:**
- `Server: Apache Sling`
- `X-Sling` headers
- `Adobe-PageState`
- `X-Adobe-Content`

### 4. CRXDE Lite Detection

```bash
# Check if CRXDE is accessible
curl -sf --max-time 5 "https://target.example.com/crx/de/index.jsp" | grep -i 'CRXDE\|AEM'

# Check for exposed CRX paths
curl -sf --max-time 5 "https://target.example.com/crx/explorer/" | grep -i 'jackrabbit\|oak'
```

### 5. DAM Path Discovery

```bash
# Standard DAM paths
curl -sf --max-time 10 "https://target.example.com/content/dam/" | grep -o 'href="[^"]*"' | head -10

# DAM API
curl -sf --max-time 10 "https://target.example.com/api/assets.json" | head -100

# Check for DAM assets
curl -sf --max-time 10 "https://target.example.com/content/dam/.assets.json"
```

### 6. Version Detection

```bash
# Check version in HTML comments
curl -s https://target.example.com/ | grep -oE 'AEM [0-9]+\.[0-9]+' | head -1
curl -s https://target.example.com/ | grep -oE 'CQ [0-9]+\.[0-9]+' | head -1

# Check system console (if accessible)
curl -sf --max-time 10 "https://target.example.com/system/console/about" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'

# Check package manager
curl -sf --max-time 10 "https://target.example.com/packagemanager" | grep -oE 'version [0-9]+\.[0-9]+'
```

### 7. Cloud Service Detection

```bash
# AEM Cloud Service indicators
curl -I https://target.example.com/ 2>/dev/null | grep -i 'x-adobe-ims'
curl -s https://target.example.com/ | grep -i 'adobeioruntime\|azure\|aemcloud'
```

### 8. Confidence Levels

| Confidence | Indicators |
|------------|------------|
| **Definitive** | `<!-- CQ -->` or `<!-- DAM -->` comments, `/crx/de/` accessible |
| **High** | Sling headers, AEM selectors, DAM paths |
| **Medium** | Adobe headers, geometric pattern (Geometrixx demo) |
| **Low** | Generic CMS patterns, content structure |

### 9. False Positive Mitigation

**Not AEM if:**
- No CQ/DAM/Sling markers in HTML
- Different URL patterns than Sling conventions
- No DAM content paths accessible
- Different authentication mechanisms

**Verification command:**
```bash
# Comprehensive AEM check
curl -s https://target.example.com/ | python3 -c "
import sys, re
html = sys.stdin.read()

indicators = {
    'cq_comment': 'CQ' in html or '<!-- CQ' in html,
    'dam_comment': 'DAM' in html or '<!-- DAM' in html,
    'sling_selectors': re.search(r'\.(html|json|infinity|model\.json)', html) is not None,
    'granite_path': 'granite' in html.lower(),
    'aem_selector': 'data-sly' in html or 'sling:resourceType' in html,
}

score = sum(indicators.values())
if score >= 2:
    print('[AEM-CONFIRMED] Multiple indicators found')
    for k, v in indicators.items():
        if v: print(f'  - {k}')
else:
    print('[AEM-NOT-DETECTED] Insufficient evidence')
"
```

### 10. Integration with Beacon Phase 3

Add to site-recon Phase 3 (Fingerprint):

```bash
# AEM detection in fingerprint phase
if curl -s "${TARGET_URL}" | grep -q -E 'CQ|DAM|AEM|Adobe|granite|sling'; then
    echo "[FRAMEWORK-DETECTED:aem]"
    # Trigger tech pack load in Phase 4
fi
```