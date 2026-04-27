# Changelog — Beacon

All notable changes to this plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [0.6.2] — 2026-04-27

### Added

- Tech pack: `technologies/woocommerce/9.x.md` — WooCommerce 9.x (WordPress e-commerce plugin)
  - 10-section pack covering fingerprinting (cookies, JS globals, Store API namespace), REST API v3
    and Store API v1 surfaces, Consumer Key/Secret auth, legacy `wc-ajax` endpoints, and 10 gotchas
  - 25 endpoint entries including product catalog, cart, checkout, coupons, shipping, payment gateways
- Tech pack: `technologies/magento/2.x.md` — Magento 2.4.x (Adobe Commerce)
  - 10-section pack covering HTTP header fingerprinting (`X-Magento-Tags`), REST V1 and GraphQL
    surfaces, Bearer token and OAuth auth, RequireJS bundle patterns, and 11 gotchas
  - GraphQL introspection probe, multi-store `Store:` header requirement, Varnish caching awareness
- SKILL.md v0.6.0 — site-recon skill improvements derived from Pen-Chalet and JetPens session analysis:
  - **Fix:** Phase 1 scaffold now uses `Write` (not `touch`) to avoid Write-before-Read failures
  - **Fix:** `www.` prefix stripped from URL before slug generation
  - **Fix:** gau alias detection — `which gau` replaced with output-checking validation
  - **New:** Chrome MCP namespace detection in Phase 1 — both namespaces tested, working one recorded
  - **New:** Phase 4 late discovery rule — tech pack re-triggered when framework found in phases 5–9
  - **New:** Phase 12 completion gate — all 11 phase markers verified before writing output files
  - **New:** Bot protection section — Cloudflare curl-403 pivot strategy and Turnstile limitation
  - **New:** E-commerce probe list — 20+ platform-specific endpoints for Phase 5 (WooCommerce,
    Magento, ZF1, Shopify, ASP.NET); "no API" verdict requires all probes exhausted
  - **New:** cmux usage guide — exact command syntax for navigation, eval, HTML, screenshot
  - **New:** Fingerprinting signals for Magento 2, WooCommerce, and ASP.NET in Phase 3
  - **New:** Version extraction for Magento 2, WooCommerce, and ASP.NET
  - **New:** 8 new graceful degradation signals (CF-BLOCKED, CF-PIVOT, CHROME-NAMESPACE, etc.)
- Session-start hook updated to advertise WooCommerce and Magento 2 in tech pack list
- Session analysis: `docs/research/beacon-session-analysis/session-analysis.md` — 353-line retrospective
  on Pen-Chalet and JetPens beacon runs documenting 13 error patterns and 15 recommended improvements

---

## [0.6.1] — 2026-04-26

### Added

- Tech pack: `technologies/zend-framework/1.x.md` — Zend Framework 1.x (EOL legacy)
  - 10-section pack covering fingerprinting, MVC route surface, config file exposure,
    Zend_Auth patterns, XML-RPC introspection, and ZF1-specific gotchas
  - Phase 3 SKILL.md updated with ZF1 HTML/error-page fingerprinting signals
  - Session-start hook updated to advertise Zend Framework 1 in tech pack list

---

## [0.6.0] — 2026-04-15

### Added

- `site-intel` Step 3a: tech pack cross-referencing — when a question involves framework-specific query patterns, endpoint conventions, or "how do I" phrasing, the relevant `technologies/{framework}/{major}.x.md` is loaded alongside the research file
- Trigger heuristics: explicit list of question types that load the tech pack vs. factual questions that use research files only
- Source labelling guidance: confirmed research findings vs. conventional tech pack knowledge are explicitly distinguished in answers
- Version mismatch handling: if exact version pack is unavailable, uses nearest major and notes it in the response
- Missing pack fallback: if no tech pack exists for a framework, proceeds with research files only without surfacing the gap to the user
- `tests/validate-site-intel.sh` — 12 checks on site-intel skill structure and tech pack logic

---

## [0.1.0] — 2026-04-15

### Added

- `/beacon:analyze {url}` — 12-phase systematic API surface analysis
- `/beacon:load` — query existing research docs without re-running analysis
- Tech fingerprinting: Wappalyzer-style heuristics + HTTP header inspection
- OSINT phase: Google dorks, certificate transparency, Wayback Machine, GitHub code search
- Script probing: source maps, webpack chunks, JS bundle extraction
- Browser recon phase via browser automation
- Framework-specific tech-pack guides (Next.js, WordPress, and more)
- OpenAPI spec generation from discovered endpoints
- Structured output to `docs/research/{site}/` with INDEX, tech-stack, site-map, API surfaces
- `site-analyst` agent for JS analysis and OSINT correlation
- SessionStart hook surfacing recent research sessions
