# Changelog — Beacon

All notable changes to this plugin are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Added
- Add Wayback Machine versioning analysis to OSINT sources (track API endpoint evolution)
- Add 30+ new OSINT sources to `references/osint-sources.md`:
  - Passive DNS: VirusTotal, DNSDumpster, Farsight DNSDB
  - Subdomain enumeration: Amass, Subfinder, DNSRecon, Assetfinder
  - Content discovery: ffuf, Gobuster, feroxbuster, Arjun, katana
  - API discovery: kiterunner, Vespasian, GraphQL introspection techniques
  - Cloud: S3 bucket enumeration, S3DNS, metadata endpoints
  - Favicon hashing, source map discovery strategies
  - Package registry search (NPM/PyPI)
  - Bug bounty scope search
  - Paste site search for leaked credentials
- Add Section 11 (GitHub Code Search Patterns) to all tech packs
- Add Section 12 (Framework-Specific Google Dorks) to all tech packs
- Add Section 13 (Cross-Cutting OSINT Patterns) to all tech packs:
  - Favicon hashing for shadow IT discovery
  - Source map discovery strategies (webpack, Vite, Rollup, esbuild)
  - Tech stack → API pattern mapping table
  - Email naming convention analysis
- Add missing probe checklist items to 8 tech packs:
  - nextjs/15.x: RSC detection, App Router endpoints, NextAuth v5, middleware
  - wordpress/6.x: namespace enumeration, XML-RPC methods, multisite
  - rails/8.x: Hotwire Turbo Streams, import map CSP, Action Cable
  - laravel/12.x: Livewire AJAX, Vite manifest, broadcasting auth
  - strapi/5.x: plugin ecosystem, component discovery, v5 changes
  - magento/2.x: MSI inventory, B2B modules, Adobe Commerce
  - django/5.x: Channels WebSocket, Django Ninja, Wagtail API
  - shopify/2024-10: Hydrogen/Remix, GraphQL introspection, admin API

### Changed
- Expand Phase 9 Session Brief Format with new OSINT sources
- Update `osint-sources.md` with comprehensive tool coverage (707 lines)

### Fixed
- None

---

## [0.6.7] — 2026-04-28

### Added

- Tech pack: `technologies/ec-cube/4.x.md` (265 lines) — Japan's dominant open-source e-commerce
  - API is **GraphQL** (not REST) via `eccube-api4` plugin at `/api`; OAuth2 Authorization Code only
  - Session cookie is `eccube` (single Symfony session, not the 2.x/3.x multi-cookie pattern)
  - Symfony version matrix: 4.0→Symfony 3.4, 4.1→4.4, 4.2→5.4, 4.3→Symfony 6.4
  - CSS source maps ship by default; admin route is configurable (harden = change it)

- Tech pack: `technologies/nopcommerce/4.x.md` (325 lines) — ASP.NET Core e-commerce (Eastern Europe / enterprise)
  - Two distinct API plugin ecosystems: SevenSpikes (OAuth 2.0) vs Official nopCommerce Web API (JWT + X-API-KEY)
  - Swagger UI at `{site}/api/index.html`; definitive cookie: `.Nop.Authentication`
  - Slug routing: ALL entity types (products, categories, manufacturers) resolve at root — no URL prefix
  - `nopAjaxCart` is third-party — NOT a reliable fingerprint signal

- Tech pack: `technologies/cs-cart/current.md` (350 lines) — PHP e-commerce, Eastern Europe / CIS
  - Current version 4.20.x (not 4.17.x as commonly cited); covers 4.17–4.20
  - 30+ REST API entities including Multi-Vendor-only endpoints (`/api/vendors/`, `/api/master_products/`)
  - `window.Tygh` JS global is the single most reliable fingerprint (Definitive)
  - Multi-Vendor detection: `GET /api/vendors/` — 200/401=Multi-Vendor, 404=single-store

- Tech pack: `technologies/sylius/2.x.md` (261 lines) — Symfony-based PHP e-commerce, European enterprise
  - Response format is JSON-LD + Hydra (`hydra:member` collections), NOT HAL
  - Admin JWT endpoint changed in 2.x: `POST /api/v2/admin-authentication-token` (not `/admin/authentication-token`)
  - Channel/locale/currency cookies: `sylius_channel`, `sylius_locale`, `sylius_currency` — all Definitive
  - Locale-prefixed storefront URLs (`/en_US/`); API at `/api/v2/` has NO locale prefix

- Session-start hook updated to advertise EC-CUBE, nopCommerce, CS-Cart, Sylius

---

## [0.6.6] — 2026-04-28

