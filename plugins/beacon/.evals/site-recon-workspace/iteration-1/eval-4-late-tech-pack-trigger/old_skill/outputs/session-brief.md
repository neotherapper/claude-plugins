# Session Brief — wordpress-org-news-feed

**Target:** https://wordpress.org/news/feed/
**Started:** 2026-04-27
**Plugin version:** 0.6.0 (beacon)
**Skill version:** OLD v0.5.0 — BASELINE (no late-tech-pack-trigger)

---

### Infrastructure

| Property | Value | Evidence |
|----------|-------|----------|
| Framework | WordPress | discovered from generator tag in Phase 6 |
| Framework version | 7.1-alpha | `v=7.1-alpha-62259` from feed generator tag |
| Web server | nginx | standard WordPress.org infrastructure |
| CDN | Unknown | no CDN headers on feed endpoint |
| Auth mechanism | None on public endpoints | REST API is publicly readable |
| Bot protection | None | feed and API accessible without challenge |
| Hosting | Automattic / WP.com | `x-nc: HIT ord 2`, nginx server |

*Note: framework was NOT known during Phase 3 — only discovered in Phase 6.*

---

### Tool Availability

- Wappalyzer MCP: [TOOL-UNAVAILABLE:wappalyzer]
- Firecrawl MCP/CLI: [TOOL-UNAVAILABLE:firecrawl]
- Chrome DevTools MCP: [TOOL-UNAVAILABLE:chrome-devtools-mcp]
- cmux browser: [TOOL-UNAVAILABLE:cmux-browser]
- GAU: [TOOL-UNAVAILABLE:gau]
- context7 MCP: not checked (Phase 4 was skipped before reaching context7)

---

### Tech Pack

**Status:** NOT LOADED (this is the eval result being measured)

- `[TECH-PACK-NOT-LOADED:wordpress:7.1-alpha]` — Phase 4 was never reached
- No tech pack loaded because Phase 3 returned `[FRAMEWORK-UNKNOWN]` for the feed URL
- Source: N/A
- Version match: N/A — no pack attempted

---

### Phase 2 — Passive Recon

**Subdomains (crt.sh):** cpanel.wordpress.org, forums.wordpress.org, git.wordpress.org, security.wordpress.org, status.wordpress.org, svn.wordpress.org, trac.wordpress.org, wiki.wordpress.org

**Passive probes:**
| Probe | Result |
|-------|--------|
| robots.txt | HTML fallback returned (page not found — feed target bypasses HTML routing) |
| sitemap | https://wordpress.org/news/sitemap.xml (Jetpack) found |
| security.txt | not found |
| humans.txt | not found |
| /.well-known/jwks.json | not found |
| /.well-known/openapi.json | not found |
| HTTP headers | nginx, x-nc:HIT, link rel="https://api.w.org/", strict-transport-security, x-frame-options:SAMEORIGIN |

---

### Phase 3 — Fingerprint

**Detection result (OLD skill — ran on feed URL):**
- Framework: `[FRAMEWORK-UNKNOWN]`
- Evidence: Feed URL returns XML (not HTML). Standard Phase 3 HTML patterns (`wp-content/`, `_next/`, etc.) don't match in XML. No generator tag rule in OLD Phase 3 list. No Wappalyzer available.
- Wappalyzer confidence: not used

**Key finding:** The feed XML contains `<generator>https://wordpress.org/?v=7.1-alpha-62259</generator>` but OLD Phase 3 has no rule to parse generator tags from XML feeds.

---

### Phase 4 — Tech Pack

**NOT EXECUTED.** OLD skill: "Once framework and major version are known" — since Phase 3 returned `[FRAMEWORK-UNKNOWN]`, Phase 4 was skipped entirely.

This is the **late-tech-pack-trigger gap**: framework discovered in Phase 6 but no re-trigger of Phase 4.

---

### Phase 5 — Known Pattern Probes (without tech pack)

Ran generic WordPress probes based on knowledge rather than tech pack guidance.

