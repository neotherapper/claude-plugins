---
framework: vercel
version: "current"
last_updated: "2026-05-02"
author: "@opencode"
status: community
---

# Vercel — Tech Pack

Vercel is a cloud platform for frontend frameworks and serverless functions, specializing in edge computing and static site hosting.

## 1. Fingerprinting Signals

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `x-vercel-*` headers | HTTP Response | Vercel-specific headers | Definitive |
| `vercel.json` config | File discovery | `/.vercel/project.json`, `/api/_vercel/*` | High |
| `now-*` references | Build output | Legacy Now.sh deployment references | Medium |
| `.vercel.app` domains | Domain pattern | Vercel Preview/Production deployments | High |
| Edge runtime markers | Response headers | V8 isolate patterns, `__NEXT_DATA__` | Medium |

**Version extraction (bash):**

```bash
# Check Vercel-specific headers
curl -I https://target.example.com/ 2>/dev/null | grep -i 'x-vercel'

# Check vercel.json if exposed
curl -sf https://target.example.com/vercel.json
curl -sf https://target.example.com/.vercel/project.json

# Look for Vercel deployment info
curl -s https://target.example.com/ | grep -o 'vercel[^"]*' | head -5
```

## 2. Default API Surfaces

Vercel serverless functions are typically at `/api/*`:

| Endpoint Pattern | Method | Auth | Notes |
|------------------|--------|------|-------|
| `/api/*` | Various | Varies | Serverless function routes |
| `/api/_vercel/*` | GET | Internal | Vercel internal endpoints |
| `/api/trpc/*` | POST | Varies | tRPC procedures if used |
| Edge Functions | Various | Varies | Vercel Edge Functions |

## 3. Config / Constants Locations

| Location | How to access | Contains |
|----------|---------------|----------|
| `vercel.json` | File discovery | Deployment configuration |
| `/.vercel/project.json` | File discovery | Project metadata |
| `/.vercel/README.txt` | File discovery | Deployment instructions |
| Environment variables | Server-side only | API keys (not exposed) |
| `next.config.js` | If Next.js | Framework configuration |

## 4. Vercel-Specific Endpoints

**Vercel internal endpoints:**
```bash
# Vercel deployment info (if exposed)
curl -sf "https://target.example.com/api/_vercel/deployment"
curl -sf "https://target.example.com/api/_vercel/insights"
```

**Common framework API routes:**
```bash
# Next.js on Vercel
curl -sf "https://target.example.com/api/*"
curl -sf "https://target.example.com/api/hello"
```

## 5. Edge Function Detection

Vercel Edge Functions run on V8 isolates and have specific patterns:

```bash
# Edge function response headers (indicative only)
curl -I https://target.example.com/ 2>/dev/null | grep -E '(x-vercel-id|x-edge-server|server-timing)'

# Edge function characteristics
curl -s https://target.example.com/ | grep -o 'Edge\|edge\|worker' | sort | uniq
```

## 6. Vercel Storage Service Endpoints

If using Vercel storage services:

```bash
# Vercel KV (Redis-compatible)
# Endpoint pattern: ${KV_REST_API_URL}

# Vercel Blob
# Endpoint pattern: ${BLOB_READ_URL_PREFIX}

# Vercel Postgres
# Endpoint pattern: ${POSTGRES_PRISMA_ENDPOINT}
```

## 7. Probe Checklist

**Phase 5 probes (Vercel platform):**

```bash
TARGET="target.example.com"

# Vercel configuration files
curl -sf "https://${TARGET}/vercel.json"
curl -sf "https://${TARGET}/.vercel/project.json"
curl -sf "https://${TARGET}/now.json"

# Check headers for Vercel markers
curl -I https://${TARGET}/ 2>/dev/null | grep -i 'x-vercel\|vercel'

# API routes discovery
curl -sf "https://${TARGET}/api/"
curl -sf "https://${TARGET}/api/hello"
curl -sf "https://${TARGET}/api/_vercel/"

# Common Next.js API routes on Vercel
for endpoint in users products auth health status; do
  curl -sf "https://${TARGET}/api/${endpoint}"
done
```

**What to log:**
- `[VERCEL-DETECTED]` when Vercel is confirmed via headers
- `[VERCEL-API:{endpoint}:{status}]` for each API probe
- `[VERCEL-STORAGE:{service}:{status}]` for Vercel storage services
- `[VERCEL-EDGE]` if Edge runtime is detected

## 8. Vercel Deployment Type Detection

```bash
# Preview deployment (typical for PRs)
curl -I https://${TARGET}/ 2>/dev/null | grep -i 'x-now-dashboard' && echo "[VERCEL-PREVIEW]"

# Production deployment
curl -I https://${TARGET}/ 2>/dev/null | grep -i 'x-now-id' && echo "[VERCEL-PRODUCTION]"

# Check for .vercel.app domain
curl -sf "https://target.vercel.app/" && echo "[VERCEL-SUBDOMAIN-DEPLOYMENT]"
```