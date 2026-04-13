---
name: site-recon
description: Analyse a website and produce structured API surface documentation. Use when the user wants to research a new site, map its API surfaces, understand its tech stack, or document how to extract data from it. Triggers on: "analyse this site", "research {url}", "map the API surface of", "document endpoints for", or /beacon:analyze.
---

# site-recon — Research Mode

> **Status: Stub** — Full skill implementation pending. Use `skill-creator` to develop this skill following the spec at `docs/specs/site-recon.feature` and the design at the plugin's design document.

## Purpose

Systematically analyses a website across 12 phases and produces a complete
`docs/research/{site-name}/` folder containing:

- `INDEX.md` — key findings, infrastructure, quick API reference
- `tech-stack.md` — detected framework, version, plugins, bot protection
- `site-map.md` — all discovered routes
- `constants.md` — taxonomy values, IDs, enums
- `api-surfaces/*.md` — one file per discovered API surface
- `specs/*.openapi.yaml` — auto-downloaded or scaffolded OpenAPI spec
- `scripts/test-*.sh` — runnable smoke tests

## Phase Sequence

1. Scaffold output folder structure
2. Passive recon (robots.txt, sitemap, security.txt, well-known URLs, crt.sh)
3. Fingerprint tech stack (Wappalyzer MCP → header/HTML fallback)
4. Load tech pack from GitHub / context7 / web search
5. Apply tech-pack probe checklist
6. Feed & structure discovery (RSS, JSON-LD, GraphQL, API versions)
7. JS bundle & source map analysis
8. OpenAPI auto-detection (15 standard paths)
9. OSINT (Google dorks, GAU/Wayback, CommonCrawl, GitHub code search)
10. Generate browse plan from all findings
11. Active browse via cmux / Chrome DevTools MCP (follows browse plan)
12. Write all output files

See `docs/specs/site-recon.feature` for acceptance scenarios.
See design spec for full phase detail and tool optionality matrix.
