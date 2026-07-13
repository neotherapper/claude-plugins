# site-utils — Shared Crawl Infrastructure — Design

- **Date:** 2026-07-13
- **Status:** Draft (awaiting review)
- **Depends on:** None (new plugin)
- **Affects:** beacon, reframe, planned SEO plugin

---

## 1. Problem Statement

Three plugins in this marketplace need overlapping web crawling, fetching, and content discovery capabilities:

- **beacon** — 16-phase site recon (API surface mapping, OSINT, security exposure)
- **reframe** — 9-phase site redesign (content crawl, IA analysis, design brief)
- **seo** (planned) — SEO audit (technical audit, on-page audit, scoring)

### 1.1 Shared capabilities (currently duplicated)

| Capability | beacon | reframe | seo |
|------------|--------|---------|-----|
| WAF-aware fetch chain (curl → Jina → Firecrawl → Crawl4AI → browser) | Phase 11 inline | Phase 3 render gate | — |
| Screenshot capture (Jina → Firecrawl → Crawl4AI → Chrome MCP → Playwright) | Phase 11 | Phase 4 | — |
| robots.txt / sitemap parsing | Phase 2 | Phase 2 | Phase 1 |
| URL clustering by path template | Phase 10 browse plan | Phase 2 structure | — |
| Content extraction (HTML → markdown) | Phase 7 JS bundles | Phase 4 content crawl | — |
| Subdomain enumeration | Phase 9 OSINT | — | Phase 1 |
| HTTP probing / URL validation | Phase 9 | Phase 3 coverage | Phase 2 |
| Content discovery (directory/param brute-force) | Phase 5/9 | — | Phase 2 |
| Vulnerability scanning | Phase 9 | — | — |

### 1.2 The sharing dilemma

Three options existed for sharing these capabilities:

**Option A: Keep scripts in one plugin, others reference by path**
- Pro: Simple, no new plugin
- Con: Hard dependency — if beacon is disabled, reframe breaks
- Con: `../other-plugin/...` paths don't resolve in installed cache (violates visual-kit's "no filesystem coupling" rule)
- Con: Users can't use reframe or SEO without enabling beacon

**Option B: Duplicate scripts into each plugin**
- Pro: Each plugin fully independent
- Con: 330+ lines duplicated across 2-3 plugins
- Con: Bug fixes must be applied in 3 places
- Con: No versioning of shared code

