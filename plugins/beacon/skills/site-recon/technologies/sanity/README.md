---
framework: sanity
version: "3.x"
last_updated: "2026-05-11"
author: "@neotherapper"
status: community
---

# Sanity — Platform Overview

Sanity is a headless CMS with a real-time collaborative editing experience, distinguished by its schema-as-code approach and the Sanity Studio — an open-source React-based editing interface. This tech pack covers fingerprinting, API surface discovery, and reconnaissance patterns for Sanity-powered sites.

## Platform Overview

Sanity is a commercial headless CMS featuring:
- **Sanity Studio** — Customizable React editing interface
- **GROQ** — Sanity's query language for content delivery
- **Real-time collaboration** — Live updates via WebSockets
- **Structured content** — Schema defined in code (not GUI)
- **Asset pipeline** — Image transformation and CDN
- **Portable Text** — Rich text format as JSON

## Fingerprinting Indicators

| Indicator | Type | Notes |
|-----------|------|-------|
| `sanity.io` domain in requests | Network | API and asset requests |
| `cdn.sanity.io` | CDN | Asset and JS delivery |
| `sanitycdn.com` | CDN | Older deployments |
| `/_` routes in HTML | Route | Sanity Studio embedded |
| `window.__SANITY__` | JS global | Studio initialization |
| `window.SANITY_DATA` | JS global | Embedded studio data |
| `@sanity/client` in bundles | Package | SDK detection |
| `groq` query string | Request | GROQ queries in requests |
| `projectId` in requests | API param | Sanity project identifier |

## Resources

- [Sanity Docs](https://www.sanity.io/docs)
- [GROQ Query Language](https://www.sanity.io/docs/groq)
- [Sanity API](https://www.sanity.io/docs/api-overview)
- [Sanity Studio](https://www.sanity.io/docs/studio)
- [JavaScript Client](https://www.sanity.io/docs/js-client)
- [Image URL Builder](https://www.sanity.io/docs/image-url-builder)

## Common Stack Pairings

| Technology | Purpose | Detection |
|------------|---------|-----------|
| Next.js | React framework | `/_next/` paths, SSR |
| Gatsby | Static generation | `gatsby-*` packages |
| Nuxt | Vue framework | Vue SFCs with Sanity |
| SvelteKit | Svelte framework | SvelteKit + @sanity/client |
| Sanity Studio | Admin interface | `/_/` routes, Studio embedded |
| GROQ | Query language | Query strings in API requests |

## Known Public Data Patterns

Sanity's Content Lake API (`api.sanity.io`) delivers published content. The `/v2024-01-01/` versioned API is commonly used. Queries are sent as GROQ strings in POST request bodies. Asset URLs follow predictable patterns with project IDs.