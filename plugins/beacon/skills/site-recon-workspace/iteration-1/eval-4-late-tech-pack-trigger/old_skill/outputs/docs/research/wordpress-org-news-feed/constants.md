# wordpress.org/news — Constants & Configuration Values

**Analysed:** 2026-04-27
**Target:** https://wordpress.org/news/feed/
**Skill version:** OLD (v0.5.0 baseline)

## Post Types (from REST API /wp/v2/types)
| Key | REST Base | Notes |
|-----|-----------|-------|
| post | posts | WordPress standard blog posts |
| page | pages | Static pages |
| attachment | media | Media library items |
| wp_block | blocks | Reusable block content |
| wp_template | templates | Site editor templates |
| wp_navigation | navigation | Navigation menus |
| podcast | podcast | Simple Podcasting plugin |

## REST API Namespaces (from /wp-json/)
| Namespace | Notes |
|-----------|-------|
| wp/v2 | Core WordPress REST API |
| oembed/1.0 | Embed support |
| wporg/v1 | WordPress.org specific |
| jetpack/v4 | Jetpack plugin features |
| akismet/v1 | Akismet spam protection |
| wpcom/v2, wpcom/v3 | WordPress.com specific endpoints |
| two-factor/1.0 | Two-factor authentication |
| wp-site-health/v1 | Site health diagnostic endpoint |
| wp-block-editor/v1 | Block editor integration |
| wp-abilities/v1 | Capabilities/permissions |

## API Version Signal
- Feed generator: `https://wordpress.org/?v=7.1-alpha-62259` — reveals WordPress 7.1-alpha
- REST API base shows full /wp-json/ with public read access

## CDN / Infrastructure
- nginx server (inferred from Server header absent but standard WP.org infra)
- `x-nc: HIT ord 2` — OpenResty/Cloudflare layer

## Notes
- All public API endpoints require no authentication for read operations
- User enumeration is enabled (user IDs exposed in REST API)