# SEO — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

SEO scores any site's SEO health — technical audits, on-page analysis, JSON-LD
structured-data validation, and Core Web Vitals. Outputs land at
`docs/sites/{site-slug}/seo/` as a structured, queryable report folder.

**Current version:** 0.1.0

**Commands:** `/seo:audit {url}` · `/seo:technical {url}` · `/seo:on-page {url}`

The plugin is callable by beacon and reframe: beacon reuses recon data, reframe
reads the audit output to populate `current-critique.md` SEO section. A
paidagogos curriculum (`seo-developer-mastery.md`) teaches the underlying methodology
in 12 lessons.

---

## File map

```
plugins/seo/
├── README.md                                ← user-facing overview (ships)
│
├── .claude-plugin/plugin.json               ← manifest: name, version, skills, agents, commands
│
├── skills/
│   ├── site-audit/
│   │   ├── SKILL.md                         ← 8-phase audit orchestrator (/seo:audit)
│   │   └── references/
│   │       ├── scoring-model.md             ← 0-100 weighted scoring breakdown
│   │       ├── free-tools.md                ← no-API-key fallbacks (httpx, pagespeed CLI, etc.)
│   │       ├── cli-tools.md                 ← nikai tools/cli/ integration via subprocess
│   │       ├── phase-detail.md              ← detailed per-phase instructions
│   │       ├── beacon-integration.md        ← how to read docs/sites/{slug}/research/
│   │       ├── reframe-integration.md       ← how to populate current-critique SEO section
│   │       └── top-issues.md                ← {{TOP_5_ISSUES}} selection algorithm
│   ├── technical-audit/
│   │   ├── SKILL.md                         ← /seo:technical — technical SEO specialist
│   │   └── references/
│   │       ├── rules-meta.md                ← 12 meta tag rules with thresholds
│   │       ├── rules-content.md             ← 9 content rules
│   │       ├── rules-technical.md           ← 10 technical rules
│   │       └── rules-performance.md         ← 6 CWV rules
│   └── on-page-audit/
│       ├── SKILL.md                         ← /seo:on-page — on-page SEO specialist
│       └── references/
│           ├── heading-structure.md         ← heading hierarchy analysis patterns
│           ├── schema-validation.md         ← JSON-LD extraction + validation
│           └── internal-linking.md          ← internal link analysis patterns
│
├── agents/
│   └── seo-analyst.md                       ← subagent for parallel audit delegation
│
├── templates/
│   ├── INDEX.md.template                    ← summary, overall score, top 5
│   ├── seo-report.md.template               ← full scored report
│   ├── technical-audit.md.template          ← CWV, crawlability, indexation
│   └── on-page-audit.md.template            ← meta, headings, schema, content
│
├── scripts/
│   ├── meta_audit.py                        ← title/desc/OG/Twitter/canonical checker
│   ├── heading_audit.py                     ← heading hierarchy analysis
│   ├── structured_data_validate.py          ← JSON-LD extraction + schema validation
│   └── composite_scorer.py                  ← weighted scoring engine
│
└── commands/
    ├── seo-audit.md                         ← /seo:audit command definition
    ├── seo-technical.md                     ← /seo:technical command definition
    └── seo-on-page.md                       ← /seo:on-page command definition
```

---

## Scoring model

Composite 0-100 score across five categories with tiered fallbacks:

| Category | Max | Top tier | Fallback tier |
|----------|-----|----------|---------------|
| Technical | 25 | wired from `technical-audit` (Phase 6) | 0 (v0.1.0 — wired in v0.2.0) |
| On-Page | 25 | full credit when each rule hits | 1 pt when only the "presence" rule passes (e.g. title is present but length is off-band; description present but off-band; OG partially filled) |
| Schema | 20 | full credit when JSON-LD valid + required properties + no deprecated types | per-property partial credit per missing required property |
| Content | 15 | exactly one `<h1>` AND no skipped heading levels | 1 pt each (one H1 alone is 3, no skips alone is 3) — partial credit stacks |
| Performance | 15 | live CWV via chrome-devtools MCP | 0 (v0.1.0 — wired in v0.2.0) |

The 1-point fallback exists because **presence-without-quality** deserves a non-zero score so users see the rule is wired and can act on it. Catch-all patterns like "any non-empty title" earn 1 pt; the 3-pt tier requires the length band, keyword, or alignment the metric asks for.

Mirrored in `skills/site-audit/references/scoring-model.md` (Phase 4) and asserted by `specs/site-audit.feature`.

---

## Output structure (per run)

```
docs/sites/{site-slug}/seo/
├── INDEX.md                                 ← per-run summary, overall score, top 5 issues
├── seo-report.md                            ← full scored report with all findings
├── technical-audit.md                       ← CWV + crawlability + indexation
└── on-page-audit.md                         ← meta + headings + schema + content signals
```

---

## Cross-plugin integration

| Plugin | Direction | Surface |
|--------|-----------|---------|
| **beacon** | read | `docs/sites/{slug}/research/` — tech stack + recon |
| **reframe** | write | `docs/sites/{slug}/redesign/current-critique.md` (SEO section) |
| **paidagogos** | reference | `plugins/paidagogos/skills/paidagogos-micro/references/curricula/seo-developer-mastery.md` |

See `skills/site-audit/references/beacon-integration.md` and
`skills/site-audit/references/reframe-integration.md` for surface contracts.

---

## Related docs

| Doc | Location |
|-----|----------|
| Feature specs (.feature) | `docs/plugins/seo/specs/` |
| Design docs | `docs/plugins/seo/designs/` |
| Implementation plans | `docs/plugins/seo/plans/` (link to `docs/superpowers/plans/2026-07-12-seo-plugin.md`) |
| Architectural decisions | `docs/plugins/seo/DECISIONS.md` |
| Roadmap | `docs/plugins/seo/ROADMAP.md` |
| User-facing README | `plugins/seo/README.md` (shipped with plugin) |
