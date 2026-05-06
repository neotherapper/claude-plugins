# SvelteKit Fingerprinting Guide

## Detection Methods

### 1. HTML Source Analysis

```bash
# Check for SvelteKit indicators in HTML
curl -s https://target.example.com/ | grep -E '(data-sveltekit|__SVELTEKIT__|svelte-kit)'
```

**Key indicators in HTML:**
- `data-sveltekit-[key]` attributes (preload, navigation, etc.)
- `<!--svelte-ignore ... -->` comments
- `data-svelte` attributes (Svelte component markers)
- Script tags loading `/_app/immutable/` bundles

### 2. JavaScript Global Detection

```bash
# Check for SvelteKit globals
curl -s https://target.example.com/ | python3 -c "
import sys, re
html = sys.stdin.read()
if '__SVELTEKIT__' in html or 'data-sveltekit' in html:
    print('[SVELTEKIT-SUSPECTED] Found SvelteKit patterns in HTML')
    # Extract version from data attributes
    match = re.search(r'data-sveltekit-[a-z]+=[\"\']([^\"\']+)[\"\']', html)
    if match:
        print(f'[SVELTEKIT-DATA:{match.group(1)}]')
"
```

### 3. Static Asset Analysis

```bash
# Check for SvelteKit static asset patterns
curl -sf https://target.example.com/_app/immutable/manifest.json && echo "[SVELTEKIT-MANIFEST] Found SvelteKit manifest"
curl -sf https://target.example.com/_app/version.json && echo "[SVELTEKIT-VERSION] Found version file"

# Check common SvelteKit asset paths
for path in '_app/immutable/assets' '_app/immutable/chunks' '_app/immutable/entry'; do
  curl -sf "https://target.example.com/${path}/" && echo "[SVELTEKIT-ASSETS] Found ${path}"
done
```

### 4. Bundle Analysis

```bash
# Analyze SvelteKit bundles for patterns
curl -s https://target.example.com/_app/immutable/entry/*.js 2>/dev/null | head -500 | grep -o '\$[a-zA-Z]\+[^a-zA-Z]\|writable\|readable\|derived' | sort | uniq
```

**Bundle patterns:**
- Svelte store functions: `writable`, `readable`, `derived`
- Reactive statements: `$:` patterns in minified code
- Svelte component markers
- `$app/*` imports (SvelteKit's app stores)

### 5. Network Traffic Analysis

**SvelteKit applications typically:**
- Make fetch requests to load function data endpoints
- Use form actions with CSRF tokens
- Load chunks from `/_app/immutable/chunks/`
- May use server-sent events or WebSockets for real-time features

### 6. SSR (Server-Side Rendering) Detection

**SvelteKit SSR indicators:**
- `data-sveltekit-*` attributes in initial HTML
- Pre-rendered content with client-side hydration
- Fast initial page load with SPA-like navigation
- `__SVELTEKIT__` global for hydration data

### 7. Build Tool Indicators

**Vite + SvelteKit patterns:**
- `/_app/immutable/` directory structure
- Hashed filenames for cache busting
- Vite manifest at `/_app/manifest.json`
- Hot module replacement in development

**Adapter-specific patterns:**
- Node adapter: Standard Node.js deployment
- Vercel adapter: Vercel-specific optimizations
- Netlify adapter: Netlify functions
- Cloudflare adapter: Cloudflare Workers patterns

### 8. Version Detection Techniques

**From HTML attributes:**
```bash
# Extract SvelteKit data from attributes
curl -s https://target.example.com/ | grep -o 'data-sveltekit-[^=]*="[^"]*"' | sed 's/data-sveltekit-//' | head -10

# Look for version in script tags
curl -s https://target.example.com/ | grep -o '@sveltejs/kit@[^"]*' | head -1
```

**From package.json:**
```bash
# Check exposed package.json
curl -sf https://target.example.com/package.json | grep -o '"@sveltejs/kit":"[^"]*"' | cut -d'"' -f4
```

### 9. Framework-Specific Patterns

**Svelte stores:**
- `$store` syntax in JavaScript
- Store subscription patterns
- Derived state computations

**SvelteKit routing:**
- File-based route patterns
- Layout inheritance
- Route parameters (`[slug]`, `[id]`)

**SvelteKit forms:**
- `enhance` action usage
- Form state management
- Progressive enhancement

### 10. Confidence Levels

| Confidence | Indicators |
|------------|------------|
| **Definitive** | `data-sveltekit-*` attributes present, `/_app/immutable/` paths |
| **High** | `__SVELTEKIT__` global, Svelte store patterns in bundle |
| **Medium** | Svelte component markers, Vite+SvelteKit build patterns |
| **Low** | Client-side routing patterns, reactive UI behavior |

### 11. False Positive Mitigation

**Not SvelteKit if:**
- React/Vue/Angular globals also present
- No `data-sveltekit` attributes in HTML
- Different static asset patterns (Next.js, Nuxt, etc.)
- Uses different SSR framework

**Verification command:**
```bash
# Comprehensive SvelteKit check
curl -s https://target.example.com/ | python3 -c "
import sys, re
html = sys.stdin.read()

indicators = {
    'data-sveltekit_attrs': 'data-sveltekit' in html,
    'sveltekit_global': '__SVELTEKIT__' in html,
    'immutable_paths': '/_app/immutable/' in html,
    'svelte_patterns': 'svelte' in html.lower() and ('writable' in html or 'readable' in html),
}

score = sum(indicators.values())
if score >= 2:
    print('[SVELTEKIT-CONFIRMED] Multiple indicators found')
    for k, v in indicators.items():
        if v: print(f'  - {k}')
else:
    print('[SVELTEKIT-NOT-DETECTED] Insufficient evidence')
"
```

### 12. Integration with Beacon Phase 3

Add to site-recon Phase 3 (Fingerprint):

```bash
# SvelteKit detection in fingerprint phase
if curl -s "${TARGET_URL}" | grep -q -E 'data-sveltekit|/_app/immutable/|__SVELTEKIT__'; then
    echo "[FRAMEWORK-DETECTED:sveltekit]"
    # Trigger tech pack load in Phase 4
fi
```