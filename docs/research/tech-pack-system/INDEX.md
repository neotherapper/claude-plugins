# Tech Pack System — Research Reference

> Tech packs are community-maintained, version-aware guides that tell Beacon exactly where to look for APIs on sites using a specific framework. They live in `technologies/` at the plugin root.

## What a Tech Pack Is

A tech pack is a markdown file that answers: "For a site running {framework} {version}, where should Beacon look?"

It is NOT site-specific. It contains only framework-level patterns — no real domain names, no real API keys, no production URLs.

Think of it as a checklist that a security researcher would write after deeply knowing a framework: "WordPress always exposes `/wp-json/wp/v2/` as REST root; always check `/wp-admin/admin-ajax.php` for AJAX actions; check the source for `wp_create_nonce`."

## File Location and Naming

```
technologies/
├── wordpress/
│   ├── 6.x.md
│   └── 5.x.md
├── nextjs/
│   ├── 15.x.md
│   └── 14.x.md
├── nuxt/
│   ├── 3.x.md
│   └── 2.x.md
├── django/
│   └── 5.x.md
├── rails/
│   └── 7.x.md
├── astro/
│   └── 4.x.md
├── laravel/
│   └── 11.x.md
├── shopify/
│   ├── storefront.md   ← non-versioned (uses API version in URL)
│   └── admin.md
├── ghost/
│   └── 5.x.md
└── strapi/
    └── 5.x.md
```

### Naming Rules

- Directory: lowercase slug matching framework name (no spaces, hyphens OK)
- File: `{major}.x.md` — covers the entire major version
- Exception: frameworks where versioning is in the URL path (Shopify, some APIs) → descriptive name instead

## Tech Pack Schema (10 Required Sections)

Every tech pack MUST contain all 10 sections. Schema validation rejects incomplete packs.

```markdown
---
framework: wordpress
version: "6.x"
last_updated: "2026-04-11"
author: "@neotherapper"
status: community|official
---

# {Framework} {Version} — Tech Pack

## 1. Fingerprinting Signals

How to detect this framework and version from HTTP responses.

| Signal | Type | Value | Confidence |
|--------|------|-------|------------|
| `wp-content/` in HTML | HTML | substring | High |
| `wp-json/` in HTML | HTML | substring | High |
| `X-Powered-By` header | HTTP header | varies | Medium |
| Generator meta tag | HTML meta | `WordPress {version}` | Version |

**Version extraction:**
```bash
curl -s {site} | grep -oP 'WordPress \K[\d.]+'
```

## 2. Default API Surfaces

Known public endpoints for this framework version. All paths are relative to site root.

| Endpoint | Method | Auth Required | Notes |
|----------|--------|--------------|-------|
| `/wp-json/` | GET | No | REST API root, lists all routes |
| `/wp-json/wp/v2/posts` | GET | No | Published posts |
| `/wp-json/wp/v2/users` | GET | No* | *Email hidden unless admin |
| `/wp-admin/admin-ajax.php` | POST | Varies | Legacy AJAX handler |

## 3. Config & Constants Locations

Where framework config, keys, and secrets typically appear in source and runtime.

| Location | What's there | How to access |
|----------|-------------|---------------|
| `wp-config.php` | DB credentials, secret keys | Source only (not accessible) |
| `/wp-json/` root | REST API namespace list | Public GET |
| `window.wpApiSettings` | REST API nonce, root URL | JS eval in browser |
| `data-nonce` attributes | Per-form nonces | HTML scrape |

## 4. Auth Patterns

Authentication mechanisms used by this framework.

| Pattern | Where it appears | Notes |
|---------|-----------------|-------|
| WP REST nonce (`X-WP-Nonce`) | `wp_create_nonce('wp_rest')` | Valid ~24h (daily WP salt) |
| Application passwords | Basic auth header | WP 5.6+, user account feature |
| Cookie auth | `wordpress_logged_in_*` | Browser session only |
| JWT (if plugin) | Bearer token | Plugin-dependent |

**Nonce acquisition:**
The REST nonce is exposed in `window.wpApiSettings.nonce` when `wp-api.min.js` is loaded. 
It is also injected inline via `wp_localize_script`.

## 5. JS Bundle Patterns

Where JS chunks and source maps typically live for this framework.

| Path | Content |
|------|---------|
| `/wp-content/themes/{theme}/assets/js/` | Theme JS |
| `/wp-content/plugins/{plugin}/assets/` | Plugin JS |
| `/wp-includes/js/` | Core WordPress JS |

Source maps: check `{bundle}.map` for each bundle URL found.

## 6. Source Map Patterns

Framework-specific source map patterns and what they reveal.

(For WordPress: themes and plugins may have source maps if compiled with webpack/vite.
Standard WordPress core files do NOT have source maps in production.)

## 7. Common Plugins & Extensions

High-value plugins that add significant API surface.

| Plugin | What it adds | Detection signal |
|--------|-------------|-----------------|
| WooCommerce | `/wp-json/wc/v3/` REST API (products, orders, customers) | `woocommerce` in HTML/cookies |
| ACF Pro | `/wp-json/acf/v3/` | `acf/` in source |
| WPML | Language switcher patterns, `/wp-json/wpml/` | WPML cookies |
| Elementor | `/wp-json/elementor/` | Elementor CSS/JS |
| Gravity Forms | `/wp-json/gf/v2/` | `gravityforms` in HTML |
| MEC (Events Calendar) | `/wp-json/wp/v2/mec-events`, `/wp-json/mec/v1/` | `mec` in HTML |

## 8. Known Public Data

Public data endpoints that typically return useful information without auth.

| Endpoint | Data | Example |
|----------|------|---------|
| `/wp-json/wp/v2/categories` | All post categories | Taxonomy structure |
| `/wp-json/wp/v2/tags` | All post tags | Content taxonomy |
| `/wp-json/wp/v2/media` | Public media library | Image URLs, alt text |
| `/feed/` | RSS feed | Recent posts, content |
| `/wp-sitemap.xml` | Full site map | All URLs by post type |

## 9. Probe Checklist

Ordered checklist of probes to run for this framework. Check all items.

- [ ] `GET /wp-json/` — REST API root (lists namespaces)
- [ ] `GET /wp-json/wp/v2/` — Core namespace (lists all routes)
- [ ] `GET /wp-json/wp/v2/posts?per_page=1` — Confirm public posts
- [ ] `GET /wp-json/wp/v2/users?per_page=10` — User list (may be public)
- [ ] `POST /wp-admin/admin-ajax.php` — AJAX endpoint (try with `action=heartbeat`)
- [ ] `GET /wp-sitemap.xml` — Built-in sitemap (WP 5.5+)
- [ ] Check HTML for `window.wpApiSettings` or `window.wp`
- [ ] Check for WooCommerce: `GET /wp-json/wc/v3/` (if woocommerce detected)
- [ ] Check for ACF: `GET /wp-json/acf/v3/` (if acf detected)
- [ ] Probe plugin-specific namespaces from `/wp-json/` root listing

## 10. Gotchas

Known quirks, security configs, and non-obvious behaviour.

- **REST API can be completely disabled** via plugin (Disable REST API, etc.). If `/wp-json/` returns 401/403, the site has disabled public REST access.
- **AJAX endpoint always accessible** even when REST is disabled. Try common AJAX actions.
- **Nonce stability**: The REST nonce changes daily (based on WP salt), not per-request. Fetch once and reuse for the session.
- **User enumeration block**: Some security plugins block `/wp-json/wp/v2/users`. A 403 here is normal.
- **REST API namespace sprawl**: Large sites may have 20+ namespaces in the root listing. Check all of them.
- **XML-RPC**: `/xmlrpc.php` is the legacy API (deprecated but often still active). System call: `system.listMethods`.
```

