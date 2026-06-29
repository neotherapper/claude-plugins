# Changelog

All notable changes to this project will be documented in this file.

## 0.4.0 — 2026-06-27

Hardening from two real redesign sessions (`amarsolutions.gr`, `trustyourphysio.com`) — see `docs/research/reframe-session-analysis/`. The driving finding: clean output depended on the harness `advisor()` rescuing both runs; these changes move those rescues into the skill.

- **Substance gate** — `check-output-complete.sh` now fails closed unless `INDEX.md`'s new `## Run log` lists all phase markers `[P1✓]`–`[P9✓]` and a `[PACK-LOADED:<cat>]` (greenfield-aware). Two new tokens `{{PHASE_MARKERS}}`/`{{SIGNALS_FIRED}}` (contract 36→38).
- **`[INFER-GUARD]`** — never assert a section is empty/missing/broken from a lossy markdown crawl; cross-check a JS render or raw HTML first. Plus a per-route render check (catches client-side 404 shells).
- **Phase 7 split** — the strategic question is relocatable (after crawl, before deliverables) but category detection is mandatory and gate-enforced.
- **`[RECON-REUSE]` branch** — explicit path for reusing a prior beacon recon (read ALL recon files; live-re-verify homepage; honest provenance tokens).
- **Tool rungs** — local Playwright screenshot/render fallback + Chrome-MCP `--isolated`/lock recovery; Jina pageshot two-step (signed URL → download); Jina HTTP 451 = geo-block note.
- **New `b2b-industrial` category pack** (6th) — quote/RFQ-driven distributors that previously mis-detected as `ecommerce` on dead store pages.
- **Brand-colour sampling** step so seed palettes are measured, not guessed. Reinforced "Write tool, not touch" in Phase 1.

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
