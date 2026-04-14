# Beacon: Tool Optionality and Graceful Degradation

## Overview

Beacon is designed to work in any environment where a terminal and internet access are available. The plugin always produces output — it never silently fails because an optional tool is missing. Instead, it logs a structured signal like `[TOOL-UNAVAILABLE:wappalyzer]` in the research output to mark exactly where a richer data source would have contributed, and then continues with the best available fallback.

The distinction between "required" and "optional" is simple: **required tools** are those without which beacon cannot run at all. This means `curl` and standard Unix utilities (`grep`, `awk`, `sort`, `uniq`) — tools you can reasonably expect in any POSIX environment. **Optional tools** are MCP servers, third-party CLI binaries, or session-level context (like being inside a `cmux` terminal multiplexer) that beacon will use when present but can operate without.

This document is the reference for understanding what each optional tool adds, what beacon does when it is absent, and what the `[TOOL-UNAVAILABLE:...]` signals in your research output mean. If you are seeing one of these signals and want to resolve it, the per-tool sections and the degradation signal table at the end of this document tell you exactly what to install.

---

## Tool Matrix

| Tool | Type | Required? | What it adds | Degradation signal | Fallback behavior |
|---|---|---|---|---|---|
| `curl` | CLI binary | **Yes** | HTTP requests, the foundation of every phase | _(none — beacon halts without it)_ | No fallback; execution stops |
| Wappalyzer MCP | MCP server | No | Structured technology fingerprinting (framework, CMS, CDN, analytics) | `[TOOL-UNAVAILABLE:wappalyzer]` | Header inspection + HTML pattern grep; generic signals only |
| Firecrawl MCP | MCP server | No | Full-site URL map, JS-rendered page content | `[TOOL-UNAVAILABLE:firecrawl]` | `curl /sitemap.xml`; sitemap entries only, no JS rendering |
| Firecrawl CLI | CLI binary | No | Same as Firecrawl MCP, as a local binary alternative | `[TOOL-UNAVAILABLE:firecrawl]` | Same as above (signal is shared with the MCP) |
| GAU (`getallurls`) | CLI binary | No | Historical URL corpus from Wayback Machine, CommonCrawl, OTX, URLScan | `[TOOL-UNAVAILABLE:gau]` | Wayback CDX API + CommonCrawl CDX API directly; CDX APIs always work |
| `cmux` browser | Session context | No | Full browser automation: JS execution, DOM interaction, accessibility snapshots | `[TOOL-UNAVAILABLE:cmux]` | Attempts Chrome DevTools MCP fallback; if also absent, Phase 11 is skipped |
| Chrome DevTools MCP | MCP server | No | Browser automation via the Chrome DevTools Protocol | `[TOOL-UNAVAILABLE:chrome-devtools-mcp]` | Attempts `cmux` browser fallback; if also absent, Phase 11 is skipped |

---

## Per-Tool Details

### Wappalyzer MCP

**What it does.** Wappalyzer is a technology detection engine that identifies software stacks from HTTP headers, HTML content, JavaScript globals, and cookie patterns. When connected as an MCP server, beacon calls it during Phase 3 (Fingerprinting) to get a structured technology manifest: framework name and version, CMS, CDN provider, analytics tags, A/B testing tools, tag managers, and more.

**Why it helps beacon.** Without structured fingerprinting, beacon falls back to inspecting raw response headers (`X-Powered-By`, `Server`, `Set-Cookie` names) and grepping HTML for known patterns (meta generator tags, script src patterns). This catches obvious signals but misses anything that requires Wappalyzer's pattern library — for example, identifying Nuxt vs Next.js from the `__NUXT__` global, or detecting a Cloudflare WAF from response headers alone.

**How to add it to Claude Code.** Add the Wappalyzer MCP server to your Claude Code session configuration. The exact server name and command depend on the Wappalyzer MCP distribution you are using; consult the server's README. Once it appears in the MCP server list visible to Claude Code, beacon will detect and use it automatically.

