# wordpress.org/news — Research Summary

**Analysed:** 2026-04-27
**Target:** https://wordpress.org/news/feed/
**Plugin version:** 0.6.0
**Skill version:** OLD (v0.5.0 baseline — no late-tech-pack-trigger mechanism)

---

## Infrastructure

| Property | Value | Source |
|----------|-------|--------|
| Framework | WordPress 7.1-alpha | generator tag in RSS feed XML (`v=7.1-alpha-62259`) |
| CDN | Unknown | no CDN headers on feed endpoint |
| Auth | None on public endpoints | REST API is publicly readable |
| Bot protection | None detected | feed and REST API accessible without challenge |
| Hosting | Automattic / WordPress.com infrastructure | `x-nc: HIT ord 2` header, nginx server |

## Tool Availability

- Wappalyzer MCP: [TOOL-UNAVAILABLE:wappalyzer]
- Firecrawl MCP/CLI: [TOOL-UNAVAILABLE:firecrawl]
- Chrome DevTools MCP: [TOOL-UNAVAILABLE:chrome-devtools-mcp]
- cmux browser: [TOOL-UNAVAILABLE:cmux-browser]
- GAU: [TOOL-UNAVAILABLE:gau]

---

## API Surfaces

| Surface | Description |
|---------|-------------|
| [api-surfaces/wordpress-rest-api.md](api-surfaces/wordpress-rest-api.md) | WordPress REST API v2 — 21 namespaces, public read access |

---

## Key Findings

- **WordPress 7.1-alpha detected from feed generator tag** (`<generator>https://wordpress.org/?v=7.1-alpha-62259</generator>`) in Phase 6
- **WordPress REST API with 21 namespaces** — public, no auth required for read operations
- **Public user enumeration** — `/wp-json/wp/v2/users` exposes user data without authentication
- **XML-RPC disabled** (returns 405 Method Not Allowed)
- **Jetpack namespaces** present (`jetpack/v4`, `jetpack/v4/stats-app`, etc.) confirming WordPress.org-specific infrastructure
- **Atom feed** available at `/feed/atom/` alongside primary RSS feed

---

## Tech Pack Status

**Tech Pack Loaded:** NO — NOT LOADED

This is the baseline bug being tested by this eval. The OLD skill (v0.5.0) ran Phase 3 fingerprinting on the feed URL (`https://wordpress.org/news/feed/`). Since the feed returns XML (not HTML), standard Phase 3 HTML pattern matching found nothing:

- No `wp-content/` in feed XML (this pattern only matches in HTML page content)
- No `generator` tag rule in OLD Phase 3 detection list
- Wappalyzer not available

Result: Phase 3 returned `[FRAMEWORK-UNKNOWN]`.  
Since no framework was known, the OLD skill skipped Phase 4 (Tech Pack Lookup).

The WordPress framework was only discovered later in Phase 6, when examining the feed content and finding the generator tag. The OLD skill (v0.5.0) has no mechanism to re-trigger Phase 4 after discovering the framework from a later phase. This is the **late-tech-pack-trigger gap** that the new skill fixes.

---

## Phase 11 — Active Browse

[PHASE-11-SKIPPED] — No browser tools available