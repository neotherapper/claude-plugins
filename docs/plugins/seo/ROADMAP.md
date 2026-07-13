# SEO — Roadmap

Planned features and capabilities in priority order. Each version ships as a
complete, tested unit.

> **Status legend:** ✅ shipped · 🔜 next · 📋 planned

---

## v0.1.0 — MVP Audit 🔜

**Goal:** Score any site's SEO health with zero API keys, reuse beacon / reframe data, support paidagogos teaching.

**What ships:**
- 8-phase site audit (`/seo:audit {url}`)
- Meta tag audit (title, description, OG, Twitter, canonical, hreflang, lang, favicon)
- Heading hierarchy analysis (h1-uniqueness, level skips, empty headings)
- JSON-LD structured-data extraction and required-property validation
- Weighted 0-100 scoring (Technical 25 · On-Page 25 · Schema 20 · Content 15 · Performance 15)
- 4 output templates (INDEX, seo-report, technical-audit, on-page-audit)
- Beacon integration (read `research/tech-stack.md`, skip redundant detection)
- Reframe integration (write SEO section of `current-critique.md`)
- Paidagogos curriculum: `seo-developer-mastery.md` (12 lessons)
- 4 Python CLI scripts under `plugins/seo/scripts/`
- `/seo:audit`, `/seo:technical`, `/seo:on-page` commands
- 1 subagent: `seo-analyst` for parallel delegation

**Not yet:** live CWV data (chrome-devtools MCP wiring), multi-page crawl, SERP/competitor analysis.

---

## v0.2.0 — Live Core Web Vitals 📋

**Goal:** Wire Chrome DevTools MCP performance traces into the Performance category of the scoring model.

**What ships:**
- `performance_start_trace` + `performance_analyze_insight` for LCP, INP, CLS in `site-audit` Skill Phase 7
- nikai `pagespeed` CLI fallback when MCP unavailable
- `{{LCP}}`, `{{INP}}`, `{{CLS}}`, `{{FCP}}`, `{{TTFB}}` populated in `technical-audit.md` from real data
- Performance score (15 pts) wired into the composite scorer output
- Technical score (25 pts) wired in (currently 0 until robots.txt/sitemap parsing ships)

**Replaces:** the `[CWV-UNAVAILABLE]` placeholder path from v0.1.0.

---

## v0.3.0 — Multi-Page Crawl 📋

**Goal:** Detect issues that only show up at scale (duplicate titles, orphan pages, sitemap mismatch).

**What ships:**
- Crawl up to N pages (configurable depth, default 50)
- Duplicate title and meta-description detection across the crawl set
- Internal-linking graph (who links to whom) → `internal-links.md`
- Sitemap vs crawled-URL overlap report
- Orphan page detection (sitemap URLs never linked internally)
- robots.txt compliance check (URLs blocked in robots.txt but listed in sitemap)

---

## v0.4.0 — SERP & Competitive Comparison 📋

**Goal:** Answer "where does this site rank" and "how does it compare to competitors".

**What ships:**
- SERP position check via nikai `serper` CLI (2,500 free queries/month)
- Keyword-overlap comparison vs competitor domain
- Side-by-side scoring (`{competitor}.seo-report.md` per competitor)
- Keyword density analysis for target URL vs page-1 results
- Content gap report (keywords page-1 ranks for, target URL doesn't)

**Prereq:** v0.3.0 crawl (to know what URLs to compare).

---

## v0.5.0 — AI Search / GEO 📋

**Goal:** Prepare site for citation by generative search (Perplexity, ChatGPT search, Google AI Overviews).

**What ships:**
- `llms.txt` generation at site root
- AI crawler accessibility check (GPTBot, ClaudeBot, PerplexityBot, Google-Extended in robots.txt)
- Content citability scoring (definition clarity, factual density, source links)
- GEO-specific structured-data patterns (author E-E-A-T signals, datePublished freshness, claim provenance)
- Validation that key facts appear as explicit, parseable statements

---

## v1.0.0 — Full Platform 📋

**Goal:** Production-grade audit pipeline with monitoring and CI integration.

**What ships:**
- Dashboard / history (track score over time per site)
- CI/CD integration (GitHub Action: `claude-plugins/seo-action`)
- Score-regression alerts (Alert if score drops >5 pts week-over-week)
- Google Search Console API integration (indexation, query data, link data)
- Bulk website audit (input list of domains, audit each, output comparison table)

---

## Phase Enhancement Backlog

Improvements that don't require a version bump — suitable for patch releases.

### Site-audit Phase 1 — Scaffold

**Multi-tool path fallback.** Today, scripts live at `${CLAUDE_PLUGIN_ROOT}/scripts/`
for Claude Code and `plugins/seo/scripts/` for other agents. Document the
fallback in `free-tools.md` so non-Claude-Code agents never silently skip the
audit because of the wrong path.

### Site-audit Phase 7 — CWV

**Threshold tightening.** The current `LCP < 2.5s` threshold is Google's
"Good" boundary. Real audit reports should additionally flag `Needs Improvement`
(2.5–4.0s) and `Poor` (>4.0s) bands so users see whether they are *near* the
threshold, not just whether they fail it.

### On-page audit — Schema validation

**Add JSON-LD `@graph` flattening.** Many CMSs emit `@graph` arrays of multiple
types in a single block. The validator must walk each `@graph[].@type` node and
apply the per-type required-property check, not just the top-level `@type`.

### On-page audit — Internal linking

**Link context extraction.** Currently we count links; we don't capture
surrounding text (paragraph context) for relevance scoring. Add a 50-char
context snippet per internal link for richer audit reports.

### Technical audit — robots.txt

**Block-list reporting.** When `Disallow: /admin/` is present, the report
should explicitly confirm whether admin pages are linked from public surfaces
(if yes, blocking leaks path discovery signals).

---

## Research sources

External references used during planning. See plan for full table.

| Topic | Reference |
|-------|-----------|
| Weighted scoring model design | `claude-seo` (AgriciDaniel/claude-seo) on GitHub |
| JSON-LD extraction patterns | nikai SEO vault (internal, not in this repo) |
| Free SEO tool fallbacks | nikai research guides (internal) |
| Developer SEO pedagogy | Google Search Central, HubSpot Academy, Semrush Academy |
