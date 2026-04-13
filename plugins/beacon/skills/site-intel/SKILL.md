---
name: site-intel
description: Route questions about a known site to its pre-built research docs in docs/research/{site}/. Use when the user asks questions about a site that has already been analysed — how to query it, what endpoints exist, what tech it uses, what category IDs it has. Triggers on questions about specific sites that have a docs/research/ folder.
---

# site-intel — Router Mode

> **Status: Stub** — Full skill implementation pending. Use `skill-creator` to develop this skill following the spec at `docs/specs/site-intel.feature`.

## Purpose

Routes questions about a known site to the correct pre-built research file.
Mirrors the `data-source-research` pattern.

## Routing Logic

1. Open `docs/research/{site-name}/INDEX.md` first.
2. Based on the question, route to one specific file:

| Question about | Open |
|---------------|------|
| Tech stack, infrastructure | `tech-stack.md` |
| Available pages, URL patterns | `site-map.md` |
| Taxonomy values, IDs, enums | `constants.md` |
| A specific API endpoint | `api-surfaces/{surface}.md` |
| OpenAPI spec | `specs/{site}.openapi.yaml` |
| How to query the site | `scripts/test-{site}.sh` |

3. Quote concrete endpoint constraints, auth requirements, and field names.
4. If no research exists: direct user to run `/beacon:analyze {url}`.

See `docs/specs/site-intel.feature` for acceptance scenarios.
