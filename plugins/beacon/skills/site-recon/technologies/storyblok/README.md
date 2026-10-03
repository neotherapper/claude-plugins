---
framework: storyblok
version: "2.x"
last_updated: "2026-05-11"
author: "@neotherapper"
status: community
---

# Storyblok — Platform Overview

Storyblok is a headless CMS with a visual editing experience, offering both a traditional field-based editor and a Visual Editor for drag-and-drop content composition. This tech pack covers fingerprinting, API surface discovery, and reconnaissance patterns for Storyblok-powered sites.

## Platform Overview

Storyblok is a commercial headless CMS featuring:
- **Visual Editor** — Drag-and-drop page composition
- **Stories** — Content entries organized hierarchically
- **Components** — Reusable content blocks
- **Content Delivery API** — Published content delivery
- **Content Management API** — Read-write content management
- **Plugin System** — Custom field types and extensions
- **Preview Mode** — Draft content viewing

## Fingerprinting Indicators

| Indicator | Type | Notes |
|-----------|------|-------|
| `storyblok.com` in requests | Network | API and asset requests |
| `a.storyblok.com` | CDN | Asset delivery |
| `app.storyblok.com` | App domain | Storyblok management interface |
| `api.storyblok.com` | API domain | API endpoints |
| `window.Storyblok` | JS global | SDK initialization |
| `storyblok-js` in bundles | Package | SDK detection |
| `_storyblork` cookie | Cookie | Preview/editor cookie |
| `space_id` in requests | API param | Storyblok space identifier |

## Resources

- [Storyblok Docs](https://www.storyblok.com/docs)
- [Content Delivery API](https://www.storyblok.com/docs/api/content-delivery-api)
- [Management API](https://www.storyblok.com/docs/api/management-api)
- [JavaScript SDK](https://www.storyblok.com/docs/api/javascript)
- [Visual Editor](https://www.storyblok.com/docs/guide/master/visual-editor)
- [Regions and URLs](https://www.storyblok.com/docs/api/content-delivery-api#core-resources/regions)

## Common Stack Pairings

| Technology | Purpose | Detection |
|------------|---------|-----------|
| Next.js | React framework | `/_next/` paths, SSR |
| Nuxt | Vue framework | Vue SFCs with Storyblok |
| Gatsby | Static generation | `gatsby-source-storyblok` |
| SvelteKit | Svelte framework | SvelteKit + Storyblok SDK |
| PHP/Symfony | PHP integration | `storyblok/php-client` |
| Ruby | Ruby integration | `storyblok/ruby-client` |

## Known Public Data Patterns

Storyblok's Content Delivery API (`api.storyblok.com`) delivers published content. Stories are fetched by slug. Components are rendered as nested JSON. The Visual Editor uses iframe-based live preview with `_storyblork` cookies for draft content.