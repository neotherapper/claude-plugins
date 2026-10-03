# Vercel Fingerprinting Guide

## Detection Methods

### 1. HTTP Response Header Analysis

```bash
# Check for Vercel-specific headers
curl -I https://target.example.com/ 2>/dev/null | grep -i 'x-vercel\|vercel\|now-'
```

**Key Vercel headers:**
- `x-vercel-id` – Unique deployment identifier
- `x-vercel-deployment-url` – Deployment URL
- `x-now-id` – Legacy Now.sh deployment ID
- `x-now-dashboard` – Dashboard link (preview deployments)
- `server: Vercel` – Server header
- `server: cloudflare` – When using Vercel + Cloudflare

### 2. Configuration File Discovery

```bash
# Check for exposed Vercel configuration
curl -sf --max-time 5 "https://target.example.com/vercel.json" && echo "vercel.json found"
curl -sf --max-time 5 "https://target.example.com/now.json" && echo "now.json found (legacy)"
curl -sf --max-time 5 "https://target.example.com/.vercel/project.json" && echo ".vercel/project.json found"
```

### 3. Vercel Domain Patterns

```bash
# Check for Vercel preview/production domains
# *.vercel.app patterns
curl -sf --max-time 5 "https://target.example.com/" | grep -o 'https\?://[^"]*\.vercel\.app[^"]*' | head -5

# Check if domain is on Vercel
curl -I https://target.example.com/ 2>/dev/null | grep -i 'x-vercel'
```

### 4. Serverless Function Detection

```bash
# Common Vercel API patterns
curl -sf --max-time 5 "https://target.example.com/api/"
curl -sf --max-time 5 "https://target.example.com/api/_vercel/"
curl -sf --max-time 5 "https://target.example.com/api/hello"

# Vercel internal endpoints
curl -sf --max-time 5 "https://target.example.com/api/_vercel/deployment"
curl -sf --max-time 5 "https://target.example.com/api/_vercel/insights"
```

### 5. Edge Function Detection

Vercel Edge Functions run on V8 isolates with specific characteristics:

```bash
# Edge function indicators in response
curl -I https://target.example.com/ 2>/dev/null | grep -E '(x-edge|server-timing|x-vercel-id)'

# Check for Edge runtime markers
curl -s https://target.example.com/ | grep -o 'Edge\|edge-runtime\|worker' | sort | uniq
```

### 6. Next.js on Vercel

Next.js is the most common framework on Vercel:

```bash
# Next.js specific endpoints
curl -sf --max-time 5 "https://target.example.com/_next/" && echo "Next.js on Vercel"
curl -sf --max-time 5 "https://target.example.com/api/" && echo "Next.js API routes"
curl -sf --max-time 5 "https://target.example.com/api/_next/webpack" && echo "Next.js webpack"
```

### 7. Vercel Storage Services Detection

```bash
# Vercel KV (Redis-compatible)
curl -sf --max-time 5 "https://target.example.com/api/kv" || true

# Look for Vercel storage patterns in bundle
curl -s https://target.example.com/ | grep -o 'vercel-kv\|vercel-storage\|@vercel/kv' | sort | uniq
```

### 8. Build Output Analysis

```bash
# Look for Vercel build output patterns
curl -s https://target.example.com/ | grep -o 'vercel\|now-[a-z0-9]\+' | sort | uniq

# Check for Vercel deployment metadata
curl -s https://target.example.com/ | grep -o '"deploymentId":"[^"]*"' || true
```

### 9. Version Detection

```bash
# Check vercel.json for version info
curl -sf --max-time 5 "https://target.example.com/vercel.json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print('Vercel version:', d.get('version', 'unknown'))
    print('Framework:', d.get('framework', 'not specified'))
except: pass
"

# Check response headers for deployment info
curl -I https://target.example.com/ 2>/dev/null | grep -i 'x-vercel-id\|x-now'
```

### 10. Framework-Specific Patterns

**Next.js on Vercel:**
- `/_next/static/` – Static assets
- `/api/*` – Serverless functions
- `__NEXT_DATA__` – SSR hydration
- `.next/` directory references

**SvelteKit on Vercel:**
- `/_app/immutable/` – SvelteKit build output
- `/api/*` – Serverless functions

**Nuxt on Vercel:**
- `/_nuxt/` – Nuxt build output
- `/api/*` – Serverless functions

### 11. Confidence Levels

| Confidence | Indicators |
|------------|------------|
| **Definitive** | `x-vercel-*` headers present, `vercel.json` exposed |
| **High** | `x-now-*` headers, `.vercel.app` domain |
| **Medium** | `server: Vercel` header, serverless function patterns |
| **Low** | Generic serverless patterns, Next.js on Vercel hints |

### 12. False Positive Mitigation

**Not Vercel if:**
- No Vercel headers present
- Different CDN/provider detected
- Cloudflare or other hosting layer in use
- Self-hosted deployment patterns

**Verification command:**
```bash
# Comprehensive Vercel check
curl -I https://target.example.com/ 2>/dev/null | python3 -c "
import sys
headers = sys.stdin.read()

indicators = {
    'x-vercel-headers': 'x-vercel' in headers.lower(),
    'vercel-config': 'vercel.json' in headers,
    'now-headers': 'x-now-' in headers.lower(),
    'server-vercel': 'server: vercel' in headers.lower(),
}

score = sum(indicators.values())
if score >= 1:
    print('[VERCEL-CONFIRMED] Vercel deployment detected')
    for k, v in indicators.items():
        if v: print(f'  - {k}')
else:
    print('[VERCEL-NOT-DETECTED] Insufficient evidence')
"
```

### 13. Integration with Beacon Phase 2-3

Add to site-recon Phase 2 (Passive recon) or Phase 3 (Fingerprint):

```bash
# Vercel detection in passive recon phase
headers=$(curl -I --max-time 10 "${TARGET_URL}" 2>/dev/null || true)
if echo "$headers" | grep -qi 'x-vercel\|server: vercel'; then
    echo "[PLATFORM-DETECTED:vercel]"
    echo "$headers" | grep -i 'x-vercel'
    # Trigger Vercel tech pack load in Phase 4
fi
```

### 14. Deployment Type Detection

```bash
# Production vs Preview deployment
curl -I https://target.example.com/ 2>/dev/null | grep -i 'x-now-dashboard' && echo "[VERCEL-PREVIEW-DEPLOYMENT]"
curl -I https://target.example.com/ 2>/dev/null | grep -i 'x-vercel-id' && echo "[VERCEL-DEPLOYMENT-ID: captured]"

# Check for preview deployment patterns
curl -sf --max-time 5 "https://target.example.com/api/_vercel/deployment" && echo "[VERCEL-DEPLOYMENT-API]"
```