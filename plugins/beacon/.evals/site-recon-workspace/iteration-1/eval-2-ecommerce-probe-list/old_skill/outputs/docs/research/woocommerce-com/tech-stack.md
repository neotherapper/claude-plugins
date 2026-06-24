# woocommerce.com — Tech Stack

## Framework
| Property | Value |
|----------|-------|
| Framework | WordPress |
| Version | 6.9.4 |
| WooCommerce Version | 9.x (inferred from wc/v3 + wc/store/v1 namespaces) |
| Platform | WordPress VIP |
| Server | nginx |

## Source Signals
- `wp-content/` in HTML
- `wp-json/` in HTTP headers
- `x-powered-by: WordPress VIP`
- Generator meta: `content="WordPress 6.9.4"`

## CDN
Cloudflare (inferred from `x-cache` headers and host-header)

## Auth
- WooCommerce REST API: Consumer Key required for `/wc/v3/` endpoints
- Store API: Public access for `/wc/store/v1/` (no auth)
- WP REST: Application passwords supported

## Bot Protection
None detected (accessible to automated probes)