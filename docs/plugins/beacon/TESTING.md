# Beacon — Testing Guide

> How to validate Beacon behaviour against its acceptance criteria.

Beacon has no runtime application code — it is an AI agent system. "Testing" means running the plugin in Claude Code and verifying observable outputs match the Gherkin scenarios in `docs/plugins/beacon/specs/`.

---

## Feature files

| File | What it covers |
|------|---------------|
| `specs/site-recon.feature` | 12-phase analysis, tech fingerprinting, OSINT, OpenAPI generation |
| `specs/site-intel.feature` | Query mode: routing to pre-built research, freshness checks |
| `specs/tech-packs.feature` | Framework guide loading, version matching, fallback behaviour |

---

## Running a scenario

1. Open a project in Claude Code with Beacon installed
2. Identify the scenario to test (copy the `Scenario:` title)
3. Set up the `Given` preconditions manually (existing research folder, target URL, etc.)
4. Run the `When` step as a natural language command
5. Verify each `Then` assertion against actual files and Claude output

---

## Validation scripts

Run these before any PR from the repo root:

```bash
bash tests/validate-fingerprinting.sh       # slug correctness + Phase 3 coverage
bash tests/validate-tech-pack.sh <file>     # validate a single tech pack file
bash tests/validate-browser-recon.sh        # browser-recon.md content checks
bash tests/validate-output-synthesis.sh     # output-synthesis.md content checks
bash tests/validate-constants-template.sh   # constants.md.template tokens
bash tests/validate-smoke-test-template.sh  # smoke-test.sh.template tokens
bash tests/validate-schemas.sh              # JSON schema files
bash tests/validate-templates.sh            # all output templates
```

All scripts exit 0 on full pass, 1 on any failure. Run them in the order above — fingerprinting is the fastest canary check.

---

## Output folder assertions

After a successful `/beacon:analyze` run, verify:

```
docs/research/{site}/
├── INDEX.md               — table of contents with links to all sub-documents
├── tech-stack.md          — detected frameworks, versions, CDN, hosting
├── site-map.md            — discovered routes and URL patterns
├── constants.md           — taxonomy IDs, nonces, enums, public config values
├── api-surfaces/
│   └── {surface}.md       — one file per discovered API surface
├── specs/
│   └── {site}.openapi.yaml — auto-downloaded, HAR-generated, or scaffolded
└── scripts/
    └── test-{site}.sh     — runnable smoke tests for key endpoints
```

Each file must be non-empty and contain the sections listed in the site-recon SKILL.md.

---

## Phase coverage checklist

Run `/beacon:analyze` on a known site and verify each phase produces output:

| Phase | Name | Verification |
|-------|------|-------------|
| 1 | Scaffold | `docs/research/{slug}/` folder created with all subdirectories |
| 2 | Passive recon | `site-map.md` contains at least one URL from robots.txt or sitemap |
| 3 | Fingerprint | `tech-stack.md` names at least one framework with a detection source |
| 4 | Tech pack | Claude references the framework-specific guide by name in output |
| 5 | Known patterns | `site-map.md` includes endpoints from tech pack probe checklist |
| 6 | Feeds & structure | RSS/JSON-LD or GraphQL introspection results captured if applicable |
| 7 | JS & source maps | Bundle endpoints and any source map findings logged |
| 8 | OpenAPI detect | `specs/{slug}.openapi.yaml` present if auto-detected; absence noted if not |
| 9 | OSINT | `api-surfaces/` includes endpoints from CDX or GitHub discovery |
| 10 | Browse plan | Browse plan written to session brief before any browser action |
| 11 | Active browse | At least one browser-derived route in `site-map.md` (or `[PHASE-11-SKIPPED]` in INDEX.md) |
| 12 | Document | All template tokens resolved; no `{{` remaining in any output file |

---

## `/beacon:load` validation

1. Run `/beacon:analyze` on a test site
2. Start a new session
3. Run `/beacon:load` and ask a question about the site's API
4. Verify Claude routes to the correct pre-built file without re-running analysis
5. Verify freshness warning appears if research is older than configured threshold

---

## Tech-pack version matching

1. Fingerprint a site running Next.js 15
2. Verify Claude loads `technologies/nextjs/15.x.md`, not `14.x.md`
3. If version cannot be determined, verify Claude loads the latest available guide and notes the uncertainty

---

## Regression checklist before any PR

- [ ] All validation scripts pass: `bash tests/validate-fingerprinting.sh` and others
- [ ] `/beacon:analyze` completes all 12 phases without halting
- [ ] Output folder created at `docs/research/{site}/` with correct subdirectory structure
- [ ] `api-surfaces/` contains at least one surface file
- [ ] `/beacon:load` routes to correct research without re-running
- [ ] Tech-pack version matched correctly for tested frameworks
- [ ] OSINT phase respects rate limits and does not error on empty results
