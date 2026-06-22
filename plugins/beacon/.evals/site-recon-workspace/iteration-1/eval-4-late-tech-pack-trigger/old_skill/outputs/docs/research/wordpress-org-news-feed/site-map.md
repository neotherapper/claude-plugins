# wordpress.org/news — Site Map

**Analysed:** 2026-04-27
**Target:** https://wordpress.org/news/feed/
**Skill version:** OLD (v0.5.0 baseline)

## Phase 2 — Passive Recon
- https://wordpress.org/news/sitemap.xml (Jetpack sitemap)
- https://wordpress.org/news/sitemap-1.xml
- https://wordpress.org/news/image-sitemap-index-1.xml
- https://wordpress.org/news/video-sitemap-index-1.xml
- https://wordpress.org/news/feed/ (primary RSS feed — target)
- https://wordpress.org/news/feed/atom/ (alternate Atom feed — 200)
- https://wordpress.org/news/comments/feed/ (comments feed)
- https://wordpress.org/news/wp-json/ (REST API root)

## Phase 5 — Known Pattern Probes (WITHOUT tech pack guidance)
- https://wordpress.org/news/wp-json/ → 200 (21 namespaces)
- https://wordpress.org/news/wp-json/wp/v2/posts → 200 (public REST API)
- https://wordpress.org/news/wp-json/wp/v2/users → 200 (public user data)
- https://wordpress.org/news/wp-admin/ → 302 redirect to login
- https://wordpress.org/news/wp-sitemap.xml → 404 (moved to Jetpack sitemap)
- https://wordpress.org/news/wp-cron.php → 200
- https://wordpress.org/news/xmlrpc.php → 405 (disabled)
- https://wordpress.org/news/wp-login.php → 302 to login.wordpress.org

## Phase 6 — Feeds & Structured Data
- https://wordpress.org/news/feed/ (RSS 2.0 — 200, primary target)
- https://wordpress.org/news/feed/atom/ (Atom — 200, found in Phase 6)
- https://wordpress.org/news/wp-json/ (REST API with 21 namespaces)
- https://wordpress.org/news/wp-json/wp/v2/types (post types enumeration)

## Notable Subdomains (crt.sh)
- cpanel.wordpress.org
- forums.wordpress.org
- git.wordpress.org
- security.wordpress.org
- status.wordpress.org
- svn.wordpress.org
- trac.wordpress.org
- wiki.wordpress.org