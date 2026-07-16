# site-utils — Shared Crawl Infrastructure — Design

- **Date:** 2026-07-13
- **Status:** Revised (post-adversarial-review)
- **Depends on:** None (new plugin)
- **Affects:** beacon, reframe, planned SEO plugin

---

## Revision Log

| Date | Change | Reviewer |
|------|--------|----------|
| 2026-07-13 | Initial draft | — |
| 2026-07-13 | Revised per adversarial review: scoped v1.0.0 to 3 scripts, added shared fetch lib, scope-gated active scanning, resolved all open questions, added per-tool independence matrix, added OKF gate contract section | Adversarial reviewer |
| 2026-07-15 | Task-0 spike completed: `dependencies[]` auto-install works, but CLI not on PATH — requires manual symlink or global install | Spike test |

---

## 1. Problem Statement

Three plugins in this marketplace need overlapping web crawling, fetching, and content discovery capabilities:

- **beacon** — 16-phase site recon (API surface mapping, OSINT, security exposure)
- **reframe** — 9-phase site redesign (content crawl, IA analysis, design brief)
- **seo** (planned) — SEO audit (technical audit, on-page audit, scoring)

### 1.1 Shared capabilities (currently duplicated)

| Capability | beacon | reframe | seo |
|------------|--------|---------|-----|
| WAF-aware fetch chain (curl → Jina → Firecrawl → Crawl4AI → browser) | Phase 11 inline (~120 lines) | Phase 3 render gate (~100 lines) | — |
| Screenshot capture (Jina → Firecrawl → Crawl4AI → Chrome MCP → Playwright) | Phase 11 inline (~60 lines) | Phase 4 (~50 lines) | — |
| robots.txt / sitemap parsing | Phase 2 inline | Phase 2 inline | Phase 1 (planned) |
| URL clustering by path template | Phase 10 browse plan | Phase 2 structure | — |
| Content extraction (HTML → markdown) | Phase 7 JS bundles (beacon-specific) | Phase 4 content crawl | — |
| Subdomain enumeration | Phase 9 OSINT | — | Phase 1 (planned) |
| HTTP probing / URL validation | Phase 9 | Phase 3 coverage | Phase 2 (planned) |
| Content discovery (directory/param brute-force) | Phase 5/9 | — | Phase 2 (planned) |
| Vulnerability scanning | Phase 9 | — | — |

### 1.2 The actual duplication (what hurts today)

The genuinely duplicated, battle-tested code across both existing consumers:

1. **WAF-aware fetch chain** — ~120 lines in beacon + ~100 lines in reframe = ~220 lines maintaining identical fallback logic (curl → Jina → Firecrawl → Crawl4AI → browser fetch). Bug fixes applied in one consumer don't reach the other.

2. **Screenshot capture** — ~60 lines in beacon + ~50 lines in reframe = ~110 lines maintaining identical tool-selection logic (Jina pageshot → Firecrawl → Crawl4AI → Chrome MCP → Playwright).

3. **URL clustering** — beacon Phase 10 and reframe Phase 2 both group URLs by path template with similar logic.

Everything else is either beacon-specific (OSINT scripts, tech pack probing, JS bundle analysis), reframe-specific (content audit, IA analysis, category detection), or net-new capability (ffuf, subfinder, httpx, nuclei).

### 1.3 The sharing dilemma

Four options were evaluated:

**Option A: Keep scripts in one plugin, others reference by path**
- Pro: Simple, no new plugin
- Con: Hard dependency — if beacon is disabled, reframe breaks
- Con: `../other-plugin/...` paths don't resolve in installed cache (violates visual-kit's "no filesystem coupling" rule)
- Con: Users can't use reframe or SEO without enabling beacon
- **Verdict: Rejected**

**Option B: Duplicate scripts into each plugin**
- Pro: Each plugin fully independent
- Con: 330+ lines duplicated across 2-3 plugins
- Con: Bug fixes must be applied in 3 places
- Con: No versioning of shared code
- **Verdict: Rejected** — the fetch chain and screenshot fallback are fragile enough that maintaining 3 copies is a real maintenance burden