| Endpoint | Method | Status | Notes |
|----------|--------|--------|-------|
| /wp-json/ | GET | ✓ 200 | 21 namespaces |
| /wp-json/wp/v2/posts | GET | ✓ 200 | public |
| /wp-json/wp/v2/users | GET | ✓ 200 | public user enumeration |
| /wp-admin/ | GET | ✗ 302 | redirects to login |
| /wp-sitemap.xml | GET | – 404 | replaced by Jetpack sitemap |
| /wp-cron.php | GET | ✓ 200 | |
| /xmlrpc.php | POST | ✗ 405 | disabled |

---

### Phase 6 — Feeds & Structured Data

- Primary RSS 2.0 feed: https://wordpress.org/news/feed/ — **200** (target URL)
- Alternate Atom feed: https://wordpress.org/news/feed/atom/ — **200**
- Comments feed: https://wordpress.org/news/comments/feed/ — accessible
- WordPress REST API: https://wordpress.org/news/wp-json/ — **200** (21 namespaces)
- GraphQL: not found

**Framework discovered here:** `<generator>https://wordpress.org/?v=7.1-alpha-62259</generator>` in RSS feed — this is the WordPress signal.

**But no re-trigger:** OLD skill v0.5.0 does not have a late-tech-pack-trigger mechanism. Phase 4 has already been skipped. The framework is now known but Phase 4 cannot be re-entered.

---

### Phase 7 — JS Analysis

- Feed URL (target): XML format — no JS bundles
- Main site (https://wordpress.org/news/): WordPress PHP-rendered HTML with standard WordPress JS files

---

### Phase 8 — OpenAPI

- Spec: not found at any standard path
- Source: not found (will scaffold in Phase 12 if session brief had endpoints)

---

### Phase 9 — OSINT

- Wayback CDX: 2 paths found — https://wordpress.org/news-test/wp-json/, https://wordpress.org/news-test/xmlrpc.php?rsd
- CommonCrawl: no additional API paths
- Subdomains: listed above (from crt.sh)
- GitHub: not searched (target is not an app requiring client library discovery)

---

### Discovered Endpoints

| Method | Endpoint | Auth | Phase | Notes |
|--------|----------|------|-------|-------|
| GET | /wp-json/ | No | 5 | 21 namespaces |
| GET | /wp-json/wp/v2/posts | No | 5 | public posts |
| GET | /wp-json/wp/v2/users | No | 5 | user enumeration |
| GET | /wp-json/wp/v2/types | No | 5 | post type registry |
| GET | /wp-admin/ | N/A | 5 | 302 to login |
| GET | /wp-cron.php | No | 5 | returns 200 |
| POST | /xmlrpc.php | N/A | 5 | 405 disabled |

---

### Browse Plan

Compiled but not executed (Phase 11 skipped):

Priority 1 — REST API surface exploration
- [ ] GET /wp-json/ → capture full namespace list
- [ ] GET /wp-json/wp/v2/categories → taxonomy enumeration
- [ ] GET /wp-json/wp/v2/tags → tag taxonomy

Priority 2 — WordPress.org specific namespaces
- [ ] GET /wp-json/wporg/v1/* → WordPress.org specific endpoints
- [ ] GET /wp-json/jetpack/v4/* → Jetpack integration

---

### Phase 11 — Active Browse

[PHASE-11-SKIPPED] — No browser tools available

---

## EVAL-4 BASELINE RESULT

**WordPress tech pack loaded?** NO
**Was it a late load?** N/A — not loaded at all
**Detection source?** Generator tag in RSS feed XML discovered in Phase 6
**Framework unknown during Phase 3:** YES — feed returns XML, not HTML, causing `[FRAMEWORK-UNKNOWN]`
**Phase 4 re-triggered?** NO — OLD skill v0.5.0 has no late-tech-pack-trigger mechanism
**Logged signal:** `[FRAMEWORK-UNKNOWN]` in Phase 3, no `[LOADED:wordpress:*]` in Tech Pack section

This confirms the baseline bug: when the framework is discovered from a non-standard signal (feed generator tag, JSON-LD, error page, etc.) that is encountered AFTER Phase 3, the OLD skill never loads the tech pack.