**What you miss without it.**

- Technology detection is limited to `Server`, `X-Powered-By`, and `X-Generator` HTTP headers plus a handful of HTML meta tags.
- JavaScript framework detection (React, Vue, Angular, Svelte, Nuxt, Next.js) will be absent or labelled `[FRAMEWORK-UNKNOWN]` unless the framework announces itself in a detectable header.
- Version information is rarely recoverable from headers alone.
- Third-party services (analytics, CDN, tag managers) are not detected at all.

**Degradation signal.** `[TOOL-UNAVAILABLE:wappalyzer]`

---

### Firecrawl (MCP or CLI)

**What it does.** Firecrawl crawls websites and returns structured content — either a full URL map of a site or rendered page content with JavaScript executed. Beacon uses it in two phases: Phase 2 (URL Discovery) to map the full URL surface of a target site, and Phase 6 to retrieve JS-rendered page bodies when plain `curl` would return an empty shell.

**Why it helps beacon.** Many modern sites are single-page applications that return near-empty HTML to a plain HTTP client. Firecrawl handles headless rendering, follows internal links, and returns a clean content representation. It also exposes sitemap-equivalent coverage for sites that do not publish a `/sitemap.xml`.

**How to install.**
- *MCP server:* Add the Firecrawl MCP server to your Claude Code configuration. Requires a Firecrawl API key set in your environment (`FIRECRAWL_API_KEY`).
- *CLI binary:* Install via npm: `npm install -g firecrawl-cli` (or the equivalent package for your distribution). The beacon skill checks for the CLI binary on `PATH` as a fallback when the MCP server is absent.

Beacon treats the MCP server and CLI as equivalent and checks for the MCP first. If either is present, the `[TOOL-UNAVAILABLE:firecrawl]` signal will not appear.

**What you miss without it.**

- URL discovery falls back to fetching `/sitemap.xml` and `/robots.txt` only. Sites without a sitemap will return a very short URL list.
- JS-rendered pages are not retrievable — you get the raw HTML returned by the server, which may be a near-empty `<div id="root"></div>` for React/Vue/Angular apps.
- Crawl depth is limited to what `curl` can reach in a single request per URL.

**Degradation signal.** `[TOOL-UNAVAILABLE:firecrawl]`

---

### GAU (`getallurls`)

**What it does.** GAU is a CLI tool that queries multiple historical URL databases — Wayback Machine, CommonCrawl, OTX (AlienVault Open Threat Exchange), and URLScan — and returns a deduplicated list of every URL ever publicly observed for a domain. Beacon uses this in Phase 9 (OSINT — URL History) to build a historical URL corpus for endpoint discovery, parameter enumeration, and detecting paths that may have been removed from the live site.

**Why it helps beacon.** GAU aggregates four separate data sources in a single call and handles deduplication, filtering, and rate-limiting automatically. Without it, beacon queries the Wayback CDX API and CommonCrawl CDX API directly, which covers roughly the same ground but omits OTX and URLScan data and requires more round trips.

**How to install.** GAU is a Go binary. Install with:

```bash
go install github.com/lc/gau/v2/cmd/gau@latest
```

