---
name: wordpress
description: WordPress is the world's most popular CMS, powering 40%+ of websites
version: 6.x
---

# WordPress Tech Pack

## API Surfaces

### REST API
- `/wp-json/` — API root, lists available routes
- `/wp-json/wp/v2/posts` — Posts CRUD
- `/wp-json/wp/v2/pages` — Pages CRUD
- `/wp-json/wp/v2/media` — Media library
- `/wp-json/wp/v2/users` — User management
- `/wp-json/wc/v3/*` — WooCommerce (if installed)
- `/wp-json/tribe/events/v1/*` — The Events Calendar (if installed)

### XML-RPC
- `/xmlrpc.php` — Classic XML-RPC API
- `wp.getUsersBlogs` — Multisite user check

### GraphQL
- `/graphql` — WPGraphQL plugin (if installed)

## Auth Patterns

- Application Passwords (WP 5.6+) — Authorization: Basic base64(user:app_password)
- Nonces — `X-WP-Nonce` header or `_wpnonce` param
- Cookie auth — requires `wp-auth-check` CSRF gate

## Discovery Checklist

- [ ] `/wp-json/` — REST API root
- [ ] `/wp-json/wp/v2/posts?per_page=1` — Posts endpoint
- [ ] `/xmlrpc.php` — XML-RPC endpoint
- [ ] `wp-login.php` — Login page
- [ ] `readme.html` — Version leak (often removed)
- [ ] `wp-config.php.bak` — Config backup leak
- [ ] `/wp-content/uploads/` — Media directory
- [ ] `/wp-json/wc/v3/` — WooCommerce API (if ecommerce)

## Common Endpoints

- `GET /wp-json/wp/v2/posts` — List posts
- `GET /wp-json/wp/v2/pages` — List pages
- `GET /wp-json/wp/v2/categories` — Categories/taxonomies
- `GET /wp-json/wp/v2/tags` — Tags
- `GET /wp-json/wp/v2/search` — Search endpoint
- `POST /wp-json/wp/v2/posts` — Create post (auth required)