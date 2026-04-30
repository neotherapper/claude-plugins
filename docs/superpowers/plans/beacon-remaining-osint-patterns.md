# Beacon OSINT Patterns Expansion Plan

## Context

Completed in this session:
- ✅ Created `plugins/beacon/references/osint-sources.md` with Wayback versioning analysis
- ❌ Subagents failed to persist Sections 11 (GitHub Code Search) and 12 (Google Dorks) to tech packs

## Remaining Work

### Phase 1: Add Missing Sections to Tech Packs (High Priority)

**Files missing Section 11 (GitHub Code Search Patterns):**
- aspnet/webforms-mvc.md
- bigcartel/* (README, fingerprinting, tech-pack)
- bigcommerce/* (README, fingerprinting, tech-pack, current.md)
- cs-cart/current.md
- drupal/* (README, fingerprinting)
- ec-cube/4.x.md
- ecwid/* (README, tech-pack, current.md)
- express/* (README, fingerprinting, tech-pack)
- joomla/* (README, fingerprinting, tech-pack)
- medusa/2.x.md
- nopcommerce/4.x.md
- nuxt/3.x.md
- opencart/* (README, fingerprinting, tech-pack)
- prestashop/* (README, fingerprinting, tech-pack)
- react/* (README, fingerprinting, tech-pack)
- saleor/current.md
- shopware/6.x.md
- squarespace/current.md
- sylius/2.x.md
- wix/current.md
- webflow/* (README, fingerprinting, tech-pack)
- zend-framework/1.x.md

**Files missing Section 12 (Framework-Specific Google Dorks):**
(Same list as above - both sections need to be added)

**Reference patterns from existing tech packs (nextjs/15.x.md, wordpress/6.x.md):**
- Section 11: GitHub Code Search Patterns with framework-specific queries
- Section 12: Framework-Specific Google Dorks with discovery queries

### Phase 2: Expand osint-sources.md (High Priority)

Add missing OSINT sources and techniques:

**Free/No-API-key sources to add:**
1. **VirusTotal** - Passive DNS records, subdomains, URL metadata
2. **BuiltWith** - Technology stack identification
3. **DNSDumpster** - Subdomains, DNS records, reverse DNS
4. **HackerTarget** - Free recon tools aggregation
5. **Netcraft Site Report** - Infrastructure details

**Passive DNS & Subdomain Discovery tools:**
1. **Amass** - 100+ passive sources, SSL/TLS scraping
2. **Subfinder** - Fast, 10+ passive sources
3. **samoscout** - AI-powered subdomain prediction
4. **Assetfinder** - Lightweight subdomain enum
5. **DNSRecon** - DNS record enumeration

**Content Discovery tools:**
1. **ffuf** - Flexible web fuzzer for directories/parameters
2. **Gobuster** - Multi-mode bruteforce
3. **feroxbuster** - Recursive directory bruteforce with wildcard detection
4. **Arjun** - Automated GET/POST parameter discovery
5. **katana** - Headless crawler for JS-heavy SPAs

**API-Specific Discovery:**
1. **kiterunner** - API-aware bruteforce using Swagger/OpenAPI dictionaries
2. **Vespasian** - Auto-generates OpenAPI/GraphQL specs from traffic
3. **GraphQL introspection** - WAF-bypass methods

**Cloud & Infrastructure:**
1. **S3 bucket discovery** - BUCKET-NAME.s3.amazonaws.com patterns
2. **Cloud metadata endpoints** - http://169.254.169.254 (AWS/GCP/Azure)
3. **Subdomain takeover detection** - Orphaned CNAME records
4. **S3DNS** - DNS-based detection of 13+ cloud storage providers

**Methodological Approaches:**
1. **Favicon hashing** - Identify tech stack by favicon hash
2. **Source map discovery strategies** - Build tool-specific patterns (Vite, webpack, Rollup)
3. **Tech stack → API pattern mapping** - Auto-map detected frameworks to likely endpoints
4. **Email naming convention analysis** - Extract emails to predict subdomains

### Phase 3: Framework-Specific Probe Checklist Gaps (Medium Priority)

**Next.js 15.x:**
- [ ] RSC (React Server Components) payload detection at page URLs with `?_rsc=` param
- [ ] `/_next/data/` endpoint enumeration for App Router
- [ ] NextAuth v5 (Auth.js v5) JWT session patterns
- [ ] Middleware detection patterns for `middleware.ts`

**WordPress 6.x:**
- [ ] `/wp-json/` namespace enumeration (list all namespaces)
- [ ] `xmlrpc.php` methods enumeration (`system.listMethods`)
- [ ] Multisite detection (`/sites/`, `blog_id` patterns)

**Rails 8.x:**
- [ ] Hotwire Turbo Stream endpoint patterns (`/turbo/`, SSE endpoints)
- [ ] Import Maps CSP nonce extraction
- [ ] Action Cable WebSocket endpoints

**Laravel 12.x:**
- [ ] Livewire AJAX endpoints (`/livewire/message/`)
- [ ] Vite manifest analysis for endpoint discovery
- [ ] Broadcasting auth endpoint (`/broadcasting/auth`)

**Strapi 5.x:**
- [ ] Plugin ecosystem discovery beyond built-in
- [ ] Component/Block discovery patterns
- [ ] Document v5 API changes vs v4

**Magento 2.x:**
- [ ] MSI Multi-Source Inventory endpoints (`/rest/V1/inventory/`)
- [ ] B2B module endpoints (`/rest/V1/company`)
- [ ] Adobe Commerce specific patterns

**Django 5.x:**
- [ ] Channels WebSocket endpoint patterns (`/ws/`, `/wss/`)
- [ ] Django Ninja API patterns
- [ ] Wagtail-specific API patterns

### Phase 4: Cross-Cutting Patterns (Medium Priority)

**Add to each tech pack:**
1. **Known subdomain patterns** - Staging, dev, API, admin subdomains
2. **Common misconfigurations** - Exposed env files, debug endpoints
3. **Source map patterns** - Build tool specific (webpack, Vite, Rollup, esbuild)

**Framework-specific Google dorks (already planned for Section 12):**
- Next.js: `inurl:/_next/`, `inurl:__NEXT_DATA__`
- WordPress: `inurl:/wp-json/`, `inurl:/wp-admin/`
- Shopify: `site:{shop}.myshopify.com`, `inurl:cdn.shopify.com`
- Rails: `inurl:/assets/application-`, `inurl:authenticity_token`
- Laravel: `inurl:/laravel_session`, `inurl:/sanctum/csrf-cookie`
- Strapi: `inurl:/api/`, `inurl:/admin/`
- Magento: `inurl:/rest/V1/`, `inurl:/pub/static/version`
- Django: `inurl:/admin/login/`, `inurl:__debug__`

### Phase 5: Documentation Updates (Low Priority)

1. **Update Phase 9 Session Brief Format** in osint-sources.md to include:
   - Versioning Analysis subsection
   - New OSINT sources
   - Framework-specific findings sections

2. **Update SKILL.md** to reference new sections

3. **Update CHANGELOG.md** with all changes

## Execution Order

1. Add Section 11 (GitHub Code Search Patterns) to all missing tech packs
2. Add Section 12 (Framework-Specific Google Dorks) to all missing tech packs
3. Expand osint-sources.md with missing OSINT sources
4. Fill framework-specific probe checklist gaps
5. Update documentation (CHANGELOG, SKILL.md)

## Verification

After each phase:
- Run `git status` to confirm expected changes
- Run `grep -r "## 11. GitHub Code Search Patterns" plugins/beacon/technologies/` to verify coverage
- Run `grep -r "## 12. Framework-Specific Google Dorks" plugins/beacon/technologies/` to verify coverage
- Test a sample site recon to verify new patterns are used
