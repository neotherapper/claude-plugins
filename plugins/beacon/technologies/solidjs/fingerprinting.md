# SolidJS Fingerprinting Guide

## Detection Methods

### 1. HTML Source Analysis

```bash
# Check for SolidJS indicators in HTML
curl -s https://target.example.com/ | grep -E '(Solid|solidjs|createSignal|createEffect|data-solid)'
```

**Key indicators in HTML:**
- `<script>` tags loading SolidJS bundles
- `data-solid` attributes on elements (SSR)
- `<!--solid-->` comments in rendered HTML
- Meta tags with `framework="solid"`

### 2. JavaScript Global Detection

```bash
# Check browser console for Solid globals
curl -s https://target.example.com/ | python3 -c "
import sys, re
html = sys.stdin.read()
if 'Solid' in html or 'createSignal' in html:
    print('[SOLIDJS-SUSPECTED] Found SolidJS patterns in HTML')
    # Extract version if possible
    match = re.search(r'Solid[:\s]+["\']([0-9.]+)["\']', html)
    if match:
        print(f'[SOLIDJS-VERSION:{match.group(1)}]')
"
```

### 3. Bundle Analysis

```bash
# Analyze JavaScript bundles for Solid patterns
curl -s https://target.example.com/assets/index.*.js 2>/dev/null | head -1000 | grep -o 'Solid\|solidjs\|create[A-Z]' | sort | uniq
```

**Bundle patterns:**
- Function names: `createSignal`, `createEffect`, `createMemo`, `createResource`
- Import statements: `from "solid-js"`, `import { createSignal } from "solid-js"`
- Webpack/Vite chunks with Solid in filename

### 4. Network Traffic Analysis

**SolidJS applications typically:**
- Make fetch/XHR requests to `/api/*` endpoints
- Use modern fetch API with `application/json` content-type
- May use GraphQL subscriptions (WebSocket connections)
- Often implement optimistic UI updates

### 5. SSR (Server-Side Rendering) Detection

**SolidStart SSR indicators:**
- `data-solid` attributes in initial HTML
- `<script type="module">` tags with Solid hydration
- Pre-rendered content with interactive enhancements
- Fast initial page load with client-side hydration

### 6. Build Tool Indicators

**Vite + Solid patterns:**
- `/dist/assets/index.*.js` (hashed filenames)
- `/src/` directory structure exposed (development)
- Hot module replacement (HMR) websocket connections
- Vite manifest at `/dist/.vite/manifest.json`

**Rollup + Solid patterns:**
- Single bundle file or chunked output
- Tree-shaking optimizations visible in bundle
- Solid runtime included in vendor chunk

### 7. Version Detection Techniques

**From HTML:**
```bash
# Look for version in script tags
curl -s https://target.example.com/ | grep -o 'solid@[0-9][^"]*' | head -1

# Check package.json if exposed
curl -sf https://target.example.com/package.json | grep -o '"solid-js":"[^"]*"'
```

**From JavaScript:**
```bash
# Extract from bundle (if minification preserves version)
curl -s https://target.example.com/assets/vendor.*.js | grep -o '"[0-9]+\.[0-9]+\.[0-9]+"' | head -5
```

### 8. Framework-Specific Patterns

**Solid Router:**
- Client-side navigation without full page reloads
- `useNavigate`, `useLocation` hooks in bundle
- Route definitions in JavaScript

**Solid Query/TanStack Query:**
- API data fetching patterns
- Cache management logic
- Background refetching behavior

**Solid Stores:**
- `createStore` function usage
- Global state management patterns
- Derived state computations

### 9. Confidence Levels

| Confidence | Indicators |
|------------|------------|
| **Definitive** | `Solid` global object present, `createSignal`/`createEffect` functions |
| **High** | `data-solid` attributes in HTML, SolidStart meta tags |
| **Medium** | Solid patterns in bundle, Vite+Solid build output |
| **Low** | Client-side routing patterns, reactive UI behavior |

### 10. False Positive Mitigation

**Not SolidJS if:**
- React/Vue/Angular globals also present (may be poly-repo)
- No reactive programming patterns in bundle
- Uses different state management (Redux, MobX)
- Server-rendered without client-side hydration

**Verification command:**
```bash
# Comprehensive check
curl -s https://target.example.com/ | python3 -c "
import sys, re
html = sys.stdin.read()

indicators = {
    'Solid_global': 'Solid' in html,
    'createSignal': 'createSignal' in html,
    'data-solid_attr': 'data-solid' in html,
    'solidjs_import': 'solid-js' in html.lower(),
}

score = sum(indicators.values())
if score >= 2:
    print('[SOLIDJS-CONFIRMED] Multiple indicators found')
    for k, v in indicators.items():
        if v: print(f'  - {k}')
else:
    print('[SOLIDJS-NOT-DETECTED] Insufficient evidence')
"
```

### 11. Integration with Beacon Phase 3

Add to site-recon Phase 3 (Fingerprint):

```bash
# SolidJS detection in fingerprint phase
if curl -s "${TARGET_URL}" | grep -q -E 'Solid|solidjs|createSignal'; then
    echo "[FRAMEWORK-DETECTED:solidjs]"
    # Trigger tech pack load in Phase 4
fi
```