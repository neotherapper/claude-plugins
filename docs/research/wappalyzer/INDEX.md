# Wappalyzer MCP — Research Reference

> Wappalyzer identifies technologies on websites. In Beacon, it's the primary fingerprinting tool when available (Phase 3). Falls back to header/HTML grep when unavailable.

## MCP Server Setup

```json
{
  "mcpServers": {
    "wappalyzer": {
      "command": "npx",
      "args": ["-y", "@wappalyzer/mcp"],
      "env": {
        "WAPPALYZER_API_KEY": "${WAPPALYZER_API_KEY}"
      }
    }
  }
}
```

Requires: `WAPPALYZER_API_KEY` from https://www.wappalyzer.com/api/

## Available Tools

### `lookup_site`

Identify technologies used by a website.

```
Input:
  url: string (required) — full URL including scheme (https://example.com)
  
Output:
  technologies: Array<{
    name: string          // "WordPress", "Next.js", "Cloudflare"
    categories: string[]  // ["CMS", "JavaScript frameworks", "CDN"]
    version: string | null // "6.5.2" or null if not detected
    confidence: number    // 0-100
  }>
  
Credit cost: 1 credit per request
```

**Example response:**
```json
{
  "technologies": [
    { "name": "WordPress", "categories": ["CMS"], "version": "6.5", "confidence": 100 },
    { "name": "PHP", "categories": ["Programming languages"], "version": "8.2", "confidence": 75 },
    { "name": "Cloudflare", "categories": ["CDN"], "version": null, "confidence": 100 },
    { "name": "WooCommerce", "categories": ["Ecommerce"], "version": "8.9", "confidence": 90 }
  ]
}
```

### `lookup_subdomains`

Discover subdomains with their technology fingerprints.

```
Input:
  domain: string (required) — domain without scheme (example.com)
  
Output:
  subdomains: Array<{
    subdomain: string       // "api.example.com"
    technologies: Array<{
      name: string
      categories: string[]
      version: string | null
    }>
  }>

Credit cost: varies (typically 5-20 credits depending on subdomain count)
```

### `get_credit_balance`

Check remaining API credits.

```
Input: none

Output:
  balance: number   // remaining credits
  plan: string      // "free", "starter", "pro", etc.
```

## Beacon Integration — Phase 3 (Fingerprinting)

Detection priority (first match wins):

1. **Wappalyzer MCP** (primary, if available): `lookup_site(url)` → extract framework + version from result
2. **HTTP headers fallback**: grep `X-Powered-By`, `Server`, framework-specific headers
3. **HTML/JS fallback**: grep `wp-content/`, `/_next/`, `/_nuxt/`, meta generator tags

```markdown
Phase 3 decision logic:

IF wappalyzer MCP available:
  result = lookup_site(target_url)
  framework = result.technologies.find(t => t.categories.includes("JavaScript frameworks") || t.categories.includes("CMS"))
  version = framework.version
  log to session brief: "Framework: {name} {version} (Wappalyzer, confidence: {confidence}%)"

ELSE:
  log [TOOL-UNAVAILABLE:wappalyzer]
  Proceed with header/HTML fingerprinting (see Phase 3 detail in site-recon skill)
```

## Fingerprinting Without Wappalyzer

When Wappalyzer is unavailable, use these signals:

| Signal | Location | Detected tech |
|--------|----------|--------------|
| `X-Powered-By: Next.js` | HTTP header | Next.js |
| `/_next/static/` | HTML src attributes | Next.js |
| `x-nuxt` | HTTP header | Nuxt |
| `/_nuxt/` | HTML src attributes | Nuxt |
| `wp-content/`, `wp-json/` | HTML | WordPress |
| Generator meta tag | `<meta name="generator">` | WordPress (with version) |
| `data-djversion` | HTML meta | Django |
| `/static/rest_framework/` | HTML src | Django REST |
| `laravel_session` | Cookie | Laravel |
| `X-Inertia` | HTTP header | Laravel/Inertia |
| `_shopify_y` | Cookie | Shopify |
| `/cdn.shopify.com/` | HTML src | Shopify |
| `Ghost-Version` | HTTP header | Ghost (with version) |
| `/ghost/api/` | HTML links | Ghost |

**Version extraction patterns:**
```bash
# WordPress version from generator meta
curl -s https://example.com | grep -oP 'WordPress \K[\d.]+'

# Next.js version from __NEXT_DATA__
curl -s https://example.com | grep -oP '"next":"\K[^"]+' | head -1

# Ghost version from header
curl -I https://example.com | grep -i ghost-version
```

## Credit Management

- `lookup_site`: 1 credit per call — use once per analysis, not per phase
- `lookup_subdomains`: use judiciously, especially on large sites
- Call `get_credit_balance` at session start if concerned about credit burn

## Availability Check

```markdown
Check if Wappalyzer MCP is available:
  Look for 'lookup_site' in the available MCP tools list.
  
If not available:
  log [TOOL-UNAVAILABLE:wappalyzer] in session brief
  Use header + HTML fingerprinting (free, no API key required)
```

## Source

- Wappalyzer API docs: https://www.wappalyzer.com/api/
- MCP package: `@wappalyzer/mcp`
- nikai research (AI tools knowledge vault — wappalyzer stub)