### Added

- Tech pack: `technologies/shopware/6.x.md` (322 lines) — dominant DACH e-commerce platform
  - Three API layers: Store API (`/store-api/`), Admin API (`/api/`), Sync API
  - Key recon: `sw-access-key` extraction from page source → context token → full product catalog
  - `POST /store-api/product-listing/{categoryId}` returns prices without auth (access key only)
  - `POST /store-api/search-suggest` — search autocomplete as product discovery
  - Admin OpenAPI spec at `/api/_info/openapi3.json` reveals full Admin API surface
  - 23 probe checklist items, 12 gotchas including DACH market context
  - Session-start hook updated to advertise Shopware 6

---

## [0.6.5] — 2026-04-28

### Added

- Tech pack: `technologies/bigcommerce/current.md` (233 lines) — Storefront GraphQL via `window.BCData.gql_token`, store hash extraction from CDN URL, Management API v3 at `api.bigcommerce.com`, Stencil theme fingerprinting, 19 probe items
- Tech pack: `technologies/opencart/3.x.md` (315 lines) — `route=extension/feed/google_base` product XML, REST API with `api/login` token, correct `extension/` route prefix (verified against OC 3.0.5.0 source), 14 probe items
- Tech pack: `technologies/sfcc/current.md` (269 lines) — dual SCAPI (Shopper API, OAuth 2.1/SLAS) and OCAPI (legacy) coverage, `demandware.net` + `dw_*` cookie fingerprinting, PWA Kit headless pattern, 11 probe items
- Tech pack: `technologies/saleor/current.md` (226 lines) — single `/graphql/` endpoint, channel-scoped product queries, Relay pagination, `tokenCreate` customer auth mutation, 11 probe items
- Tech pack: `technologies/medusa/2.x.md` (181 lines) — v2 auth at `/auth/customer/emailpass` (corrected from v1 `/store/auth/token`), `NEXT_PUBLIC_MEDUSA_BACKEND_URL` extraction, publishable API key from page source, 11 probe items
- Tech pack: `technologies/wix/current.md` (196 lines) — `/_api/wix-ecommerce-reader/v1/catalog/products/query` internal API, dual XSRF token requirement, `metaSiteId` extraction, 11 probe items
- Tech pack: `technologies/squarespace/current.md` (230 lines) — `?format=json` suffix works on any page (richest unauthenticated technique), `sqs-*` CSS class fingerprinting, `crumb` CSRF extraction, 12 probe items
- Tech pack: `technologies/ecwid/current.md` (165 lines) — store ID from script tag → fully public products + categories API at `app.ecwid.com`, no auth required, 9 probe items
- Session-start hook updated to advertise all 8 new tech packs

---

## [0.6.4] — 2026-04-28

### Added

- Tech pack: `technologies/prestashop/8.x.md` — PrestaShop 8.x
  - 10-section pack: `PrestaShop-{hash}` cookie + `window.prestashop` JS global fingerprinting,
    Web Services API (`/api/`), front-office AJAX controllers (always active, no key), PS 8.1+
    API Platform (`/api/v2/`), cart AJAX POST-body pattern, 12 module detections, 11 gotchas
  - Covers both Web Services API (XML/JSON, key-gated) and unauthenticated front-office endpoints
  - Session-start hook updated to advertise PrestaShop in tech pack list

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

## [0.6.3] — 2026-04-27

### Added

- Tech pack: `technologies/aspnet/webforms-mvc.md` — ASP.NET WebForms & MVC
  - 10-section pack: `__VIEWSTATE`/`__EVENTVALIDATION` WebForms fingerprints, `.axd` endpoint
    probes, anti-forgery token acquisition, ViewState POST pattern, ELMAH/trace.axd exposure
    check, ASP.NET Web API detection, SignalR detection, 10 gotchas
  - Session-start hook updated to advertise ASP.NET in tech pack list

### Fixed

- `references/tool-availability.md`: gau alias detection — output-checking validation replaces
  `which gau` to detect git alias; Chrome MCP now documents both plugin-level and project-level
  namespaces with stale CDP connection recovery instructions
- `references/browser-recon.md`: new Cloudflare/bot protection section covering cf-ray detection,
  same-origin browser fetch() pivot strategy, Turnstile limitation; cmux commands corrected
  from real session failures (--load-state removed, --surface flag required, get html selector
  requirement documented)

### Changed

- Eval workspace: `skills/site-recon-workspace/` created with old-skill-snapshot (v0.5.0 baseline),
  4 eval test cases, iteration-1 results showing with-skill improvements over baseline
- Plugin version bumped to 0.6.3

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