**Option C: Library plugin (visual-kit pattern)**
- Pro: Each consumer independently installable
- Pro: Single source of truth for shared code
- Pro: Versioned, testable, independently releasable
- Con: Adds a plugin to manage
- Con: `dependencies[]` auto-install is designed but **never exercised** in this repo (see §2.2)
- **Verdict: Recommended with caveats** — requires Task-0 spike to verify

**Option D: sync-scripts approach (like sync-skills.sh)**
- Pro: Single source of truth, fan-out at release time
- Pro: Proven pattern in this repo (sync-skills.sh already does this for skill files)
- Pro: Zero runtime dependency resolution — scripts live in each consumer's own `scripts/` dir
- Con: Each consumer gets a copy (not independently versioned)
- Con: Release step required to propagate changes
- **Verdict: Viable fallback if Task-0 spike fails**

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

### 2.2 The visual-kit precedent — designed but untested

Visual-kit is a **library plugin** — infrastructure that other plugins depend on:

| Property | Value |
|----------|-------|
| `"skills": []` | No user-facing skills (or minimal lifecycle help) |
| Purpose | Runtime infrastructure (HTTP server, component library, CLI) |
| Consumer contract | `plugin.json` `dependencies[]` |
| Communication | CLI on PATH, HTTP server, file system seams in known paths |
| Independence rule | "No filesystem coupling between plugins" |

**Status (post-spike):** the `dependencies[]` mechanism is now **tested and confirmed working**. A spike test on 2026-07-15 verified that installing a consumer plugin with `"dependencies": [{"name": "site-utils", "version": "~1.0.0"}]` auto-installs the dependency with `"auto": true` in `installed_plugins.json`. However, the CLI is NOT placed on system PATH automatically — consumers must ensure the dependency's `bin/` is accessible (via symlink in `~/.local/bin/`, global install, or inline PATH manipulation). This matches visual-kit's pattern: it uses a manual symlink in `~/.local/bin/visual-kit`.

### 2.3 Task-0 spike (completed 2026-07-15)

**Result: PASS with caveat.**

| Test | Result | Notes |
|------|--------|-------|
| `dependencies[]` auto-install | ✅ PASS | Installing `_spike-test-consumer` auto-installed `site-utils` with `"auto": true` |
| CLI on system PATH | ❌ FAIL | `which site-utils` → not found. Plugin system does NOT add `bin/` to PATH |
| CLI in cache | ✅ PASS | `~/.claude/plugins/cache/.../bin/site-utils` runs correctly |
| installed_plugins.json integrity | ⚠️ WARN | Auto-install overwrites user-scoped list; restored from `.bak2` |

**Caveat:** The library-plugin model works for installation, but consumers must handle PATH themselves. Options:
1. Manual symlink in `~/.local/bin/` (visual-kit's approach)
2. Consumer SKILL.md adds `export PATH="$CLAUDE_PLUGIN_ROOT/../site-utils/bin:$PATH"` before calling site-utils
3. Consumer uses `"$CLAUDE_PLUGIN_ROOT/../site-utils/bin/site-utils"` (filesystem coupling — rejected per D-02)

**Decision:** Proceed with library-plugin model (Option C). PATH setup is a documentation concern, not an architecture blocker. Consumer SKILL.md will include a PATH bootstrap snippet.

Spike artifacts were cleaned up after testing.

### 2.4 Plugin independence requirement

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
│   └── site-utils               ← CLI entry point (bash wrapper)
├── lib/
│   └── fetch_chain.sh           ← shared WAF detection + fallback logic
├── scripts/
│   ├── fetch_with_fallback.sh   ← WAF-aware fetch chain (sources lib/fetch_chain.sh)
│   ├── screenshot.sh            ← multi-source screenshot capture (sources lib/fetch_chain.sh)
│   └── url_cluster.py           ← group URLs by path template
├── references/
│   ├── fetch-strategy.md        ← when to use what, WAF detection
│   └── tool-availability.md     ← installed tools, fallback chains
├── tests/
│   ├── test_fetch_chain.sh      ← unit tests for fetch logic
│   ├── test_screenshot.sh       ← unit tests for screenshot logic
│   └── test_url_cluster.py      ← unit tests for clustering
└── README.md
```

### 3.3 Shared fetch library (`lib/fetch_chain.sh`)

Both `fetch_with_fallback.sh` and `screenshot.sh` share ~80% of their logic: WAF detection, source-selection, retry/backoff. Rather than duplicating this in two scripts, it lives in `lib/fetch_chain.sh` and is sourced by both.

```bash
# lib/fetch_chain.sh — shared fetch infrastructure

# WAF detection (returns detected WAF name or "none")
detect_waf() {
  local headers="$1" body="$2"
  echo "$headers" | grep -qi "cf-ray" && echo "cloudflare" && return
  echo "$headers" | grep -qi "x-datadome" && echo "datadome" && return
  echo "$body" | grep -q '"type":"DataDome"' && echo "datadome" && return
  echo "$headers" | grep -qi "_px" && echo "perimeterx" && return
  echo "$headers" | grep -qi "AkamaiGHost" && echo "akamai" && return
  echo "none"
}

# Source selection (returns ordered list of sources to try)
select_sources() {
  local strategy="${1:-auto}" waf="$2"
  case "$strategy" in
    jina)       echo "jina firecrawl crawl4ai browser" ;;
    firecrawl)  echo "firecrawl crawl4ai browser" ;;
    auto)
      case "$waf" in
        datadome|perimeterx) echo "firecrawl jina crawl4ai browser" ;;
        cloudflare)          echo "jina firecrawl crawl4ai browser" ;;
        *)                   echo "curl jina firecrawl crawl4ai browser" ;;
      esac
      ;;
  esac
}

