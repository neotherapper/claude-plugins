# Beacon OKF producer profile

The authoritative, human/agent-readable schema for `site-recon` output. This is the single
source of truth both `okf_validate.py` and the skill read from — if you're editing a beacon
output file by hand, this is the doc that tells you what's legal.

Beacon is an **OKF producer**: it conforms to Google Cloud's **Open Knowledge Format v0.1**
(published 2026-06-12, Apache 2.0) as its interoperability surface, and layers its own closed
`type` enum + typed producer fields on top. Beacon ships its **own** validator
(`scripts/okf_validate.py`) — it does not import or depend on ai-sdlc's validator, even though
both are modelled on the same OKF base.

## Google OKF v0.1 — the base rules

- A **bundle** is a directory of markdown files; **no manifest required**. Each file is a
  **concept**; its **path is its identity**.
- **Only `type` is required** in frontmatter. Reserved optional fields: `title`, `description`,
  `resource` (URL), `tags`, `timestamp` (ISO 8601). **Producers may add custom fields.**
- **Relationships are plain markdown links** — that is what makes the directory a graph.
- Two reserved filenames: `index.md` (progressive disclosure entrypoint) and `log.md` (change
  history). Beacon's entrypoint is `INDEX.md` (uppercase, `type: site-index`).

## Beacon `type` enum (closed)

An unknown `type` value is a validation failure, by design — fail-closed, not fail-open.

| `type` | File | Notes |
|--------|------|-------|
| `site-index` | `INDEX.md` | the OKF `index.md` entrypoint; links to every other concept |
| `tech-stack` | `tech-stack.md` | framework/version/CDN/auth/hosting |
| `site-map` | `site-map.md` | discovered URLs by category |
| `api-surface` | `api-surfaces/{surface}.md` | one per surface |
| `constants` | `constants.md` | nonces/enums/public config |
| `session-brief` | `.beacon/session-brief.md` | running working memory |
| `phase-checklist` | `.beacon/phase-checklist.md` | phase-by-phase completion tracker |
| `data-source-index` | `INDEX.md` (data mode) | reserved for the open-data recon mode |
| `dataset` | `datasets/{name}.md` (data mode) | reserved |
| `access-profile` | `access.md` (data mode) | reserved |

Note: `openapi-spec` (`specs/{slug}.openapi.yaml`) is referenced by `api-surface` concepts but is
a YAML file, not a frontmattered markdown concept — it is not part of the `type` enum.

## Reserved OKF fields used

`type` (required on every concept), `title`, `description`, `resource`, `tags`, `timestamp`.

## Beacon producer fields (with enums)

| Field | Enum / form | Applies to |
|-------|-------------|-----------|
| `access_mode` | `open-api \| bulk-download \| scrape \| gated \| mixed` | api-surface, index |
| `auth` | `none \| api-key \| oauth \| session \| cac-pki \| account` | api-surface |
| `bot_protection` | `none \| cloudflare \| akamai \| datadome \| perimeterx \| f5 \| recaptcha \| turnstile` | tech-stack, api-surface |
| `verification` | `live-verified \| wayback-verified \| asserted-unverified` | api-surface |
| `status` | `draft \| in-progress \| complete` | all (drives the completion gate) |
| `licensing` | free string (SPDX-ish) | data-source mode |

## Required fields by type

- **`api-surface`**: `type`, `title`, `access_mode`, `auth`, `verification`, `status` — the full
  access triad plus `title`, because an api-surface with an unspecified access mode or auth is
  not usable output.
- **Every other type**: `type`, `status` — the OKF minimum plus the field that drives the
  completion gate.

## Edges (the graph)

Edges are **plain markdown links** (the OKF minimum): `INDEX.md` links to each surface; an
`api-surface` links to its `openapi-spec`. Optional explicit `depends_on`/`feeds_to` frontmatter
lists (ai-sdlc-style) may back the same edges for machine traversal, but are not required by this
profile — markdown links are sufficient for validation.

## Example — `api-surfaces/nav-warnings.md`

```yaml
---
type: api-surface
title: NGA MSI — Broadcast Navigational Warnings
description: Public JSON REST surface for NAV warnings + ASAM.
resource: https://msi.nga.mil/api/publications/broadcast-warn
tags: [maritime, distress, open-data]
timestamp: 2026-07-02T16:55:00Z
access_mode: open-api
auth: none
bot_protection: f5
verification: live-verified
status: complete
openapi: ./specs/nga-msi.openapi.yaml
---
```

## Fail-closed stance

`okf_validate.py` treats all of the following as validation failures:

- missing or unparseable YAML frontmatter;
- a `type` value outside the closed enum above;
- a required field (per "Required fields by type") missing or empty;
- an enum field (`access_mode`, `auth`, `bot_protection`, `verification`, `status`) present with a
  value outside its enum.

Nothing here is best-effort: an unrecognized or malformed concept is a hard failure, not a
warning, so a recon run can never silently ship non-conforming output.
