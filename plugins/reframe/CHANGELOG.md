# Changelog

All notable changes to this project will be documented in this file.

## 0.1.0 — 2026-06-22

Initial release.

- **9-phase pipeline:** Scaffold + tool check → Structure discovery → Render + coverage gate → Content crawl + screenshots → Content audit → IA / journey map → Intent inference → Current-design critique → Synthesize
- **Coverage-first architecture:** Render gate escalates JS-rendered SPAs to a markdown crawler (Jina → Firecrawl → Crawl4AI); content-sufficiency gate detects placeholder sites and enters greenfield mode before inferring
- **Content-extraction preference:** Jina Reader → Firecrawl → Crawl4AI (Crawl4AI used only if installed); Chrome DevTools MCP reserved for authenticated/interactive flows and element screenshots, not default content extraction
- **Category packs** bundled locally: `local-service`, `saas-marketing`, `ecommerce` — plus a `generic.md` fallback; the rest of the ~10-category taxonomy follows in subsequent releases
- **Two-stage deliverable:** `brief.md` (Claude Design onboarding block) + `run-sheet.md` (sequenced canvas prompts)
- **Evaluative content audit** (`content-inventory.md`) with keep / revise / consolidate / remove verdicts + ROT flags
- **IA / journey map** (`ia-map.md`) with primary conversion path and per-page intent triplets
- **Current-design critique** (`current-critique.md`) severity-rated 0–4, principle-cited, with concrete fixes
- **WAF fallback chain:** Firecrawl → Jina → browser-fetch
- **Graceful degradation:** 9 annotated failure modes (`[RENDER-ESCALATED]`, `[WAF-BLOCKED]`, `[GREENFIELD-MODE]`, etc.)
- **Beacon interop:** reads `docs/research/{slug}/tech-stack.md` if present for the tech-constraint note; never requires a prior Beacon run
- **Output lives under the shared `docs/sites/{slug}/` workspace** (alongside beacon's `research/`)