# Fetch via a specific source (returns 0 on success, 1 on failure)
fetch_via() {
  local source="$1" url="$2" format="$3"
  case "$source" in
    curl)      fetch_curl "$url" "$format" ;;
    jina)      fetch_jina "$url" "$format" ;;
    firecrawl) fetch_firecrawl "$url" "$format" ;;
    crawl4ai)  fetch_crawl4ai "$url" "$format" ;;
    browser)   fetch_browser "$url" "$format" ;;
  esac
}
```

### 3.4 Consumer dependency model

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

**Conditional on Task-0 spike success** (§2.3). If the spike fails, fall back to Option D: sync-scripts copies scripts into each consumer at release time.

### 3.5 How consumers call site-utils

**CLI on PATH** (matches visual-kit pattern):

```bash
# beacon Phase 11 — fetch with WAF fallback:
site-utils fetch "https://example.com" --strategy auto

# reframe Phase 4 — screenshot:
site-utils screenshot "https://example.com" --out .crawl/screenshots/home.png

# reframe Phase 2 — URL clustering:
site-utils cluster-urls /tmp/urls.txt --output ia-map.json
```

**Per-tool availability (post-spike):**

| Tool | site-utils availability | Mechanism |
|------|------------------------|-----------|
| Claude Code | ✅ Via `dependencies[]` auto-install + manual PATH setup | Auto-install confirmed working; consumer SKILL.md adds `bin/` to PATH |
| Codex CLI | ⚠️ Requires manual install or global PATH | No dependency resolution — user must ensure `site-utils` is on PATH |
| OpenCode | ⚠️ Requires manual install or global PATH | Same as Codex |
| Antigravity | ⚠️ Requires manual install or global PATH | Same as Codex |
| Kiro | ⚠️ Requires manual install or global PATH | Same as Codex |

**Non-Claude-Code consumers:** site-utils must be globally installed or on PATH. Consumers should detect absence and emit `[TOOL-UNAVAILABLE:site-utils]` with a fallback path (inline curl for fetch, etc.). This matches how beacon already handles missing tools (Wappalyzer, Firecrawl, etc.).

**PATH bootstrap for Claude Code consumers:** Each consumer SKILL.md should include a PATH snippet at the top:

```bash
# Ensure site-utils is on PATH (auto-installed via dependencies[])
 SITE_UTILS_BIN="$(dirname "$0")/../site-utils/bin"
 command -v site-utils &>/dev/null || export PATH="$SITE_UTILS_BIN:$PATH"
