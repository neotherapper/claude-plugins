# reframe

Turn any live site into a purpose-driven redesign brief for Claude Design.

`reframe` is a Claude Code plugin that reads an existing website — its content, structure, and information architecture — and produces a concise, high-signal brief that you paste into [claude.ai/design](https://claude.ai/design) to drive a redesign grounded in what the site should *accomplish*, not just what it currently looks like.

**Claude Design captures what a site looks like. reframe argues what it should accomplish and why the current one underperforms.**

---

## Entrypoint

```
/reframe:analyze <url>
```

Runs the full 9-phase pipeline on the given URL and writes output to `docs/sites/{site-slug}/redesign/`.

---

## Output folder layout

```
docs/sites/{site-slug}/redesign/
├── INDEX.md              — summary, assumptions header, coverage manifest, how to use
├── brief.md             — THE Claude Design onboarding brief (the headline deliverable)
├── run-sheet.md         — sequential canvas prompts (screens/components)
├── content-inventory.md  — evaluative content audit (keep/revise/consolidate/remove + ROT flags)
├── ia-map.md            — information architecture + journeys + conversion path
├── current-critique.md   — keep/fix vs category best-practice (incl. screenshots referenced)
└── .crawl/              — raw per-page markdown + screenshots (git-ignored working data)
```

Slug derivation: strip `www.`, then `example.com` → `example-com`.
`.crawl/` is git-ignored (raw HTML dumps and PNGs are not committed); the five markdown files and the brief are the committed artifacts.

---

## Category packs

reframe ships with **5 category packs** (`plugins/reframe/categories/`); ~10 are planned. Each pack contains:

- Category-specific redesign priorities and conversion patterns
- Trust signals and IA conventions for that category
- Opinionated design-system seed values (palette / type / motion stance)
- Reference and anti-reference sites
- "What to emphasize in the brief"

**Available now:** `local-service`, `saas-marketing`, `ecommerce`, `portfolio-personal`, plus a `generic` fallback for ambiguous sites.
**Planned (v1.1):** `editorial-blog`, `nonprofit`, `restaurant-hospitality`, `corporate-brochure`, `education-course`, `events` — until they ship, these detect to `generic`.

Category is detected automatically in Phase 7. Low confidence falls back to `generic`. Multi-category sites use the dominant pack with secondaries noted inline.

---

## How to use the output

1. Run `/reframe:analyze <url>` — the pipeline writes `docs/sites/{slug}/redesign/` to your project.
2. Open `brief.md` — read the **Assumptions header** first; correct any wrong inferences before using.
3. In [claude.ai/design](https://claude.ai/design), paste the full contents of `brief.md` as your onboarding prompt.
4. Enable **web-capture** on the live URL — Claude Design uses it for current content, structure, and brand assets to KEEP only. The design direction in the brief overrides all captured visual styling (this is intentional — you are redesigning, not cloning).
5. Follow `run-sheet.md` for sequenced canvas prompts: onboarding → palette/hero validation → key screens → remaining screens/components.

---

## Design spec

Full design rationale, pipeline phases, and architecture decisions:
[`docs/plugins/reframe/designs/2026-06-21-reframe-v0.1.0-design.md`](../../docs/plugins/reframe/designs/2026-06-21-reframe-v0.1.0-design.md)

---

## Installation

### Claude Code
```
/plugin marketplace add neotherapper/claude-plugins
/plugin install reframe@neotherapper-plugins
```
