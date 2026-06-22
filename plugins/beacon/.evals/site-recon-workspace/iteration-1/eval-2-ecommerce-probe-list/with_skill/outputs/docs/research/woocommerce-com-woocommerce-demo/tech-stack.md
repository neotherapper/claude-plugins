# Tech Stack — woocommerce.com

## Framework Detection
| Signal | Framework | Confidence |
|--------|-----------|------------|
| `x-powered-by: WordPress VIP` | WordPress VIP | High |
| `wp-content/` (not observed) | WooCommerce via JS | High |
| `window.wcAnalytics` JS global | WooCommerce | High |

## Version Evidence
- **WordPress:** 6.9.4 (`generator` meta tag)
- **WooCommerce:** 10.7.0-rc.1 (from `wcAnalytics.woo_version`)
- **WooCommerce Blocks:** 4.3.1 (`wc_prl_params.version`)
- **PHP:** Unknown
- **Jetpack:** 15.5-beta

## Server Info
- **Server:** nginx
- **Vip:** true (from `host-header`)
- **Cache:** STALE (x-cache header)

## CDN
Unknown — WP VIP manages CDN behind their proxy.

## Auth
- **Store API:** None (public access)
- **REST API v3:** Consumer key/secret required
- **AJAX:** None (public access)