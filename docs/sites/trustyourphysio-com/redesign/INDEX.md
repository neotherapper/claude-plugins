# Trust Your Physio — Redesign Brief Index

**Analysed:** 2026-06-24   **Target:** https://trustyourphysio.com/   **Category:** local-service (confidence: high)

## Assumptions (edit if wrong)
- **Inferred purpose:** Market and sell an 8-week online physiotherapy program for knee/hip OA and lower back pain management
- **Target purpose:** Same — same-purpose redesign (improved conversion, credibility, and bilingual clarity)
- **Audience:** Greek-speaking adults 45–70 with chronic OA pain; secondary: English-speaking international patients
- **Primary goal:** Convert site visitors into Active Life Program enrolments via the application form

## Coverage
- Pages enumerated: 3 (/, /about, /book)
- Pages successfully crawled: 2 (/, /about) via Jina Reader (SPA-rendered)
- /book: 404 at crawl time — critical broken CTA
- /guides: referenced on homepage; 404 at crawl time
- Sitemap: empty → `[NO-SITEMAP]` → fell back to homepage nav crawl
- `[SAMPLED:2-templates]` — homepage + about page sampled; book and guides unavailable
- Coverage: Partial — `[COVERAGE-PARTIAL:gated]` for /book (404) and /guides (404)
- Tool: Jina Reader (AVAILABLE) used as primary crawler — SPA content rendered successfully
- Chrome DevTools MCP: not used (text-only per task bounds; `[TOOL-UNAVAILABLE:chrome-mcp]` for this run)
- `[TECH-STACK-ABSENT]` — no docs/sites/trustyourphysio-com/research/tech-stack.md or legacy path found
- `[PACK-LOADED:local-service]` — category detected from signals: physiotherapy, practitioner bio, appointment/booking intent

## Signals fired
- `[NO-SITEMAP]`
- `[SAMPLED:2-templates]`
- `[COVERAGE-PARTIAL:gated]` (two 404 routes)
- `[TOOL-UNAVAILABLE:chrome-mcp]` (not used per task bounds)
- `[TECH-STACK-ABSENT]`
- `[PACK-LOADED:local-service]`

## Files
| File | Contents |
|------|----------|
| [brief.md](brief.md) | Paste-into-Claude-Design onboarding brief |
| [run-sheet.md](run-sheet.md) | Sequential canvas prompts (screens/components) |
| [content-inventory.md](content-inventory.md) | Evaluative content audit |
| [ia-map.md](ia-map.md) | Information architecture + journeys |
| [current-critique.md](current-critique.md) | Keep/fix findings vs local-service best-practice |

## How to use
1. Open [claude.ai/design](https://claude.ai/design), start a project.
2. Paste **brief.md** as the opening message; attach reference screenshots it names (claphamphysio.co.uk for reference).
3. Let Claude Design **web-capture https://trustyourphysio.com/** for content/brand-assets only (the brief says so).
4. Validate the palette + one hero screen, then run **run-sheet.md** prompts in order.

## Priority actions before design
1. **Fix /book (404)** — the primary "Book Position Now" CTA is broken. This is the single most urgent fix before any design work.
2. **Fix /guides (404)** — remove the homepage section or build the page.
3. **Run beacon first** to identify the tech stack before committing to a design export target.
