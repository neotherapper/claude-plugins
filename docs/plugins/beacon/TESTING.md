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

## Output folder assertions

After a successful `/beacon:analyze` run, verify:

```
docs/research/{site}/
├── INDEX.md          — table of contents with links to all sub-documents
├── tech-stack.md     — detected frameworks, versions, CDN, hosting
├── site-map.md       — discovered routes and URL patterns
├── api-surfaces.md   — all discovered endpoints with methods and payloads
└── openapi.yaml      — generated OpenAPI 3.x spec
```

Each file must be non-empty and contain the sections listed in the site-recon SKILL.md.

---

## Phase coverage checklist

Run `/beacon:analyze` on a known site and verify each phase produces output:

| Phase | Verification |
|-------|-------------|
| Tech fingerprinting | `tech-stack.md` names at least one framework |
| Tech-pack load | Claude references the framework-specific guide by name |
| OSINT | `api-surfaces.md` includes endpoints from non-HTML discovery |
| Script probing | Source map or bundle endpoint listed if applicable |
| Browser recon | At least one browser-derived route in `site-map.md` |
| OpenAPI generation | `openapi.yaml` parses as valid YAML with at least one path |

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
2. Verify Claude loads `technologies/nextjs/15.x.md`, not `13.x.md`
3. If version cannot be determined, verify Claude loads the latest available guide and notes the uncertainty

---

## Regression checklist before any PR

- [ ] `/beacon:analyze` completes all 12 phases without halting
- [ ] Output folder created at `docs/research/{site}/` with all 5 files
- [ ] `/beacon:load` routes to correct research without re-running
- [ ] Tech-pack version matched correctly for tested frameworks
- [ ] Availability check falls back gracefully: CF → Porkbun → whois
- [ ] OSINT phase respects rate limits and does not error on empty results