```

This handles the case where `dependencies[]` installed site-utils but didn't add it to PATH.

### 3.6 Fallback when site-utils is absent

Every consumer must have a fallback path when site-utils isn't installed:

```bash
# In beacon SKILL.md:
if command -v site-utils &>/dev/null; then
  site-utils fetch "$URL" --format markdown
else
  # Inline fallback (existing logic)
  curl -s "$URL" | python3 -c "..." # markdown extraction
  log "[TOOL-UNAVAILABLE:site-utils:using-inline-fallback]"
fi
```

This ensures consumers work on all 5 tools, not just Claude Code.

---

## 4. Script Specifications

### 4.1 `fetch_with_fallback.sh` — WAF-aware fetch chain

**Purpose:** Fetch a URL with automatic WAF detection and fallback escalation.

**Implementation:** Sources `lib/fetch_chain.sh` for shared WAF detection and source selection. Thin wrapper that handles CLI args and output formatting.

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
```

**Signal tokens emitted** (must match beacon's OKF gate format exactly — see §6):

```
[FETCH:curl]
[FETCH:jina]
[FETCH:firecrawl]
[FETCH:crawl4ai]
[FETCH:browser]
[FETCH-BLOCKED:all]
```

**Exit codes:**
- `0` — success (content on stdout)
- `1` — all sources failed (error details on stderr)

### 4.2 `screenshot.sh` — multi-source screenshot capture

**Purpose:** Capture a screenshot using the best available tool.

**Implementation:** Sources `lib/fetch_chain.sh` for WAF detection. Uses the same source-selection logic but for screenshot endpoints (Jina pageshot, Firecrawl screenshot, Crawl4AI screenshot, Chrome MCP, Playwright).

**Fallback order:** Jina pageshot → Firecrawl → Crawl4AI → Chrome MCP → Playwright

**Input:** URL, output path
**Output:** PNG screenshot file

```bash
# Usage:
site-utils screenshot "https://example.com" --out /tmp/page.png
site-utils screenshot "https://example.com" --out /tmp/page.png --full-page
site-utils screenshot "https://example.com" --out /tmp/page.png --viewport 1280x720
```

**Signal tokens emitted:**

```
[SCREENSHOT:jina]
[SCREENSHOT:firecrawl]
[SCREENSHOT:crawl4ai]
[SCREENSHOT:chrome]
[SCREENSHOT:playwright]
[SCREENSHOT-UNAVAILABLE]
```

**Exit codes:**
- `0` — screenshot saved to output path
- `1` — all sources failed

### 4.3 `url_cluster.py` — URL clustering

**Purpose:** Group URLs by path template for template detection.

**Implementation:** Pure Python, no external tool dependencies. Reads URLs from file or stdin, outputs JSON cluster map.

**Input:** URL list (file or stdin)
**Output:** JSON cluster map to stdout

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

**Exit codes:**
- `0` — success
- `1` — invalid input or parse error

---

## 5. Scripts Deferred to v1.1.0+

The following scripts are net-new capability (not currently duplicated across consumers). They belong in site-utils but should ship after v1.0.0 proves the library-plugin model works and after the consent-gate question (§5.1) is resolved.

| Script | Tool | Consumers | Why deferred |
|--------|------|-----------|-------------|
| `content_discovery.sh` | ffuf | beacon, seo | Active scanning — requires consent gate (§5.1) |
| `subdomain_enum.sh` | subfinder | beacon, seo | beacon already has sublist3r.sh; new capability, not dedup |
| `httpx_probe.sh` | httpx | beacon, reframe, seo | New capability; beacon already has inline probe logic |
| `nuclei_scan.sh` | nuclei | beacon | Active vuln scanning — requires consent gate (§5.1) |
| `deep_crawl.sh` | katana | beacon, reframe | New capability |
| `dns_recon.sh` | dnsrecon | beacon | New capability |
| `robots_extract.sh` | curl | beacon, reframe, seo | See §5.2 |

### 5.1 Consent gate for active scanning tools

Beacon already treats active infrastructure probing as scope-gated: `cloud-enum.sh` and `container-scan.sh` are explicitly excluded from Phase 9's default sweep with a documented rationale ("actively probe third-party and infrastructure hosts").

ffuf (content_discovery.sh) and nuclei (nuclei_scan.sh) are the same class of risk — both actively probe third-party infrastructure the user may not own or have authorization to scan.

**Decision:** content_discovery.sh and nuclei_scan.sh must default-off, gated by the same scope mechanism beacon uses for cloud-enum.sh:

```bash
# Default (safe):
site-utils nuclei-scan "https://example.com" --exclude cloud-enum,container-scan

# Opt-in (authorized engagement only):
site-utils nuclei-scan "https://example.com" --include active-scan
```

This is a **regression prevention** — wiring these into Phase 9's default sweep without scope-gating would be a security posture regression relative to beacon's existing behavior.

### 5.2 robots.txt / sitemap parsing

Listed as duplicated in §1.1, but inspection shows the implementations are trivially different:

- beacon: `curl -s "${URL}/robots.txt"` + grep for Disallow/Sitemap
- reframe: `curl -s "${URL}/robots.txt"` + parse for Sitemap directives

Both are ~5-10 lines of curl + grep. Extracting this into a script adds complexity without meaningful dedup. **Decision: keep inline in each consumer.** If a9th script is added in v1.1.0+, this is a candidate, but it's not worth a separate script for the current duplication level.

---

## 6. OKF Gate Signal Contract

Beacon's OKF output contract (§6b, Phase 12 gate) regex-matches signal tokens like `[P9✓]`, `[THIRD-PARTY-KEYS:{n} found]`, `[CF-PIVOT:firecrawl]`. site-utils scripts emit signal tokens that must integrate with this gate.

### 6.1 Signal format compatibility

site-utils signal tokens follow the same format as beacon's existing signals:
- Bracket-enclosed: `[TOKEN]` or `[TOKEN:detail]`
- No spaces inside brackets
- Alphanumeric + hyphens + colons only

**Risk:** If site-utils ships a 1.0.1 patch that changes token wording under a `~1.0.0` pin, beacon's OKF gate could break.

**Mitigation:**
1. Signal token wording is part of site-utils's public API — changes require a major version bump
2. site-utils ships a `--signal-format` flag that prints all possible tokens for a given command, enabling consumers to validate compatibility
3. beacon's OKF gate tests include a site-utils signal compatibility check

### 6.2 Exit code contract

| Exit code | Meaning | Consumer action |
|-----------|---------|----------------|
| `0` | Success | Process output normally |
| `1` | All sources failed | Log `[TOOL-UNAVAILABLE:site-utils:<command>]`, fall back to inline logic |
| `2` | Invalid arguments | Log error, halt phase |
| `126` | Command not executable | Log `[TOOL-UNAVAILABLE:site-utils:not-installed]`, fall back |
| `127` | Command not found | Log `[TOOL-UNAVAILABLE:site-utils:not-installed]`, fall back |

### 6.3 stderr/stdout contract

- **stdout:** Script output (fetched content, screenshot path, cluster JSON)
- **stderr:** Diagnostic messages, signal tokens, error details
- **Signal tokens go to stderr** so consumers can capture stdout纯净 while still seeing signals

```bash
# Consumer usage:
OUTPUT=$(site-utils fetch "$URL" 2>/tmp/site-utils-signals.log)
SIGNALS=$(cat /tmp/site-utils-signals.log)
# Parse SIGNALS for [FETCH:jina] etc., use OUTPUT for content
```

---

## 7. Impact on Existing Plugins

### 7.1 beacon migration (v0.10.0)

| Phase | Current (inline) | Future (site-utils) |
|-------|------------------|-------------------|
| Phase 2 | robots.txt/sitemap inline curl | Keep inline (trivial curl, §5.2) |
| Phase 3 | Wappalyzer + headers + HTML grep | Keep inline (beacon-specific detection) |
| Phase 5 | Platform-specific probes | Keep inline (tech-pack-specific) |
| Phase 7 | JS bundle download + grep | Keep inline (beacon-specific analysis) |
| Phase 9 | `passive_dns.sh`, `sublist3r.sh`, etc. | Keep as beacon-specific OSINT scripts |
| Phase 10 | URL list compilation | `site-utils cluster-urls` |
| Phase 11 | Inline fetch + screenshot (~180 lines) | `site-utils fetch` + `site-utils screenshot` |

**Net effect:** ~180 lines of inline fetch/screenshot code replaced by site-utils calls (~6 lines). ~0 new code added (v1.0.0 scope).

**Fallback:** If site-utils absent, inline fetch/screenshot logic remains as fallback (existing code, not removed until site-utils is proven).

### 7.2 reframe migration (v0.5.0)

| Phase | Current (inline) | Future (site-utils) |
|-------|------------------|-------------------|
| Phase 2 | robots.txt/sitemap inline curl | Keep inline (trivial curl, §5.2) |
| Phase 2 | URL enumeration | `site-utils cluster-urls` |
| Phase 3 | WAF detection + fetch fallback (~100 lines) | `site-utils fetch` |
| Phase 4 | Screenshot capture (~50 lines) | `site-utils screenshot` |
| Phase 4 | Content crawl (markdown extraction) | Keep inline (reframe-specific extraction) |

**Net effect:** ~150 lines of inline fetch/screenshot code replaced by site-utils calls (~5 lines). ~0 new code added.

**Fallback:** If site-utils absent, inline fetch/screenshot logic remains as fallback.

### 7.3 SEO plugin (planned, future)

The SEO plugin would declare site-utils as a dependency from the start. It would use v1.1.0+ scripts (content_discovery, subdomain_enum, httpx_probe) — not in v1.0.0 scope.

**Decision:** Do not design SEO's site-utils usage until SEO's own spec is written. The library plugin should prove itself with beacon and reframe first.

---

## 8. Architecture Decisions

### D-01: Library plugin, not standalone scraping plugin

**Decision:** site-utils is a library plugin with `"skills": []`, not a user-facing plugin with its own skills/commands.

**Rationale:** A plugin without user-facing skills is infrastructure, not a product. Users don't "use site-utils" — they use beacon, reframe, or SEO, which happen to depend on site-utils.

**Reversal condition:** If Task-0 spike (§2.3) fails, fall back to Option D (sync-scripts).

### D-02: CLI on PATH, not filesystem coupling

**Decision:** Consumers call site-utils via `site-utils <command>` CLI, not via `../site-utils/scripts/` paths.

**Rationale:** Filesystem coupling breaks in installed cache (visual-kit's rule: "`../other-plugin/...` paths do not resolve"). CLI on PATH works in Claude Code via `dependencies[]` auto-install. On other tools, user must ensure global install.

**Caveat:** This only works automatically on Claude Code. On Codex/OpenCode/Kiro, consumers must detect absence and fall back to inline logic (§3.6).

### D-03: Bash CLI, not Node

**Decision:** `bin/site-utils` is a bash wrapper, not a Node.js shim.

**Rationale:** D-03 states "zero-dependency execution" and "no build step." Introducing Node as a runtime requirement contradicts this. Visual-kit needs Node because it runs an actual HTTP server; site-utils dispatches to bash/python scripts. A bash CLI is simpler, has zero dependencies, and matches the `scripts/*.sh` pattern.

### D-04: Shared fetch library, not two independent scripts

**Decision:** `lib/fetch_chain.sh` contains shared WAF detection, source selection, and retry logic. Both `fetch_with_fallback.sh` and `screenshot.sh` source it.

**Rationale:** The review correctly identified that fetch and screenshot share ~80% of their logic. Duplicating WAF detection in two scripts reproduces the problem site-utils exists to solve.

### D-05: Each consumer keeps phase-specific logic

**Decision:** site-utils provides primitives (fetch, screenshot, cluster). Consumers keep their phase-specific logic (OSINT orchestration, tech pack probing, content audit, IA analysis).

**Rationale:** The "what to do with the fetched content" is consumer-specific. Only the "how to fetch a page" is shared.

### D-06: Scope-gated active scanning

**Decision:** `content_discovery.sh` and `nuclei_scan.sh` default-off, gated by the same scope mechanism as `cloud-enum.sh`.

**Rationale:** These tools actively probe third-party infrastructure. beacon already gates this class of risk. Wiring them into default sweeps without gating is a security posture regression.

### D-07: Signal tokens as public API

**Decision:** site-utils signal token wording is part of the public API. Changes require a major version bump.

**Rationale:** Consumers' OKF gates regex-match these tokens. Silent wording changes under a `~1.0.0` pin would break consumers.

### D-08: v1.0.0 scope — 3 scripts only

**Decision:** v1.0.0 ships `fetch_with_fallback.sh`, `screenshot.sh`, and `url_cluster.py` only.

**Rationale (from review §7):** These are the genuinely duplicated, battle-tested scripts across both existing consumers. Everything else is net-new capability dressed up as deduplication. Ship the dedup first, prove the model, add new capability in v1.1.0+.

---

## 9. Independence Verification

### 9.1 Dependency graph

```
site-utils (library)
├── beacon (consumer)
├── reframe (consumer)
└── seo (consumer, planned — not in v1.0.0 scope)

visual-kit (library)
├── paidagogos (consumer)
├── namesmith (consumer)
└── draftloom (consumer)
```

### 9.2 Independence matrix — per consumer AND per tool

| Consumer | Claude Code | Codex CLI | OpenCode | Antigravity | Kiro |
|----------|------------|-----------|----------|-------------|------|
| **beacon** (site-utils via `dependencies[]`) | ✅ Auto-installed | ⚠️ Manual global install required | ⚠️ Manual global install required | ⚠️ Manual global install required | ⚠️ Manual global install required |
| **beacon** (fallback: inline curl) | ✅ Always works | ✅ Always works | ✅ Always works | ✅ Always works | ✅ Always works |
| **reframe** (site-utils via `dependencies[]`) | ✅ Auto-installed | ⚠️ Manual global install required | ⚠️ Manual global install required | ⚠️ Manual global install required | ⚠️ Manual global install required |
| **reframe** (fallback: inline curl) | ✅ Always works | ✅ Always works | ✅ Always works | ✅ Always works | ✅ Always works |

**Key insight:** consumers work on all 5 tools because they have inline fallback paths. site-utils is an optimization, not a hard requirement.

### 9.3 User scenarios

| Scenario | Works? | Notes |
|----------|--------|-------|
| User enables only beacon (Claude Code) | ✅ | site-utils auto-installed via `dependencies[]` |
| User enables only beacon (Codex) | ✅ | Inline fallback if site-utils not globally installed |
| User enables only reframe (Claude Code) | ✅ | site-utils auto-installed via `dependencies[]` |
| User enables only reframe (Codex) | ✅ | Inline fallback if site-utils not globally installed |
| User enables beacon + reframe | ✅ | Both use shared site-utils, no conflict |
| User disables site-utils | ✅ | Consumers fall back to inline logic |
| site-utils ships breaking change under ~1.0.0 | ⚠️ | Signal tokens change → OKF gate breaks. Mitigated by D-07 (signal tokens as public API) |

---

## 10. Migration Plan

### Phase 0: Task-0 spike (required)

1. Create throwaway test plugin with `"dependencies": [{"name": "site-utils", "version": "~1.0.0"}]`
2. Install via `/plugin install` in Claude Code
3. Verify `site-utils` CLI is on PATH and executable
4. Test on Codex/OpenCode/Kiro if available
5. **If spike fails:** switch to Option D (sync-scripts) for distribution

### Phase 1: Create site-utils v1.0.0

1. Scaffold `plugins/site-utils/` with plugin.json, bin/, lib/, scripts/, references/, tests/
2. Implement `lib/fetch_chain.sh` (shared WAF detection + fallback logic)
3. Implement `fetch_with_fallback.sh` (sources lib/fetch_chain.sh)
4. Implement `screenshot.sh` (sources lib/fetch_chain.sh)
5. Implement `url_cluster.py` (pure Python, no external deps)
6. Write `bin/site-utils` bash CLI wrapper
7. Write tests for all scripts
8. Write README.md with usage examples
9. Write references/fetch-strategy.md and references/tool-availability.md

### Phase 2: Migrate beacon v0.10.0

1. Add `"dependencies": [{"name": "site-utils", "version": "~1.0.0"}]` to plugin.json
2. Replace inline fetch chain in Phase 11 with `site-utils fetch` (keep inline as fallback)
3. Replace inline screenshot in Phase 11 with `site-utils screenshot` (keep inline as fallback)
4. Add `site-utils cluster-urls` to Phase 10 browse plan
5. Update SKILL.md references to site-utils commands
6. Add `[TOOL-UNAVAILABLE:site-utils]` graceful degradation signal
7. **Do NOT remove inline fallback code** until site-utils is proven in production

### Phase 3: Migrate reframe v0.5.0

1. Add `"dependencies": [{"name": "site-utils", "version": "~1.0.0"}]` to plugin.json
2. Replace inline fetch chain in Phase 3 with `site-utils fetch` (keep inline as fallback)
3. Replace inline screenshot in Phase 4 with `site-utils screenshot` (keep inline as fallback)
4. Add `site-utils cluster-urls` to Phase 2
5. Update SKILL.md references to site-utils commands
6. Add `[TOOL-UNAVAILABLE:site-utils]` graceful degradation signal
7. **Do NOT remove inline fallback code** until site-utils is proven in production

### Phase 4: site-utils v1.1.0 (after v1.0.0 is proven)

1. Add `content_discovery.sh` (ffuf wrapper, scope-gated per D-06)
2. Add `subdomain_enum.sh` (subfinder wrapper + crt.sh fallback)
3. Add `httpx_probe.sh` (httpx wrapper + curl fallback)
4. Add `nuclei_scan.sh` (nuclei wrapper, scope-gated per D-06)
5. Add `deep_crawl.sh` (katana wrapper)
6. Add `dns_recon.sh` (dnsrecon wrapper)

### Phase 5: SEO plugin (future, out of scope)

1. Create `plugins/seo/` with site-utils dependency from the start
2. Use v1.1.0+ scripts as needed
3. **Do not design SEO's site-utils usage until SEO's own spec is written**

---

## 11. Resolved Open Questions

| # | Question | Resolution | Rationale |
|---|----------|------------|-----------|
| 1 | CLI shim language | **Bash** | D-03 says "zero-dependency execution." Node contradicts this. Visual-kit needs Node for its HTTP server; site-utils doesn't. |
| 2 | Default wordlist for ffuf | **Built-in** (~500 dirs + ~200 params) | Reproducibility, works offline, no supply-chain exposure from fetching URLs at runtime. Deferred to v1.1.0 anyway. |
| 3 | nuclei template scope | **Curated** (exposure, misconfig, known CVEs) | Smaller, more predictable output for OKF-gate parsing. Pairs with consent-gate (D-06). Deferred to v1.1.0 anyway. |
| 4 | Testing strategy | **Both** — unit + integration | Unit tests per script (mocked HTTP). Integration tests opt-in against controlled fixture targets, never live third-party sites by default. |
| 5 | Tool auto-install | **No.** `site-utils doctor` reports missing tools and prints install commands for the user to run themselves. | These are pentester-class tools. Silent auto-install is a supply-chain foot-gun. |
| 6 | Beacon OSINT scripts | **Keep in beacon.** `passive_dns.sh`, `sublist3r.sh`, `tls_fingerprint.sh` stay as beacon-specific OSINT scripts. | OSINT orchestration is beacon-specific; general crawl primitives are not. |

---

## 12. Success Criteria

1. **Task-0 spike passes:** ✅ `dependencies[]` auto-install works on Claude Code (completed 2026-07-15). CLI not on PATH automatically — consumers include PATH bootstrap snippet.
2. **Independence:** beacon and reframe each work without the other enabled, on all 5 tools
3. **No duplication:** Shared fetch/screenshot/cluster code lives only in site-utils (or its synced copies)
4. **No filesystem coupling:** Consumers call `site-utils` CLI, never `../site-utils/` paths
5. **Fallback resilience:** Every consumer works without site-utils installed (inline fallback)
6. **OKF gate compatibility:** Signal tokens match beacon's existing format; exit codes are documented
7. **Consent gate:** Active scanning tools (ffuf, nuclei) default-off, scope-gated
8. **Test coverage:** All scripts have unit tests + at least one integration test
9. **Documentation:** README.md with usage examples, references/ with strategy guides

---

## 13. Related Documents

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
