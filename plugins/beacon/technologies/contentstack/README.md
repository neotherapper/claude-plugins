---
framework: contentstack
version: "3.x"
last_updated: "2026-05-11"
author: "@neotherapper"
status: community
---

# Contentstack — Platform Overview

Contentstack is a headless CMS designed for enterprise, offering a headless architecture with a cloud-based management dashboard. This tech pack covers fingerprinting, API surface discovery, and reconnaissance patterns for Contentstack-powered sites.

## Platform Overview

Contentstack is a commercial headless CMS featuring:
- **Content Delivery API** — CDN-cached published content delivery
- **Content Management API** — Content authoring and management
- **Assets API** — Digital asset management
- **Global Fields** — Reusable field schemas
- **Workflows** — Content publishing approval flows
- **Environments** — Multiple deployment targets
- **Webhooks** — Event-driven integrations

## Fingerprinting Indicators

| Indicator | Type | Notes |
|-----------|------|-------|
| `contentstack.com` in requests | Network | API and asset requests |
| `cdn.contentstack.com` | CDN | Asset delivery |
| `api.contentstack.com` | API | Management and delivery API |
| `app.contentstack.com` | App domain | Management dashboard |
| `window.contentstack` | JS global | SDK initialization |
| `st-content` in HTML | Class prefix | Contentstack-rendered elements |
| `x-header` patterns | API headers | Contentstack-specific headers |
| `api_key` in requests | API param | Contentstack API key |
| `access_token` in requests | API param | Delivery API token |

## Resources

- [Contentstack Docs](https://www.contentstack.com/docs)
- [Content Delivery API](https://www.contentstack.com/docs/apis/content-management-api/)
- [Content Delivery API Reference](https://www.contentstack.com/docs/apis/content-delivery-api/)
- [SDKs](https://www.contentstack.com/docs/sdks)
- [Webhooks](https://www.contentstack.com/docs/webhooks)
- [Environments](https://www.contentstack.com/docs/environments)

## Common Stack Pairings

| Technology | Purpose | Detection |
|------------|---------|-----------|
| React | UI framework | React SDK |
| Next.js | React framework | Next.js SDK |
| Nuxt | Vue framework | Vue SDK |
| Gatsby | Static generation | Gatsby source plugin |
| Node.js | Runtime | Management SDK |
| Ruby | Ruby integration | Ruby SDK |

## Known Public Data Patterns

Contentstack's Delivery API (`cdn.contentstack.com`) delivers published content through globally distributed CDN. Content is fetched by content type and locale. Management API (`api.contentstack.com`) handles authoring and requires authentication.