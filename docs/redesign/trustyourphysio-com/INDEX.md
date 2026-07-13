# Trust Your Physio — Redesign Brief Index

**Analysed:** 2026-06-22   **Target:** https://trustyourphysio.com   **Category:** local-service (confidence: high)

## Assumptions (edit if wrong)
- **Inferred purpose:** Solo-practitioner online physiotherapy practice (Athens, Greece) — flagship product is an 8-week Active Life Programme for knee/hip pain; secondary: home-visit sessions, PDF guides.
- **Target purpose:** Same as inferred (same-purpose redesign — no pivot declared).
- **Audience:** Greek-speaking adults 50+ with knee/hip pain or osteoarthritis; secondary: English-speaking patients and younger active adults.
- **Primary goal:** Drive "Book Free Call" applications to the Active Life Programme.

## Coverage

| URL | Status | Method |
|-----|--------|--------|
| / (homepage) | Rendered — full content | SPA render via Chrome DevTools (prior session); homepage.json in .crawl/ |
| /about | Partial — static HTML near-empty | WebFetch (SPA, no JS render); Chrome timed out on second attempt |
| /contact | Partial — static HTML near-empty | WebFetch (SPA, no JS render) |
| /programme, /services/*, /guides, /blog | Not crawled — inferred from nav | — |

**Signals fired:** `[RENDER-ESCALATED]` `[NO-SITEMAP]` `[PACK-LOADED:local-service]` `[SAMPLED:1-template]`

Note: This is a smoke-test run with hard bounds (≤3 pages, no re-screenshots). A production run should render all SPA routes via Chrome DevTools to complete the content audit.

## Files
| File | Contents |
|------|----------|
| [brief.md](brief.md) | Paste-into-Claude-Design onboarding brief |
| [run-sheet.md](run-sheet.md) | Sequential canvas prompts (screens/components) |
| [content-inventory.md](content-inventory.md) | Evaluative content audit |
| [ia-map.md](ia-map.md) | Information architecture + journeys |
| [current-critique.md](current-critique.md) | Keep/fix findings vs category best-practice |

## How to use
1. Open [claude.ai/design](https://claude.ai/design), start a project.
2. Paste **brief.md** as the opening message; attach `.crawl/screenshots/homepage-above-fold.png`.
3. Let Claude Design **web-capture https://trustyourphysio.com** for content/brand-assets only (the brief says so).
4. Validate the palette and one hero screen, then run **run-sheet.md** prompts in order.
5. After the homepage hero is approved, proceed with remaining screens (Step 3) in severity order per the run-sheet.