Or download a pre-built binary from the [GAU releases page](https://github.com/lc/gau/releases) and place it on your `PATH`. Verify with `gau --version`.

**What you miss without it.**

- OTX and URLScan URL data is not queried — these sources occasionally surface URLs not indexed by Wayback or CommonCrawl.
- URL deduplication and filtering must be handled by beacon's own post-processing rather than GAU's built-in logic, which may result in a noisier URL list.
- The overall historical URL corpus is somewhat smaller, though for most targets the Wayback + CommonCrawl CDX fallback covers the majority of historically observed URLs.

**Degradation signal.** `[TOOL-UNAVAILABLE:gau]`

---

### cmux browser

**What it does.** `cmux` is a terminal multiplexer that ships with an integrated WebKit browser surface. When beacon is running inside a `cmux` session, it can drive the browser to load a target URL, execute JavaScript, take accessibility snapshots, and interact with the DOM. Beacon uses this in Phase 11 (Active Browse) to capture the live rendered state of a page — including dynamically injected content, SPA routing behavior, and client-side technology signatures that are invisible to a plain HTTP client.

**Why it helps beacon.** Phase 11 is the only phase that can observe a site as a real user's browser would see it: fully rendered, with all client-side JavaScript executed. This enables detection of lazy-loaded content, client-side routing structures, and technologies that only reveal themselves after JavaScript runs.

**How to get it.** cmux is part of specific Claude Code environments and is not a standalone installable tool. If you are running beacon inside a cmux session, the `CMUX_SURFACE_ID` environment variable will be set and beacon will detect it automatically.

**What you miss without it.**

- Phase 11 is either skipped entirely or falls back to Chrome DevTools MCP (see below).
- Client-side technology fingerprints that require JavaScript execution are not captured.
- Dynamic routing paths and SPA navigation patterns are not observed.
- JavaScript errors and console output from the live page are not collected.

**Degradation signal.** `[TOOL-UNAVAILABLE:cmux]` (Phase 11 falls back to Chrome DevTools MCP; if that is also absent, `[PHASE-11-SKIPPED]` is emitted)

---

### Chrome DevTools MCP

**What it does.** The Chrome DevTools MCP server exposes browser automation via the Chrome DevTools Protocol, allowing beacon to open pages, evaluate JavaScript, capture screenshots, and inspect network requests. It serves as the fallback for Phase 11 when beacon is not running inside a `cmux` session.

**Why it helps beacon.** It provides the same functional capability as cmux browser (live page rendering, JS execution, DOM inspection) in environments where cmux is not available — for example, a standard terminal or a remote Claude Code session.

**How to add it to Claude Code.** Add the Chrome DevTools MCP server to your Claude Code session configuration. It requires a running Chrome or Chromium instance with the DevTools Protocol port exposed (typically `--remote-debugging-port=9222`). Consult the MCP server's documentation for the exact setup.

**What you miss without it.**

- If both cmux and Chrome DevTools MCP are absent, Phase 11 is skipped entirely and `[PHASE-11-SKIPPED]` is logged.
- The same live-rendering capabilities described under cmux browser are unavailable.

**Degradation signal.** `[TOOL-UNAVAILABLE:chrome-devtools-mcp]` (Phase 11 falls back to cmux browser; if that is also absent, `[PHASE-11-SKIPPED]` is emitted)

---

## Degradation Signal Reference

Use this table to quickly diagnose a signal you have seen in a beacon research output.

| Signal | What caused it | Phase affected | How to resolve |
|---|---|---|---|
| `[TOOL-UNAVAILABLE:wappalyzer]` | Wappalyzer MCP server not present in the Claude Code session | Phase 3 (Fingerprint) | Add the Wappalyzer MCP server to your Claude Code config; see the Wappalyzer section above |
| `[TOOL-UNAVAILABLE:firecrawl]` | Firecrawl MCP server not in session AND `firecrawl` CLI binary not on `PATH` | Phase 2 (URL Discovery), Phase 6 (Content Retrieval) | Install the Firecrawl CLI or add the Firecrawl MCP server; see the Firecrawl section above |
| `[TOOL-UNAVAILABLE:gau]` | `gau` binary not found on `PATH` | Phase 9 (OSINT — URL History) | Install GAU; see the GAU section above |
| `[TOOL-UNAVAILABLE:cmux]` | Beacon is not running inside a `cmux` session (`CMUX_SURFACE_ID` not set) | Phase 11 (Active Browse) | Run beacon inside a cmux session, or install Chrome DevTools MCP as the fallback |
| `[TOOL-UNAVAILABLE:chrome-devtools-mcp]` | Chrome DevTools MCP server not present in the Claude Code session | Phase 11 (Active Browse) | Add the Chrome DevTools MCP server to your Claude Code config; see the Chrome DevTools MCP section above |
| `[PHASE-11-SKIPPED]` | Both `cmux` browser and Chrome DevTools MCP are absent | Phase 11 (Active Browse) | Install either browser tool; accept the limitation if live rendering is not needed |
| `[FRAMEWORK-UNKNOWN]` | No technology pack matched the detected framework or no framework was detected | Phase 3 (Fingerprint) | Install Wappalyzer MCP for better detection; or the target site may use a stack not yet in beacon's tech pack library |
| `[TECH-PACK-UNAVAILABLE:f:v]` | A tech pack for framework `f` at version `v` exists as a known framework but the pack file is not present in the beacon repository | Phase 3 (Fingerprint), Phase 5 (Tech Pack Load) | Pull the latest beacon skill updates, which may include the missing tech pack; or contribute the pack |
| `[GENERATED-INLINE:path]` | A script at `path` could not be downloaded (GitHub raw URL unreachable and no local `.beacon/` cache entry) | Any script-dependent phase | Check network connectivity to GitHub; or pre-cache the script in `.beacon/` |

---

## Minimum Viable Setup

### Tier 1: curl only

This is the absolute minimum. You need `curl` on `PATH` plus standard Unix utilities (`grep`, `awk`, `sort`, `uniq`).

**What you get:**

- HTTP response headers and status codes for target URLs
- Raw HTML content of pages that do not require JavaScript rendering
- `/robots.txt` and `/sitemap.xml` if the target publishes them
- Basic technology signals from `Server`, `X-Powered-By`, and `X-Generator` headers
- Historical URL data from the Wayback CDX and CommonCrawl CDX APIs (these are HTTP APIs that curl can reach directly)
- DNS and certificate information via `curl` and `openssl`

**What you miss:**

- Structured technology fingerprinting — you will see `[TOOL-UNAVAILABLE:wappalyzer]` and generic signals like `server: nginx` rather than `framework: Next.js 14.2`
- Full site URL maps beyond what `/sitemap.xml` provides — you will see `[TOOL-UNAVAILABLE:firecrawl]`
- JS-rendered page content for SPA targets
- OTX and URLScan URL history — you will see `[TOOL-UNAVAILABLE:gau]`
- Any live browser interaction — you will see `[PHASE-11-SKIPPED]`

Tier 1 is useful for quick checks on simple, server-rendered targets where technology detection from headers is sufficient and a complete URL surface is not required.

---

### Tier 2: Recommended setup

Add **Wappalyzer MCP** and **Firecrawl MCP** to your Claude Code session on top of the Tier 1 baseline.

**What this unlocks over Tier 1:**

- Full structured technology fingerprinting: framework, version, CMS, CDN, analytics, tag managers, A/B testing tools — the complete Wappalyzer detection pattern library instead of header-only signals
- Complete URL surface mapping including JS-rendered sites, not just what `/sitemap.xml` publishes
- JS-rendered page content retrieval in Phase 6, making beacon useful against React, Vue, Angular, and other SPA targets
- The `[TOOL-UNAVAILABLE:wappalyzer]` and `[TOOL-UNAVAILABLE:firecrawl]` signals will no longer appear

**Still missing at Tier 2:**

- OTX + URLScan URL history (`[TOOL-UNAVAILABLE:gau]` will still appear unless you install GAU)
- Live browser interaction (`[PHASE-11-SKIPPED]` will still appear unless you add cmux or Chrome DevTools MCP)

For most reconnaissance tasks on modern web targets, Tier 2 represents a strong balance between setup cost and output quality. Installing GAU is a one-time step that also materially improves historical URL coverage and is recommended if you run beacon against targets where historical endpoint discovery matters.
