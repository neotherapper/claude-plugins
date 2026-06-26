# Changelog

All notable changes to this project will be documented in this file.

## 0.3.0 — 2026-06-26

- **New category pack: `portfolio-personal`** (5th pack) — individual designer/developer/freelancer portfolios. Optimises for two co-primary goals (win the next client/role + grow an audience) with an enforced CTA hierarchy so the goals don't compete; covers creative and developer disciplines with per-type variations noted inline. Auto-detected in Phase 7 (38 detect_signals); sites that previously fell back to `generic` now get an opinionated pack. No code change needed — `detect-category.py` discovers it via the `categories/*.md` glob.

## 0.2.0 — 2026-06-24

Deterministic helper scripts for the coverage gates (`coverage-metrics.py`), category detection (`detect-category.py`), and output completeness (`check-output-complete.sh`); the skill prefers them and falls back to inspection when unavailable. First plugin scripts; paths resolved via `${CLAUDE_PLUGIN_ROOT}`.

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
- **Beacon interop:** reads `docs/sites/{slug}/research/tech-stack.md` (falls back to legacy `docs/research/{slug}/tech-stack.md`) for the tech-constraint note; never requires a prior Beacon run
- **Output lives under the shared `docs/sites/{slug}/` workspace** (alongside beacon's `research/`)