**Option C: Library plugin (visual-kit pattern)** ← recommended
- Pro: Each consumer independently installable
- Pro: Single source of truth for shared code
- Pro: Versioned, testable, independently releasable
- Pro: Matches established ecosystem pattern (visual-kit)
- Con: Adds a plugin to manage (but it's a library, not a user-facing skill)

---

## 2. Current Architecture Analysis

### 2.1 How plugins share today

**Data sharing (not code):**
- beacon writes `docs/sites/{slug}/research/`
- reframe reads `docs/sites/{slug}/research/` when available (`[RECON-REUSE]` signal)
- slug derivation rule is duplicated in both plugins (same logic, independent implementations)

**No code sharing:**
- Neither plugin references the other's scripts
- `CLAUDE_PLUGIN_ROOT` resolves to the plugin's own root — no cross-plugin paths
- The `sync-skills.sh` symlink farm exposes skills across tools, not code across plugins

### 2.2 The visual-kit precedent

Visual-kit is a **library plugin** — infrastructure that other plugins depend on:

| Property | Value |
|----------|-------|
| `"skills": []` | No user-facing skills (or minimal lifecycle help) |
| Purpose | Runtime infrastructure (HTTP server, component library, CLI) |
| Consumer contract | `plugin.json` `dependencies[]` |
| Communication | CLI on PATH, HTTP server, file system seams in known paths |
| Independence rule | "No filesystem coupling between plugins" |

Consumer plugins (paidagogos, namesmith, draftloom) declare visual-kit as a dependency. Installing a consumer auto-installs visual-kit. Consumers never read visual-kit's filesystem — they use its runtime API (CLI, HTTP endpoints, SurfaceSpec JSON).

### 2.3 Plugin independence requirement

Users must be able to:
- Use beacon without reframe or SEO
- Use reframe without beacon or SEO
- Use SEO without beacon or reframe
- Use any combination

Any architecture that creates a hard dependency between consumer plugins violates this requirement.

---

## 3. Proposed Solution: `plugins/site-utils`

### 3.1 What it is

A **library plugin** following the visual-kit pattern. Provides shared web crawling, fetching, and content discovery primitives as a CLI and script library. No user-facing skills (or a minimal help skill only).

### 3.2 What it provides

```
plugins/site-utils/
├── .claude-plugin/
│   └── plugin.json              ← "skills": [], library plugin
├── bin/
│   └── site-utils               ← CLI entry point (Node/shell shim)
├── scripts/
│   ├── fetch_with_fallback.sh   ← WAF-aware fetch chain
│   ├── screenshot.sh            ← multi-source screenshot capture
│   ├── content_extract.py       ← HTML → clean markdown
│   ├── url_cluster.py           ← group URLs by path template
│   ├── content_discovery.sh     ← ffuf wrapper (dir/param discovery)
│   ├── subdomain_enum.sh        ← subfinder wrapper
│   ├── httpx_probe.sh           ← httpx wrapper (validate URLs)
│   └── nuclei_scan.sh           ← nuclei wrapper (vuln scanning)
├── references/
│   ├── fetch-strategy.md        ← when to use what, WAF detection
│   └── tool-availability.md     ← installed tools, fallback chains
├── tests/
│   └── ...                      ← unit + integration tests
└── README.md
```

### 3.3 Consumer dependency model

```json
// plugins/beacon/.claude-plugin/plugin.json
{
  "name": "beacon",
  "dependencies": [
    { "name": "site-utils", "version": "~1.0.0" }
  ]
}
```

Installing beacon auto-installs site-utils. The same for reframe and SEO.

### 3.4 How consumers call site-utils

**CLI on PATH** (matches visual-kit pattern):

```bash
# beacon Phase 2 — fetch with WAF fallback:
site-utils fetch "https://example.com" --strategy auto

# reframe Phase 4 — screenshot:
site-utils screenshot "https://example.com" --out .crawl/screenshots/home.png

# beacon Phase 5/9 — content discovery:
site-utils content-discovery "https://example.com" --wordlist common.txt

# beacon Phase 9 — subdomain enum:
site-utils subdomain-enum "example.com"

# beacon Phase 9 — HTTP probe:
site-utils probe "https://example.com/api/v1" --check-tech

# beacon Phase 9 — vuln scan:
site-utils nuclei-scan "https://example.com" --severity medium,high,critical

# reframe Phase 2 — URL clustering:
site-utils cluster-urls /tmp/urls.txt --output ia-map.json

# beacon Phase 4 — content extraction:
site-utils extract "https://example.com/page" --format markdown
```

**Alternative: direct script invocation** (simpler, no CLI shim):

```bash
SITE_UTILS="${CLAUDE_PLUGIN_ROOT}/../site-utils/scripts"
bash "${SITE_UTILS}/fetch_with_fallback.sh" "https://example.com"
```

The CLI approach is preferred because:
- Works across all tools (Codex, OpenCode, Kiro) without filesystem coupling
- Matches visual-kit's established pattern
- Enables versioning and dependency resolution via marketplace

---

## 4. Script Specifications

### 4.1 `fetch_with_fallback.sh` — WAF-aware fetch chain

**Purpose:** Fetch a URL with automatic WAF detection and fallback escalation.

**Fallback order:** curl → Jina Reader → Firecrawl → Crawl4AI → browser fetch

**Input:** URL, optional strategy flag
**Output:** Fetched content (markdown or HTML) to stdout

```bash
# Usage:
site-utils fetch "https://example.com"
site-utils fetch "https://example.com" --strategy jina      # skip curl
site-utils fetch "https://example.com" --strategy firecrawl  # skip curl+jina
site-utils fetch "https://example.com" --format html         # return raw HTML
site-utils fetch "https://example.com" --format markdown     # return clean markdown (default)

# Signals emitted:
# [FETCH:curl] [FETCH:jina] [FETCH:firecrawl] [FETCH:crawl4ai] [FETCH:browser]
# [FETCH-BLOCKED:all] — all methods failed
```

**WAF detection logic:**
- `cf-ray` header → Cloudflare
- `x-datadome-*` or `{"type":"DataDome"}` body → DataDome
- `_px*` cookies → PerimeterX
- `AkamaiGHost` in Server header → Akamai
- 403 with challenge page → generic WAF

### 4.2 `screenshot.sh` — multi-source screenshot capture

**Purpose:** Capture a screenshot using the best available tool.

**Fallback order:** Jina pageshot → Firecrawl → Crawl4AI → Chrome MCP → Playwright

**Input:** URL, output path
**Output:** PNG screenshot file

```bash
# Usage:
site-utils screenshot "https://example.com" --out /tmp/page.png
site-utils screenshot "https://example.com" --out /tmp/page.png --full-page
site-utils screenshot "https://example.com" --out /tmp/page.png --viewport 1280x720

# Signals emitted:
# [SCREENSHOT:jina] [SCREENSHOT:firecrawl] [SCREENSHOT:crawl4ai] [SCREENSHOT:chrome] [SCREENSHOT:playwright]
# [SCREENSHOT-UNAVAILABLE] — no screenshot source available
```

### 4.3 `content_extract.py` — HTML to clean markdown

**Purpose:** Extract clean text content from HTML, stripping navigation, scripts, ads.

**Input:** HTML file or URL (via stdin or argument)
**Output:** Clean markdown to stdout

```python
# Usage:
site-utils extract /tmp/page.html --format markdown
curl -s "https://example.com" | site-utils extract --format markdown
site-utils extract "https://example.com" --format json  # structured output
```

**Output JSON schema (when --format json):**
```json
{
  "title": "Page Title",
  "headings": ["h1", "h2", ...],
  "word_count": 1234,
  "link_count": 56,
  "image_count": 12,
  "has_forms": true,
  "has_api_endpoints": false,
  "nav_links": [...],
  "content_links": [...]
}
```

### 4.4 `url_cluster.py` — URL clustering

**Purpose:** Group URLs by path template for template detection.

**Input:** URL list (file or stdin)
**Output:** JSON cluster map

```bash
# Usage:
site-utils cluster-urls /tmp/urls.txt
site-utils cluster-urls /tmp/urls.txt --output clusters.json
echo "https://example.com/blog/post-1" | site-utils cluster-urls
```

**Clustering logic:**
- `/` → homepage
- `/blog/*` → blog posts
- `/products/*` → product pages
- `/services/*` → service pages
- Detect recurring prefixes dynamically
- Group by path depth and parameter patterns

### 4.5 `content_discovery.sh` — ffuf wrapper

**Purpose:** Discover hidden directories, files, and parameters using ffuf.

**Input:** Target URL, optional wordlist
**Output:** Discovered paths to stdout

```bash
# Usage:
site-utils content-discovery "https://example.com"
site-utils content-discovery "https://example.com" --wordlist /path/to/wordlist.txt
site-utils content-discovery "https://example.com" --extensions .php,.bak,.config
site-utils content-discovery "https://example.com" --mode dirs    # directory discovery (default)
site-utils content-discovery "https://example.com" --mode params  # parameter discovery
site-utils content-discovery "https://example.com" --mode vhosts  # virtual host discovery

# Output format:
# [200] /admin  (4523 bytes)
# [301] /backup → /backup/
# [403] /config (217 bytes)
```

**Default wordlist:** Built-in common wordlist (~500 entries for dirs, ~200 for params). Custom wordlist via `--wordlist`.

### 4.6 `subdomain_enum.sh` — subfinder wrapper

**Purpose:** Enumerate subdomains using subfinder (passive, 15+ sources).

**Input:** Target domain
**Output:** Subdomain list to stdout

```bash
# Usage:
site-utils subdomain-enum "example.com"
site-utils subdomain-enum "example.com" --recursive
site-utils subdomain-enum "example.com" --sources crtsh,virustotal,securitytrails

# Output:
# api.example.com
# staging.example.com
# admin.example.com
```

**Fallback:** If subfinder not installed, falls back to crt.sh API (always available).

### 4.7 `httpx_probe.sh` — httpx wrapper

**Purpose:** Validate that discovered URLs return real content (not 404 shells, not empty pages).

**Input:** URL list (file or stdin)
**Output:** Probed URLs with status, tech, content length

```bash
# Usage:
site-utils probe "https://example.com/api/v1"
cat /tmp/urls.txt | site-utils probe --check-tech
site-utils probe /tmp/urls.txt --filter-status 200 --min-size 100

# Output:
# https://example.com/api/v1  [200] [WordPress/6.5] [12345 bytes]
# https://example.com/api/v2  [404] [] [0 bytes]
# https://example.com/api/v3  [403] [Cloudflare] [217 bytes]
```

### 4.8 `nuclei_scan.sh` — nuclei wrapper

**Purpose:** Run template-based vulnerability scanning.

**Input:** Target URL
**Output:** Findings to stdout

```bash
# Usage:
site-utils nuclei-scan "https://example.com"
site-utils nuclei-scan "https://example.com" --severity medium,high,critical
site-utils nuclei-scan "https://example.com" --templates exposure,misconfig

# Output:
# [critical] [cve-2024-xxxx] https://example.com/api/vulnerable
# [medium] [misconfig] https://example.com/.env
# [low] [info-disclosure] https://example.com/server-status
```

**Default scope:** Exposure, misconfiguration, and known CVE templates. Excludes brute-force, DoS, and active exploitation templates by default.

---

## 5. Impact on Existing Plugins

### 5.1 beacon migration

| Phase | Current (inline) | Future (site-utils) |
|-------|------------------|-------------------|
| Phase 2 | robots.txt/sitemap inline curl | Keep inline (simple curl, no fallback needed) |
| Phase 3 | Wappalyzer + headers + HTML grep | Keep inline (detection logic is beacon-specific) |
| Phase 5 | Platform-specific probes | Keep inline (tech-pack-specific) |
| Phase 7 | JS bundle download + grep | Keep inline (bundle analysis is beacon-specific) |
| Phase 9 | `passive_dns.sh`, `sublist3r.sh`, etc. | Keep as beacon-specific OSINT scripts |
| Phase 9 | — | `site-utils subdomain-enum` (replaces sublist3r) |
| Phase 9 | — | `site-utils probe` (validates discovered URLs) |
| Phase 9 | — | `site-utils nuclei-scan` (new vuln scanning) |
| Phase 5/9 | — | `site-utils content-discovery` (new hidden endpoint finding) |
| Phase 10 | URL list compilation | `site-utils cluster-urls` (URL clustering) |
| Phase 11 | Inline fetch + screenshot | `site-utils fetch` + `site-utils screenshot` |

**Net effect:** ~150 lines of inline fetch/screenshot code replaced by site-utils calls. ~150 lines of new content discovery, subdomain enum, HTTP probe, and vuln scan code added (via site-utils).

### 5.2 reframe migration

| Phase | Current (inline) | Future (site-utils) |
|-------|------------------|-------------------|
| Phase 2 | robots.txt/sitemap inline curl | Keep inline (simple curl) |
| Phase 2 | URL enumeration | `site-utils cluster-urls` (URL clustering) |
| Phase 3 | WAF detection + fetch fallback | `site-utils fetch` (WAF-aware fetch chain) |
| Phase 4 | Screenshot capture (5-rung fallback) | `site-utils screenshot` |
| Phase 4 | Content crawl (markdown extraction) | `site-utils extract` |

**Net effect:** ~100 lines of inline fetch/screenshot code replaced by site-utils calls. ~30 lines of URL clustering added via site-utils.

### 5.3 SEO plugin (planned)

The SEO plugin would declare site-utils as a dependency from the start:

```json
{
  "name": "seo",
  "dependencies": [
    { "name": "site-utils", "version": "~1.0.0" }
  ]
}
```

SEO would use:
- `site-utils fetch` — fetch pages for meta analysis
- `site-utils probe` — validate URL accessibility
- `site-utils content-discovery` — find hidden pages for completeness audit
- `site-utils subdomain-enum` — discover subdomains for comprehensive coverage

---

## 6. Free Tools to Add (scoped to site-utils)

### 6.1 Priority HIGH — ship in v1.0.0

| Tool | Script | Purpose | Consumers |
|------|--------|---------|-----------|
| **ffuf** | `content_discovery.sh` | Directory/param/vhost brute-force | beacon, reframe, seo |
| **subfinder** | `subdomain_enum.sh` | Passive subdomain enumeration (15+ sources) | beacon, seo |
| **httpx** | `httpx_probe.sh` | HTTP probing with tech detection | beacon, reframe, seo |
| **nuclei** | `nuclei_scan.sh` | Template-based vulnerability scanning | beacon |

### 6.2 Priority MEDIUM — ship in v1.1.0

| Tool | Script | Purpose | Consumers |
|------|--------|---------|-----------|
| **katana** | `deep_crawl.sh` | Deep web crawling (JS-rendered sites) | beacon, reframe |
| **whatweb** | (inline probe) | Deep technology fingerprinting | beacon, seo |
| **dnsrecon** | `dns_recon.sh` | DNS enumeration, zone transfer | beacon |

### 6.3 Priority LOW — future consideration

| Tool | Script | Purpose | Consumers |
|------|--------|---------|-----------|
| **Arjun** | (future) | Hidden parameter discovery | beacon |
| **Kiterunner** | (future) | API path brute-forcing | beacon |

### 6.4 Fallback chains

Each script must work without the primary tool installed:

| Script | Primary tool | Fallback |
|--------|-------------|----------|
| `content_discovery.sh` | ffuf | curl-based directory check (limited) |
| `subdomain_enum.sh` | subfinder | crt.sh API (always available) |
| `httpx_probe.sh` | httpx | curl + python3 (slower) |
| `nuclei_scan.sh` | nuclei | None (skip with warning) |
| `deep_crawl.sh` | katana | sitemap + robots.txt parsing |
| `dns_recon.sh` | dnsrecon | dig + nslookup (basic) |

---

## 7. Architecture Decisions

### D-01: Library plugin, not standalone scraping plugin

**Decision:** site-utils is a library plugin with `"skills": []`, not a user-facing plugin with its own skills/commands.

**Rationale:** A plugin without user-facing skills is infrastructure, not a product. Users don't "use site-utils" — they use beacon, reframe, or SEO, which happen to depend on site-utils. This matches visual-kit's pattern exactly.

**Contra-indication considered:** Creating a `plugins/scraper` with a `site-crawl` skill. Rejected because:
- Adds a user-facing skill that does the same thing as beacon/reframe Phase 3/4
- Creates confusion about which plugin to use for crawling
- Forces users to learn a new skill when beacon/reframe already handle it

### D-02: CLI on PATH, not filesystem coupling

**Decision:** Consumers call site-utils via `site-utils <command>` CLI, not via `../site-utils/scripts/` paths.

**Rationale:** Filesystem coupling breaks in installed cache (visual-kit's rule: "`../other-plugin/...` paths do not resolve"). CLI on PATH works everywhere — Claude Code, Codex, OpenCode, Kiro.

### D-03: Scripts, not a compiled binary

**Decision:** site-utils ships bash/python scripts, not a compiled Go/Rust binary.

**Rationale:**
- Zero-dependency execution on typical CI/dev environments
- Easy to inspect, modify, and debug
- Matches beacon's existing `scripts/*.sh` pattern
- No build step required for development

### D-04: Each consumer keeps phase-specific logic

**Decision:** site-utils provides primitives (fetch, screenshot, discover). Consumers keep their phase-specific logic (OSINT orchestration, tech pack probing, content audit, IA analysis).

**Rationale:** The "what to do with the fetched content" is consumer-specific. beacon does security exposure analysis; reframe does content inventory; SEO does meta audit. Only the "how to fetch a page" and "how to discover content" are shared.

### D-05: Versioned via marketplace tags

**Decision:** site-utils versions follow semver. Consumers declare `~1.0.0` (pessimistic minor version constraint).

**Rationale:** Matches visual-kit's versioning model. Breaking changes require a major version bump. Additive scripts (new tools) ship as minor versions.

---

## 8. Independence Verification

### 8.1 Dependency graph

```
site-utils (library)
├── beacon (consumer)
├── reframe (consumer)
├── seo (consumer, planned)
└── paidagogos (consumer, visual-kit only)
    └── visual-kit (library)
```

### 8.2 Independence matrix

| Consumer | Works alone? | Requires beacon? | Requires reframe? | Requires seo? | Requires site-utils? |
|----------|-------------|-------------------|-------------------|---------------|---------------------|
| beacon | ✅ Yes | — | No | No | Yes |
| reframe | ✅ Yes | No | — | No | Yes |
| seo | ✅ Yes | No | No | — | Yes |
| paidagogos | ✅ Yes | No | No | No | No (uses visual-kit) |

### 8.3 User scenarios

| Scenario | Works? | Notes |
|----------|--------|-------|
| User enables only beacon | ✅ | site-utils auto-installed as dependency |
| User enables only reframe | ✅ | site-utils auto-installed as dependency |
| User enables only SEO | ✅ | site-utils auto-installed as dependency |
| User enables beacon + reframe | ✅ | Both use shared site-utils, no conflict |
| User enables all three | ✅ | All use shared site-utils, no conflict |
| User disables site-utils | ⚠️ | Consumer plugins fail with clear error: "site-utils not found" |

---

## 9. Migration Plan

### Phase 1: Create site-utils (v1.0.0)

1. Scaffold `plugins/site-utils/` with plugin.json, bin/, scripts/, references/, tests/
2. Implement `fetch_with_fallback.sh` (extract from beacon Phase 11 + reframe Phase 3)
3. Implement `screenshot.sh` (extract from beacon Phase 11 + reframe Phase 4)
4. Implement `content_extract.py` (extract from reframe Phase 4)
5. Implement `url_cluster.py` (extract from beacon Phase 10 + reframe Phase 2)
6. Implement `content_discovery.sh` (new ffuf wrapper)
7. Implement `subdomain_enum.sh` (new subfinder wrapper + crt.sh fallback)
8. Implement `httpx_probe.sh` (new httpx wrapper + curl fallback)
9. Implement `nuclei_scan.sh` (new nuclei wrapper)
10. Write tests for all scripts
11. Write README.md with usage examples

### Phase 2: Migrate beacon (v0.10.0)

1. Add `"dependencies": [{"name": "site-utils", "version": "~1.0.0"}]` to plugin.json
2. Replace inline fetch chain in Phase 11 with `site-utils fetch`
3. Replace inline screenshot in Phase 11 with `site-utils screenshot`
4. Add `site-utils subdomain-enum` to Phase 9 OSINT sweep
5. Add `site-utils probe` to Phase 9 URL validation
6. Add `site-utils nuclei-scan` to Phase 9 security exposure
7. Add `site-utils content-discovery` to Phase 5/9
8. Add `site-utils cluster-urls` to Phase 10 browse plan
9. Remove inline fetch/screenshot code (~150 lines)
10. Update SKILL.md references to site-utils commands

### Phase 3: Migrate reframe (v0.5.0)

1. Add `"dependencies": [{"name": "site-utils", "version": "~1.0.0"}]` to plugin.json
2. Replace inline fetch chain in Phase 3 with `site-utils fetch`
3. Replace inline screenshot in Phase 4 with `site-utils screenshot`
4. Replace inline content extraction in Phase 4 with `site-utils extract`
5. Add `site-utils cluster-urls` to Phase 2
6. Remove inline fetch/screenshot code (~100 lines)
7. Update SKILL.md references to site-utils commands

### Phase 4: SEO plugin (v0.1.0, future)

1. Create `plugins/seo/` with site-utils dependency from the start
2. Use `site-utils fetch`, `site-utils probe`, `site-utils content-discovery`, `site-utils subdomain-enum`

---

## 10. Open Questions

1. **CLI shim language:** Should `bin/site-utils` be a Node.js shim (like visual-kit) or a bash wrapper? Bash is simpler but less portable. Node matches visual-kit.

2. **Default wordlist for ffuf:** Ship a built-in common wordlist or download on first use? Built-in is ~500 entries (dirs) + ~200 (params). Downloading allows updating without version bump.

3. **nuclei template scope:** Should site-utils ship with curated templates or use nuclei's defaults? Curated = smaller, safer. Defaults = more comprehensive.

4. **Testing strategy:** Unit tests per script (mocked HTTP) + integration tests (live targets)? Or just integration tests?

5. **Tool auto-install:** Should site-utils offer to install missing tools (ffuf, subfinder, etc.) via `site-utils install`? Or just warn and fall back?

6. **Beacon OSINT scripts:** Should `passive_dns.sh`, `sublist3r.sh`, `tls_fingerprint.sh` move to site-utils? Or stay in beacon as beacon-specific OSINT? Recommendation: keep in beacon — they're OSINT-specific, not general crawl infrastructure.

---

## 11. Success Criteria

1. **Independence:** beacon, reframe, and SEO each work without the others enabled
2. **No duplication:** Shared fetch/screenshot/extract/cluster code lives only in site-utils
3. **No filesystem coupling:** Consumers call `site-utils` CLI, never `../site-utils/` paths
4. **Fallback resilience:** Every script works without its primary tool (graceful degradation)
5. **Test coverage:** All scripts have unit tests + at least one integration test
6. **Documentation:** README.md with usage examples, references/ with strategy guides

---

## 12. Related Documents

| Document | Location |
|----------|----------|
| visual-kit design spec | `docs/superpowers/specs/2026-04-17-visual-kit-design.md` |
| visual-kit contributor index | `docs/plugins/visual-kit/_index.md` |
| beacon site-recon SKILL.md | `plugins/beacon/skills/site-recon/SKILL.md` |
| beacon OSINT sources | `plugins/beacon/skills/site-recon/references/osint-sources.md` |
| beacon ROADMAP.md | `docs/plugins/beacon/ROADMAP.md` |
| reframe site-redesign SKILL.md | `plugins/reframe/skills/site-redesign/SKILL.md` |
| reframe crawl-and-coverage | `plugins/reframe/skills/site-redesign/references/crawl-and-coverage.md` |
| SEO plugin plan | `docs/superpowers/plans/2026-07-12-seo-plugin.md` |
| multi-tool support | `docs/platform/multi-tool-support.md` |
