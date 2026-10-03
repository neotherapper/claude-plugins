---
framework: contentful
version: "current"
last_updated: "2026-05-11"
author: "@neotherapper"
status: community
---

# Contentful — Platform Overview

Contentful is a headless CMS that separates content from presentation, delivering content via APIs (Content Delivery API and Content Management API) to any channel. This tech pack covers fingerprinting, API surface discovery, and reconnaissance patterns for Contentful-powered sites.

## Platform Overview

Contentful is a commercial headless CMS used by enterprises worldwide. It provides:
- **Content Delivery API** — Read-only delivery of published content
- **Content Management API** — Read-write management of content
- **Content Preview API** — Access to draft/unpublished content
- **webApp** — Browser-based content editing interface
- **CLI** — Management via `contentful-cli`

## Fingerprinting Indicators

| Indicator | Type | Notes |
|-----------|------|-------|
| `ctfl.io` domain in requests | Network | Contentful preview/delivery host |
| `cdn.contentful.com` | CDN | Static asset delivery |
| `images.ctfassets.net` | CDN | Image delivery |
| `contentful` in JS bundle names | Bundle | SDK and plugin detection |
| `window.contentful` | JS global | Contentful SDK initialization |
| `space_id` in requests | Request param | Contentful space identifier |
| `access_token` in requests | Auth header | API access token |
| `_ga` or `ajs_anonymous_id` cookies | Analytics | Often present on Contentful sites |

## Resources

- [Contentful Docs](https://www.contentful.com/developers/docs/)
- [Content Delivery API](https://www.contentful.com/developers/api-references/content-delivery-api/)
- [Content Management API](https://www.contentful.com/developers/api-references/content-management-api/)
- [GraphQL Content API](https://www.contentful.com/developers/docs/references/graphql/)
- [Contentful CLI](https://www.contentful.com/developers/docs/tutorials/cli/)
- [Official SDKs](https://www.contentful.com/developers/docs/sdks/)

## Common Stack Pairings

| Technology | Purpose | Detection |
|------------|---------|-----------|
| Gatsby | Static site generation | `gatsby-*` packages, `/static/` builds |
| Next.js | React framework | `/_next/` paths, React SSR |
| Nuxt | Vue framework | `/nuxt/` paths, Vue SSR |
| Astro | Content-focused SSG | `/_astro/` paths |
| Contentful UI Extensions | Custom editors | `ctf()` API in extension iframes |

## Known Public Data Patterns

Contentful-delivered content is often publicly accessible. Published content via the Delivery API typically has no auth requirement. Preview API requires a separate access token.