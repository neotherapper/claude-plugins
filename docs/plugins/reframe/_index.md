# reframe — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

reframe takes the URL of an existing website and produces a purpose-driven redesign brief for [Claude Design](https://claude.ai/design), plus the strategic analysis behind it. It reads a site's content, IA, and structure; evaluates it against category-specific best-practice; and synthesises a concise, high-signal brief that — pasted into Claude Design alongside its native web-capture — drives a redesign grounded in what the site should *accomplish*, not what it currently looks like.

**The job in one line:** Claude Design captures what a site looks like; reframe argues what it should accomplish and why the current one underperforms.

**Current version:** 0.1.0

**Command:** `/reframe:analyze {url}`

---

## File map

```
plugins/reframe/
├── README.md                          ← user-facing overview (ships)
├── CHANGELOG.md                       ← version history
│
├── .claude-plugin/plugin.json         ← manifest (name, version, description, author)
│
├── commands/
│   └── reframe-analyze.md             ← /reframe:analyze command definition
│
├── skills/
│   └── site-redesign/
│       ├── SKILL.md                   ← 9-phase coverage-first pipeline
│       └── references/                ← on-demand detail files loaded during analysis
│           ├── tool-availability.md   ← crawler detection, WAF fallback chain
│           ├── crawl-and-coverage.md  ← render/coverage gate thresholds, crawl budget
│           └── brief-format.md        ← brief.md section order, intent triplet, seed format
│
├── categories/                        ← pluggable category best-practice packs
│   ├── _TEMPLATE.md                   ← canonical pack structure (8 sections)
│   ├── generic.md                     ← low-confidence fallback
│   ├── local-service.md               ← clinics, trades, local professionals
│   ├── saas-marketing.md              ← SaaS product marketing sites
│   └── ecommerce.md                   ← online retail
│
└── templates/                         ← Phase 9 output templates (token-based)
    ├── INDEX.md.template
    ├── brief.md.template
    ├── run-sheet.md.template
    ├── content-inventory.md.template
    ├── ia-map.md.template
    └── current-critique.md.template
```

---

## Output structure (per run)

```
docs/sites/{site-slug}/redesign/
├── INDEX.md              ← summary, assumptions header, coverage manifest, how-to-use
├── brief.md              ← paste-ready Claude Design onboarding brief (headline deliverable)
├── run-sheet.md          ← sequential canvas prompts (validate → key screen → remaining)
├── content-inventory.md  ← evaluative audit (keep/revise/consolidate/remove + ROT flags)
├── ia-map.md             ← nav hierarchy, per-page intent triplets, journeys, conversion path
├── current-critique.md   ← severity-rated findings vs category best-practice + screenshots
└── .crawl/               ← raw per-page markdown + screenshots (git-ignored)
```

Slug derivation: strip `www.`, then `example.com → example-com`.
`.crawl/` is git-ignored; the five markdown files and `brief.md` are the committed artifacts.

---

## Related docs

| Doc | Location |
|-----|----------|
| Feature specs (.feature) | `docs/plugins/reframe/specs/` |
| Design doc | `docs/plugins/reframe/designs/2026-06-21-reframe-v0.1.0-design.md` |
| Implementation plan | `docs/plugins/reframe/plans/2026-06-22-reframe-v0.1.0-implementation.md` |
| Architectural decisions | `docs/plugins/reframe/DECISIONS.md` |
| Testing guide | `docs/plugins/reframe/TESTING.md` |
| Roadmap | `docs/plugins/reframe/ROADMAP.md` |
| User-facing README | `plugins/reframe/README.md` |
