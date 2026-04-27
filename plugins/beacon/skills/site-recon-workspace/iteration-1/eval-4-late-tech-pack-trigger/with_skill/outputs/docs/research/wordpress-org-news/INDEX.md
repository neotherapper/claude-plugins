# WordPress News - Site Research

**Target:** https://wordpress.org/news/feed/
**Date:** 2026-04-27

## Framework & Tech Stack

| Component | Details |
|-----------|---------|
| Framework | WordPress 7.1-alpha |
| Detection Source | Atom feed generator tag (late discovery) |
| Server | nginx |
| CDN | wordpress.org |
| Auth | WordPress Nonce (X-WP-Nonce header) |

## API Surface

### WordPress REST API
| Endpoint | Auth | Phase | Notes |
|----------|------|-------|-------|
| `/news/wp-json/` | No | 3 | API root |
| `/news/wp-json/wp/v2/posts` | No | 5 | Posts (3 latest) |
| `/news/wp-json/wp/v2/pages` | No | 5 | Pages |
| `/news/wp-json/wp/v2/categories` | No | 5 | Categories |
| `/news/wp-json/wporg/v1/*` | No | 5 | WP.org custom endpoints |

### Feeds
| Endpoint | Auth | Phase | Notes |
|----------|------|-------|-------|
| `/news/feed/` | No | 6 | Atom RSS feed |
| `/news/sitemap.xml` | No | 2 | Jetpack sitemap index |
| `/news/sitemap-1.xml` | No | 2 | Page sitemap |

## Notes

- Tech pack loaded via **late discovery** in Phase 6 from feed generator tag
- `[TECH-PACK-LATE-LOAD:wordpress:7.x:phase=6]` logged
- Used wordpress/6.x.md fallback (7.x not available in plugin tech pack)