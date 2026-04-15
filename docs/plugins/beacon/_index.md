# Beacon — Plugin Contributor Index

> AI agent entrypoint. Read this file first before modifying anything in this plugin.

## What this plugin does

Beacon maps any website's API surface through a 12-phase systematic analysis — tech fingerprinting, passive recon, script probing, JS analysis, OSINT, browser recon, and OpenAPI spec generation. Output lands in `docs/research/{site-slug}/` as a structured, queryable research folder.

**Current version:** 0.6.0

**Commands:** `/beacon:analyze {url}` · `/beacon:load`

---

## File map

```
plugins/beacon/
├── README.md                        ← user-facing overview (ships)
├── CONTRIBUTING.md                  ← contributor guide
├── CHANGELOG.md                     ← version history
│
├── .claude-plugin/plugin.json       ← manifest (name, version, hooks pointer)
│
├── commands/
│   ├── beacon-analyze.md            ← /beacon:analyze command definition
│   └── beacon-load.md               ← /beacon:load command definition
│
├── skills/
│   ├── site-recon/
│   │   ├── SKILL.md                 ← /beacon:analyze — 12-phase analysis
│   │   └── references/              ← on-demand detail files loaded during analysis
│   │       ├── browser-recon.md     ← Phase 11: browser tool signatures, HAR→OpenAPI
│   │       ├── osint-sources.md     ← Phase 9: CDX APIs, crt.sh, dorking, sitemap mining
│   │       ├── output-synthesis.md  ← Phase 12: how to write all output files from session brief
│   │       ├── phase-detail.md      ← Phases 2, 5–7, 9: probe URLs, bash commands, CDX params
│   │       ├── session-brief-format.md ← complete session brief schema
│   │       └── tool-availability.md ← tool detection, fallback matrix, browser command ref
│   └── site-intel/
│       └── SKILL.md                 ← /beacon:load — query pre-built research docs
│
├── agents/
│   └── site-analyst.md              ← JS analysis, OSINT correlation, tech-pack application
│
├── technologies/                    ← tech-pack guides per framework/version
│   ├── astro/5.x.md
│   ├── django/5.x.md
│   ├── fastapi/0.x.md
│   ├── ghost/5.x.md
│   ├── graphql/generic.md           ← protocol-level, not framework-specific
│   ├── laravel/12.x.md
│   ├── nextjs/15.x.md
│   ├── nuxt/3.x.md
│   ├── rails/8.x.md
│   ├── shopify/2024-10.md
│   ├── strapi/5.x.md
│   └── wordpress/6.x.md
│
├── templates/                       ← Phase 12 output templates (token-based)
│   ├── INDEX.md.template
│   ├── tech-stack.md.template
│   ├── site-map.md.template
│   ├── constants.md.template
│   ├── api-surface.md.template
│   └── smoke-test.sh.template
│
├── schemas/
│   ├── tech-pack.schema.json        ← JSON Schema for tech pack frontmatter validation
│   └── output.schema.json           ← JSON Schema for research output structure
│
├── scripts/
│   ├── checksums.sha256             ← SHA256 hashes for downloaded probe scripts
│   └── core/
│       └── har-reconstruct.py       ← converts .har capture to OpenAPI spec
│
└── hooks/
    ├── hooks.json                   ← SessionStart hook registration
    └── session-start.sh             ← hook script
```

---

## Output structure (per run)

```
docs/research/{site-slug}/
├── INDEX.md                         ← summary, infrastructure table, quick API reference
├── tech-stack.md                    ← framework, version, CDN, auth, hosting evidence
├── site-map.md                      ← all discovered URLs grouped by phase
├── constants.md                     ← taxonomy IDs, nonces, enums, public config values
├── api-surfaces/
│   └── {surface}.md                 ← one file per discovered API surface
├── specs/
│   └── {site-slug}.openapi.yaml     ← auto-downloaded, HAR-generated, or scaffolded
└── scripts/
    └── test-{site-slug}.sh          ← runnable smoke tests for key endpoints
```

---

## Validation scripts

All in `tests/`. Run before any PR:

| Script | What it checks |
|--------|---------------|
| `validate-fingerprinting.sh` | Phase 1 slug correctness + Phase 3 coverage for all 12 tech packs |
| `validate-tech-pack.sh <file>` | 12 checks: frontmatter fields, 10 sections, ≥5 probe items |
| `validate-browser-recon.sh` | 15 checks on browser-recon.md content and tool signatures |
| `validate-output-synthesis.sh` | 11 checks on output-synthesis.md content and token references |
| `validate-constants-template.sh` | 16 checks on constants.md.template tokens and sections |
| `validate-smoke-test-template.sh` | 11 checks on smoke-test.sh.template tokens and structure |
| `validate-schemas.sh` | 19 checks on JSON schema files |
| `validate-templates.sh` | 24 checks across all output templates |

---

## Related docs

| Doc | Location |
|-----|----------|
| Feature specs (.feature) | `docs/plugins/beacon/specs/` |
| Design docs | `docs/plugins/beacon/designs/` |
| Implementation plans | `docs/plugins/beacon/plans/` |
| Architectural decisions | `docs/plugins/beacon/DECISIONS.md` |
| Testing guide | `docs/plugins/beacon/TESTING.md` |
| Roadmap | `docs/plugins/beacon/ROADMAP.md` |
| User-facing README | `plugins/beacon/README.md` |