## Version Coverage Strategy

| Situation | Action |
|-----------|--------|
| User site is `nextjs@15.2.0` | Load `technologies/nextjs/15.x.md` |
| User site is `nextjs@14.3.1` | Load `technologies/nextjs/14.x.md` |
| Pack exists for 15.x but site is 15.4 (new minor) | Use 15.x pack with caveat |
| Pack exists for 5.x but site is 6.x (no 6.x pack yet) | Use 5.x pack as baseline + offer to create PR for 6.x |
| No pack exists at all | Web search fallback + offer PR |

## Pack Validation (CI)

PR validation runs this check on all tech pack files:

1. YAML frontmatter: `framework`, `version`, `last_updated`, `author`, `status` all present
2. All 10 sections present (checked by heading count + name match)
3. No real domain names (regex: fails if `https?://[a-z0-9-]+\.[a-z]{2,6}` appears outside examples)
4. No credentials or API keys (regex scan)

Schema file: `schemas/tech-pack.schema.json`

## Community Contribution Flow

When Beacon encounters a missing tech pack:

```
1. Log [TECH-PACK-UNAVAILABLE:{framework}:{version}] in session brief
2. Run web search: "{framework} {version} API routes endpoints file structure"
3. Summarise findings as a temporary in-memory pack
4. Offer user: "Would you like to open a PR to add this pack to the community?"
5. If yes:
   a. Draft the pack file following the 10-section schema
   b. Show user for review
   c. Guide: create branch tech-pack/{framework}-{version}
   d. PR title: feat(tech-packs): add {framework} {version}
   e. DCO sign-off required: git commit -s
```

The CONTRIBUTING.md in the beacon-plugin repo documents this flow for contributors.

## Currently Shipped Packs

| Framework | Versions |
|-----------|---------|
| WordPress | 6.x, 5.x |
| Next.js | 15.x, 14.x |
| Nuxt | 3.x, 2.x |
| Django | 5.x |
| Rails | 7.x |
| Astro | 4.x |
| Laravel | 11.x |
| Shopify | storefront, admin |
| Ghost | 5.x |
| Strapi | 5.x |

Community additions welcome via PR.

## Source

- Design spec §§ 3, 4 (tech pack section), 7 (PR-04 through PR-08), 8 (community flow)
- CONTRIBUTING.md in beacon-plugin repo
- Elevate Greece research as example of WordPress tech pack application
